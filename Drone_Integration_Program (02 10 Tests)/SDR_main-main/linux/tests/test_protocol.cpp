#include "test_framework.hpp"

#include "pupradar/Protocol.hpp"

#include <stdexcept>

using namespace pupradar;

PUPRADAR_TEST(Protocol_command_packet_is_512_bytes) {
    auto p = makeCommandPacket(opcode::kBoardInfoRequest, 0x00);
    ASSERT_EQ(p.size(), 512u);
}

PUPRADAR_TEST(Protocol_command_packet_is_little_endian_word_repeat) {
    // FA00 little-endian = 00 FA 00 FA 00 FA ...
    auto p = makeCommandPacket(0xFA, 0x00);
    ASSERT_EQ(p[0], 0x00u);
    ASSERT_EQ(p[1], 0xFAu);
    ASSERT_EQ(p[510], 0x00u);
    ASSERT_EQ(p[511], 0xFAu);
    // E105 → 05 E1 05 E1 ...
    auto p2 = makeCommandPacket(0xE1, 0x05);
    ASSERT_EQ(p2[0], 0x05u);
    ASSERT_EQ(p2[1], 0xE1u);
}

PUPRADAR_TEST(Protocol_sweep_time_table) {
    ASSERT_EQ(sweepTimeFromIndex(1), 0.5e-3);
    ASSERT_EQ(sweepTimeFromIndex(2), 1.0e-3);
    ASSERT_EQ(sweepTimeFromIndex(3), 2.0e-3);
    ASSERT_EQ(sweepTimeFromIndex(4), 4.0e-3);
    ASSERT_EQ(sweepTimeFromIndex(5), 8.0e-3);
    ASSERT_THROWS(sweepTimeFromIndex(0), std::out_of_range);
    ASSERT_THROWS(sweepTimeFromIndex(6), std::out_of_range);
}

PUPRADAR_TEST(Protocol_samples_per_sweep_match_GUI_table) {
    // Spot-check from PUPradarGUI.m:2150..2252.
    // Rx=1, sweep_idx=1 (500us), sn_idx=1 → BASN 1024
    ASSERT_EQ(samplesPerSweep(1, 1, 1), 1024);
    // Rx=2, sweep_idx=3 (2ms), sn_idx=2 → 2048/2 = 1024
    ASSERT_EQ(samplesPerSweep(3, 2, 2), 1024);
    // Rx=4, sweep_idx=5 (8ms), sn_idx=4 → 4096/8 = 512
    ASSERT_EQ(samplesPerSweep(5, 4, 4), 512);
}

PUPRADAR_TEST(Protocol_tx_count_validates_mask) {
    ASSERT_EQ(txCount(1), 1);
    ASSERT_EQ(txCount(2), 1);
    ASSERT_EQ(txCount(3), 2);
    ASSERT_THROWS(txCount(0), std::out_of_range);
    ASSERT_THROWS(txCount(4), std::out_of_range);
}

PUPRADAR_TEST(Protocol_rx_count_validates_mask) {
    ASSERT_EQ(rxCount(0x01), 1);
    ASSERT_EQ(rxCount(0x02), 1);
    ASSERT_EQ(rxCount(0x04), 1);
    ASSERT_EQ(rxCount(0x08), 1);
    ASSERT_EQ(rxCount(0x03), 2);
    ASSERT_EQ(rxCount(0x0C), 2);
    ASSERT_EQ(rxCount(0x0F), 4);
    ASSERT_THROWS(rxCount(0),    std::out_of_range);  // none
    ASSERT_THROWS(rxCount(0x07), std::out_of_range);  // 3 channels (not allowed)
}

PUPRADAR_TEST(Protocol_pll_sawtooth_command_count) {
    auto cmds = buildSawtoothPllCommands(24.0e9, 24.25e9, 2);
    // 2 sweep-stop bytes + 5×3 PLL register bytes = 17 commands
    ASSERT_EQ(cmds.size(), 17u);
}

PUPRADAR_TEST(Protocol_pll_first_two_are_sweep_stop) {
    auto cmds = buildSawtoothPllCommands(24.0e9, 24.25e9, 2);
    ASSERT_EQ(cmds[0].opcode, opcode::kPllSweepStopL);
    ASSERT_EQ(cmds[1].opcode, opcode::kPllSweepStopH);
}

PUPRADAR_TEST(Protocol_pll_order_matches_GUI) {
    auto cmds = buildSawtoothPllCommands(24.0e9, 24.25e9, 2);
    // Order from PUPradarGUI.m:2444..2599
    const std::uint8_t expected_order[] = {
        opcode::kPllSweepStopL, opcode::kPllSweepStopH,
        opcode::kPll03L, opcode::kPll03M, opcode::kPll03H,
        opcode::kPll04L, opcode::kPll04M, opcode::kPll04H,
        opcode::kPll0AL, opcode::kPll0AM, opcode::kPll0AH,
        opcode::kPll0CL, opcode::kPll0CM, opcode::kPll0CH,
        opcode::kPll0DL, opcode::kPll0DM, opcode::kPll0DH,
    };
    ASSERT_EQ(cmds.size(), sizeof(expected_order) / sizeof(expected_order[0]));
    for (std::size_t i = 0; i < cmds.size(); ++i) {
        ASSERT_EQ(cmds[i].opcode, expected_order[i]);
    }
}

PUPRADAR_TEST(Protocol_pll_rejects_inverted_band) {
    ASSERT_THROWS(buildSawtoothPllCommands(24e9, 24e9, 2), std::invalid_argument);
    ASSERT_THROWS(buildSawtoothPllCommands(24e9, 23e9, 2), std::invalid_argument);
    ASSERT_THROWS(buildSawtoothPllCommands(0,    24e9, 2), std::invalid_argument);
}

PUPRADAR_TEST(Protocol_pll_start_n_at_24GHz_low_band) {
    // F_start = 24e9/16 = 1.5e9; Start_N = 1.5e9/50e6 = 30.0 → integer 30, frac 0
    auto cmds = buildSawtoothPllCommands(24.0e9, 24.25e9, 2);
    // PLL Reg 03 L, M, H = LSB, mid, MSB of 30 = 0x1E, 0x00, 0x00
    // Find them
    auto get = [&](std::uint8_t op) {
        for (auto& c : cmds) if (c.opcode == op) return static_cast<int>(c.param);
        throw std::runtime_error("opcode not in cmds");
    };
    ASSERT_EQ(get(opcode::kPll03L), 30);
    ASSERT_EQ(get(opcode::kPll03M), 0);
    ASSERT_EQ(get(opcode::kPll03H), 0);
    // PLL Reg 04 (frac) = round(0 * 2^24) = 0
    ASSERT_EQ(get(opcode::kPll04L), 0);
    ASSERT_EQ(get(opcode::kPll04M), 0);
    ASSERT_EQ(get(opcode::kPll04H), 0);
}
