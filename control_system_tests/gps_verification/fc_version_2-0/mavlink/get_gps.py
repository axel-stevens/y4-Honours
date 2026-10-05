from pymavlink import mavutil

# Connect to the flight controller
master = mavutil.mavlink_connection("/dev/ttyACM0", baud=115200)

print("Waiting for heartbeat...")
master.wait_heartbeat()
print("Connected!")

print("System:", master.target_system)
print("Component:", master.target_component)

# Continuously receive GPS data
while True:

    msg = master.recv_match(type="GPS_RAW_INT", blocking=True)

    if msg is not None:

        fix_type = msg.fix_type
        satellites = msg.satellites_visible

        print(f"GPS fix: {fix_type} | " f"Satellites: {satellites}")
