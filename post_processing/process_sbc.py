import folium
import pandas as pd
import os

# parameters
filename = "flight_log_4.csv"


# Code
df = pd.read_csv(filename)

# first lat/lon sample is invalid, drop it and reindex from 0
df = df.iloc[1:].reset_index(drop=True)

output_file = os.path.splitext(filename)[0] + ".html"  # -> "flight_log_4.html"
os.remove("synced_data.html") if os.path.exists("synced_data.html") else None

m = folium.Map(location=[df.at[0, "latitude"], df.at[0, "longitude"]], zoom_start=100)

# Create list of [latitude, longitude] points
points = list(zip(df["latitude"], df["longitude"]))

# Draw flight path
folium.PolyLine(points, weight=3).add_to(m)

capture_count = 0
for i, row in df.iterrows():
    tooltip_html = (
        f"<b>#{i}</b><br>"
        f"Latitude: {row['latitude']:.6f}<br>"
        f"Longitude: {row['longitude']:.6f}<br>"
        f"Capture Count: {row['radar_capture_count']}<br>"
    )

    if row["radar_capture_count"] == capture_count + 1:
        folium.CircleMarker(
            location=[row["latitude"], row["longitude"]],
            radius=3,
            color="blue",
            fill=True,
            fill_opacity=0.8,
            tooltip=tooltip_html,
        ).add_to(m)
        capture_count = 1 + capture_count
# Save map
m.save(output_file)
