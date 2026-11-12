#include "pupradar/IntelHex.hpp"

#include <fstream>
#include <sstream>
#include <stdexcept>

namespace pupradar {

namespace {

std::uint8_t hexNibble(char c) {
    if (c >= '0' && c <= '9') return static_cast<std::uint8_t>(c - '0');
    if (c >= 'A' && c <= 'F') return static_cast<std::uint8_t>(c - 'A' + 10);
    if (c >= 'a' && c <= 'f') return static_cast<std::uint8_t>(c - 'a' + 10);
    throw std::runtime_error("Intel HEX: non-hex character");
}

std::uint8_t hexByte(const std::string& s, std::size_t i) {
    if (i + 1 >= s.size()) {
        throw std::runtime_error("Intel HEX: truncated record");
    }
    return static_cast<std::uint8_t>((hexNibble(s[i]) << 4) | hexNibble(s[i + 1]));
}

}  // namespace

std::vector<HexRecord> parseIntelHex(std::istream& input) {
    std::vector<HexRecord> records;
    std::string line;
    bool saw_eof = false;
    std::size_t line_no = 0;

    while (std::getline(input, line)) {
        ++line_no;
        // Trim trailing CR/LF/whitespace
        while (!line.empty() &&
               (line.back() == '\r' || line.back() == '\n' ||
                line.back() == ' '  || line.back() == '\t')) {
            line.pop_back();
        }
        if (line.empty()) continue;

        if (line[0] != ':') {
            std::ostringstream oss;
            oss << "Intel HEX line " << line_no << ": missing ':' prefix";
            throw std::runtime_error(oss.str());
        }
        // Minimum: ':' + len(2) + addr(4) + type(2) + checksum(2) = 11 chars
        if (line.size() < 11 || (line.size() % 2) == 0) {
            std::ostringstream oss;
            oss << "Intel HEX line " << line_no << ": bad length " << line.size();
            throw std::runtime_error(oss.str());
        }

        const std::uint8_t  byte_count = hexByte(line, 1);
        const std::uint16_t address    = static_cast<std::uint16_t>(
            (hexByte(line, 3) << 8) | hexByte(line, 5));
        const std::uint8_t  rec_type   = hexByte(line, 7);

        // Expected line length = 1 + 2 + 4 + 2 + byte_count*2 + 2
        const std::size_t expected = 11 + static_cast<std::size_t>(byte_count) * 2;
        if (line.size() != expected) {
            std::ostringstream oss;
            oss << "Intel HEX line " << line_no
                << ": expected " << expected << " chars, got " << line.size();
            throw std::runtime_error(oss.str());
        }

        // Sum bytes (incl. checksum) — must be 0 mod 256
        unsigned sum = 0;
        for (std::size_t i = 1; i + 1 < line.size(); i += 2) {
            sum += hexByte(line, i);
        }
        if ((sum & 0xFFu) != 0) {
            std::ostringstream oss;
            oss << "Intel HEX line " << line_no << ": checksum failure";
            throw std::runtime_error(oss.str());
        }

        switch (rec_type) {
            case 0x00: {  // Data
                HexRecord rec;
                rec.address = address;
                rec.data.reserve(byte_count);
                for (std::uint8_t k = 0; k < byte_count; ++k) {
                    rec.data.push_back(
                        hexByte(line, 9 + 2 * static_cast<std::size_t>(k)));
                }
                records.push_back(std::move(rec));
                break;
            }
            case 0x01:  // EOF
                saw_eof = true;
                break;
            case 0x02: case 0x03: case 0x04: case 0x05:
                // Extended-address / start-segment records — irrelevant for FX2LP 8051
                break;
            default: {
                std::ostringstream oss;
                oss << "Intel HEX line " << line_no
                    << ": unknown record type 0x" << std::hex << +rec_type;
                throw std::runtime_error(oss.str());
            }
        }

        if (saw_eof) break;
    }

    if (!saw_eof) {
        throw std::runtime_error("Intel HEX: missing EOF record (type 01)");
    }
    return records;
}

std::vector<HexRecord> parseIntelHexFile(const std::string& path) {
    std::ifstream f(path);
    if (!f.is_open()) {
        throw std::runtime_error("Cannot open Intel HEX file: " + path);
    }
    return parseIntelHex(f);
}

}  // namespace pupradar
