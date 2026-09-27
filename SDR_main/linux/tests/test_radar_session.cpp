#include "test_framework.hpp"
#include "FakeUsbBackend.hpp"

#include "pupradar/Protocol.hpp"
#include "pupradar/RadarSession.hpp"

#include <cstdint>
#include <fstream>
#include <sstream>
#include <vector>

using namespace pupradar;
using pupradar::test::FakeUsbBackend;
using pupradar::test::UsbEvent;

namespace {
// Generate a tiny one-record + EOF Intel HEX file at a temp path.
std::string writeTinyFirmware() {
    // Build a valid 1-byte data record at addr 0x0100, value 0x42
    int len = 1, ahi = 0x01, alo = 0x00, type = 0x00, b0 = 0x42;
    int s = len + ahi + alo + type + b0;
    int cs = (-s) & 0xFF;
    char line[64];
    std::snprintf(line, sizeof(line), ":%02X%02X%02X%02X%02X%02X\n",
                  len, ahi, alo, type, b0, cs);
    std::string path = "tiny_fw.hex";
    std::ofstream f(path, std::ios::trunc);
    f << line << ":00000001FF\n";
    f.close();
    return path;
}

// Build a board-info response: 2048 bytes of header zeros, then 0xFA 0x05
// little-endian, then 30 more bytes of dummy info.
std::vector<std::uint8_t> makeBoardInfoResponse() {
    std::vector<std::uint8_t> r(2560, 0);
    r[2048] = 0x05;  // little-endian 0xFA05
    r[2049] = 0xFA;
    r[2050] = 0xF0;  // FrequencyBand byte
    r[2051] = 0x00;
    return r;
}
}  // namespace

PUPRADAR_TEST(Session_initialize_sequence_is_correct) {
    FakeUsbBackend usb;
    // Pre-firmware: open returns OK by default. Firmware download:
    //   1 control IN read (CPUCS readback) — return cpucs=0
    //   1 control OUT (set reset)
    //   1 control OUT per data record (1 in tiny firmware)
    //   1 control OUT (clear reset)
    // Post-firmware: reopen + claim + alt + send 0xFA00 + bulk-IN 2560 bytes
    usb.control_in_responses.push_back({0x00});
    usb.bulk_in_responses.push_back(makeBoardInfoResponse());

    auto fw_path = writeTinyFirmware();
    RadarSession s(usb, fw_path);
    s.initialize({{0x04B4, 0x1234}}, /*timeout*/ 100);

    // Expected event sequence
    auto& ev = usb.events;
    std::size_t i = 0;
    ASSERT_EQ(ev[i].kind, UsbEvent::Kind::Open);
    ASSERT_EQ(ev[i].vid,  0x04B4);
    ASSERT_EQ(ev[i].pid,  0x8613);
    ++i;
    ASSERT_EQ(ev[i].kind, UsbEvent::Kind::ClaimInterface);
    ASSERT_EQ(ev[i].interface_no, 0);
    ++i;
    ASSERT_EQ(ev[i].kind, UsbEvent::Kind::SetAlt);
    ASSERT_EQ(ev[i].alt_setting, 1);
    ++i;
    ASSERT_EQ(ev[i].kind, UsbEvent::Kind::ControlIn);   // CPUCS read
    ASSERT_EQ(ev[i].b_request, kFwLoaderRequest);
    ASSERT_EQ(ev[i].w_value,   kCpucsRegister);
    ++i;
    ASSERT_EQ(ev[i].kind, UsbEvent::Kind::ControlOut);  // CPUCS write reset=1
    ASSERT_EQ(ev[i].payload.size(), 1u);
    ASSERT_EQ(ev[i].payload[0],  static_cast<std::uint8_t>(0x01));
    ++i;
    ASSERT_EQ(ev[i].kind, UsbEvent::Kind::ControlOut);  // data record
    ASSERT_EQ(ev[i].w_value, 0x0100u);
    ASSERT_EQ(ev[i].payload.size(), 1u);
    ASSERT_EQ(ev[i].payload[0], 0x42u);
    ++i;
    ASSERT_EQ(ev[i].kind, UsbEvent::Kind::ControlOut);  // CPUCS write reset=0
    ASSERT_EQ(ev[i].payload[0], 0x00u);
    ++i;
    ASSERT_EQ(ev[i].kind, UsbEvent::Kind::ReopenAfterRenum);
    ASSERT_EQ(ev[i].vid,  0x04B4);
    ASSERT_EQ(ev[i].pid,  0x1234);
    ++i;
    ASSERT_EQ(ev[i].kind, UsbEvent::Kind::ClaimInterface);  // post-firmware
    ++i;
    ASSERT_EQ(ev[i].kind, UsbEvent::Kind::SetAlt);
    ++i;
    ASSERT_EQ(ev[i].kind, UsbEvent::Kind::BulkOut);   // 0xFA00 board info request
    ASSERT_EQ(ev[i].endpoint, kEpOutBulk);
    ASSERT_EQ(ev[i].payload.size(), 512u);
    ASSERT_EQ(ev[i].payload[0], 0x00u);
    ASSERT_EQ(ev[i].payload[1], 0xFAu);
    ++i;
    ASSERT_EQ(ev[i].kind, UsbEvent::Kind::BulkIn);
    ASSERT_EQ(ev[i].endpoint, kEpInBulk);
    ASSERT_EQ(ev[i].requested_len, 2560u);
    // Board info parsed
    ASSERT_TRUE(s.lastBoardInfo().size() >= 2);
    ASSERT_EQ(s.lastBoardInfo()[0], 0xFA05u);
}

PUPRADAR_TEST(Session_configure_sends_expected_opcodes) {
    FakeUsbBackend usb;
    usb.is_open = true;  // skip initialize

    auto fw_path = writeTinyFirmware();
    RadarSession s(usb, fw_path);

    CaptureConfig cfg;
    cfg.modulation     = Modulation::Sawtooth;
    cfg.sweep_time_idx = 2;
    cfg.samp_num_idx   = 1;
    cfg.tx_mask        = 0x01;
    cfg.rx_mask        = 0x01;
    cfg.f_low_hz       = 24.0e9;
    cfg.f_high_hz      = 24.25e9;
    s.configure(cfg);

    // Expected sequence: kModulation, kSweepTimeIndex, kSamplingNumIndex,
    // kTxMask, kRxMask, then 17 PLL bytes — total 22 BulkOut events.
    auto outs = usb.only(UsbEvent::Kind::BulkOut);
    ASSERT_EQ(outs.size(), 22u);
    ASSERT_EQ(outs[0].payload[1], opcode::kModulation);
    ASSERT_EQ(outs[0].payload[0], static_cast<std::uint8_t>(Modulation::Sawtooth));
    ASSERT_EQ(outs[1].payload[1], opcode::kSweepTimeIndex);
    ASSERT_EQ(outs[1].payload[0], 2u);
    ASSERT_EQ(outs[2].payload[1], opcode::kSamplingNumIndex);
    ASSERT_EQ(outs[3].payload[1], opcode::kTxMask);
    ASSERT_EQ(outs[4].payload[1], opcode::kRxMask);
    // First PLL command in the GUI's order is kPllSweepStopL
    ASSERT_EQ(outs[5].payload[1], opcode::kPllSweepStopL);
}

PUPRADAR_TEST(Session_capture_sinks_data_and_returns_metadata) {
    FakeUsbBackend usb;
    usb.is_open = true;
    // Each bulk read returns a small chunk of synthetic IQ.
    std::vector<std::uint8_t> chunk(1024, 0x55);
    for (int i = 0; i < 30; ++i) usb.bulk_in_responses.push_back(chunk);

    auto fw_path = writeTinyFirmware();
    RadarSession s(usb, fw_path);

    CaptureConfig cfg;
    cfg.duration_s     = 0.05;  // 50 ms
    cfg.sweep_time_idx = 2;
    cfg.samp_num_idx   = 1;
    cfg.tx_mask        = 0x01;
    cfg.rx_mask        = 0x01;

    std::vector<std::uint8_t> received;
    auto sink = [&](const std::uint8_t* d, std::size_t n) {
        received.insert(received.end(), d, d + n);
    };
    auto md = s.captureIq(cfg, sink);

    ASSERT_TRUE(md.bytes_captured >= 1024u);
    ASSERT_TRUE(md.reads_completed >= 1u);
    ASSERT_EQ(md.num_tx, 1);
    ASSERT_EQ(md.num_rx, 1);
    ASSERT_EQ(md.samples_per_sweep_per_rx, 2048);  // BASN for 1ms/Rx=1
    ASSERT_TRUE(md.fs_hz > 1e6 && md.fs_hz < 5e6);
    // Sink received the same number of bytes that metadata claims
    ASSERT_EQ(received.size(), md.bytes_captured);
}

PUPRADAR_TEST(Session_configure_rejects_CW_in_MVP) {
    FakeUsbBackend usb;
    usb.is_open = true;
    auto fw_path = writeTinyFirmware();
    RadarSession s(usb, fw_path);
    CaptureConfig cfg;
    cfg.modulation = Modulation::CW;
    ASSERT_THROWS(s.configure(cfg), std::invalid_argument);
}
