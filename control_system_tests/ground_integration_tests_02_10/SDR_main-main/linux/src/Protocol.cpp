#include "pupradar/Protocol.hpp"

#include <cmath>
#include <cstdint>
#include <stdexcept>

namespace pupradar {

std::array<std::uint8_t, kBulkOutPacketBytes>
makeCommandPacket(std::uint8_t opcode, std::uint8_t parameter) {
    // 16-bit command word, little-endian: low byte = parameter, high byte = opcode.
    // Replicated to fill 512 bytes — matches MEX miniradarputdata behavior.
    std::array<std::uint8_t, kBulkOutPacketBytes> pkt{};
    for (std::size_t i = 0; i < kBulkOutPacketBytes; i += 2) {
        pkt[i]     = parameter;
        pkt[i + 1] = opcode;
    }
    return pkt;
}

double sweepTimeFromIndex(int index_1_5) {
    switch (index_1_5) {
        case 1: return 0.5e-3;
        case 2: return 1.0e-3;
        case 3: return 2.0e-3;
        case 4: return 4.0e-3;
        case 5: return 8.0e-3;
        default:
            throw std::out_of_range("sweep_time_index must be 1..5");
    }
}

namespace {
// Returns the BASE active sampling number table [num_rx][sweep_idx_1_5].
// Mirrors SetActiveParameters() — see PUPradarGUI.m lines 2150..2252.
int baseSamplingNumber(int sweep_idx, int num_rx) {
    if (sweep_idx < 1 || sweep_idx > 5) {
        throw std::out_of_range("sweep_idx must be 1..5");
    }
    // BASN[num_rx][sweep_idx-1]
    static constexpr int kBasn1[5] = {1024, 2048, 4096, 8192, 16384};  // Rx=1
    static constexpr int kBasn2[5] = { 512, 1024, 2048, 4096,  8192};  // Rx=2
    static constexpr int kBasn4[5] = { 256,  512, 1024, 2048,  4096};  // Rx=4
    switch (num_rx) {
        case 1: return kBasn1[sweep_idx - 1];
        case 2: return kBasn2[sweep_idx - 1];
        case 4: return kBasn4[sweep_idx - 1];
        default:
            throw std::out_of_range("num_rx must be 1, 2, or 4");
    }
}
}  // namespace

int samplesPerSweep(int sweep_time_idx, int sn_idx, int num_rx) {
    // SN_Selections = [BASN, BASN/2, BASN/4, BASN/8] for sn_idx 1..4
    if (sn_idx < 1 || sn_idx > 4) {
        throw std::out_of_range("sn_idx must be 1..4");
    }
    int basn = baseSamplingNumber(sweep_time_idx, num_rx);
    return basn >> (sn_idx - 1);
}

int txCount(std::uint8_t tx_mask) {
    switch (tx_mask) {
        case 1: case 2: return 1;
        case 3:         return 2;
        default:
            throw std::out_of_range("tx_mask must be 1, 2, or 3");
    }
}

int rxCount(std::uint8_t rx_mask) {
    int n = 0;
    for (int b = 0; b < 4; ++b) {
        if ((rx_mask >> b) & 0x1) ++n;
    }
    if (n == 0 || n == 3) {
        throw std::out_of_range("rx_mask must select 1, 2, or 4 channels");
    }
    return n;
}

std::vector<PllCommand>
buildSawtoothPllCommands(double f_low_hz, double f_high_hz, int sweep_time_idx) {
    if (!(f_low_hz > 0.0) || !(f_high_hz > f_low_hz)) {
        throw std::invalid_argument("f_high_hz must be > f_low_hz > 0");
    }
    const double bw_hz       = f_high_hz - f_low_hz;
    const double sweep_time  = sweepTimeFromIndex(sweep_time_idx);
    const double t_ref       = 1.0 / 50e6;

    // Sweep-up percentage table — copied from PUPradarGUI.m:2415..2425
    double t_up_pct;
    if      (bw_hz <= 0.5e9) t_up_pct = 0.94;
    else if (bw_hz == 1.0e9) t_up_pct = 0.92;
    else if (bw_hz == 1.5e9) t_up_pct = 0.84;
    else if (bw_hz == 2.0e9) t_up_pct = 0.80;
    else                     t_up_pct = 0.75;

    // MaxSweepover steps per sweep-time index — PUPradarGUI.m:2426..2436
    int max_sweepover;
    switch (sweep_time_idx) {
        case 1: max_sweepover =  4096; break;
        case 2: max_sweepover =  8192; break;
        case 3: max_sweepover = 16384; break;
        case 4: max_sweepover = 32768; break;
        case 5: max_sweepover = 65536; break;
        default: throw std::out_of_range("sweep_time_idx");
    }
    const int pll_sweep_stop = static_cast<int>(
        std::ceil(static_cast<double>(max_sweepover) * (t_up_pct + 0.01)));

    const double t_sweepup = sweep_time * t_up_pct;

    // BGT24: F_PLLinput = F_Tx / 16; reference = 50 MHz; 24-bit fraction.
    const double f_start = f_low_hz  / 16.0;
    const double f_stop  = f_high_hz / 16.0;
    const double start_n = f_start   / 50e6;
    const double stop_n  = f_stop    / 50e6;

    const long long start_n_int  = static_cast<long long>(std::floor(start_n));
    const double    start_n_frac = start_n - static_cast<double>(start_n_int);

    long long pll_reg03 = start_n_int;
    long long pll_reg04 = static_cast<long long>(std::llround(start_n_frac * (1LL << 24)));

    const double num_steps_d = t_sweepup / t_ref;
    const double step_int    = (stop_n - start_n) / num_steps_d;
    long long pll_reg0a = static_cast<long long>(std::llround(step_int * (1LL << 24)));

    // Adjust to land near actual stop frequency (mirrors GUI line 2548).
    const long long num_steps =
        static_cast<long long>(std::llround((stop_n - start_n) /
                               (static_cast<double>(pll_reg0a) / (1LL << 24))));
    const long long num_50mhz =
        static_cast<long long>(std::floor(static_cast<double>(num_steps) *
                                          static_cast<double>(pll_reg0a) / (1LL << 24)));
    long long pll_reg0c = start_n_int + num_50mhz;
    long long pll_reg0d = (num_steps * pll_reg0a) % (1LL << 24) + pll_reg04;
    if (pll_reg0d > (1LL << 24)) {
        pll_reg0c += 1;
        pll_reg0d -= (1LL << 24);
    }

    auto byte = [](long long v, int shift) -> std::uint8_t {
        return static_cast<std::uint8_t>((v >> shift) & 0xFF);
    };

    std::vector<PllCommand> cmds;
    cmds.reserve(20);
    // Order matches PUPradarGUI.m:2444..2599 exactly.
    cmds.push_back({opcode::kPllSweepStopL, byte(pll_sweep_stop, 0)});
    cmds.push_back({opcode::kPllSweepStopH, byte(pll_sweep_stop, 8)});
    cmds.push_back({opcode::kPll03L, byte(pll_reg03, 0)});
    cmds.push_back({opcode::kPll03M, byte(pll_reg03, 8)});
    cmds.push_back({opcode::kPll03H, byte(pll_reg03, 16)});
    cmds.push_back({opcode::kPll04L, byte(pll_reg04, 0)});
    cmds.push_back({opcode::kPll04M, byte(pll_reg04, 8)});
    cmds.push_back({opcode::kPll04H, byte(pll_reg04, 16)});
    cmds.push_back({opcode::kPll0AL, byte(pll_reg0a, 0)});
    cmds.push_back({opcode::kPll0AM, byte(pll_reg0a, 8)});
    cmds.push_back({opcode::kPll0AH, byte(pll_reg0a, 16)});
    cmds.push_back({opcode::kPll0CL, byte(pll_reg0c, 0)});
    cmds.push_back({opcode::kPll0CM, byte(pll_reg0c, 8)});
    cmds.push_back({opcode::kPll0CH, byte(pll_reg0c, 16)});
    cmds.push_back({opcode::kPll0DL, byte(pll_reg0d, 0)});
    cmds.push_back({opcode::kPll0DM, byte(pll_reg0d, 8)});
    cmds.push_back({opcode::kPll0DH, byte(pll_reg0d, 16)});
    return cmds;
}

BoardInfo decodeBoardInfo(const std::vector<std::uint16_t>& words) {
    BoardInfo info{};
    if (words.size() < 4 || words[0] != 0xFA05u) {
        return info;  // valid stays false
    }
    info.valid        = true;
    // word[1]: dec2hex gives ABCD; chars 3-4 = low byte
    info.freq_band    = static_cast<std::uint8_t>(words[1] & 0xFF);
    // word[2]: char 1 = (w>>12)&0xF, char 2 = (w>>8)&0xF, chars 3-4 = w&0xFF
    info.num_tx       = static_cast<std::uint8_t>((words[2] >> 12) & 0xFu);
    info.num_rx       = static_cast<std::uint8_t>((words[2] >>  8) & 0xFu);
    info.antenna_type = static_cast<std::uint8_t>(words[2] & 0xFF);
    // word[3]: char 2 = (w>>8)&0xF
    info.version      = static_cast<std::uint8_t>((words[3] >>  8) & 0xFu);
    // GUI line 2684
    info.modelcode    = static_cast<std::uint32_t>(info.freq_band)    * 1000000u
                      + static_cast<std::uint32_t>(info.num_tx)       *  100000u
                      + static_cast<std::uint32_t>(info.num_rx)       *   10000u
                      + static_cast<std::uint32_t>(info.antenna_type) *     100u
                      + static_cast<std::uint32_t>(info.version);
    // GUI lines 2687-2699
    switch (info.modelcode) {
        case  24240100u: info.model_name = "PUP_DU24P_T2R4";    break;
        case 240240100u: info.model_name = "PUP_EN24P_T2R4";    break;
        case 240240200u: info.model_name = "PUP_EN24C_T2R4 V1"; break;
        case 240240202u: info.model_name = "PUP_EN24C_T2R4 V2"; break;
        case 240140201u: info.model_name = "PUP_EN24C_T1R4";    break;
        default:         info.model_name = "unknown (Needs Refresh)"; break;
    }
    return info;
}

}  // namespace pupradar
