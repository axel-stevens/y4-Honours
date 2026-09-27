#!/usr/bin/env python3

import csv
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

radar = Radar()
drone = Drone()


# ============================================================
# CSV LOGGING
# ============================================================


def initialise_csv(filename):

    file = open(filename, "w", newline="")

    writer = csv.writer(file)

    writer.writerow(
        [
            "runtime",
            "latitude",
            "longitude",
            "gps_fix",
            "satellites",
            "altitude",
            "relative_altitude",
            "groundspeed",
            "roll",
            "pitch",
            "yaw",
            "armed",
            "flight_mode",
            "battery_voltage",
            "battery_current",
            "battery_remaining",
            "rc_channel_15",
            "radar_capturing",
            "radar_capture_count",
            "radar_last_capture_time",
        ]
    )

    return file, writer


def log_data(writer, runtime, drone, radar):

    writer.writerow(
        [
            runtime,
            drone.latitude,
            drone.longitude,
            drone.gps_fix,
            drone.satellites,
            drone.altitude,
            drone.relative_altitude,
            drone.groundspeed,
            drone.roll,
            drone.pitch,
            drone.yaw,
            drone.armed,
            drone.flight_mode,
            drone.battery_voltage,
            drone.battery_current,
            drone.battery_remaining,
            drone.rc_channel_15,
            radar.capturing,
            radar.capture_count,
            radar.last_capture_time,
        ]
    )


# ============================================================
# MAIN LOOP
# ============================================================


def main():

    global start_time

    print("Starting drone radar interface...")

    # --------------------------------------------------------
    # Connect to flight controller
    # --------------------------------------------------------

    drone.connect()

    # --------------------------------------------------------
    # Request required MAVLink messages
    # --------------------------------------------------------

    drone.request_messages()

    # --------------------------------------------------------
    # Initialise CSV
    # --------------------------------------------------------

    csv_file, csv_writer = initialise_csv("flight_log.csv")

    try:

        while True:

            # ------------------------------------------------
            # RUNTIME
            # ------------------------------------------------

            runtime = time.monotonic() - start_time

            # ------------------------------------------------
            # UPDATE DRONE
            # ------------------------------------------------

            drone.update()

            # ------------------------------------------------
            # RADAR CAPTURE
            # ------------------------------------------------

            if drone.rc_channel_15 and drone.rc15_last_low:

                radar.start_capture(runtime)

                radar.stop_capture()

                drone.rc15_last_low = 0

            if not drone.rc_channel_15:

                drone.rc15_last_low = 1

            # ------------------------------------------------
            # LOG DATA
            # ------------------------------------------------

            log_data(csv_writer, runtime, drone, radar)

            # Make sure the data is actually written to disk
            csv_file.flush()

            # ------------------------------------------------
            # DISPLAY
            # ------------------------------------------------

            display(radar, drone, runtime)

            time.sleep(DISPLAY_REFRESH)

    except KeyboardInterrupt:

        shutdown()

    finally:

        csv_file.close()


# ============================================================
# SHUTDOWN
# ============================================================


def shutdown():

    print("\nCleaning up...")

    GPIO.cleanup()


# ============================================================
# SIGNAL HANDLER
# ============================================================


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
