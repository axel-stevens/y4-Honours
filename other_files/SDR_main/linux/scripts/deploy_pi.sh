#!/usr/bin/env bash
# Deploy a freshly cross-compiled binary + firmware + udev rule to a Pi.
# Usage:   scripts/deploy_pi.sh [user@]<host>[:<dest_dir>]
# Example: scripts/deploy_pi.sh pi@raspberrypi.local:/home/pi/pupradar
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <user@host[:dest]>" >&2
    exit 2
fi

TARGET="$1"
HOST="${TARGET%%:*}"
DEST="${TARGET#*:}"
[[ "$DEST" == "$TARGET" ]] && DEST="~/pupradar"

BIN=build-arm64/pupradar_capture
if [[ ! -x "$BIN" ]]; then
    echo "Cross-compiled binary not found at $BIN. Run scripts/build_cross.sh first." >&2
    exit 1
fi

ssh "$HOST" "mkdir -p $DEST/firmware"
scp "$BIN"                              "$HOST:$DEST/"
scp firmware/SDR_USB_FW.hex             "$HOST:$DEST/firmware/"
scp scripts/99-pupradar.rules           "$HOST:$DEST/"

cat <<EOF

Deployed. On the Pi, install the udev rule once:
    sudo cp $DEST/99-pupradar.rules /etc/udev/rules.d/
    sudo udevadm control --reload-rules && sudo udevadm trigger

Then test:
    cd $DEST
    ./pupradar_capture --download-firmware --duration 5 --out /tmp/cap

If the board does not reappear after the firmware load, find its
post-firmware VID/PID with 'lsusb' and set kPostFirmwareVid /
kPostFirmwarePid in include/pupradar/Protocol.hpp, then rebuild.
EOF
