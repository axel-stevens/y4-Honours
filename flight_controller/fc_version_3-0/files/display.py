import os
import time


def format_time(seconds):

    if seconds is None:
        return "--:--:--"

    seconds = int(seconds)

    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    seconds = seconds % 60

    return f"{hours:02d}:{minutes:02d}:{seconds:02d}"


def display(radar, drone, runtime):

    os.system("clear")

    # --------------------------------------------------------
    # RUNNING TIMES
    # --------------------------------------------------------

    # --------------------------------------------------------
    # HEADER
    # --------------------------------------------------------

    print("=" * 60)
    print("              DRONE RADAR CONTROL INTERFACE")
    print("=" * 60)

    print()

    # --------------------------------------------------------
    # DRONE STATUS
    # --------------------------------------------------------

    print("  DRONE STATUS")
    print("  " + "-" * 32)

    print(f"  Program running time:  {format_time(runtime)}")

    print()

    # --------------------------------------------------------
    # RC INPUTS
    # --------------------------------------------------------

    print("  RC INPUTS")
    print("  " + "-" * 32)

    rc7_state = "HIGH" if rc.rc7_high else "LOW"
    rc8_state = "HIGH" if rc.rc8_high else "LOW"

    print(f"  RC7  GPIO 17:          {rc7_state}")
    print(f"       Pulse width:      {rc.rc7_pulse_width:.0f} us")

    print()

    print(f"  RC8  GPIO 27:          {rc8_state}")
    print(f"       Pulse width:      {rc.rc8_pulse_width:.0f} us")

    print()

    # --------------------------------------------------------
    # RADAR
    # --------------------------------------------------------

    print("  RADAR")
    print("  " + "-" * 32)

    radar_status = "CAPTURING" if radar.capturing else "NOT CAPTURING"

    print(f"  Capture status:        {radar_status}")
    print(f"  Captures:              {radar.capture_count}")

    if radar.last_capture_time is not None:
        capture_runtime = radar.last_capture_time
        print(f"  Last capture:          " f"{format_time(capture_runtime)}")
    else:
        print("  Last capture:          --:--:--")

    print()

    # --------------------------------------------------------
    # GPS
    # --------------------------------------------------------

    print("  GPS")
    print("  " + "-" * 32)

    gps_status = "ACTIVATED" if gps.activated else "NOT ACTIVATED"

    print(f"  Status:                {gps_status}")

    if gps.activation_time is not None:
        gps_runtime = gps.activation_time
        print(f"  Activation runtime:    " f"{format_time(gps_runtime)}")
    else:
        print("  Activation runtime:    --:--:--")

    print()

    # --------------------------------------------------------
    # FOOTER
    # --------------------------------------------------------

    print("=" * 60)
    print("  Press Ctrl+C to exit")
    print("=" * 60)
