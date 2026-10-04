from pymavlink import mavutil
import matplotlib.pyplot as plt
import os
import numpy as np

log = mavutil.mavlink_connection("2026-08-27 14-22-52.tlog")

latitude = []
longitude = []
time = []

os.remove("gps_flight_path.html") if os.path.exists("gps_flight_path.html") else None

# Extract latitude/longitude points
while True:
    msg = log.recv_match(type="GLOBAL_POSITION_INT", blocking=False)

    if msg is None:
        break

    time.append(msg.time_boot_ms / 1000)
    latitude.append(msg.lat / 1e7)
    longitude.append(msg.lon / 1e7)

latitude = np.array(latitude)
longitude = np.array(longitude)
time = np.array(time)

mask = (latitude != 0) & (longitude != 0)

latitude = latitude[mask]
longitude = longitude[mask]
time = time[mask]

import folium

# Centre map on first GPS position
m = folium.Map(location=[latitude[0], longitude[0]], zoom_start=15)

# Create list of [latitude, longitude] points
points = list(zip(latitude, longitude))

# Draw flight path
folium.PolyLine(points, weight=3).add_to(m)

# Start marker
folium.Marker([latitude[0], longitude[0]], popup="Start").add_to(m)

# End marker
folium.Marker([latitude[-1], longitude[-1]], popup="End").add_to(m)

# Save map
m.save("gps_flight_path.html")
