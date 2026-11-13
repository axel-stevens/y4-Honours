import sys


def format_time(seconds):
    if seconds is None:
        return "--:--:--"

    seconds = int(seconds)

    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    seconds = seconds % 60

    return f"{hours:02d}:{minutes:02d}:{seconds:02d}"


def display(radar, drone, runtime):

    # Build the whole frame first, then draw it in one write. Moving the
    # cursor home and overwriting (instead of clearing the screen) stops
    # the display from flashing on every refresh.
    lines = []

    def out(text=""):
        # \033[K clears leftover characters when a line gets shorter
        lines.append(text + "\033[K")

    # ========================================================
    # DRONE STATUS
    # ========================================================

    out("  DRONE STATUS")
    out("  " + "-" * 32)

    armed_status = "ARMED" if drone.armed else "DISARMED"

    out(f"  Program running time:  {format_time(runtime)}")
    out(f"  Flight mode:           {drone.flight_mode}")
    out(f"  Armed:                 {armed_status}")
    out()

    # ========================================================
    # GPS
    # ========================================================

    out("  GPS")
    out("  " + "-" * 32)

    out(f"  Fix type:              {drone.gps_fix}")
    out(f"  Satellites:            {drone.satellites}")
    out(f"  Position:              " f"{drone.latitude:.7f}, {drone.longitude:.7f}")
    out(f"  Altitude:              {drone.altitude:.2f} m")
    out(f"  Relative altitude:     {drone.relative_altitude:.2f} m")
    out(f"  Groundspeed:           {drone.groundspeed:.2f} m/s")
    out()

    # ========================================================
    # ATTITUDE
    # ========================================================

    out("  ATTITUDE")
    out("  " + "-" * 32)

    out(f"  Roll:                  {drone.roll:.2f} rad")
    out(f"  Pitch:                 {drone.pitch:.2f} rad")
    out(f"  Yaw:                   {drone.yaw:.2f} rad")
    out()

    # ========================================================
    # BATTERY
    # ========================================================

    out("  BATTERY")
    out("  " + "-" * 32)

    out(f"  Voltage:               {drone.battery_voltage:.2f} V")
    out(f"  Current:               {drone.battery_current:.2f} A")

    if drone.battery_remaining >= 0:
        out(f"  Remaining:             {drone.battery_remaining}%")
    else:
        out("  Remaining:             --")

    out()

    # ========================================================
    # RC INPUT
    # ========================================================

    out("  RC INPUT")
    out("  " + "-" * 32)

    out(f"  Channel 15:            {drone.rc_channel_15}")
    out()

    # ========================================================
    # RADAR
    # ========================================================

    out("  RADAR")
    out("  " + "-" * 32)

    out(f"  Capture status:        {radar.state}")
    out(f"  Captures:              {radar.capture_count}")

    if radar.last_capture_time is not None:
        out(f"  Last capture:          " f"{format_time(radar.last_capture_time)}")
    else:
        out("  Last capture:          --:--:--")

    out()

    # ========================================================
    # FOOTER
    # ========================================================

    out("=" * 60)
    out("  Press Ctrl+C to exit")
    out("=" * 60)

    # \033[H moves the cursor home, \033[J clears anything below the frame
    sys.stdout.write("\033[H" + "\n".join(lines) + "\n\033[J")
    sys.stdout.flush()
