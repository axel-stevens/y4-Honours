#!/usr/bin/env python3
import RPi.GPIO as GPIO # Uses rpi-lgpio backend automatically
import time
import signal
import subprocess

# Setup
PWM_PIN = 17
GPIO.setmode(GPIO.BCM)
GPIO.setup(PWM_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)

print("Sensing PWM Signal...")

rising_time = None
drone_armed = False
start_time = None

capture_time = []

def pwm_callback(channel):
    global drone_armed

    if drone_armed == False:
        drone_armed = True
        print("Drone Armed, starting timer")
        start_time = time.monotonic()

    global rising_time

    if GPIO.input(channel):
        
        # rising edge
        rising_time = time.monotonic_ns()
    else:
        # falling edge
        if rising_time is not None:
            falling_time = time.monotonic_ns()

            pulse_width_us = (falling_time - rising_time) / 1000

            print(f"Pulse width: {pulse_width_us:.0f} us")

            if pulse_width_us > 1700:
                print("Switch high")
                trigger_response()
            elif pulse_width_us < 1300:
                print("Switch low")

def trigger_response():
    print("triggering response")

    # Records time of capture since arming
    global capture_time
    capture_time.append(time.monotonic - start_time)

    print(capture_time)
    
    #subprocess.run(
    #    """
    #    cd ../SDR_main-main/linux/build-native
    #    pupradar --out duration
    #    """,
    #    shell=True,
    #    executable="/bin/bash",
    #    check=True
   # )

# If needing to test trigger_response uncomment:
#trigger_response()

GPIO.add_event_detect(
    PWM_PIN,
    GPIO.BOTH,
    callback=pwm_callback
)

def shutdown(signal_number, frame):
    print("cleaning up...")
    GPIO.cleanup()
    exit(0)


signal.signal(signal.SIGINT, shutdown)
signal.signal(signal.SIGTERM, shutdown)

print("Waiting for PWM signal...")

while True:
    time.sleep(1)
