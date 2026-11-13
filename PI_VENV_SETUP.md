# Setting up the Python venv on the Pi

Run these commands on the Pi to install everything `fc_version_3-0` needs.

The Pi 5 uses `rpi-lgpio` instead of `RPi.GPIO`, because `RPi.GPIO` doesn't work on the Pi 5. `rpi-lgpio` is a drop-in replacement that uses `lgpio` underneath, so the code doesn't need changing. The two can't be installed in the same environment.

## Install

```bash
sudo apt update
sudo apt install -y python3-venv python3-pip
cd ~/Drone_Integration_Program
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install pymavlink rpi-lgpio
sudo usermod -aG dialout $USER
getent group gpio && sudo usermod -aG gpio $USER
```

Log out and back in afterwards so the group changes take effect.

## Run

```bash
source ~/Drone_Integration_Program/.venv/bin/activate
cd ~/Drone_Integration_Program/fc_version_3-0
python main.py
```

Don't use `sudo python3 main.py`. It runs outside the venv, so the packages won't be found.
