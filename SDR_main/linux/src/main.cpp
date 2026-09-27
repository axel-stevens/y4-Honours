// pupradar_capture — capture-only MVP for the PUP EN24C T2R4 radar on Linux.
//
// Single-binary deployment: parses an Intel HEX firmware blob, downloads it
// to the FX2LP via the standard Cypress 0xA0 loader, configures sawtooth FMCW,
// captures raw IQ for N seconds, writes <out>.bin + <out>.json.
//
// Usage:
//   pupradar_capture --duration 5 --out /tmp/cap [--firmware /path/to.hex]
//                    [--fc-low 24.0e9 --fc-high 24.25e9]
//                    [--sweep-time 2 --samp-num 1 --tx 1 --rx 1]
//
// Defaults: 24.0..24.25 GHz, 1 ms sweep, max samples, Tx1+Rx1.

#include "pupradar/IqWriter.hpp"
#include "pupradar/Protocol.hpp"
#include "pupradar/RadarSession.hpp"
#include "pupradar/UsbDevice.hpp"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <map>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

void printUsage(const char* prog) {
    std::cout <<
        "Usage: " << prog << " --out <basename> [options]\n"
        "Options:\n"
        "  --duration <s>            Capture duration in seconds (default 5)\n"
        "  --out <basename>          Output basename (writes <basename>.bin and .json)\n"
        "  --firmware <path>         Path to SDR_USB_FW.hex (default: ./firmware/SDR_USB_FW.hex)\n"
        "  --fc-low <Hz>             Sawtooth low frequency (default 24.0e9)\n"
        "  --fc-high <Hz>            Sawtooth high frequency (default 24.25e9)\n"
        "  --sweep-time <1-5>        Sweep-time index: 1=0.5ms 2=1ms 3=2ms 4=4ms 5=8ms (default 2)\n"
        "  --samp-num <1-4>          Sampling-number index (1=BASN, 2=BASN/2, ... default 1)\n"
        "  --tx <mask>               Tx mask: 1=Tx1, 2=Tx2, 3=both (default 1)\n"
        "  --rx <mask>               Rx mask: 1/2/4/8 single, 3=Rx12, 12=Rx34, 15=All (default 1)\n"
        "  --download-firmware       Apply this flag to a board that haven't downloaded the firmware yet. (i.e., when board is in a new power cycle)\n"
        "  --cmd-delay-us <us>       Settling delay after each command packet (default 20000).\n"
        "                            Raise it if the board ignores parameters or returns filler.\n"
        "  --drain-sweeps <n>        Sweeps to read and discard after configuring, before the\n"
        "                            timed capture (default 0 = no drain; 64 is the GUI's\n"
        "                            per-frame value). Set it if a changed --rx/--tx still\n"
        "                            shows up a run or two late.\n"
        "  --drain-timeout-ms <ms>   Upper bound on the drain (default 1000)\n"
        "  -h, --help                Show this help\n";
}

class Args {
public:
    explicit Args(int argc, char** argv) {
        for (int i = 1; i < argc; ++i) {
            std::string a = argv[i];
            if (a == "-h" || a == "--help") { help_ = true; continue; }
            if (a.rfind("--", 0) != 0) {
                throw std::runtime_error("Unexpected positional argument: " + a);
            }
            // Valueless flags must be checked before the "needs a value" test.
            if (a == "--download-firmware") { download_firmware_ = true; continue; }
            if (i + 1 >= argc) {
                throw std::runtime_error("Missing value for " + a);
            }
            kv_[a.substr(2)] = argv[++i];
        }
    }
    bool        help() const { return help_; }
    bool        downloadFirmware() const { return download_firmware_; }
    bool        has(const std::string& k) const { return kv_.count(k) != 0; }
    std::string get(const std::string& k, const std::string& def = "") const {
        auto it = kv_.find(k); return it == kv_.end() ? def : it->second;
    }
    double      getDouble(const std::string& k, double def) const {
        return has(k) ? std::stod(get(k)) : def;
    }
    int         getInt(const std::string& k, int def) const {
        return has(k) ? std::stoi(get(k), nullptr, 0) : def;
    }
    unsigned int getUint(const std::string& k, unsigned int def) const {
        return has(k) ? static_cast<unsigned int>(std::stoul(get(k), nullptr, 0)) : def;
    }
private:
    bool help_ = false;
    bool download_firmware_ = false;
    std::map<std::string, std::string> kv_;
};

}  // namespace

int main(int argc, char** argv) try {
    Args args(argc, argv);
    if (args.help()) { printUsage(argv[0]); return 0; }
    if (!args.has("out")) {
        std::cerr << "Error: --out is required.\n\n";
        printUsage(argv[0]);
        return 2;
    }

    pupradar::CaptureConfig cfg;
    cfg.duration_s      = args.getDouble("duration", 5.0);
    cfg.f_low_hz        = args.getDouble("fc-low",   24.0e9);
    cfg.f_high_hz       = args.getDouble("fc-high",  24.25e9);
    cfg.sweep_time_idx  = args.getInt   ("sweep-time", 2);
    cfg.samp_num_idx    = args.getInt   ("samp-num",   1);
    cfg.tx_mask         = static_cast<std::uint8_t>(args.getInt("tx", 1));
    cfg.rx_mask         = static_cast<std::uint8_t>(args.getInt("rx", 1));
    cfg.drain_sweeps    = args.getInt   ("drain-sweeps", 0);
    cfg.drain_timeout_ms = args.getUint ("drain-timeout-ms", 1000);
    if (cfg.drain_sweeps < 0) {
        std::cerr << "Error: --drain-sweeps must be >= 0 (0 disables the drain).\n";
        return 2;
    }

    const std::string out_base    = args.get("out");
    const std::string firmware    = args.get("firmware", "firmware/SDR_USB_FW.hex");
    const unsigned int cmd_delay_us = args.getUint("cmd-delay-us", 2000);

    std::cout << "[pupradar] firmware: "  << firmware  << "\n";
    std::cout << "[pupradar] out: "       << out_base  << ".bin / .json\n";
    std::cout << "[pupradar] capture: "   << cfg.duration_s << " s, "
              << cfg.f_low_hz/1e9 << ".."  << cfg.f_high_hz/1e9 << " GHz, "
              << "sweep_idx=" << cfg.sweep_time_idx
              << " samp_idx=" << cfg.samp_num_idx
              << " tx_mask=0x" << std::hex << +cfg.tx_mask
              << " rx_mask=0x" << +cfg.rx_mask << std::dec << "\n";
    std::cout << "[pupradar] cmd delay: " << cmd_delay_us << " us\n";
    std::cout << "[pupradar] drain: "     << cfg.drain_sweeps << " sweeps (max "
              << cfg.drain_timeout_ms     << " ms)\n";

    pupradar::UsbDevice    usb;
    pupradar::RadarSession session(usb, firmware);
    // Set before bring-up so the board-info handshake gets the same pacing.
    session.setCommandDelayUs(cmd_delay_us);
    if (args.downloadFirmware()) {
        std::cout << "[pupradar] initializing (open → claim → firmware → reopen)…\n";
        session.initialize({{pupradar::kPostFirmwareVid, pupradar::kPostFirmwarePid}});
    } else {
        std::cout << "[pupradar] attaching to a running board…\n";
        session.attachRunning(pupradar::kPostFirmwareVid, pupradar::kPostFirmwarePid);
    }

    std::printf("[pupradar] board info (uint16 words, hex): ");
    for (auto w : session.lastBoardInfo()) std::printf("%04X ", w);
    std::printf("\n");

    const pupradar::BoardInfo info = pupradar::decodeBoardInfo(session.lastBoardInfo());
    if (info.valid) {
        std::printf("[pupradar] model:        %s\n",  info.model_name);
        std::printf("[pupradar] freq_band:    %u  num_tx: %u  num_rx: %u\n",
                    info.freq_band, info.num_tx, info.num_rx);
        std::printf("[pupradar] antenna_type: %u  version: %u\n",
                    info.antenna_type, info.version);
    } else {
        std::printf("[pupradar] warning: FA05 signature not found in board info\n");
    }

    std::cout << "[pupradar] configuring sawtooth FMCW…\n";
    session.configure(cfg);

    pupradar::IqWriter writer(out_base);
    auto sink = [&writer](const std::uint8_t* d, std::size_t n) {
        writer.write(d, n);
    };

    std::cout << "[pupradar] capturing for " << cfg.duration_s << " s…\n";
    auto md = session.captureIq(cfg, sink);
    writer.finalize(md);

    std::cout << "[pupradar] done: " << md.bytes_captured << " bytes in "
              << md.reads_completed  << " reads ("
              << md.actual_duration_s << " s).\n";
    std::cout << "[pupradar] wrote: " << writer.binPath()
              << " + "                << writer.jsonPath() << "\n";

    session.shutdown();
    return 0;
} catch (const std::exception& e) {
    std::cerr << "[pupradar] error: " << e.what() << "\n";
    return 1;
}
