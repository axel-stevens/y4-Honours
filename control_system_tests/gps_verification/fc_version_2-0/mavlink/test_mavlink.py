from pymavlink import mavutil

master = mavutil.mavlink_connection("/dev/ttyACM0", baud=115200)

print("Waiting for heartbeat...")
master.wait_heartbeat()

print("Connected!")
print("System:", master.target_system)
print("Component:", master.target_component)
