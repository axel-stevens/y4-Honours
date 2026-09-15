import os


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

    # ========================================================
    # HEADER
    # ========================================================

    print("=" * 60)
    print("              DRONE RADAR CONTROL INTERFACE")
    print("=" * 60)
    print()

    # ========================================================
    # DRONE STATUS
    # ========================================================

    print("  DRONE STATUS")
    print("  " + "-" * 32)

    armed_status = "ARMED" if drone.armed else "DISARMED"

    print(f"  Program running time:  {format_time(runtime)}")
    print(f"  Flight mode:           {drone.flight_mode}")
    print(f"  Armed:                 {armed_status}")
    print()

    # ========================================================
    # GPS
    # ========================================================

    print("  GPS")
    print("  " + "-" * 32)

    print(f"  Fix type:              {drone.gps_fix}")
    print(f"  Satellites:            {drone.satellites}")
    print(f"  Position:              " f"{drone.latitude:.7f}, {drone.longitude:.7f}")
    print(f"  Altitude:              {drone.altitude:.2f} m")
    print(f"  Relative altitude:     {drone.relative_altitude:.2f} m")
    print(f"  Groundspeed:           {drone.groundspeed:.2f} m/s")
    print()

    # ========================================================
    # ATTITUDE
    # ========================================================

    print("  ATTITUDE")
    print("  " + "-" * 32)

    print(f"  Roll:                  {drone.roll:.2f} rad")
    print(f"  Pitch:                 {drone.pitch:.2f} rad")
    print(f"  Yaw:                   {drone.yaw:.2f} rad")
    print()

    # ========================================================
    # BATTERY
    # ========================================================

    print("  BATTERY")
    print("  " + "-" * 32)

    print(f"  Voltage:               {drone.battery_voltage:.2f} V")
    print(f"  Current:               {drone.battery_current:.2f} A")

    if drone.battery_remaining >= 0:
        print(f"  Remaining:             {drone.battery_remaining}%")
    else:
        print("  Remaining:             --")

    print()

    # ========================================================
    # RC INPUT
    # ========================================================

    print("  RC INPUT")
    print("  " + "-" * 32)

    print(f"  Channel 15:            {drone.rc_channel_15}")
    print()

    # ========================================================
    # RADAR
    # ========================================================

    print("  RADAR")
    print("  " + "-" * 32)

    radar_status = "CAPTURING" if radar.capturing else "NOT CAPTURING"

    print(f"  Capture status:        {radar_status}")
    print(f"  Captures:              {radar.capture_count}")

    if radar.last_capture_time is not None:
        print(f"  Last capture:          " f"{format_time(radar.last_capture_time)}")
    else:
        print("  Last capture:          --:--:--")

    print()

    # ========================================================
    # FOOTER
    # ========================================================

    print("=" * 60)
    print("  Press Ctrl+C to exit")
    print("=" * 60)
