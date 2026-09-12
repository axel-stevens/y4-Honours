import time


class GPS:

    def __init__(self):

        self.activated = False
        self.activation_time = None

    def activate(self):

        if self.activated:
            return

        self.activated = True

        self.activation_time = time.monotonic()
        with open("output.txt", "a") as file:
            file.write(f"GPS Activation time: {self.activation_time}\n")

    def deactivate(self):

        self.activated = False
