/// libusb-1.0 implementation of IUsbBackend.
#pragma once

#include "pupradar/IUsbBackend.hpp"

struct libusb_context;
struct libusb_device_handle;

namespace pupradar {

class UsbDevice final : public IUsbBackend {
public:
    UsbDevice();
    ~UsbDevice() override;

    UsbDevice(const UsbDevice&)            = delete;
    UsbDevice& operator=(const UsbDevice&) = delete;

    void open(std::uint16_t vid, std::uint16_t pid) override;
    void close() override;
    bool isOpen() const override;

    void claimInterface(int interface_number) override;
    void setAltSetting(int interface_number, int alt_setting) override;
    void resetDevice() override;

    std::size_t controlTransfer(std::uint8_t  bm_request_type,
                                std::uint8_t  b_request,
                                std::uint16_t w_value,
                                std::uint16_t w_index,
                                std::uint8_t* data,
                                std::size_t   length,
                                unsigned int  timeout_ms) override;

    std::size_t bulkWrite(std::uint8_t  endpoint,
                          const std::uint8_t* data,
                          std::size_t   length,
                          unsigned int  timeout_ms) override;

    std::size_t bulkRead(std::uint8_t  endpoint,
                         std::uint8_t* data,
                         std::size_t   length,
                         unsigned int  timeout_ms) override;

    void reopenAfterRenumeration(const VidPid* candidates,
                                 std::size_t   num_candidates,
                                 unsigned int  timeout_ms) override;

private:
    libusb_context*       ctx_    = nullptr;
    libusb_device_handle* handle_ = nullptr;
    int                   claimed_iface_ = -1;
    std::uint16_t         last_vid_ = 0;
    std::uint16_t         last_pid_ = 0;
};

}  // namespace pupradar
