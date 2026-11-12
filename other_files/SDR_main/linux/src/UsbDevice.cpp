#include "pupradar/UsbDevice.hpp"

#include <libusb-1.0/libusb.h>

#include <chrono>
#include <iomanip>
#include <sstream>
#include <thread>

namespace pupradar {

namespace {

// How long to wait for the device to come back if a reset re-enumerates it.
constexpr unsigned int kResetReopenTimeoutMs = 2000;

/**
 * @brief Throws a UsbError whose message includes the libusb error name and code.
 * @param what Short label identifying the failing libusb call.
 * @param rc   Negative libusb return code.
 * @throws UsbError Always.
 */
[[noreturn]] void throwLibusb(const char* what, int rc) {
    std::ostringstream oss;
    oss << what << ": " << libusb_error_name(rc) << " (" << rc << ")";
    throw UsbError(oss.str());
}

/**
 * @brief Returns a human-readable list of every USB device currently visible.
 *
 * Produces a comma-separated string of @c VID:PID hex pairs, e.g.
 * @c "04B4:00F3, 1D6B:0002".  Used to build diagnostic messages when
 * re-enumeration fails.
 *
 * @param ctx libusb context to enumerate against.
 * @return Formatted string, or @c "(none)" / @c "(could not enumerate)" on failure.
 */
std::string listVisibleDevices(libusb_context* ctx) {
    libusb_device** list = nullptr;
    ssize_t cnt = libusb_get_device_list(ctx, &list);
    if (cnt < 0) return "(could not enumerate)";

    std::ostringstream oss;
    bool first = true;
    for (ssize_t i = 0; i < cnt; ++i) {
        libusb_device_descriptor d{};
        if (libusb_get_device_descriptor(list[i], &d) != 0) continue;
        if (!first) oss << ", ";
        oss << std::hex << std::uppercase
            << std::setw(4) << std::setfill('0') << d.idVendor << ':'
            << std::setw(4) << std::setfill('0') << d.idProduct;
        first = false;
    }
    libusb_free_device_list(list, 1);
    return first ? "(none)" : oss.str();
}

/**
 * @brief Attempts to open the first USB device matching @p vid and @p pid.
 * @param ctx libusb context.
 * @param vid USB Vendor ID to match.
 * @param pid USB Product ID to match.
 * @return Opened device handle, or @c nullptr if no matching device was found
 *         or could be opened.
 * @throws UsbError if @c libusb_get_device_list fails.
 */
libusb_device_handle* tryOpen(libusb_context* ctx,
                              std::uint16_t vid, std::uint16_t pid) {
    libusb_device** list = nullptr;
    ssize_t cnt = libusb_get_device_list(ctx, &list);
    if (cnt < 0) throwLibusb("libusb_get_device_list", static_cast<int>(cnt));

    libusb_device_handle* h = nullptr;
    for (ssize_t i = 0; i < cnt; ++i) {
        libusb_device_descriptor d{};
        if (libusb_get_device_descriptor(list[i], &d) != 0) continue;
        if (d.idVendor == vid && d.idProduct == pid) {
            int rc = libusb_open(list[i], &h);
            if (rc == 0) break;
            // Permission or busy — keep trying others in the unlikely case of duplicates.
            h = nullptr;
        }
    }
    libusb_free_device_list(list, 1);
    return h;
}

}  // namespace

/**
 * @brief Initialises the libusb-1.0 context.
 * @throws UsbError if @c libusb_init fails.
 */
UsbDevice::UsbDevice() {
    int rc = libusb_init(&ctx_);
    if (rc != 0) throwLibusb("libusb_init", rc);
}

/**
 * @brief Releases the USB interface (if claimed), closes the device handle,
 *        and exits the libusb context.
 */
UsbDevice::~UsbDevice() {
    close();
    if (ctx_) libusb_exit(ctx_);
}

/**
 * @brief Opens the USB device identified by @p vid / @p pid.
 *
 * Any previously opened device is closed first.  Enumerates all attached USB
 * devices and opens the first match.
 *
 * @param vid USB Vendor ID.
 * @param pid USB Product ID.
 * @throws UsbError if no matching device is found or @c libusb_open fails.
 */
void UsbDevice::open(std::uint16_t vid, std::uint16_t pid) {
    close();
    handle_ = tryOpen(ctx_, vid, pid);
    if (!handle_) {
        std::ostringstream oss;
        oss << "USB device " << std::hex << vid << ":" << pid << " not found";
        throw UsbError(oss.str());
    }
    last_vid_ = vid;
    last_pid_ = pid;
}

/**
 * @brief Releases the currently claimed interface and closes the device handle.
 *
 * Safe to call on an already-closed device (no-op).
 */
void UsbDevice::close() {
    if (handle_) {
        if (claimed_iface_ >= 0) {
            libusb_release_interface(handle_, claimed_iface_);
            claimed_iface_ = -1;
        }
        libusb_close(handle_);
        handle_ = nullptr;
    }
}

/**
 * @brief Returns whether a device handle is currently held open.
 * @return @c true if open, @c false otherwise.
 */
bool UsbDevice::isOpen() const { return handle_ != nullptr; }

/**
 * @brief Claims a USB interface, detaching any kernel driver that holds it.
 *
 * On Linux, @c usbfs refuses to claim an interface while a kernel driver
 * (e.g. @c usbhid) owns it.  This method detaches the driver first, then
 * claims the interface.  The interface number is stored so that close() can
 * release it automatically.
 *
 * @param interface_number USB interface number (0-based).
 * @throws UsbError if the device is not open, driver detach fails (excluding
 *         @c LIBUSB_ERROR_NOT_FOUND), or @c libusb_claim_interface fails.
 */
void UsbDevice::claimInterface(int interface_number) {
    if (!handle_) throw UsbError("claimInterface: device not open");
    // Detach kernel driver if attached (Linux usbfs requirement).
    if (libusb_kernel_driver_active(handle_, interface_number) == 1) {
        int rc = libusb_detach_kernel_driver(handle_, interface_number);
        if (rc != 0 && rc != LIBUSB_ERROR_NOT_FOUND) {
            throwLibusb("libusb_detach_kernel_driver", rc);
        }
    }
    int rc = libusb_claim_interface(handle_, interface_number);
    if (rc != 0) throwLibusb("libusb_claim_interface", rc);
    claimed_iface_ = interface_number;
}

/**
 * @brief Selects an alternate setting for the specified USB interface.
 * @param interface_number USB interface number (must already be claimed).
 * @param alt_setting      Alternate setting index.
 * @throws UsbError if the device is not open or the call fails.
 */
void UsbDevice::setAltSetting(int interface_number, int alt_setting) {
    if (!handle_) throw UsbError("setAltSetting: device not open");
    int rc = libusb_set_interface_alt_setting(handle_, interface_number, alt_setting);
    if (rc != 0) throwLibusb("libusb_set_interface_alt_setting", rc);
}

/**
 * @brief Issues a USB port reset, returning the chip to its power-on state.
 *
 * @c libusb_reset_device reports @c LIBUSB_ERROR_NOT_FOUND when the device
 * re-enumerated as a result of the reset — the previous handle is then dead and
 * the device must be reopened. That is a normal outcome here rather than a
 * failure, so this method transparently reopens the same VID:PID (recorded by
 * open()) and returns with a usable handle. Firmware already resident in FX2
 * RAM survives the reset.
 *
 * @throws UsbError if the device is not open, the reset fails for any other
 *         reason, or the device does not reappear after re-enumerating.
 */
void UsbDevice::resetDevice() {
    if (!handle_) throw UsbError("resetDevice: device not open");
    int rc = libusb_reset_device(handle_);
    if (rc == 0) return;
    if (rc != LIBUSB_ERROR_NOT_FOUND) throwLibusb("libusb_reset_device", rc);

    // Device re-enumerated during the reset — reopen it under the same IDs.
    const VidPid same{last_vid_, last_pid_};
    reopenAfterRenumeration(&same, 1, kResetReopenTimeoutMs);
}

/**
 * @brief Issues a USB control transfer (IN or OUT, depending on @p bm).
 *
 * Parameters map directly onto the USB SETUP packet fields and are passed
 * verbatim to @c libusb_control_transfer.
 *
 * @param bm         @c bmRequestType — direction, type, and recipient bits.
 * @param br         @c bRequest — the specific request code.
 * @param wv         @c wValue field.
 * @param wi         @c wIndex field.
 * @param data       Data buffer (written by device for IN; read by device for OUT).
 * @param length     Buffer size in bytes; must be ≤ 65535.
 * @param timeout_ms Transfer timeout in milliseconds (0 = wait indefinitely).
 * @return Number of bytes actually transferred.
 * @throws UsbError if the device is not open, @p length exceeds 65535, or the
 *         transfer fails.
 */
std::size_t UsbDevice::controlTransfer(std::uint8_t  bm,
                                       std::uint8_t  br,
                                       std::uint16_t wv,
                                       std::uint16_t wi,
                                       std::uint8_t* data,
                                       std::size_t   length,
                                       unsigned int  timeout_ms) {
    if (!handle_) throw UsbError("controlTransfer: device not open");
    if (length > 0xFFFFu) throw UsbError("controlTransfer: length > 65535");
    int rc = libusb_control_transfer(handle_, bm, br, wv, wi,
                                     data, static_cast<std::uint16_t>(length),
                                     timeout_ms);
    if (rc < 0) throwLibusb("libusb_control_transfer", rc);
    return static_cast<std::size_t>(rc);
}

/**
 * @brief Performs a synchronous USB bulk OUT (host-to-device) transfer.
 * @param ep         Bulk OUT endpoint address (direction bit 7 clear).
 * @param data       Data to send.
 * @param length     Number of bytes to send.
 * @param timeout_ms Transfer timeout in milliseconds (0 = wait indefinitely).
 * @return Number of bytes actually written.
 * @throws UsbError if the device is not open or the transfer fails.
 */
std::size_t UsbDevice::bulkWrite(std::uint8_t  ep,
                                 const std::uint8_t* data,
                                 std::size_t   length,
                                 unsigned int  timeout_ms) {
    if (!handle_) throw UsbError("bulkWrite: device not open");
    int actual = 0;
    int rc = libusb_bulk_transfer(handle_, ep,
                                  const_cast<std::uint8_t*>(data),
                                  static_cast<int>(length), &actual, timeout_ms);
    if (rc != 0) throwLibusb("libusb_bulk_transfer (out)", rc);
    return static_cast<std::size_t>(actual);
}

/**
 * @brief Performs a synchronous USB bulk IN (device-to-host) transfer.
 *
 * On @c LIBUSB_ERROR_TIMEOUT, any bytes received before the deadline are
 * returned rather than raising an exception, allowing the capture loop to
 * save partial data and retry instead of aborting the entire capture.
 *
 * @param ep         Bulk IN endpoint address (direction bit 7 set).
 * @param data       Buffer to receive data into.
 * @param length     Buffer capacity in bytes.
 * @param timeout_ms Transfer timeout in milliseconds (0 = wait indefinitely).
 * @return Number of bytes received; 0 indicates a genuine timeout with no data
 *         (caller should retry).
 * @throws UsbError if the device is not open or a non-timeout transfer error
 *         occurs.
 */
std::size_t UsbDevice::bulkRead(std::uint8_t  ep,
                                std::uint8_t* data,
                                std::size_t   length,
                                unsigned int  timeout_ms) {
    if (!handle_) throw UsbError("bulkRead: device not open");
    int actual = 0;
    int rc = libusb_bulk_transfer(handle_, ep, data,
                                  static_cast<int>(length), &actual, timeout_ms);
    // On LIBUSB_ERROR_TIMEOUT, actual contains the bytes received before the
    // deadline — that data is valid. Return it so the capture loop can save it
    // and retry rather than aborting the entire capture.
    if (rc == 0 || (rc == LIBUSB_ERROR_TIMEOUT && actual > 0))
        return static_cast<std::size_t>(actual);
    if (rc == LIBUSB_ERROR_TIMEOUT)
        return 0;  // genuine timeout with no data — caller treats 0 as "retry"
    throwLibusb("libusb_bulk_transfer (in)", rc);
}

/**
 * @brief Polls for the device to reappear after a firmware-triggered re-enumeration.
 *
 * The FX3 chip disconnects and reconnects with a new USB address (and possibly
 * a new VID:PID) after receiving the @c 0xA0 boot firmware.  This method closes
 * the stale handle, then polls @p candidates every 100 ms until one reappears
 * or @p timeout_ms elapses.  The post-firmware VID:PID must be included in
 * @p candidates.
 *
 * @param candidates     Array of VID:PID pairs to accept as the re-enumerated device.
 * @param num_candidates Number of entries in @p candidates.
 * @param timeout_ms     Maximum time to wait in milliseconds.
 * @throws UsbError if no candidate device appears within the timeout, with a
 *         diagnostic listing the currently visible USB devices.
 */
void UsbDevice::reopenAfterRenumeration(const VidPid* candidates,
                                        std::size_t   num_candidates,
                                        unsigned int  timeout_ms) {
    close();  // release old handle; chip will re-enumerate
    using clock = std::chrono::steady_clock;
    const auto deadline = clock::now() + std::chrono::milliseconds(timeout_ms);
    while (clock::now() < deadline) {
        for (std::size_t i = 0; i < num_candidates; ++i) {
            libusb_device_handle* h = tryOpen(ctx_, candidates[i].vid,
                                              candidates[i].pid);
            if (h) {
                handle_ = h;
                return;
            }
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    std::ostringstream oss;
    oss << "reopenAfterRenumeration: device did not reappear within "
        << timeout_ms << " ms.\n"
        << "  Searched for:";
    for (std::size_t i = 0; i < num_candidates; ++i) {
        oss << " " << std::hex << std::uppercase
            << std::setw(4) << std::setfill('0') << candidates[i].vid << ':'
            << std::setw(4) << std::setfill('0') << candidates[i].pid;
    }
    oss << "\n  Currently visible: " << listVisibleDevices(ctx_)
        << "\n  Hint: check the post-firmware VID:PID with lsusb and update "
           "kPostFirmwareVid / kPostFirmwarePid in Protocol.hpp";
    throw UsbError(oss.str());
}

}  // namespace pupradar
