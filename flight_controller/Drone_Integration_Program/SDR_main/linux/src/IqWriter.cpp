#include "pupradar/IqWriter.hpp"

#include <iomanip>
#include <sstream>
#include <stdexcept>

namespace pupradar {

namespace {

// Minimal JSON string escape — handles the few characters that can show up
// in our metadata (paths with backslashes, ISO timestamps).
std::string jsonEscape(const std::string& s) {
    std::string out;
    out.reserve(s.size() + 2);
    for (char c : s) {
        switch (c) {
            case '"':  out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\b': out += "\\b";  break;
            case '\f': out += "\\f";  break;
            case '\n': out += "\\n";  break;
            case '\r': out += "\\r";  break;
            case '\t': out += "\\t";  break;
            default:
                if (static_cast<unsigned char>(c) < 0x20) {
                    char buf[8];
                    std::snprintf(buf, sizeof(buf), "\\u%04x",
                                  static_cast<unsigned>(c));
                    out += buf;
                } else {
                    out += c;
                }
        }
    }
    return out;
}

}  // namespace

std::string serializeMetadataJson(const CaptureMetadata& md) {
    std::ostringstream o;
    o << std::setprecision(15);
    o << "{\n";
    o << "  \"format\": \"pupradar_capture/v1\",\n";
    o << "  \"timestamp_utc\": \""    << jsonEscape(md.timestamp_utc) << "\",\n";
    o << "  \"firmware_path\": \""    << jsonEscape(md.firmware_path) << "\",\n";
    o << "  \"f_low_hz\": "           << md.f_low_hz                  << ",\n";
    o << "  \"f_high_hz\": "          << md.f_high_hz                 << ",\n";
    o << "  \"bandwidth_hz\": "       << (md.f_high_hz - md.f_low_hz) << ",\n";
    o << "  \"fs_hz\": "              << md.fs_hz                     << ",\n";
    o << "  \"sweep_time_s\": "       << md.sweep_time_s              << ",\n";
    o << "  \"samples_per_sweep_per_rx\": " << md.samples_per_sweep_per_rx << ",\n";
    o << "  \"num_tx\": "             << md.num_tx                    << ",\n";
    o << "  \"num_rx\": "             << md.num_rx                    << ",\n";
    o << "  \"tx_mask\": "            << static_cast<int>(md.tx_mask) << ",\n";
    o << "  \"rx_mask\": "            << static_cast<int>(md.rx_mask) << ",\n";
    o << "  \"requested_duration_s\": " << md.requested_duration_s    << ",\n";
    o << "  \"actual_duration_s\": "  << md.actual_duration_s         << ",\n";
    o << "  \"bytes_captured\": "     << md.bytes_captured            << ",\n";
    o << "  \"reads_completed\": "    << md.reads_completed           << ",\n";
    o << "  \"capture_completed\": "  << (md.capture_completed ? "true" : "false") << ",\n";
    o << "  \"drain_sweeps_requested\": " << md.drain_sweeps_requested << ",\n";
    o << "  \"drain_bytes_discarded\": "  << md.drain_bytes_discarded  << ",\n";
    o << "  \"drain_completed\": "    << (md.drain_completed ? "true" : "false") << ",\n";
    o << "  \"sample_dtype\": \"int16_interleaved_iq\",\n";
    o << "  \"endian\": \"little\",\n";
    o << "  \"board_info_words_hex\": [";
    for (std::size_t i = 0; i < md.board_info_words.size(); ++i) {
        if (i > 0) o << ", ";
        o << "\"" << std::hex << std::uppercase << std::setw(4)
          << std::setfill('0') << md.board_info_words[i] << "\"";
        o << std::dec << std::nouppercase << std::setfill(' ');
    }
    o << "]\n";
    o << "}\n";
    return o.str();
}

IqWriter::IqWriter(const std::string& out_basename)
    : bin_path_(out_basename + ".bin"),
      json_path_(out_basename + ".json") {
    bin_.open(bin_path_, std::ios::binary | std::ios::trunc);
    if (!bin_.is_open()) {
        throw std::runtime_error("Cannot open output file: " + bin_path_);
    }
}

IqWriter::~IqWriter() = default;

void IqWriter::write(const std::uint8_t* data, std::size_t length) {
    bin_.write(reinterpret_cast<const char*>(data),
               static_cast<std::streamsize>(length));
    if (!bin_) {
        throw std::runtime_error("Write failure on " + bin_path_);
    }
}

void IqWriter::finalize(const CaptureMetadata& md) {
    bin_.flush();
    bin_.close();
    std::ofstream j(json_path_, std::ios::trunc);
    if (!j.is_open()) {
        throw std::runtime_error("Cannot open sidecar: " + json_path_);
    }
    j << serializeMetadataJson(md);
    if (!j) throw std::runtime_error("Write failure on " + json_path_);
}

}  // namespace pupradar
