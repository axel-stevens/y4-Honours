# pupradar_capture — Linux ARM64 capture-only MVP

Single-binary tool for the **PUP EN24C T2R4** 24 GHz FMCW radar. Initializes the device, downloads firmware to the Cypress FX2LP, configures sawtooth FMCW, captures raw IQ for N seconds, and writes `<out>.bin` + `<out>.json`.

No MATLAB runtime on the target. Tested without hardware via the FakeUsbBackend test suite.

## Layout

```
linux/
├── CMakeLists.txt
├── toolchains/aarch64-linux-gnu.cmake     # cross-compile toolchain file
├── firmware/SDR_USB_FW.hex                # FX2LP firmware (copied from Matlab src/)
├── include/pupradar/                      # public headers
│   ├── Protocol.hpp                       # opcodes, command-packet builder, PLL math
│   ├── IntelHex.hpp                       # firmware HEX parser
│   ├── IUsbBackend.hpp                    # abstract USB interface (testable)
│   ├── UsbDevice.hpp                      # libusb-1.0 implementation
│   ├── RadarSession.hpp                   # init / configure / captureIq
│   └── IqWriter.hpp                       # raw .bin + JSON sidecar
├── src/                                   # implementations
├── tests/                                 # FakeUsbBackend + ~25 unit tests
└── scripts/
    ├── build_native.sh                    # host build + ctest
    ├── build_cross.sh                     # aarch64 cross build
    ├── deploy_pi.sh                       # scp to Pi
    └── 99-pupradar.rules                  # udev rule for non-root access
```

## Build & test on dev host (WSL / Linux)

Prereqs: `cmake >= 3.16`, `g++` with C++17, `libusb-1.0-0-dev`, `pkg-config`.

```bash
cd linux
./scripts/build_native.sh
```

This builds the executable for the host arch and runs the full test suite (`ctest --output-on-failure`). The Windows-side build path (CMake on MSVC) is not supported — use WSL.

## Cross-compile for Raspberry Pi 4/5 (Raspberry Pi OS 64-bit)

Prereqs in WSL/Debian:

```bash
sudo dpkg --add-architecture arm64
echo 'deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ jammy main universe' \
    | sudo tee /etc/apt/sources.list.d/arm64.list
sudo apt-get update
sudo apt-get install -y g++-aarch64-linux-gnu pkg-config libusb-1.0-0-dev:arm64
```

Then:

```bash
./scripts/build_cross.sh
file build-arm64/pupradar_capture   # → ELF 64-bit LSB executable, ARM aarch64
```

## Deploy and run on the Pi

```bash
./scripts/deploy_pi.sh pi@raspberrypi.local:~/pupradar
ssh pi@raspberrypi.local
sudo cp ~/pupradar/99-pupradar.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger

cd ~/pupradar
./pupradar_capture --duration 5 --out /tmp/cap
```

## Discovering the post-firmware VID/PID (one-time)

The Cypress FX2LP boots with a default VID/PID of `04B4:8613`, then re-enumerates after firmware load with VID/PID defined inside `SDR_USB_FW.hex`. The MATLAB driver hides this; libusb does not. The defaults baked into this binary are placeholders.

After the first attempted capture (which may fail at the re-enumeration step), inspect:

```bash
lsusb
# Look for the new Cypress (vendor 04b4) entry that wasn't there before firmware load.
```

Then pass it explicitly:

```bash
./pupradar_capture --post-fw-vid 0x04B4 --post-fw-pid 0xNNNN \
                   --duration 5 --out /tmp/cap
```

Once confirmed, edit `99-pupradar.rules` to match and reinstall, and add the value to `main.cpp` defaults (or document it in your operator notes).

## CLI reference

```
pupradar_capture --out <basename> [options]
  --duration <s>            Capture duration (default 5)
  --firmware <path>         Path to SDR_USB_FW.hex (default ./firmware/SDR_USB_FW.hex)
  --fc-low <Hz>             Sawtooth low frequency (default 24.0e9)
  --fc-high <Hz>            Sawtooth high frequency (default 24.25e9)
  --sweep-time <1-5>        1=0.5ms, 2=1ms, 3=2ms, 4=4ms, 5=8ms (default 2)
  --samp-num <1-4>          Sampling-number index, 1=BASN, 2=BASN/2, ... (default 1)
  --tx <mask>               1=Tx1, 2=Tx2, 3=Both (default 1)
  --rx <mask>               1/2/4/8=single, 3=Rx12, 12=Rx34, 15=All (default 1)
  --post-fw-vid <0xNNNN>    Post-firmware VID (default 0x04B4)
  --post-fw-pid <0xNNNN>    Post-firmware PID (default 0x1004; CONFIRM with lsusb)
  --post-fw-vid2/--pid2     Optional second candidate
  --reenum-timeout-ms <ms>  Re-enumeration wait (default 5000)
  --bulk-timeout-ms <ms>    Bulk-read timeout per chunk (default 2000)
```

## Output format

- `<out>.bin` — raw bulk-IN stream from EP6 (interleaved `int16` I/Q, little-endian).
  Includes the firmware-side framing/header bytes (≈2048-byte preamble per
  acquisition window per the GUI's deinterleave path). Parse with the same
  logic as `PUPradarGUI.m::GetComplexData` if you need calibrated samples.
- `<out>.json` — sidecar with frequencies, sweep time, sample rate per channel,
  channel masks, board info uint16 dump, ISO-8601 timestamp.

## Test approach (no hardware required)

`tests/FakeUsbBackend.hpp` records every USB call and replays scripted
responses for `controlTransfer` IN and `bulkRead`. Unit tests cover:

- Intel HEX parsing (valid, checksum failure, missing EOF, real first line)
- 512-byte command packet packing
- PLL register math (count, ordering, Start_N at 24.0 GHz)
- Sweep-time / sampling-number tables (verified against GUI `SetActiveParameters`)
- Tx/Rx mask validation
- Full session initialize sequence (open → claim → CPUCS → firmware → reopen → board info)
- Configure: opcodes in expected order, all 22 BulkOut commands
- captureIq: sinks bytes, returns coherent metadata
- IqWriter: bin size matches, JSON contains expected fields, escape characters

Run `ctest --output-on-failure` after `build_native.sh`.

## Known limitations / deferred

- CW mode (`--modulation cw`) — not implemented; `Send_PLL_CW` lives in MATLAB only.
- On-device DSP (FFT, range-Doppler) — explicitly out of scope per `PLAN.md`.
- Async libusb transfers — sync-only in MVP. Move to `libusb_submit_transfer` ring if sustained throughput proves insufficient.
- Windows host build — not supported. Use WSL.

See `progress/PROGRESS_*.md` for the implementation log.
