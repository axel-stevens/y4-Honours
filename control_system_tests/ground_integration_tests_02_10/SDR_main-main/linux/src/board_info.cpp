// pupradar_board_info — minimal USB connectivity diagnostic for the PUP EN24C T2R4 radar.
//
// Two modes:
//   Default:          open pre-firmware device (VID 0x04B4/PID 0x8613), download firmware,
//                     wait for re-enumeration, then request and print board info.
//   --skip-firmware:  device already has firmware in RAM (USB cable was NOT unplugged since
//                     the last firmware load); connect directly to the post-firmware VID/PID.
//
// Usage:
//   pupradar_board_info [--firmware <path>] [--post-fw-vid <VID>] [--post-fw-pid <PID>]
//                       [--reenum-timeout-ms <ms>] [--skip-firmware]

#include "pupradar/IUsbBackend.hpp"
#include "pupradar/Protocol.hpp"
#include "pupradar/RadarSession.hpp"
#include "pupradar/UsbDevice.hpp"

#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

void printHelp(const char* prog) {
    std::cout <<
        "Usage: " << prog << " [options]\n"
        "  --firmware <path>         Path to SDR_USB_FW.hex  (default: firmware/SDR_USB_FW.hex)\n"
        "  --post-fw-vid <0xNNNN>    Post-firmware VID        (default: 0x04B4)\n"
        "  --post-fw-pid <0xNNNN>    Post-firmware PID        (default: 0x1004)\n"
        "  --reenum-timeout-ms <ms>  Re-enumeration timeout   (default: 5000)\n"
        "  --skip-firmware           Skip firmware download; device must already have\n"
        "                            firmware resident in RAM (USB cable not unplugged).\n"
        "  -h, --help                Show this help\n";
}

// Direct board-info query used when firmware is already resident.
// Opens the post-firmware device, claims interface 0 / alt 1, sends opcode 0xFA,
// reads back the response, and decodes the useful region as little-endian uint16 words.
std::vector<std::uint16_t> queryBoardInfoDirect(
        std::uint16_t post_vid, std::uint16_t post_pid)
{
    // GUI line 2672: DataLength = 512 + 2048
    constexpr std::size_t kReadBytes    = 512 + 2048;
    // GUI line 2674: PUPradarBoardInfo(1025:1100) — word 1025 (1-based) = byte 2048
    constexpr std::size_t kUsefulOffset = 2048;
    // GUI reads 76 words but only words 0-4 have meaning (FA05, FreqBand, Tx/Rx, Version).
    // 32 bytes = 16 words gives comfortable headroom over those 5 semantic words.
    constexpr std::size_t kExposedBytes = 32;

    pupradar::UsbDevice usb;
    usb.open(post_vid, post_pid);
    usb.claimInterface(pupradar::kInterfaceNumber);
    usb.setAltSetting(pupradar::kInterfaceNumber, pupradar::kAlternateSetting);

    auto pkt = pupradar::makeCommandPacket(pupradar::opcode::kBoardInfoRequest, 0x00);
    usb.bulkWrite(pupradar::kEpOutBulk, pkt.data(), pkt.size(), /*timeout_ms*/ 1000);

    std::vector<std::uint8_t> buf(kReadBytes, 0);
    std::size_t n = usb.bulkRead(pupradar::kEpInBulk, buf.data(), buf.size(),
                                  /*timeout_ms*/ 2000);
    if (n < kUsefulOffset + 2) {
        throw std::runtime_error("Board info short read: got " + std::to_string(n) +
                                 " bytes, need at least " +
                                 std::to_string(kUsefulOffset + 2));
    }

    // Decode however many complete uint16 words arrived, up to kExposedBytes.
    const std::size_t avail_bytes  = n - kUsefulOffset;
    const std::size_t decode_bytes = (std::min(kExposedBytes, avail_bytes) / 2) * 2;
    std::vector<std::uint16_t> words;
    words.reserve(decode_bytes / 2);
    for (std::size_t i = 0; i < decode_bytes; i += 2) {
        std::uint8_t lo = buf[kUsefulOffset + i];
        std::uint8_t hi = buf[kUsefulOffset + i + 1];
        words.push_back(static_cast<std::uint16_t>((hi << 8) | lo));
    }

    usb.close();
    return words;
}

}  // namespace

int main(int argc, char** argv) try {
    std::string  firmware     = "firmware/SDR_USB_FW.hex";
    std::uint16_t post_vid    = 0x04B4;
    std::uint16_t post_pid    = 0x8613;
    unsigned int  reenum_ms   = 5000;
    bool          skip_fw     = false;

    for (int i = 1; i < argc; ++i) {
        std::string a = argv[i];
        auto next = [&]() -> std::string {
            if (i + 1 >= argc) throw std::runtime_error("Missing value for " + a);
            return argv[++i];
        };
        if      (a == "--firmware")          firmware  = next();
        else if (a == "--post-fw-vid")       post_vid  = static_cast<std::uint16_t>(std::stoul(next(), nullptr, 0));
        else if (a == "--post-fw-pid")       post_pid  = static_cast<std::uint16_t>(std::stoul(next(), nullptr, 0));
        else if (a == "--reenum-timeout-ms") reenum_ms = static_cast<unsigned int>(std::stoul(next()));
        else if (a == "--skip-firmware")     skip_fw   = true;
        else if (a == "-h" || a == "--help") { printHelp(argv[0]); return 0; }
        else throw std::runtime_error("Unknown argument: " + a);
    }

    std::vector<std::uint16_t> words;

    if (skip_fw) {
        std::printf("[board_info] mode: direct (skip firmware download)\n");
        std::printf("[board_info] opening post-firmware device 0x%04X:0x%04X …\n",
                    post_vid, post_pid);
        words = queryBoardInfoDirect(post_vid, post_pid);
    } else {
        std::printf("[board_info] mode: full init (firmware download + re-enumerate)\n");
        std::printf("[board_info] firmware: %s\n", firmware.c_str());
        std::printf("[board_info] opening pre-firmware device (VID 0x%04X / PID 0x%04X) …\n",
                    pupradar::kPreFirmwareVid, pupradar::kPreFirmwarePid);

        pupradar::UsbDevice    usb;
        pupradar::RadarSession session(usb, firmware);

        std::vector<pupradar::IUsbBackend::VidPid> post_fw = {{ post_vid, post_pid }};
        session.initialize(post_fw, reenum_ms);
        words = session.lastBoardInfo();
        session.shutdown();
    }

    std::printf("[board_info] board info (%zu uint16 words, hex):\n  ", words.size());
    for (auto w : words) std::printf("%04X ", w);
    std::printf("\n");

    const pupradar::BoardInfo info = pupradar::decodeBoardInfo(words);
    if (info.valid) {
        std::printf("[board_info] signature:    FA05 (OK)\n");
        std::printf("[board_info] freq_band:    %u\n",     info.freq_band);
        std::printf("[board_info] num_tx:       %u\n",     info.num_tx);
        std::printf("[board_info] num_rx:       %u\n",     info.num_rx);
        std::printf("[board_info] antenna_type: %u\n",     info.antenna_type);
        std::printf("[board_info] version:      %u\n",     info.version);
        std::printf("[board_info] model code:   %u\n",     info.modelcode);
        std::printf("[board_info] model:        %s\n",     info.model_name);
    } else {
        std::printf("[board_info] signature mismatch (word[0] = %04X, expected FA05)\n",
                    words.empty() ? 0u : static_cast<unsigned>(words[0]));
    }
    std::printf("[board_info] OK\n");
    return 0;

} catch (const std::exception& e) {
    std::fprintf(stderr, "[board_info] error: %s\n", e.what());
    return 1;
}
