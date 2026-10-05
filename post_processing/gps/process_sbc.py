import folium
import pandas as pd
import os

# parameters
filename = "flight_log_4.csv"


# Code
df = pd.read_csv(filename)

# first lat/lon sample is invalid, drop it and reindex from 0
df = df.iloc[1:].reset_index(drop=True)


os.remove("synced_data.html") if os.path.exists("synced_data.html") else None

m = folium.Map(location=[df.at[0, "latitude"], df.at[0, "longitude"]], zoom_start=15)

# Create list of [latitude, longitude] points
points = list(zip(df["latitude"], df["longitude"]))

# Draw flight path
folium.PolyLine(points, weight=3).add_to(m)

for i, row in df.iterrows():
    if row["radar_capturing"] == True:
        folium.CircleMarker(
            location=[row["latitude"], row["longitude"]],
            radius=3,
            color="blue",
            fill=True,
            fill_opacity=0.8,
            tooltip=f"#{i}",
        ).add_to(m)
# Save map
m.save("synced_data.html")
