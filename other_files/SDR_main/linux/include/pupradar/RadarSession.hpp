#pragma once

#include "pupradar/IUsbBackend.hpp"
#include "pupradar/Protocol.hpp"

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

namespace pupradar {

struct CaptureConfig {
    double          f_low_hz       = 24.0e9;
    double          f_high_hz      = 24.25e9;
    int             sweep_time_idx = 2;        // 1ms
    int             samp_num_idx   = 1;        // BASN (max samples)
    std::uint8_t    tx_mask        = 0x01;     // Tx1 only
    std::uint8_t    rx_mask        = 0x01;     // Rx1 only
    Modulation      modulation     = Modulation::Sawtooth;
    double          duration_s     = 5.0;

    /// Sweeps to read and discard between configure() and the real capture.
    ///
    /// The board free-runs into the EP6 FIFO whether or not the host reads, so
    /// a cold configure-then-read returns data produced under the PREVIOUS
    /// configuration — which is why a changed Rx mask appeared to take effect
    /// only one or two runs later. The GUI never hits this: Record is
    /// unreachable until Start has been pressed (PUPradarGUI.m:57 disables the
    /// recorder panel, :195 is the only enable, immediately before the loop at
    /// :203), and that loop re-sends the whole configuration and drains 64
    /// sweeps (:244) continuously, so every Record follows a fresh drain by
    /// milliseconds.
    ///
    /// Default 0 disables the drain (cold read). 64 mirrors the GUI's
    /// per-frame NumSweeps. When the drain runs, the configuration is re-sent
    /// afterwards, as every iteration of the GUI's loop does.
    int             drain_sweeps    = 0;

    /// Upper bound on the drain, in milliseconds. The drain stops early on a
    /// short read (FIFO empty); this only bounds the pathological case of a
    /// board that keeps handing back full packets forever.
    unsigned int    drain_timeout_ms = 1000;
};

struct CaptureMetadata {
    // Echoed configuration
    double          f_low_hz;
    double          f_high_hz;
    double          fs_hz;             // samples / sweep / sweep_time
    double          sweep_time_s;
    int             samples_per_sweep_per_rx;
    int             num_tx;
    int             num_rx;
    std::uint8_t    tx_mask;
    std::uint8_t    rx_mask;
    double          requested_duration_s;
    double          actual_duration_s;
    // What we measured
    std::size_t     bytes_captured;
    std::size_t     reads_completed;
    // Pre-capture drain: what was configured, and what it actually discarded.
    int             drain_sweeps_requested = 0;
    std::size_t     drain_bytes_discarded  = 0;
    bool            drain_completed        = false;  // false = hit the timeout
    // Board info from 0xFA00 response (raw, host-byte-order uint16 dump,
    // first 16 16-bit words from the info region — let user verify modelcode)
    std::vector<std::uint16_t> board_info_words;
    std::string     firmware_path;
    // ISO-8601 UTC timestamp
    std::string     timestamp_utc;
    // Inter-command settling delay in effect during this capture (microseconds).
    unsigned int    cmd_delay_us = 0;
};

// Non-owning pointer to a sink that writes IQ bytes to disk (or wherever).
// We keep this a simple callback so the writer is fully decoupled from the
// session and easy to mock in tests.
using IqSink = std::function<void(const std::uint8_t* data, std::size_t length)>;

class RadarSession {
public:
    RadarSession(IUsbBackend& usb, std::string firmware_hex_path);

    /// Full bring-up: enumerate (pre-firmware), claim, download firmware,
    /// wait for re-enumeration, claim again, request board info.
    /// @param post_fw_candidates List of (vid,pid) the chip may take after firmware load.
    /// Throws UsbError or std::runtime_error on failure.
    void initialize(const std::vector<IUsbBackend::VidPid>& post_fw_candidates,
                    unsigned int reenum_timeout_ms = 5000);

    /// Attach to a board that is already running firmware: open, claim, set alt,
    /// request board info. No firmware download and no re-enumeration.
    ///
    /// @param vid,pid The post-firmware VID/PID the running board presents.
    /// @throws UsbError if the device cannot be opened or claimed.
    void attachRunning(std::uint16_t vid, std::uint16_t pid);

    /// Apply a configuration: send modulation/sweep/sampling/Tx/Rx and PLL regs.
    void configure(const CaptureConfig& cfg);

    /// Bulk-read IQ for `cfg.duration_s` seconds, sinking bytes to `sink`.
    /// Fills out the metadata struct. Does NOT include parsing of the byte
    /// stream — capture-only MVP.
    CaptureMetadata captureIq(const CaptureConfig& cfg, const IqSink& sink);

    /// Power-down convenience: release interfaces, close device.
    void shutdown();

    /// Settling delay inserted after every command packet, in microseconds.
    ///
    /// The MCU needs a moment to act on a command before the next one lands;
    /// back-to-back writes on a fast host can outrun it. Default 0 (no delay) —
    /// raise it if the board ignores parameters or returns filler data.
    void setCommandDelayUs(unsigned int us) { cmd_delay_us_ = us; }
    unsigned int commandDelayUs() const { return cmd_delay_us_; }

    /// For testing / observability.
    const std::vector<std::uint16_t>& lastBoardInfo() const { return last_board_info_; }

private:
    void sendCommand(std::uint8_t opcode, std::uint8_t parameter);
    void downloadFirmware();
    void requestBoardInfo();
    /// One pass of the bring-up sequence; initialize() retries this until the
    /// board info carries the FA05 signature.
    void attemptBringUp(const std::vector<IUsbBackend::VidPid>& post_fw_candidates,
                        unsigned int reenum_timeout_ms);

    IUsbBackend&               usb_;
    std::string                fw_path_;
    std::vector<std::uint16_t> last_board_info_;
    unsigned int               cmd_delay_us_ = 0;
};

}  // namespace pupradar
