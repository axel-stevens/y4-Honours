/// Abstract USB backend. The libusb implementation lives in UsbDevice.cpp;
/// tests substitute FakeUsbBackend (in tests/FakeUsbBackend.hpp).
///
/// Designing this interface around the *operations the radar driver actually
/// performs* (control transfer, bulk read/write, claim, set-alt, reopen)
/// rather than wrapping libusb verbatim keeps tests focused on radar logic
/// instead of USB-stack mechanics.
#pragma once

#include <cstdint>
#include <cstddef>
#include <stdexcept>
#include <string>

namespace pupradar {

class UsbError : public std::runtime_error {
public:
    using std::runtime_error::runtime_error;
};

class IUsbBackend {
public:
    virtual ~IUsbBackend() = default;

    /// Open the first device matching VID/PID. Throws UsbError on failure.
    virtual void open(std::uint16_t vid, std::uint16_t pid) = 0;

    /// Close current handle (idempotent).
    virtual void close() = 0;

    /// Whether a device is currently open.
    virtual bool isOpen() const = 0;

    /// Detach kernel driver if attached, then claim the interface.
    virtual void claimInterface(int interface_number) = 0;

    /// Set alternate interface setting on the currently-claimed interface.
    virtual void setAltSetting(int interface_number, int alt_setting) = 0;

    /// Issue a USB port reset, returning the chip to its power-on state.
    /// The device may re-enumerate as a side effect; implementations must
    /// leave a usable handle open on the same VID/PID when it does.
    virtual void resetDevice() = 0;

    /// Vendor-specific control transfer (request type 0x40 OUT or 0xC0 IN).
    /// Returns the number of bytes transferred.
    virtual std::size_t controlTransfer(std::uint8_t  bm_request_type,
                                        std::uint8_t  b_request,
                                        std::uint16_t w_value,
                                        std::uint16_t w_index,
                                        std::uint8_t* data,
                                        std::size_t   length,
                                        unsigned int  timeout_ms) = 0;

    /// Bulk transfers. Endpoint MSB encodes direction (0x80 = IN).
    /// Returns bytes actually transferred. Throws on error or timeout.
    virtual std::size_t bulkWrite(std::uint8_t  endpoint,
                                  const std::uint8_t* data,
                                  std::size_t   length,
                                  unsigned int  timeout_ms) = 0;

    virtual std::size_t bulkRead(std::uint8_t  endpoint,
                                 std::uint8_t* data,
                                 std::size_t   length,
                                 unsigned int  timeout_ms) = 0;

    /// After firmware download, the FX2LP re-enumerates with a new VID/PID.
    /// This polls until a device matching one of the candidate (vid,pid) pairs
    /// appears, with up to `timeout_ms` total wait. Throws on timeout.
    struct VidPid { std::uint16_t vid; std::uint16_t pid; };
    virtual void reopenAfterRenumeration(const VidPid* candidates,
                                         std::size_t   num_candidates,
                                         unsigned int  timeout_ms) = 0;
};

}  // namespace pupradar
