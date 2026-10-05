// In-memory fake of IUsbBackend that:
//   - records every call (op kind + args) for assertions
//   - returns scripted responses for control IN reads and bulk IN reads
//
// Test pattern: pre-load `bulk_in_responses` and `control_in_responses` queues
// with the bytes the backend should return; run RadarSession; then assert
// over `events`.
#pragma once

#include "pupradar/IUsbBackend.hpp"

#include <cstdint>
#include <cstring>
#include <deque>
#include <ostream>
#include <stdexcept>
#include <string>
#include <vector>

namespace pupradar::test {

struct UsbEvent {
    enum class Kind {
        Open, Close, ClaimInterface, SetAlt,
        ControlOut, ControlIn,
        BulkOut, BulkIn,
        ReopenAfterRenum
    };
    friend std::ostream& operator<<(std::ostream& os, Kind k) {
        switch (k) {
            case Kind::Open:             return os << "Open";
            case Kind::Close:            return os << "Close";
            case Kind::ClaimInterface:   return os << "ClaimInterface";
            case Kind::SetAlt:           return os << "SetAlt";
            case Kind::ControlOut:       return os << "ControlOut";
            case Kind::ControlIn:        return os << "ControlIn";
            case Kind::BulkOut:          return os << "BulkOut";
            case Kind::BulkIn:           return os << "BulkIn";
            case Kind::ReopenAfterRenum: return os << "ReopenAfterRenum";
        }
        return os << "?";
    }
    Kind                       kind;
    std::uint16_t              vid          = 0;
    std::uint16_t              pid          = 0;
    int                        interface_no = 0;
    int                        alt_setting  = 0;
    std::uint8_t               bm_request_type = 0;
    std::uint8_t               b_request    = 0;
    std::uint16_t              w_value      = 0;
    std::uint16_t              w_index      = 0;
    std::uint8_t               endpoint     = 0;
    std::vector<std::uint8_t>  payload;       // for *_OUT: bytes written
    std::size_t                requested_len = 0;
};

class FakeUsbBackend final : public IUsbBackend {
public:
    std::vector<UsbEvent>           events;
    std::deque<std::vector<std::uint8_t>> control_in_responses;
    std::deque<std::vector<std::uint8_t>> bulk_in_responses;
    bool                            is_open  = false;

    void open(std::uint16_t vid, std::uint16_t pid) override {
        UsbEvent e; e.kind = UsbEvent::Kind::Open; e.vid = vid; e.pid = pid;
        events.push_back(e);
        is_open = true;
    }
    void close() override {
        if (!is_open) return;
        UsbEvent e; e.kind = UsbEvent::Kind::Close; events.push_back(e);
        is_open = false;
    }
    bool isOpen() const override { return is_open; }

    void claimInterface(int n) override {
        UsbEvent e; e.kind = UsbEvent::Kind::ClaimInterface; e.interface_no = n;
        events.push_back(e);
    }
    void setAltSetting(int iface, int alt) override {
        UsbEvent e; e.kind = UsbEvent::Kind::SetAlt;
        e.interface_no = iface; e.alt_setting = alt;
        events.push_back(e);
    }

    std::size_t controlTransfer(std::uint8_t bm, std::uint8_t br,
                                std::uint16_t wv, std::uint16_t wi,
                                std::uint8_t* data, std::size_t length,
                                unsigned int /*timeout*/) override {
        UsbEvent e;
        e.bm_request_type = bm; e.b_request = br;
        e.w_value = wv; e.w_index = wi; e.requested_len = length;
        // Direction bit is MSB of bm
        if (bm & 0x80) {
            // IN
            e.kind = UsbEvent::Kind::ControlIn;
            if (control_in_responses.empty()) {
                throw std::runtime_error("FakeUsbBackend: no scripted control IN response");
            }
            auto resp = std::move(control_in_responses.front());
            control_in_responses.pop_front();
            std::size_t n = std::min(resp.size(), length);
            std::memcpy(data, resp.data(), n);
            events.push_back(e);
            return n;
        }
        // OUT
        e.kind = UsbEvent::Kind::ControlOut;
        e.payload.assign(data, data + length);
        events.push_back(e);
        return length;
    }

    std::size_t bulkWrite(std::uint8_t ep, const std::uint8_t* data,
                          std::size_t length, unsigned int) override {
        UsbEvent e; e.kind = UsbEvent::Kind::BulkOut; e.endpoint = ep;
        e.payload.assign(data, data + length);
        events.push_back(e);
        return length;
    }

    std::size_t bulkRead(std::uint8_t ep, std::uint8_t* data,
                         std::size_t length, unsigned int) override {
        UsbEvent e; e.kind = UsbEvent::Kind::BulkIn; e.endpoint = ep;
        e.requested_len = length;
        events.push_back(e);
        if (bulk_in_responses.empty()) {
            // Default: return requested zero-fill so tests that just want the
            // session to "make progress" don't have to script every read.
            std::memset(data, 0, length);
            return length;
        }
        auto resp = std::move(bulk_in_responses.front());
        bulk_in_responses.pop_front();
        std::size_t n = std::min(resp.size(), length);
        std::memcpy(data, resp.data(), n);
        return n;
    }

    void reopenAfterRenumeration(const VidPid* cands, std::size_t n,
                                 unsigned int) override {
        UsbEvent e; e.kind = UsbEvent::Kind::ReopenAfterRenum;
        if (n > 0) { e.vid = cands[0].vid; e.pid = cands[0].pid; }
        events.push_back(e);
        is_open = true;
    }

    // Helpers
    std::size_t countOf(UsbEvent::Kind k) const {
        std::size_t c = 0;
        for (const auto& e : events) if (e.kind == k) ++c;
        return c;
    }

    std::vector<UsbEvent> only(UsbEvent::Kind k) const {
        std::vector<UsbEvent> out;
        for (const auto& e : events) if (e.kind == k) out.push_back(e);
        return out;
    }
};

}  // namespace pupradar::test
