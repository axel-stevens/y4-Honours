/// Writes raw IQ stream to \<out\>.bin and metadata to \<out\>.json.
/// The JSON writer is hand-rolled (~50 lines) — no external dep.
#pragma once

#include "pupradar/RadarSession.hpp"

#include <cstdint>
#include <fstream>
#include <string>

namespace pupradar {

class IqWriter {
public:
    /// @param out_basename Base path with no extension; .bin and .json are appended.
    explicit IqWriter(const std::string& out_basename);
    ~IqWriter();

    IqWriter(const IqWriter&)            = delete;
    IqWriter& operator=(const IqWriter&) = delete;

    /// IqSink-compatible — feed into RadarSession::captureIq.
    void write(const std::uint8_t* data, std::size_t length);

    /// Closes the binary file (flushes), then writes the JSON sidecar.
    void finalize(const CaptureMetadata& md);

    const std::string& binPath()  const { return bin_path_; }
    const std::string& jsonPath() const { return json_path_; }

private:
    std::string   bin_path_;
    std::string   json_path_;
    std::ofstream bin_;
};

/// Exposed for unit tests: serialize metadata as JSON into a string.
std::string serializeMetadataJson(const CaptureMetadata& md);

}  // namespace pupradar
