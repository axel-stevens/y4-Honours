/// Minimal Intel HEX parser, scoped to what the FX2LP firmware loader needs.
/// Supports record types 00 (data), 01 (EOF). Other types (02 ext segment,
/// 03 start segment, 04 ext linear, 05 start linear) are accepted-and-skipped
/// because the FX2LP 8051 firmware fits inside a single 16-bit address space
/// and never uses them. We validate the per-record checksum.
#pragma once

#include <cstdint>
#include <istream>
#include <string>
#include <vector>

namespace pupradar {

struct HexRecord {
    std::uint16_t              address;  // Destination address in 8051 RAM
    std::vector<std::uint8_t>  data;     // Payload bytes
};

/// Parses a stream of Intel HEX text and returns all data records (type 00)
/// in file order. Throws std::runtime_error on:
///   - missing leading ':'
///   - non-hex character
///   - byte-count mismatch
///   - checksum failure
///   - unknown record type other than 00/01/02/03/04/05
///   - missing EOF record (type 01)
std::vector<HexRecord> parseIntelHex(std::istream& input);

/// Convenience wrapper that opens a file and parses it.
std::vector<HexRecord> parseIntelHexFile(const std::string& path);

}  // namespace pupradar
