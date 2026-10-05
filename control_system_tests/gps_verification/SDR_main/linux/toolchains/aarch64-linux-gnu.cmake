# Cross-compile toolchain for Raspberry Pi OS 64-bit (aarch64).
# Usage: cmake -B build-arm64 -DCMAKE_TOOLCHAIN_FILE=toolchains/aarch64-linux-gnu.cmake -S .
#
# Prerequisites on Debian/Ubuntu/WSL:
#   sudo apt-get install -y g++-aarch64-linux-gnu pkg-config
#   sudo dpkg --add-architecture arm64
#   sudo apt-get update
#   sudo apt-get install -y libusb-1.0-0-dev:arm64

set(CMAKE_SYSTEM_NAME      Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER   aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

# Search for libraries and headers in the cross-arch sysroot first; then host.
set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu /usr/lib/aarch64-linux-gnu)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)

# Tell pkg-config where the arm64 .pc files live (Debian multiarch).
set(ENV{PKG_CONFIG_LIBDIR}        /usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig)
set(ENV{PKG_CONFIG_SYSROOT_DIR}  "")
