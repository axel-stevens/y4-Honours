# Quickstart:\

> **`telemetry_sync_main` is the main program. It's the version to copy to and run on the Pi.** 
This is the program that runs on the Raspberry Pi on the drone. It does three things:

1. Reads telemetry from the flight controller over MAVLink: GPS, attitude, battery, armed state, flight mode and RC channels.
2. Logs that telemetry to a CSV file once a second, together with the radar's current state.
3. Starts a radar capture (`pupradar_capture`) when the pilot flips switch SF on the transmitter (RC channel 15).

Because telemetry and radar state go into the same CSV row, each radar capture can be matched to where the drone was and how it was oriented when the capture was taken.

---

## 1. Devices used

| Device | Details |
|---|---|
| Raspberry Pi | Raspberry Pi 5 running Ubuntu Server LTS. |
| Drone | Aurelia X6 Standard hexacopter. |
| Flight controller | CubePilot Cube Orange (the flight controller fitted to the Aurelia X6 Standard), running ArduPilot (ArduCopter). It is connected to the Pi by USB. The program expects it at `/dev/ttyACM0` (see `files/Drone.py`). |
| Radar | Luswave PUP_EN24C_T2R4: 24 GHz FMCW radar with 2 transmitters, 4 receivers and 6 external antennas. It connects to the Pi by USB-B Micro -> USB-A. It is controlled by the `pupradar_capture` program. |
| RC transmitter | Switch SF is mapped to RC channel 15 and triggers radar captures. |
| Laptop | Used to SSH into the Pi over a direct Ethernet cable. See `write_to_pi.md`. |

---

## 2. Folder layout

```
y4-Honours/
├── README.md                     Short overview, links to this guide
├── QUICKSTART.md                 This guide
├── PI_VENV_SETUP.md              Python venv setup on the Pi
├── write_to_pi.md                Ethernet link and SSH to the Pi
├── telemetry_sync_main/
│       ├── main.py               Entry point: connect, log, trigger captures, show the display
│       ├── radar_config.json     Radar settings (paths, frequencies, timings). Edit this, not the Python
│       ├── RADAR_CONFIG.md       Full reference for radar_config.json
│       └── files/
│           ├── Drone.py          MAVLink connection and telemetry parsing
│           ├── radar.py          Radar state machine; launches pupradar_capture
│           ├── display.py        Live terminal status screen
│           └── config.py         DISPLAY_REFRESH (loop period, 1 s). The other values are currently unused
├── telemetry_sync_testing/       Test flight logs and results
├── post_processing/              Analysis scripts for flight logs
└── other_files/                  Supporting material (SDR program copy, report data, experiments)
```

---

## 3. One-time setup on the Pi

### 3.1 Network access

Follow `write_to_pi.md` to set up the direct Ethernet link and a static IP. The Pi has been at `192.168.137.2`, with user `axel`.

```bash
ssh axel@192.168.137.2
```

### 3.2 Python dependencies

The program runs from a venv at `~/Drone_Integration_Program/.venv` with `pymavlink` and `rpi-lgpio` installed. Follow `PI_VENV_SETUP.md` to create it.

The Pi 5 uses `rpi-lgpio` instead of `RPi.GPIO`, which doesn't work on the Pi 5. `PI_VENV_SETUP.md` explains why.

### 3.3 Radar software

`radar_config.json` expects the radar tools at these paths:

```
~/Drone_Integration_Program/SDR_main-main/linux/build-arm64/pupradar_capture
~/Drone_Integration_Program/SDR_main-main/linux/firmware/SDR_USB_FW.hex
```

`SDR_main-main` is the SDR program that runs the radar captures. `pupradar_capture` is its capture tool, and `main.py` runs it for every capture. The SDR program's own `linux/README.md` has the build instructions, including the "Cross-compile for Raspberry Pi 4/5" section that produces `build-arm64/pupradar_capture`.

`use_sudo` is `true`, so the program runs `sudo pupradar_capture ...`.

### 3.4 Copy the code to the Pi

From the laptop, in `telemetry_sync_main/`:

```bash
scp -r . axel@192.168.137.2:Drone_Integration_Program/
```

---

## 4. Running it

The program is started manually over SSH. Connect to the Pi (see `write_to_pi.md`), then run:

```bash
source ~/Drone_Integration_Program/.venv/bin/activate
cd ~/Drone_Integration_Program
python main.py
```

What happens at startup:

1. **`Waiting for heartbeat...`** The program blocks until the flight controller responds. If it stays here, check the USB cable and that the device is `/dev/ttyACM0` (`ls /dev/ttyACM*`).
2. **`Connected!`** It asks the flight controller to stream the telemetry messages it needs.
3. **`Logging to ~/.local/flight_logs/flight_log_YYYYMMDD_HHMMSS.csv`** A new file is created for each run.
4. **`Radar initialising (uploading firmware)`** A one-off capture uploads the firmware to the radar and writes to `initialise_radar_capture`. Captures can't be triggered until this finishes and the state shows `IDLE`.
5. The live status screen appears and refreshes every second.


---

## 5. Triggering a radar capture

Flip switch SF high (PWM > 1800). Before the next capture can be triggered, the switch has to go low again (PWM < 1200), so holding it high only gives one capture. The status screen shows the live channel 15 value, which helps when checking the switch.

Each request runs through these states (see `files/radar.py`):

```
IDLE → FLUSHING → SETTLING (settle_time) → CAPTURING (capture.duration) → COOLDOWN (buffer_time) → IDLE
```

With the current `radar_config.json`, that is a 5 s settle, a 3 s capture and no cooldown, so about 8 s per capture. A request made while the radar is busy is ignored, and the terminal prints `Radar busy (...)`.

> The separate flush run is commented out in `radar.py`, so `FLUSHING` goes straight to `SETTLING` and the `flush` block in `radar_config.json` is not used. Flushing old data from the radar is meant to be handled by the SDR program's `--drain-sweeps` option instead. `radar.py` doesn't pass that option, and its default is 0, so captures currently run without a flush. Each capture's `.json` file shows what happened (`drain_sweeps_requested`, `drain_bytes_discarded`).

To change frequencies, durations or timings, edit `radar_config.json`. `RADAR_CONFIG.md` explains every key and the JSON syntax rules.


---

## 6. Output files

| Output | Location on the Pi |
|---|---|
| Flight log CSV | `~/.local/flight_logs/flight_log_<start date/time>.csv` |
| Radar captures | `output_dir` from the config (currently `~/SDR-data/1609_intergration/`) |

Radar captures are named `<capture_count>_time_<runtime>`, with dots in the runtime replaced by underscores. For example, `3_time_12_5` is capture 3, taken 12.5 s after the program started.

### Matching captures to telemetry

- `runtime` in the CSV is the number of seconds since `main.py` started. It isn't the time of day. The start date and time are in the CSV filename.
- While a capture is being recorded, `radar_file` in the CSV contains its path and `radar_capturing` is `True`. Filter on these to find the telemetry for each capture.
- `radar_capture_count` and `radar_last_capture_time` match the number and time in the capture's filename.

Units: latitude/longitude in degrees, altitudes in m, groundspeed in m/s, roll/pitch/yaw in radians, battery in V and A, and channel 15 as raw PWM.

### Copying data back to the laptop

```bash
scp -r axel@192.168.137.2:~/.local/flight_logs .
scp -r axel@192.168.137.2:~/SDR-data .
```

Analysis scripts are in `post_processing/`. `process_drone.py` plots GPS paths from the flight controller's `.tlog` files.
