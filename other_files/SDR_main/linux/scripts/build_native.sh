#!/usr/bin/env bash
# Native x86_64 host build (for running tests). Run from linux/ directory.
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD_DIR=${BUILD_DIR:-build-native}
cmake -B "$BUILD_DIR" -S . -DCMAKE_BUILD_TYPE=Debug
cmake --build "$BUILD_DIR" -j"$(nproc)"
ctest --test-dir "$BUILD_DIR" --output-on-failure
echo "[build_native] OK — binary at $BUILD_DIR/pupradar_capture (host arch)"
file "$BUILD_DIR/pupradar_capture" || true
