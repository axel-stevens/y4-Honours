import time
import subprocess


class Radar:

    def __init__(self):

        self.capturing = False
        self.capture_count = 0
        self.last_capture_time = None

        self.capture_times = []

    def start_capture(self, runtime):

        self.capture_count += 1

        self.last_capture_time = runtime

        self.capture_times.append(self.last_capture_time)

        print("Radar capture started")

        subprocess.run(
            f"sudo ~/Drone_Integration_Program/SDR_main-main/linux/build-arm64/pupradar_capture --firmware ~/Drone_Integration_Program/SDR_main-main/linux/firmware/SDR_USB_FW.hex --duration 1 --fc-low 24.00e9 --fc-high 26.00e9 --sweep-time 1 --samp-num 1 --out ~/SDR-data/1609_intergration/{self.capture_count}_time_{str(self.last_capture_time).replace(".", "_")} --rx 4",
            shell=True,
            executable="/bin/bash",
            check=True,
        )

    def flush(self, runtime):

        if self.capturing:
            return

        self.capturing = True

        print("Radar flushing")

        # Start radar here
        subprocess.run(
            f"sudo ~/Drone_Integration_Program/SDR_main-main/linux/build-arm64/pupradar_capture --firmware ~/Drone_Integration_Program/SDR_main-main/linux/firmware/SDR_USB_FW.hex --duration 1 --fc-low 24.00e9 --fc-high 26.00e9 --sweep-time 1 --samp-num 1 --out ~/SDR-data/1609_intergration/flush --rx 4",
            shell=True,
            executable="/bin/bash",
            check=True,
        )

    def stop_capture(self):

        if not self.capturing:
            return

        self.capturing = False

        print("Radar capture stopped")
