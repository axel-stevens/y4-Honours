# PUP EN24C T2R4 — 24 GHz FMCW Radar

24 GHz, 2Tx / 4Rx FMCW radar over USB 3.x, driven by a Cypress FX3 controller.

Two parallel workflows live in this repo:

| Workflow | Platform | Where to start |
|---|---|---|
| Windows MATLAB GUI (existing reference) | Windows + MATLAB | [docs/Matlab src/PUPradarGUI.m](docs/Matlab%20src/PUPradarGUI.m) |
| Linux standalone capture (new port) | Raspberry Pi 4/5, aarch64 | [linux/README.md](linux/README.md) |

Post-capture signal processing (range profile, Doppler) runs on the Windows/MATLAB host from [processing_src/](processing_src/) — no on-device DSP.

---

## Repository layout

```
SDR_main/
│
├── docs/                              # All reference material
│   ├── PUP_EN24C_T2R4_datasheet.pdf  # RF specs, register map
│   ├── PUP_EN24C_T2R4_Manual.pdf     # Operating manual, RF parameter ranges
│   │
│   ├── Matlab src/                   # READ-ONLY — Windows MATLAB GUI
│   │   ├── PUPradarGUI.m             # Main GUI: init, configure, capture, plot
│   │   ├── PUPradarGUI.fig           # GUIDE figure layout
│   │   ├── SDR_USB_FW.hex            # Cypress FX3 firmware blob
│   │   └── *.mexw64                  # Pre-built Windows MEX binaries (CyAPI wrappers)
│   │
│   └── Mex src/                      # READ-ONLY — C++ MEX sources (Windows/CyAPI)
│       ├── PupRadar_Protocol.docx    # Authoritative on-the-wire USB protocol
│       ├── PupRadar_DataFormat.docx  # IQ packet and frame-header layout
│       ├── usbdownload.cpp           # Firmware download via Cypress 0xA0 boot
│       ├── miniradargetdata.cpp      # Bulk IQ ingest (endpoint, packet size, timeout)
│       ├── usbcheckchip.cpp          # VID/PID enumeration
│       └── *.cpp / *.mexw64          # Other USB wrapper sources and binaries
│
├── linux/                            # Standalone Linux/ARM64 capture binary
│   ├── README.md                     # Build, deploy, run, and CLI reference
│   ├── CMakeLists.txt
│   ├── firmware/SDR_USB_FW.hex       # Firmware copy used at runtime
│   ├── include/pupradar/             # Public C++ headers
│   │   ├── Protocol.hpp              # Opcodes, command-packet builder, PLL math
│   │   ├── IUsbBackend.hpp           # Abstract USB interface (enables unit tests)
│   │   ├── UsbDevice.hpp             # libusb-1.0 implementation
│   │   ├── RadarSession.hpp          # init / configureFMCW / captureIq
│   │   ├── IqWriter.hpp              # Raw .bin + JSON sidecar writer
│   │   └── IntelHex.hpp              # Intel HEX parser for firmware download
│   ├── src/                          # Implementations
│   ├── tests/                        # FakeUsbBackend + unit tests (no hardware needed)
│   ├── scripts/
│   │   ├── build_native.sh           # Host build + ctest
│   │   ├── build_cross.sh            # aarch64 cross-compile
│   │   ├── deploy_pi.sh              # scp binary to Pi
│   │   └── 99-pupradar.rules         # udev rule for non-root USB access
│   └── toolchains/
│       └── aarch64-linux-gnu.cmake   # Cross-compile toolchain file
│
├── processing_src/                   # Host-side MATLAB signal processing
│   ├── process.m                     # Read .bin, strip headers, compute range profile
│   ├── process_new.m                 # Background-subtraction variant (two captures)
│   └── plotRangeProfile.m            # Helper: FFT → range axis + power (dB)
│
└── temp/                             # Local captures (.bin / .json) — not committed
```

> `docs/Matlab src/` and `docs/Mex src/` are the canonical reference for the radar's wire protocol. Do not modify them.

---

## How to run the interface (Linux standalone capture)

`linux/` contains a C++17 binary that replaces the Windows GUI with a CLI. It runs **without any MATLAB runtime** on the Pi, using libusb-1.0 instead of CyAPI.

See **[linux/README.md](linux/README.md)** for full details. Quick reference:

```bash
# Build (WSL)
cd linux && ./scripts/build_cross.sh

# Deploy
./scripts/deploy_pi.sh pi@raspberrypi.local:~/pupradar

# Run on Pi
./pupradar_capture --firmware firmware/SDR_USB_FW.hex --duration 5 --out /tmp/cap
```

Outputs: `/tmp/cap.bin` (raw interleaved `int16` I/Q) + `/tmp/cap.json` (capture metadata).

---

## Post-capture processing (MATLAB on Windows)

Load a `.bin` capture on the Windows host:

| Script | Purpose |
|---|---|
| [processing_src/process.m](processing_src/process.m) | Read `.bin`, strip frame headers, separate I/Q, plot range profile |
| [processing_src/process_new.m](processing_src/process_new.m) | Same but with background subtraction (two captures) |
| [processing_src/plotRangeProfile.m](processing_src/plotRangeProfile.m) | Helper function: FFT → range axis + power (dB) |

The `.bin` format is interleaved `uint16` I/Q. Frame header bytes have values ≥ `0xC000` — subtract `0xC000` to recover the sample. See [docs/Mex src/PupRadar_DataFormat.docx](docs/Mex%20src/PupRadar_DataFormat.docx) for the authoritative layout.

---

## Reference documents

| Document | Content |
|---|---|
| [docs/PUP_EN24C_T2R4_datasheet.pdf](docs/PUP_EN24C_T2R4_datasheet.pdf) | RF specs, register map |
| [docs/PUP_EN24C_T2R4_Manual.pdf](docs/PUP_EN24C_T2R4_Manual.pdf) | Operating manual |
| [docs/Mex src/PupRadar_Protocol.docx](docs/Mex%20src/PupRadar_Protocol.docx) | USB command packet format (authoritative) |
| [docs/Mex src/PupRadar_DataFormat.docx](docs/Mex%20src/PupRadar_DataFormat.docx) | IQ packet and frame-header layout |
