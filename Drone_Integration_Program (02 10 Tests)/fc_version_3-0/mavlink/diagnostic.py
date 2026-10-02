from pymavlink import mavutil

master = mavutil.mavlink_connection("/dev/ttyACM0", baud=115200)

print("Waiting for heartbeat...")
master.wait_heartbeat()
print("Connected!")


# Request GPS_RAW_INT at 1 Hz
master.mav.command_long_send(
    master.target_system,
    master.target_component,
    mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
    0,
    24,  # GPS_RAW_INT
    1_000_000,  # 1 Hz
    0,
    0,
    0,
    0,
    0,
)


while True:

    msg = master.recv_match(type="GPS_RAW_INT", blocking=True)

    if msg is not None:

        gps_fix = msg.fix_type >= 3
        satellites = msg.satellites_visible

        latitude = msg.lat / 1e7
        longitude = msg.lon / 1e7

        print(
            f"GPS: {gps_fix} | "
            f"Fix: {msg.fix_type} | "
            f"Sats: {satellites} | "
            f"Lat: {latitude:.7f} | "
            f"Lon: {longitude:.7f}"
        )
