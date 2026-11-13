# Drone radar telemetry sync

Code for a Raspberry Pi 5 on an Aurelia X6 drone. It logs telemetry from the flight controller and triggers radar captures from a switch on the RC transmitter, so each capture can be matched to the drone's position and orientation.

The main program is `telemetry_sync_main/fc_version_3-0`.

**Start with [QUICKSTART.md](QUICKSTART.md).**

| Guide | What it covers |
|---|---|
| [QUICKSTART.md](QUICKSTART.md) | Devices, folder layout, setup, running the program, output files, troubleshooting |
| [PI_VENV_SETUP.md](PI_VENV_SETUP.md) | Installing the Python dependencies on the Pi |
| [write_to_pi.md](write_to_pi.md) | Direct Ethernet link and SSH from a Windows laptop to the Pi |
| [RADAR_CONFIG.md](telemetry_sync_main/fc_version_3-0/RADAR_CONFIG.md) | Radar settings in `radar_config.json` |
