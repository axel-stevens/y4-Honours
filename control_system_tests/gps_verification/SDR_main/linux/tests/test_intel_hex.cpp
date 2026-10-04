#include "test_framework.hpp"

#include "pupradar/IntelHex.hpp"

#include <fstream>
#include <sstream>
#include <stdexcept>

using pupradar::parseIntelHex;
using pupradar::HexRecord;

PUPRADAR_TEST(IntelHex_parses_minimal_eof_only) {
    std::istringstream s(":00000001FF\n");
    auto recs = parseIntelHex(s);
    ASSERT_EQ(recs.size(), 0u);
}

PUPRADAR_TEST(IntelHex_parses_one_data_record) {
    // Address 0x00B8, 3 bytes [0x02, 0x00, 0xB8]
    // Sum check: 03 + 00 + B8 + 00 + 02 + 00 + B8 = 0x175 → low byte 0x75 → checksum = 0x100-0x75 = 0x8B
    // Build it programmatically:
    auto sum = [](std::initializer_list<int> v) {
        int s = 0; for (int b : v) s += b; return static_cast<std::uint8_t>((-s) & 0xFF);
    };
    int len = 3, ahi = 0x00, alo = 0xB8, type = 0x00;
    int b0 = 0x02, b1 = 0x00, b2 = 0xB8;
    auto cs = sum({len, ahi, alo, type, b0, b1, b2});
    char line[64];
    std::snprintf(line, sizeof(line), ":%02X%02X%02X%02X%02X%02X%02X%02X\n",
                  len, ahi, alo, type, b0, b1, b2, cs);
    std::string text = line;
    text += ":00000001FF\n";
    std::istringstream s(text);
    auto recs = parseIntelHex(s);
    ASSERT_EQ(recs.size(), 1u);
    ASSERT_EQ(recs[0].address, 0x00B8u);
    ASSERT_EQ(recs[0].data.size(), 3u);
    ASSERT_EQ(recs[0].data[0], 0x02u);
    ASSERT_EQ(recs[0].data[1], 0x00u);
    ASSERT_EQ(recs[0].data[2], 0xB8u);
}

PUPRADAR_TEST(IntelHex_rejects_checksum_failure) {
    // :01 0000 00 FF 01  → sum 0x01+0x00+0x00+0x00+0xFF+0x01 = 0x101 → !=0 mod 256
    std::istringstream s(":01000000FF01\n:00000001FF\n");
    ASSERT_THROWS(parseIntelHex(s), std::runtime_error);
}

PUPRADAR_TEST(IntelHex_rejects_missing_eof) {
    std::istringstream s(":0300000002000343\n");  // no :00000001FF
    ASSERT_THROWS(parseIntelHex(s), std::runtime_error);
}

PUPRADAR_TEST(IntelHex_rejects_missing_colon) {
    std::istringstream s("0300000002000343\n:00000001FF\n");
    ASSERT_THROWS(parseIntelHex(s), std::runtime_error);
}

PUPRADAR_TEST(IntelHex_parses_real_firmware_first_line) {
    // Real first line from SDR_USB_FW.hex: :030000000200B843
    // Length 3, addr 0x0000, type 0x00, data {0x02, 0x00, 0xB8}, cksum 0x43
    std::istringstream s(":030000000200B843\n:00000001FF\n");
    auto recs = parseIntelHex(s);
    ASSERT_EQ(recs.size(), 1u);
    ASSERT_EQ(recs[0].address, 0x0000u);
    ASSERT_EQ(recs[0].data.size(), 3u);
    ASSERT_EQ(recs[0].data[0], 0x02u);
    ASSERT_EQ(recs[0].data[1], 0x00u);
    ASSERT_EQ(recs[0].data[2], 0xB8u);
}

PUPRADAR_TEST(IntelHex_parses_lowercase_hex) {
    std::istringstream s(":030000000200b843\n:00000001ff\n");
    auto recs = parseIntelHex(s);
    ASSERT_EQ(recs.size(), 1u);
    ASSERT_EQ(recs[0].data[2], 0xB8u);
}

PUPRADAR_TEST(IntelHex_strips_crlf_line_endings) {
    std::istringstream s(":030000000200B843\r\n:00000001FF\r\n");
    auto recs = parseIntelHex(s);
    ASSERT_EQ(recs.size(), 1u);
}
