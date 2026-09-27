#include "test_framework.hpp"

#include "pupradar/IqWriter.hpp"

#include <cstdio>
#include <fstream>
#include <sstream>
#include <vector>

using namespace pupradar;

PUPRADAR_TEST(IqWriter_writes_bin_and_json) {
    const std::string base = "test_capture";
    {
        IqWriter w(base);
        std::vector<std::uint8_t> chunk(1000, 0xAB);
        w.write(chunk.data(), chunk.size());

        CaptureMetadata md{};
        md.f_low_hz = 24e9;
        md.f_high_hz = 24.25e9;
        md.fs_hz = 1.024e6;
        md.sweep_time_s = 1e-3;
        md.samples_per_sweep_per_rx = 1024;
        md.num_tx = 1; md.num_rx = 1;
        md.tx_mask = 1; md.rx_mask = 1;
        md.requested_duration_s = 1.0;
        md.actual_duration_s    = 1.001;
        md.bytes_captured       = 1000;
        md.reads_completed      = 1;
        md.timestamp_utc        = "2026-05-06T12:00:00Z";
        md.firmware_path        = "fw.hex";
        md.board_info_words     = {0xFA05, 0x00F0};
        w.finalize(md);
    }
    // Read back and verify
    std::ifstream bin(base + ".bin", std::ios::binary);
    ASSERT_TRUE(bin.is_open());
    bin.seekg(0, std::ios::end);
    std::streampos sz = bin.tellg();
    ASSERT_EQ(static_cast<std::size_t>(sz), 1000u);

    std::ifstream js(base + ".json");
    ASSERT_TRUE(js.is_open());
    std::ostringstream o; o << js.rdbuf();
    std::string text = o.str();
    ASSERT_TRUE(text.find("\"format\"") != std::string::npos);
    ASSERT_TRUE(text.find("\"bytes_captured\": 1000") != std::string::npos);
    ASSERT_TRUE(text.find("\"FA05\"") != std::string::npos);
    ASSERT_TRUE(text.find("\"sample_dtype\": \"int16_interleaved_iq\"") != std::string::npos);

    std::remove((base + ".bin").c_str());
    std::remove((base + ".json").c_str());
}

PUPRADAR_TEST(IqWriter_serializeMetadataJson_pure_string) {
    CaptureMetadata md{};
    md.f_low_hz = 24e9;
    md.f_high_hz = 24.25e9;
    md.fs_hz = 1.024e6;
    md.sweep_time_s = 1e-3;
    md.samples_per_sweep_per_rx = 1024;
    md.num_tx = 1; md.num_rx = 1;
    md.tx_mask = 1; md.rx_mask = 1;
    md.requested_duration_s = 5.0;
    md.actual_duration_s    = 5.001;
    md.bytes_captured = 12345;
    md.reads_completed = 7;
    md.timestamp_utc = "2026-05-06T12:00:00Z";
    md.firmware_path = "C:\\path\\fw.hex";  // backslash escape
    auto s = serializeMetadataJson(md);
    ASSERT_TRUE(s.find("C:\\\\path\\\\fw.hex") != std::string::npos);
    ASSERT_TRUE(s.find("\"bandwidth_hz\":") != std::string::npos);
}
