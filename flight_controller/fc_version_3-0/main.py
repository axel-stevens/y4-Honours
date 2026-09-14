#!/usr/bin/env python3

import RPi.GPIO as GPIO
import time
import signal


from files.radar import Radar
from files.Drone import Drone
from files.display import display
from files.config import DISPLAY_REFRESH

# ============================================================
# GLOBAL STATE
# ============================================================

start_time = time.monotonic()

# ============================================================
# INITIALISE
# ============================================================

GPIO.setmode(GPIO.BCM)

rc = RCInput()

radar = Radar()

gps = GPS()

drone = Drone()

# ============================================================
# OUTPUT
# ============================================================


def update_output(gps, radar):
    with open("output.txt", "w") as file:
        file.write(f"GPS Activation time: {gps.activation_time}\n")
        file.write(f"Radar capture times: {radar.capture_times}\n")


# ============================================================
# MAIN LOOP
# ============================================================


def main():

    global drone_armed
    global start_time

    print("Starting drone radar interface...")
    open("output.txt", "w")  # overwrite previous file

    try:

        while True:

            runtime = time.monotonic() - start_time

            # ------------------------------------------------
            # Radar Capture
            # ------------------------------------------------

            if rc.rc7_high and rc.rc7_last_low:

                radar.start_capture(runtime)
                update_output(gps, radar)
                radar.stop_capture()
                rc.rc7_last_low = 0

            if not rc.rc7_high:
                rc.rc7_last_low = 1

            # ------------------------------------------------
            # GPS
            # ------------------------------------------------

            if rc.rc8_high:

                gps.activate()
                update_output(gps, radar)

            # ------------------------------------------------
            # DISPLAY
            # ------------------------------------------------

            display(rc, radar, gps, runtime)

            time.sleep(DISPLAY_REFRESH)

    except KeyboardInterrupt:

        shutdown()


# ============================================================
# SHUTDOWN
# ============================================================


def shutdown():

    print("\nCleaning up...")

    GPIO.cleanup()


def signal_handler(signal_number, frame):

    shutdown()

    exit(0)


signal.signal(signal.SIGINT, signal_handler)

signal.signal(signal.SIGTERM, signal_handler)


# ============================================================
# START
# ============================================================

if __name__ == "__main__":

    main()
