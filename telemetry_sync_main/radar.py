import json
import os
import subprocess
from pathlib import Path

# radar_config.json lives in fc_version_3-0/, one level above files/
DEFAULT_CONFIG = Path(__file__).resolve().parent.parent / "radar_config.json"

# ============================================================
# RADAR STATES
# ============================================================
#
# INITIALISING -> IDLE                       (once, at startup)
# IDLE -> FLUSHING -> SETTLING -> CAPTURING -> COOLDOWN -> IDLE
#
# INITIALISING  startup capture running, uploads firmware to the radar
# FLUSHING   flush process running
# SETTLING   waiting settle_time seconds after the flush
# CAPTURING  capture process running
# COOLDOWN   waiting buffer_time seconds before another capture is allowed

INITIALISING = "INITIALISING"
IDLE = "IDLE"
FLUSHING = "FLUSHING"
SETTLING = "SETTLING"
CAPTURING = "CAPTURING"
COOLDOWN = "COOLDOWN"


class Radar:

    def __init__(self, config_path=DEFAULT_CONFIG):

        with open(config_path) as f:
            self.config = json.load(f)

        self.settle_time = self.config["settle_time"]
        self.buffer_time = self.config["buffer_time"]

        self.state = IDLE

        # Set once the startup capture has uploaded the firmware
        self.initialised = False

        # Running pupradar_capture process (flush or capture), if any
        self.process = None

        # Runtime at which the current state was entered
        self.state_start_time = None

        self.capture_count = 0
        self.last_capture_time = None

        # Path of the capture currently being recorded, None otherwise
        self.current_capture_file = None

        self.capture_times = []

    @property
    def capturing(self):

        return self.state == CAPTURING

    def ready(self):

        return self.state == IDLE

    def _build_command(self, mode, out_name, firmware=False):

        cfg = self.config
        params = cfg[mode]

        out_dir = os.path.expanduser(cfg["output_dir"])
        os.makedirs(out_dir, exist_ok=True)

        cmd = [
            os.path.expanduser(cfg["binary"]),
            "--firmware",
            os.path.expanduser(cfg["firmware"]),
            "--duration",
            str(params["duration"]),
            "--fc-low",
            str(params["fc_low"]),
            "--fc-high",
            str(params["fc_high"]),
            "--sweep-time",
            str(params["sweep_time"]),
            "--samp-num",
            str(params["samp_num"]),
            "--out",
            os.path.join(out_dir, out_name),
            "--rx",
            str(params["rx"]),
        ]

        if firmware:
            cmd.append("--download-firmware")

        if cfg.get("use_sudo", False):
            cmd.insert(0, "sudo")

        return cmd

    def _set_state(self, state, runtime):

        self.state = state
        self.state_start_time = runtime

    def _process_finished(self, name):

        # Returns True once the running process has exited
        return_code = self.process.poll()

        if return_code is None:
            return False

        if return_code != 0:
            print(f"Radar {name} failed with exit code {return_code}")

        self.process = None

        return True

    def request_capture(self, runtime):

        # Starts the flush -> settle -> capture sequence.
        # Returns False if the radar is still busy with the previous one.

        if not self.initialised or not self.ready():
            return False

        # print("Radar flushing")

        # self.process = subprocess.Popen(self._build_command("flush", "flush"))

        self._set_state(FLUSHING, runtime)

        return True

    def initialise_capture(self, runtime):

        # One-off startup capture that uploads the firmware. Every later
        # flush/capture omits --firmware so it is never re-uploaded.
        # Returns False if already initialised or the radar is busy.

        if self.initialised or not self.ready():
            return False

        print("Radar initialising (uploading firmware)")

        cmd = self._build_command("capture", "initialise_radar_capture", firmware=True)

        self.process = subprocess.Popen(cmd)

        self.current_capture_file = cmd[cmd.index("--out") + 1]

        self._set_state(INITIALISING, runtime)

        return True

    def _start_capture(self, runtime):

        self.capture_count += 1

        self.last_capture_time = runtime

        self.capture_times.append(self.last_capture_time)

        print("Radar capture started")

        out_name = (
            f"{self.capture_count}_time_{str(self.last_capture_time).replace('.', '_')}"
        )

        cmd = self._build_command("capture", out_name)

        self.process = subprocess.Popen(cmd)

        self.current_capture_file = cmd[cmd.index("--out") + 1]

        self._set_state(CAPTURING, runtime)

    def update(self, runtime):

        # Call once per main loop iteration. Never blocks.

        if self.state == INITIALISING:

            if self._process_finished("initialise"):
                print("Radar initialised")
                self.initialised = True
                self.current_capture_file = None
                self._set_state(IDLE, runtime)

        elif self.state == FLUSHING:

            # if self._process_finished("flush"):
            self._set_state(SETTLING, runtime)

        elif self.state == SETTLING:

            if runtime >= self.state_start_time + self.settle_time:
                self._start_capture(runtime)

        elif self.state == CAPTURING:

            if self._process_finished("capture"):
                print("Radar capture stopped")
                self.current_capture_file = None
                self._set_state(COOLDOWN, runtime)

        elif self.state == COOLDOWN:

            if runtime >= self.state_start_time + self.buffer_time:
                self._set_state(IDLE, runtime)

    def stop(self):

        # Terminates any running flush/capture, e.g. on shutdown

        if self.process is not None and self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()

        self.process = None
        self.current_capture_file = None
        self.state = IDLE
