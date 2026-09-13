import RPi.GPIO as GPIO
import time

from .config import RC7_PIN, RC8_PIN
from .config import PWM_HIGH, PWM_LOW


class RCInput:

    def __init__(self):

        self.rc7_pulse_width = 0
        self.rc8_pulse_width = 0

        self.rc7_high = False
        self.rc8_high = False

        self.rc7_rising_time = None
        self.rc8_rising_time = None

        self.rc7_last_low = 0
        self.rc8_last_low = 0

        GPIO.setup(RC7_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)

        GPIO.setup(RC8_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)

        GPIO.add_event_detect(RC7_PIN, GPIO.BOTH, callback=self.rc7_callback)

        GPIO.add_event_detect(RC8_PIN, GPIO.BOTH, callback=self.rc8_callback)

    def rc7_callback(self, channel):

        if GPIO.input(channel):

            # Rising edge
            self.rc7_rising_time = time.monotonic_ns()

        else:

            # Falling edge
            if self.rc7_rising_time is not None:

                falling_time = time.monotonic_ns()

                self.rc7_pulse_width = (falling_time - self.rc7_rising_time) / 1000

                self.rc7_rising_time = None

                if self.rc7_pulse_width > PWM_HIGH:

                    self.rc7_high = True

                elif self.rc7_pulse_width < PWM_LOW:

                    self.rc7_high = False

    def rc8_callback(self, channel):

        if GPIO.input(channel):

            # Rising edge
            self.rc8_rising_time = time.monotonic_ns()

        else:

            # Falling edge
            if self.rc8_rising_time is not None:

                falling_time = time.monotonic_ns()

                self.rc8_pulse_width = (falling_time - self.rc8_rising_time) / 1000

                self.rc8_rising_time = None

                if self.rc8_pulse_width > PWM_HIGH:

                    self.rc8_high = True

                elif self.rc8_pulse_width < PWM_LOW:

                    self.rc8_high = False
