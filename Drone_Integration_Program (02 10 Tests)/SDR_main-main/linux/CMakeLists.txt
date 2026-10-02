cmake_minimum_required(VERSION 3.16)
project(pupradar_capture LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)
endif()

option(PUPRADAR_BUILD_TESTS "Build unit tests (requires native build)" ON)
option(PUPRADAR_USE_LIBUSB  "Link the real libusb-1.0 backend (off for test-only builds)" ON)

add_compile_options(
    -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wsign-conversion
    -Wnon-virtual-dtor -Wold-style-cast -Wcast-align -Woverloaded-virtual
    -Wformat=2
)

# -------------------------------------------------------------------- libpupradar
set(PUPRADAR_CORE_SOURCES
    src/IntelHex.cpp
    src/Protocol.cpp
    src/RadarSession.cpp
    src/IqWriter.cpp
)

add_library(pupradar_core STATIC ${PUPRADAR_CORE_SOURCES})
target_include_directories(pupradar_core PUBLIC include third_party)

# -------------------------------------------------------------------- libusb backend
if(PUPRADAR_USE_LIBUSB)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(LIBUSB REQUIRED IMPORTED_TARGET libusb-1.0)
    add_library(pupradar_usb STATIC src/UsbDevice.cpp)
    target_include_directories(pupradar_usb PUBLIC include)
    target_link_libraries(pupradar_usb PUBLIC PkgConfig::LIBUSB pupradar_core)
endif()

# -------------------------------------------------------------------- executables
if(PUPRADAR_USE_LIBUSB)
    add_executable(pupradar_capture src/main.cpp)
    target_link_libraries(pupradar_capture PRIVATE pupradar_usb pupradar_core)

    add_executable(pupradar_board_info src/board_info.cpp)
    target_link_libraries(pupradar_board_info PRIVATE pupradar_usb pupradar_core)
endif()

# -------------------------------------------------------------------- tests
if(PUPRADAR_BUILD_TESTS)
    enable_testing()
    add_executable(pupradar_tests
        tests/test_main.cpp
        tests/test_intel_hex.cpp
        tests/test_protocol.cpp
        tests/test_radar_session.cpp
        tests/test_iq_writer.cpp
    )
    target_include_directories(pupradar_tests PRIVATE tests)
    target_link_libraries(pupradar_tests PRIVATE pupradar_core)
    add_test(NAME pupradar_tests COMMAND pupradar_tests)
endif()
