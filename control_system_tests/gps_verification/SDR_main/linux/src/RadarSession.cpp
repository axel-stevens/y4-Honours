#include "pupradar/RadarSession.hpp"

#include "pupradar/IntelHex.hpp"

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstring>
#include <ctime>
#include <iomanip>
#include <sstream>
#include <stdexcept>
#include <thread>
#include <utility>

namespace pupradar {

namespace {

constexpr std::uint8_t kCtrlOut   = 0x40;  // vendor, host→device, recipient=device
constexpr std::uint8_t kCtrlIn    = 0xC0;  // vendor, device→host, recipient=device
constexpr unsigned int kCtrlTimeoutMs = 1000;
constexpr unsigned int kBulkOutTimeoutMs = 1000;

// GUI line 2672: DataLength = 512 + 2048
constexpr std::size_t kBoardInfoReadBytes = 512 + 2048;
// GUI line 2674: PUPradarBoardInfo(1025:1100) — word 1025 (1-based) = byte 2048
constexpr std::size_t kBoardInfoUsefulOffsetBytes = 2048;
// GUI reads 76 words (1025:1100) but only words 0-4 have meaning:
//   word 0 — FA05 signature (checked at GUI line 2675)
//   word 1 — FrequencyBand  (GUI line 2677)
//   word 2 — Num_Tx, Num_Rx, AntennaType (GUI line 2679-2681)
//   word 3 — Version        (GUI line 2682-2683)
// 32 bytes = 16 words gives comfortable headroom over those 4-5 semantic words.
// Hardware note: the device may return fewer bytes than kBoardInfoReadBytes;
// the decode in requestBoardInfo() is therefore bounded by what actually arrived.
constexpr std::size_t kBoardInfoExposedBytes = 32;

// FX2LP high-speed bulk max packet. Every bulk IN request length must be a
// whole multiple of this: ask for less than a packet and the device's next full
// packet overflows the buffer, which libusb reports as LIBUSB_ERROR_OVERFLOW
// and the kernel logs as a buffer overflow against the USB device.
constexpr std::size_t kBulkPacketBytes = 512;

// Ceiling on a single bulk IN request. A whole recording is tens of megabytes;
// asking libusb for all of it at once pins the entire buffer in usbfs, past the
// process-wide budget (usbfs_memory_mb, 16 MB by default on Raspberry Pi OS).
// That does not fail cleanly — it presents as a capture that hangs, or heap
// corruption ("free(): invalid pointer") when the buffers are released.
// Chunking the reads changes nothing on the device: no command is sent between
// them, so the sweep generator is never re-triggered mid-capture.
constexpr std::size_t kMaxBulkRequestBytes = 1024u * 1024u;  // 2048 max-packets

// Ceiling on a single pre-capture drain request. The drain only has to clear a
// FIFO, never a whole recording, so it stays far below the usbfs budget.
constexpr std::size_t kDrainChunkBytes = 64u * kBulkPacketBytes;  // 32 KB

/**
 * @brief Returns the current UTC wall-clock time as an ISO-8601 string.
 * @return Timestamp in the form "YYYY-MM-DDTHH:MM:SSZ" (second resolution).
 */
std::string isoTimestampUtcNow() {
    auto t  = std::chrono::system_clock::now();
    auto tt = std::chrono::system_clock::to_time_t(t);
    std::tm tm{};
#if defined(_WIN32)
    gmtime_s(&tm, &tt);
#else
    gmtime_r(&tt, &tm);
#endif
    std::ostringstream oss;
    oss << std::put_time(&tm, "%Y-%m-%dT%H:%M:%SZ");
    return oss.str();
}

}  // namespace

/**
 * @brief Constructs a RadarSession bound to a USB backend and a firmware image.
 * @param usb               Reference to the USB backend (lifetime must exceed this object).
 * @param firmware_hex_path Path to the FX3 firmware Intel HEX file (e.g. "SDR_USB_FW.hex").
 */
RadarSession::RadarSession(IUsbBackend& usb, std::string firmware_hex_path)
    : usb_(usb), fw_path_(std::move(firmware_hex_path)) {}

/**
 * @brief Packs an opcode/parameter pair into a 512-byte bulk-OUT packet and sends it to EP2.
 *
 * The MCU interprets only the first 16-bit little-endian word (opcode | param << 8), but the
 * full 512-byte max-packet must be sent to avoid FX2LP framing issues observed on some hosts.
 * @param opcode    Command opcode byte (see pupradar::opcode namespace in Protocol.hpp).
 * @param parameter Command parameter byte (semantics depend on opcode).
 * @throws std::runtime_error if fewer bytes than the full 512-byte packet are transferred.
 */
void RadarSession::sendCommand(std::uint8_t opcode, std::uint8_t parameter) {
    auto pkt = makeCommandPacket(opcode, parameter);
    std::size_t n = usb_.bulkWrite(kEpOutBulk, pkt.data(), pkt.size(),
                                    kBulkOutTimeoutMs);
    if (n != pkt.size()) {
        std::ostringstream oss;
        oss << "sendCommand(0x" << std::hex << +opcode << ",0x" << +parameter
            << "): short write " << std::dec << n << "/" << pkt.size();
        throw std::runtime_error(oss.str());
    }
    // Give the MCU time to act on this command before the next one lands.
    // See RadarSession::setCommandDelayUs for why this is not always zero.
    if (cmd_delay_us_ > 0) {
        std::this_thread::sleep_for(std::chrono::microseconds(cmd_delay_us_));
    }
}

/**
 * @brief Downloads the Intel HEX firmware image into FX3 RAM via the Cypress 0xA0 loader protocol.
 *
 * Sequence mirrors usbdownload.cpp:
 *   1. Read CPUCS register (0xE600), set bit 0 to hold the 8051 in reset.
 *   2. Write each HEX data record to its target address via control transfers.
 *   3. Clear CPUCS bit 0 to release reset — the 8051 begins executing firmware.
 *
 * After this returns the chip re-enumerates under a new VID/PID. Callers must invoke
 * IUsbBackend::reopenAfterRenumeration() before issuing any further transfers.
 * @throws std::runtime_error if the HEX file contains no data records or if any
 *         control transfer completes with fewer bytes than expected.
 */
void RadarSession::downloadFirmware() {
    auto records = parseIntelHexFile(fw_path_);
    if (records.empty()) {
        throw std::runtime_error("Firmware HEX has no data records");
    }

    // Step 1: read CPUCS, set bit 0 (hold 8051 in reset), write back.
    std::uint8_t cpucs = 0;
    usb_.controlTransfer(kCtrlIn,  kFwLoaderRequest, kCpucsRegister, 0,
                         &cpucs, 1, kCtrlTimeoutMs);
    cpucs = static_cast<std::uint8_t>(cpucs | kCpucsReset);
    usb_.controlTransfer(kCtrlOut, kFwLoaderRequest, kCpucsRegister, 0,
                         &cpucs, 1, kCtrlTimeoutMs);

    // Step 2: write each data record into 8051 RAM.
    for (const auto& rec : records) {
        if (rec.data.empty()) continue;
        std::size_t n = usb_.controlTransfer(
            kCtrlOut, kFwLoaderRequest, rec.address, 0,
            const_cast<std::uint8_t*>(rec.data.data()),
            rec.data.size(), kCtrlTimeoutMs);
        if (n != rec.data.size()) {
            std::ostringstream oss;
            oss << "Firmware download: short write at addr 0x"
                << std::hex << rec.address << " (" << std::dec
                << n << "/" << rec.data.size() << ")";
            throw std::runtime_error(oss.str());
        }
    }

    // Step 3: clear CPUCS bit 0 → 8051 starts running firmware.
    cpucs = static_cast<std::uint8_t>(cpucs & ~kCpucsReset);
    usb_.controlTransfer(kCtrlOut, kFwLoaderRequest, kCpucsRegister, 0,
                         &cpucs, 1, kCtrlTimeoutMs);
}

/**
 * @brief Sends the 0xFA board-info request and parses the response into last_board_info_.
 *
 * Mirrors the GUI at line 2674: sends opcode kBoardInfoRequest, bulk-reads
 * kBoardInfoReadBytes (512 + 2048) bytes from EP6, then extracts up to
 * kBoardInfoExposedBytes starting at kBoardInfoUsefulOffsetBytes (2048),
 * decoded as little-endian uint16 words.
 *
 * Hardware note: the device may return fewer than kBoardInfoReadBytes bytes.
 * The observed minimum is ~2058 (useful_offset + 10), which covers all 5
 * semantically meaningful words from the MATLAB GUI (lines 2675-2683).
 * The decode is therefore bounded by however many bytes actually arrived,
 * not by the nominal kBoardInfoExposedBytes.
 *
 * @throws std::runtime_error if the bulk read returns fewer than
 *         kBoardInfoUsefulOffsetBytes + 2 bytes (less than 1 uint16 word).
 */
void RadarSession::requestBoardInfo() {
    sendCommand(opcode::kBoardInfoRequest, 0x00);
    std::vector<std::uint8_t> buf(kBoardInfoReadBytes, 0);
    std::size_t n = usb_.bulkRead(kEpInBulk, buf.data(), buf.size(),
                                   /*timeout_ms*/ 2000);
    if (n < kBoardInfoUsefulOffsetBytes + 2) {
        std::ostringstream oss;
        oss << "Board info: short read " << n
            << " bytes (need at least " << (kBoardInfoUsefulOffsetBytes + 2) << ")";
        throw std::runtime_error(oss.str());
    }
    // Decode however many complete uint16 words arrived, up to kBoardInfoExposedBytes.
    const std::size_t avail_bytes = n - kBoardInfoUsefulOffsetBytes;
    const std::size_t decode_bytes = (std::min(kBoardInfoExposedBytes, avail_bytes) / 2) * 2;
    last_board_info_.clear();
    last_board_info_.reserve(decode_bytes / 2);
    for (std::size_t i = 0; i < decode_bytes; i += 2) {
        std::uint8_t lo = buf[kBoardInfoUsefulOffsetBytes + i];
        std::uint8_t hi = buf[kBoardInfoUsefulOffsetBytes + i + 1];
        last_board_info_.push_back(
            static_cast<std::uint16_t>((hi << 8) | lo));
    }
}

/**
 * @brief Full device bring-up, retried until the board info carries FA05.
 *
 * Each attempt (attemptBringUp()) performs the sequence PUPradar_initiating()
 * does in the MATLAB GUI:
 *   1. Open the unprogrammed FX2LP (VID 0x04B4 / PID 0x8613).
 *   2. Claim interface 0, set alternate setting 1 (benign if the descriptor lacks it).
 *   3. Download firmware via the Cypress 0xA0 loader (downloadFirmware()).
 *   4. Wait for the chip to detach and re-enumerate under one of post_fw_candidates.
 *   5. Claim interface 0 and set alternate setting 1 again (now required for bulk EPs).
 *   6. Request board info (requestBoardInfo()) — result available via lastBoardInfo().
 *
 * @param post_fw_candidates Non-empty list of (VID, PID) pairs the chip may present after
 *                           the firmware boots. Tried in order until one opens or the timeout
 *                           elapses.
 * @param reenum_timeout_ms  Maximum time in milliseconds to wait for re-enumeration
 *                           on each attempt (default: 5000 ms).
 * @throws std::invalid_argument if post_fw_candidates is empty.
 * @throws UsbError or std::runtime_error if the final attempt hits a USB failure.
 */
void RadarSession::initialize(
        const std::vector<IUsbBackend::VidPid>& post_fw_candidates,
        unsigned int reenum_timeout_ms) {
    if (post_fw_candidates.empty()) {
        throw std::invalid_argument("Need at least one post-firmware VID/PID candidate");
    }

    // The bring-up handshake is unreliable, so retry it until the board info carries the FA05 signature.   
    constexpr int kMaxInitAttempts = 7;  // GUI's 2 unconditional + 5 retries
    for (int attempt = 1; attempt <= kMaxInitAttempts; ++attempt) {
        std::fprintf(stderr, "[pupradar] init attempt %d/%d\n",
                     attempt, kMaxInitAttempts);
        try {
            attemptBringUp(post_fw_candidates, reenum_timeout_ms);
            if (decodeBoardInfo(last_board_info_).valid) {
                std::fprintf(stderr, "[pupradar] init attempt %d: FA05 OK\n", attempt);
                return;  // FA05 present — device is in a known-good state.
            }
            std::fprintf(stderr, "[pupradar] init attempt %d: no FA05 in board info\n",
                         attempt);
        } catch (const std::exception& e) {
            std::fprintf(stderr, "[pupradar] init attempt %d failed: %s\n",
                         attempt, e.what());
        }
        usb_.close();  // drop the handle so the next attempt opens cleanly
    }
    std::fprintf(stderr,
                 "[pupradar] WARNING: all %d init attempts failed to return a valid\n"
                 "[pupradar]          FA05 board info.",
                 kMaxInitAttempts);
}

/**
 * @brief One pass of the bring-up sequence, as attempted by initialize().
 *
 * Split out so initialize() can retry it. Leaves the board info in
 * last_board_info_; the caller checks it for the FA05 signature.
 *
 * @param post_fw_candidates VID/PID pairs the chip may present after booting.
 * @param reenum_timeout_ms  Re-enumeration wait budget.
 * @throws UsbError or std::runtime_error on any USB failure.
 */
void RadarSession::attemptBringUp(
        const std::vector<IUsbBackend::VidPid>& post_fw_candidates,
        unsigned int reenum_timeout_ms) {
    // Pre-firmware open
    usb_.open(kPreFirmwareVid, kPreFirmwarePid);
    std::fprintf(stderr, "[pupradar]   opened %04X:%04X\n",
                 kPreFirmwareVid, kPreFirmwarePid);

    // Force the chip back to its power-on state before running the loader.
    // NOTE: Firmware already running in FX2 RAM survives it.
    std::fprintf(stderr, "[pupradar]   resetting USB connection\n");
    usb_.resetDevice();
    std::fprintf(stderr, "[pupradar]   reset done\n");

    usb_.claimInterface(kInterfaceNumber);

    // Set alt 1 — this matches PUPradar_initiating ordering. On the
    // unprogrammed FX2LP this is benign because the default descriptor
    // exposes a single interface 0 with one alt setting.
    try {
        usb_.setAltSetting(kInterfaceNumber, kAlternateSetting);
    } catch (const UsbError&) {
        // Some unprogrammed FX2LP descriptors do not have alt 1; ignore here,
    }

    std::fprintf(stderr, "[pupradar]   downloading firmware…\n");
    downloadFirmware();

    // Re-enumeration: chip detaches and re-appears with firmware-defined VID/PID.
    std::fprintf(stderr, "[pupradar]   waiting for re-enumeration…\n");
    usb_.reopenAfterRenumeration(post_fw_candidates.data(),
                                 post_fw_candidates.size(),
                                 reenum_timeout_ms);
    usb_.claimInterface(kInterfaceNumber);
    usb_.setAltSetting(kInterfaceNumber, kAlternateSetting);

    requestBoardInfo();
}

/**
 * @brief Attaches to a board already running firmware, skipping the loader.
 *
 * Opens the post-firmware device, forces a USB re-enumeration, claims
 * interface 0 / alt 1, then reads board info. No firmware download.
 *
 * The re-enumeration is the point of doing this rather than just opening the
 * device: it puts the USB side back to a known state and drops whatever the
 * previous session left queued on the endpoints, without re-running the loader.
 *
 * @param vid Post-firmware Vendor ID.
 * @param pid Post-firmware Product ID.
 * @throws UsbError or std::runtime_error if the device cannot be opened, reset,
 *         claimed, or does not answer the board-info request.
 */
void RadarSession::attachRunning(std::uint16_t vid, std::uint16_t pid) {
    std::fprintf(stderr, "[pupradar] attaching to running device %04X:%04X "
                         "(no firmware download)\n", vid, pid);
    usb_.open(vid, pid);

    std::fprintf(stderr, "[pupradar]   re-enumerating…\n");
    usb_.resetDevice();
    std::fprintf(stderr, "[pupradar]   re-enumeration done\n");

    usb_.claimInterface(kInterfaceNumber);
    usb_.setAltSetting(kInterfaceNumber, kAlternateSetting);
    requestBoardInfo();
    std::fprintf(stderr, "[pupradar] attached: %s\n",
                 decodeBoardInfo(last_board_info_).valid
                     ? "FA05 OK" : "no FA05 — is the board actually running firmware?");
}

/**
 * @brief Pushes a full set of FMCW parameters to the radar over USB.
 *
 * Sends commands in the same order as the MATLAB GUI (SetActiveParameters →
 * Send_Basic_Parameter → Send_PLL_Sawtooth): modulation, sweep time index, sampling
 * number index, Tx mask, Rx mask, then all PLL register bytes for the sawtooth ramp.
 * @param cfg Capture configuration describing the desired waveform. The MVP requires
 *            cfg.modulation == Modulation::Sawtooth; CW is deferred.
 * @throws std::invalid_argument if cfg.modulation is not Modulation::Sawtooth.
 * @throws std::runtime_error on any USB write failure (propagated from sendCommand).
 */
void RadarSession::configure(const CaptureConfig& cfg) {
    if (cfg.modulation != Modulation::Sawtooth) {
        throw std::invalid_argument("MVP supports Sawtooth only (CW deferred)");
    }

    // Order mirrors GUI: SetActiveParameters → Send_Basic_Parameter → Send_PLL_Sawtooth.
    // Modulation
    sendCommand(opcode::kModulation, static_cast<std::uint8_t>(cfg.modulation));
    // Sweep time index
    sendCommand(opcode::kSweepTimeIndex,
                static_cast<std::uint8_t>(cfg.sweep_time_idx));
    // Sampling number index
    sendCommand(opcode::kSamplingNumIndex,
                static_cast<std::uint8_t>(cfg.samp_num_idx));
    // Tx mask
    sendCommand(opcode::kTxMask, cfg.tx_mask);
    // Rx mask
    sendCommand(opcode::kRxMask, cfg.rx_mask);

    // PLL register byte writes (sawtooth)
    auto pll = buildSawtoothPllCommands(cfg.f_low_hz, cfg.f_high_hz,
                                        cfg.sweep_time_idx);
    for (const auto& c : pll) sendCommand(c.opcode, c.param);
}

/**
 * @brief Records cfg.duration_s of IQ the way the GUI's Record button does.
 *
 * Follows PUPradarGUI.m:1831-1859 (Record), NOT the display loop at :203-248:
 *   1. configure() ONCE — basic parameters and PLL registers.
 *   1b. Drain cfg.drain_sweeps of stale FIFO content, then reconfigure. This has
 *      no GUI counterpart in Record itself; it stands in for the Start loop,
 *      which Record can only ever run after and which drains continuously.
 *   2. One logical transfer sized for the whole recording:
 *      NumSweeps = duration / sweep_time, then GUI line 2730's
 *      ceil((NumSweeps+40)*LASN*2*LANR*LANT/512)*512 + 4096 bytes. Issued as a
 *      series of kMaxBulkRequestBytes reads (see that constant); the config is
 *      never re-sent between them, so the device still sees one stream.
 *   4. Drop the leading 4096 stale-FIFO bytes (GUI line 2734) before the sink.
 *
 * The device is deliberately not reconfigured during the transfer. Doing so
 * re-triggers the sweep generator mid-stream, which yields one live sweep per
 * read followed by the mixer output decaying to DC.
 *
 * @param cfg  Capture configuration used for buffer sizing, run duration, and bulk timeout.
 *             Applied by this function; no prior configure() call is needed.
 * @param sink Called once with the de-preambled capture (pointer into an
 *             internal buffer, valid only for the duration of the call).
 * @return CaptureMetadata populated with echoed config values, derived sample rate (fs_hz),
 *         sweep time, actual capture duration, byte and read counts, last board info words,
 *         firmware path, and a UTC ISO-8601 timestamp.
 * @throws std::runtime_error on a USB error during bulk transfer (propagated from bulkRead).
 */
CaptureMetadata RadarSession::captureIq(const CaptureConfig& cfg,
                                         const IqSink& sink) {
    const int n_rx = rxCount(cfg.rx_mask);
    const int n_tx = txCount(cfg.tx_mask);
    const int samples_per_sweep_per_rx =
        samplesPerSweep(cfg.sweep_time_idx, cfg.samp_num_idx, n_rx);
    const double sweep_time_s = sweepTimeFromIndex(cfg.sweep_time_idx);
    const double fs_hz = static_cast<double>(samples_per_sweep_per_rx) / sweep_time_s;

    // GUI line 2728: LASNperSweep = LASN*LANR*2*LANT — that is a count of uint16
    // WORDS per sweep (the *2 is I and Q). Confirmed against real captures: at
    // LASN=128, 1 Rx, 1 Tx the measured marker-to-marker stride is 256 words.
    const std::size_t words_per_sweep =
        static_cast<std::size_t>(samples_per_sweep_per_rx) *
        2u /* I and Q */ *
        static_cast<std::size_t>(n_rx) * static_cast<std::size_t>(n_tx);

    // ...and two bytes per word. The GUI drops this factor: line 2730 builds
    // DataLength from the WORD count, but miniradargetdata hands it to CyAPI
    // XferData as a BYTE count (miniradargetdata.cpp:40), so the GUI actually
    // transfers half the sweeps it asked for — which is why it then has to clamp
    // NumSweeps down to ValidSweepNumber at lines 2744-2748. Mirroring that
    // exactly gave captures half the requested duration, so keep the factor.
    const std::size_t bytes_per_sweep = words_per_sweep * 2u;

    // ---- 1. Size the transfer, as GUI Record does --------------------------
    //
    // GUI Record (PUPradarGUI.m:1831-1859) sets NumSweeps = RecordTime /
    // SweepTime — the whole recording, not a batch — and makes a SINGLE
    // GetComplexData call for it.
    const auto num_sweeps = static_cast<std::size_t>(cfg.duration_s / sweep_time_s);
    const std::size_t raw_bytes = (num_sweeps + 40) * bytes_per_sweep;
    // Round UP to a 512-byte boundary, then add 4096 (GUI line 2730). The extra
    // 4096 exists because the first 4096 bytes are stale FIFO content; the GUI
    // discards exactly that many at line 2734.
    const std::size_t capture_bytes = ((raw_bytes + 511u) / 512u) * 512u + 4096u;

    // ---- 2. Buffer and the read helper both phases share -------------------
    //
    // One max-packet of slack past capture_bytes. libusb hands the whole request
    // to the kernel, which will write a complete packet or fail the transfer, so
    // the destination must always have room for one even when the tail of the
    // capture does not need it.
    std::vector<std::uint8_t> buf(capture_bytes + kBulkPacketBytes, 0);

    using clock = std::chrono::steady_clock;

    // Timeouts scale with the wire rate — the board emits bytes_per_sweep every
    // sweep_time_s — so a chunk gets twice its nominal time plus the configured
    // slack, and the capture as a whole gets twice its own.
    //
    // The old code used (duration + bulk_timeout) as the timeout for EVERY read
    // and only left the loop on a read that returned exactly zero, so a device
    // dribbling a few non-zero bytes per read held it for one duration-length
    // timeout per read, thousands of times over: the capture that "just hangs".
    const double ms_per_byte =
        bytes_per_sweep != 0u
            ? sweep_time_s * 1000.0 / static_cast<double>(bytes_per_sweep)
            : 0.0;
    const auto budget_ms = [&](std::size_t n) {
        return std::chrono::milliseconds(
            static_cast<long long>(2.0 * ms_per_byte * static_cast<double>(n)) +
            cfg.bulk_timeout_ms);
    };
    const unsigned int chunk_timeout_ms =
        static_cast<unsigned int>(budget_ms(kMaxBulkRequestBytes).count());
    // Re-armed at t_start, once configure/drain/reconfigure are done — otherwise
    // every millisecond spent setting the board up is billed to the capture.
    auto capture_deadline = clock::now() + budget_ms(capture_bytes);

    // Fills `buf` up to capture_bytes without reconfiguring, returning the bytes
    // received; clears `completed_out` if it stopped on the deadline instead.
    //
    // Every request length is a whole multiple of the 512-byte endpoint max
    // packet. A bulk IN request that is not gets LIBUSB_ERROR_OVERFLOW the
    // moment the device sends a full packet into the short remainder — which
    // surfaces as a kernel "buffer overflow" against the USB device. Rounding
    // down is what keeps every request legal; the slack in `buf` covers the case
    // where the device answers with a partial packet and leaves total_bytes off
    // a 512-byte boundary.
    auto readCapture = [&](std::size_t& reads_out, bool& completed_out) -> std::size_t {
        std::size_t total = 0;
        while (total < capture_bytes) {
            if (clock::now() >= capture_deadline) { completed_out = false; break; }
            const std::size_t remaining = capture_bytes - total;
            const std::size_t request =
                (std::min(remaining, kMaxBulkRequestBytes) / kBulkPacketBytes) *
                kBulkPacketBytes;
            if (request == 0) break;  // less than one packet left to ask for
            std::size_t got = usb_.bulkRead(kEpInBulk, buf.data() + total,
                                             request, chunk_timeout_ms);
            ++reads_out;
            if (got == 0) break;  // device has nothing more to give
            total += got;
        }
        return total;
    };

    // ---- 3. Configure, drain, reconfigure ----------------------------------
    //
    // configure() is sent ONCE per phase and the device is left alone for the
    // whole timed transfer. An earlier implementation re-sent all 22 command
    // packets before every 30 KB read, hundreds of times per capture;
    // re-triggering the sweep generator mid-stream produced one live sweep per
    // read followed by the mixer output decaying to DC. That stays fixed — the
    // drain below happens strictly BEFORE the timed capture begins.
    //
    // Why the drain exists: the board free-runs into the EP6 FIFO regardless of
    // whether the host reads it, so the first bytes of a cold configure-then-read
    // are data produced under the PREVIOUS configuration. The fixed 4096-byte
    // discard below is a preamble skip copied from GUI line 2734, not a flush —
    // if more than that is queued, stale-config samples land in the capture, and
    // on a short capture the whole file can predate the change. See
    // CaptureConfig::drain_sweeps for why the GUI never hits this.
    configure(cfg);

    std::size_t drain_bytes = 0;
    bool drain_completed = true;
    if (cfg.drain_sweeps > 0) {
        const std::size_t drain_target =
            static_cast<std::size_t>(cfg.drain_sweeps) * bytes_per_sweep;
        // Same one-packet slack as `buf`, and for the same reason: the kernel
        // writes a COMPLETE packet or fails the transfer, so the destination
        // must have room for one even when the request does not need it.
        // Without the slack a request of exactly kDrainChunkBytes could be
        // overrun by up to 512 bytes — heap corruption that surfaces as
        // "free(): invalid pointer" when the buffers are released at exit.
        std::vector<std::uint8_t> scratch(kDrainChunkBytes + kBulkPacketBytes, 0);
        const auto drain_deadline =
            clock::now() + std::chrono::milliseconds(cfg.drain_timeout_ms);
        const auto drain_started = clock::now();

        while (drain_bytes < drain_target) {
            if (clock::now() >= drain_deadline) {
                drain_completed = false;
                break;
            }
            const std::size_t remaining = drain_target - drain_bytes;
            // Same whole-packet rule as the capture read: a bulk IN request that
            // is not a multiple of the max packet size overflows the moment the
            // device sends a full packet into a short remainder.
            const std::size_t request =
                (std::min(remaining, kDrainChunkBytes) / kBulkPacketBytes) *
                kBulkPacketBytes;
            if (request == 0) break;  // less than one packet left to ask for

            // Rate-scaled like the capture reads. cfg.bulk_timeout_ms alone let a
            // silent board hold each drain read for its full 2 s.
            const std::size_t got = usb_.bulkRead(
                kEpInBulk, scratch.data(), request,
                static_cast<unsigned int>(budget_ms(request).count()));
            drain_bytes += got;
            if (got < request) break;  // short read — FIFO is empty, we are current
        }
        const auto drain_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
            clock::now() - drain_started).count();
        std::fprintf(stderr,
                     "[pupradar] drained %zu bytes of %zu in %lld ms "
                     "(%d sweeps requested)%s\n",
                     drain_bytes, drain_target, static_cast<long long>(drain_ms),
                     cfg.drain_sweeps,
                     drain_completed ? "" : " — hit drain timeout");

        // Reassert the parameters, as every iteration of the GUI's loop does.
        // A command swallowed while stale data was still draining out would
        // otherwise leave the capture on the old settings.
        if (cfg.reconfigure_after_drain) {
            configure(cfg);
        }
    }

    // ---- 4. The recording --------------------------------------------------
    const auto t_start = clock::now();
    // Start the capture budget here, not back where the lambda was defined, so
    // the setup above does not eat into it.
    capture_deadline = t_start + budget_ms(capture_bytes);

    // One logical transfer, issued as a series of bounded reads — the config is
    // never re-sent between them.
    std::size_t reads_done       = 0;
    bool        capture_completed = true;
    const std::size_t total_bytes = readCapture(reads_done, capture_completed);
    const auto t_done = clock::now();
    if (!capture_completed) {
        std::fprintf(stderr,
                     "[pupradar] capture hit its deadline after %zu/%zu bytes "
                     "— the board stopped keeping up with the stream\n",
                     total_bytes, capture_bytes);
    }

    // Discard the stale FIFO preamble, as GUI line 2734
    // (RawData = double(RawData(2049:end))), then hand over the real samples.
    constexpr std::size_t kStalePreambleBytes = 2048 * 2;
    if (total_bytes > kStalePreambleBytes) {
        sink(buf.data() + kStalePreambleBytes, total_bytes - kStalePreambleBytes);
    }

    CaptureMetadata md;
    md.f_low_hz                 = cfg.f_low_hz;
    md.f_high_hz                = cfg.f_high_hz;
    md.fs_hz                    = fs_hz;
    md.sweep_time_s             = sweep_time_s;
    md.samples_per_sweep_per_rx = samples_per_sweep_per_rx;
    md.num_tx                   = n_tx;
    md.num_rx                   = n_rx;
    md.tx_mask                  = cfg.tx_mask;
    md.rx_mask                  = cfg.rx_mask;
    md.requested_duration_s     = cfg.duration_s;
    md.actual_duration_s        = std::chrono::duration<double>(t_done - t_start).count();
    // Report what actually reached the sink (and therefore the .bin), not what
    // came off the wire, so the sidecar matches the file on disk.
    md.bytes_captured           = total_bytes > kStalePreambleBytes
                                      ? total_bytes - kStalePreambleBytes : 0;
    md.reads_completed          = reads_done;
    md.capture_completed        = capture_completed;
    md.drain_sweeps_requested   = cfg.drain_sweeps;
    md.drain_bytes_discarded    = drain_bytes;
    md.drain_completed          = drain_completed;
    md.board_info_words         = last_board_info_;
    md.firmware_path            = fw_path_;
    md.timestamp_utc            = isoTimestampUtcNow();
    md.cmd_delay_us             = cmd_delay_us_;
    return md;
}

/**
 * @brief Releases all USB interfaces and closes the device handle.
 *
 * After this call the RadarSession is not usable again without a fresh call to initialize().
 */
void RadarSession::shutdown() {
    usb_.close();
}

}  // namespace pupradar
