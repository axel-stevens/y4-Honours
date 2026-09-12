import time
import subprocess


class Radar:

    def __init__(self):

        self.capturing = False
        self.capture_count = 0
        self.last_capture_time = None

        self.capture_times = []

    def start_capture(self, start_time):

        if self.capturing:
            return

        self.capturing = True

        self.capture_count += 1

        self.last_capture_time = time.monotonic()

        if start_time is not None:
            self.capture_times.append(self.last_capture_time - start_time)

        print("Radar capture started")

        # Start radar here
        subprocess.run(
            """
            sudo ./build-arm64/pupradar_capture --firmware firmware/SDR_USB_FW.hex --duration 5 --fc-low 24.00e9 --fc-high 26e9 --sweep-time 1 --samp-num 4 --out ~/SDR-data/0209_pi/0209_2GHz_128_0-5ms_loopback_rx1_01 --rx 1
            """,
            shell=True,
            executable="/bin/bash",
            check=True,
        )

    def stop_capture(self):

        if not self.capturing:
            return

        self.capturing = False

        print("Radar capture stopped")
