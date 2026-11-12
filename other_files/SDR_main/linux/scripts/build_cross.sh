#!/usr/bin/env bash
# Cross-compile for Raspberry Pi OS 64-bit (aarch64).
# Prerequisites in WSL/Debian:
#   sudo dpkg --add-architecture arm64
#   sudo sed -i -E 's|^deb (http.*)|deb [arch=amd64] \1|' /etc/apt/sources.list
#   echo 'deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ jammy main universe' | sudo tee /etc/apt/sources.list.d/arm64.list
#   sudo apt-get update
#   sudo apt-get install -y g++-aarch64-linux-gnu pkg-config libusb-1.0-0-dev:arm64
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD_DIR=${BUILD_DIR:-build-arm64}
cmake -B "$BUILD_DIR" -S . \
      -DCMAKE_TOOLCHAIN_FILE=toolchains/aarch64-linux-gnu.cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DPUPRADAR_BUILD_TESTS=OFF
cmake --build "$BUILD_DIR" -j"$(nproc)"
echo "[build_cross] OK — binary at $BUILD_DIR/pupradar_capture"
file "$BUILD_DIR/pupradar_capture"
