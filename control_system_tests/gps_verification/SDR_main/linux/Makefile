# Makefile for pupradar — thin CMake wrapper.
# Run from the linux/ directory (where CMakeLists.txt lives).
#
# Targets
#   make / make cross           Cross-compile for Raspberry Pi OS 64-bit (aarch64)
#   make native                 Native build on the current host (x86-64 or Pi)
#   make tests                  Native Debug build + run unit tests
#   make deploy PI=user@host    Deploy binaries + firmware + udev rule to the Pi
#   make clean                  Remove all build directories

# ── Configuration ──────────────────────────────────────────────────────────────
BUILD_CROSS  := build-arm64
BUILD_NATIVE := build-native
BUILD_TESTS  := build-tests
TOOLCHAIN    := toolchains/aarch64-linux-gnu.cmake
NPROC        := $(shell nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 4)

# deploy target defaults — override on the command line:
#   make deploy PI=pi@192.168.1.42 DEST=/home/pi/radar
PI   ?= pi@raspberrypi.local
DEST ?= ~/pupradar

# ── Default target ─────────────────────────────────────────────────────────────
.DEFAULT_GOAL := cross

# ── Cross-compile (aarch64) ────────────────────────────────────────────────────
.PHONY: cross
cross: $(BUILD_CROSS)/.configured
	cmake --build $(BUILD_CROSS) -j$(NPROC)
	@echo ""
	@echo "  cross build done:"
	@file $(BUILD_CROSS)/pupradar_capture
	@file $(BUILD_CROSS)/pupradar_board_info

# Reconfigure only when CMakeLists.txt or the toolchain file changes.
$(BUILD_CROSS)/.configured: CMakeLists.txt $(TOOLCHAIN)
	cmake -B $(BUILD_CROSS) -S . \
	      -DCMAKE_TOOLCHAIN_FILE=$(TOOLCHAIN) \
	      -DCMAKE_BUILD_TYPE=Release \
	      -DPUPRADAR_BUILD_TESTS=OFF
	@touch $@

# ── Native build (x86-64 or Pi itself) ────────────────────────────────────────
.PHONY: native
native: $(BUILD_NATIVE)/.configured
	cmake --build $(BUILD_NATIVE) -j$(NPROC)

$(BUILD_NATIVE)/.configured: CMakeLists.txt
	cmake -B $(BUILD_NATIVE) -S . \
	      -DCMAKE_BUILD_TYPE=Release \
	      -DPUPRADAR_BUILD_TESTS=OFF
	@touch $@

# ── Unit tests (native, Debug) ─────────────────────────────────────────────────
.PHONY: tests
tests: $(BUILD_TESTS)/.configured
	cmake --build $(BUILD_TESTS) -j$(NPROC) --target pupradar_tests
	ctest --test-dir $(BUILD_TESTS) --output-on-failure

$(BUILD_TESTS)/.configured: CMakeLists.txt
	cmake -B $(BUILD_TESTS) -S . \
	      -DCMAKE_BUILD_TYPE=Debug \
	      -DPUPRADAR_BUILD_TESTS=ON \
	      -DPUPRADAR_USE_LIBUSB=OFF
	@touch $@

# ── Deploy to Raspberry Pi ─────────────────────────────────────────────────────
# Usage:
#   make deploy PI=pi@raspberrypi.local
#   make deploy PI=pi@192.168.1.42 DEST=/home/pi/radar
.PHONY: deploy
deploy: cross
	@echo "Deploying to $(PI):$(DEST) …"
	ssh $(PI) "mkdir -p $(DEST)/firmware"
	scp $(BUILD_CROSS)/pupradar_capture    $(PI):$(DEST)/
	scp $(BUILD_CROSS)/pupradar_board_info $(PI):$(DEST)/
	scp firmware/SDR_USB_FW.hex            $(PI):$(DEST)/firmware/
	scp scripts/99-pupradar.rules          $(PI):$(DEST)/
	@echo ""
	@echo "Deploy complete. On the Pi, run once to install the udev rule:"
	@echo "  sudo cp $(DEST)/99-pupradar.rules /etc/udev/rules.d/"
	@echo "  sudo udevadm control --reload-rules && sudo udevadm trigger"
	@echo ""
	@echo "Then test the connection:"
	@echo "  cd $(DEST) && ./pupradar_board_info --firmware firmware/SDR_USB_FW.hex"

# ── Clean ──────────────────────────────────────────────────────────────────────
.PHONY: clean
clean:
	rm -rf $(BUILD_CROSS) $(BUILD_NATIVE) $(BUILD_TESTS)
