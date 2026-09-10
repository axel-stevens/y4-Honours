#!/usr/bin/env python3
import RPi.GPIO as GPIO # Uses rpi-lgpio backend automatically
from time import sleep
import signal

# Setup
GPIO_PIN = 17
GPIO.setmode(GPIO.BCM)
GPIO.setup(GPIO_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)

print("Sensing 3.3V High...")

try:
    while True:
        if GPIO.input(GPIO_PIN):
            print("Pin High")
            sleep(1)
except KeyboardInterrupt:
    print("Stopping...")
finally:
    GPIO.cleanup()