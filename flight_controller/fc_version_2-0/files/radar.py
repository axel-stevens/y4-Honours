import time


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

    def stop_capture(self):

        if not self.capturing:
            return

        self.capturing = False

        print("Radar capture stopped")

        # Stop radar here
