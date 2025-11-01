# Chatterbox Application - ESP32 RTOS Assignment

## Overview
This is a Zephyr RTOS application for ESP32 DevKitC that demonstrates multi-threaded task scheduling with LED indicators.

## Hardware Requirements
- ESP32 DevKitC board
- 3 LEDs (Red, Green, Blue)
- Appropriate current-limiting resistors
- Breadboard and jumper wires

## Pin Configuration
- GPIO 16 → Red LED (Task 1)
- GPIO 17 → Green LED (Task 2)
- GPIO 18 → Blue LED (Task 3)

## Task Configuration
- **Task 1**: Priority 1, Period 3000ms, Execution 1000ms, Release 1000ms
- **Task 2**: Priority 2, Period 4000ms, Execution 2000ms, Release 0ms
- **Task 3**: Priority 3, Period 6000ms, Execution 1000ms, Release 0ms

## Building

### Prerequisites
- Zephyr SDK 0.17.0 or later
- West tool
- CMake 3.20.0 or later
- Ninja build system

### Build Commands
```bash
# Set up environment
export ZEPHYR_BASE=/path/to/zephyr
export ZEPHYR_SDK_INSTALL_DIR=/path/to/zephyr-sdk

# Build
west build -p always -b esp32_devkitc/esp32/procpu --sysbuild .

# Flash
west flash
```

## Expected Behavior
- Red LED blinks every 3 seconds (1 second ON)
- Green LED blinks every 4 seconds (2 seconds ON)
- Blue LED blinks every 6 seconds (1 second ON)

## Project Structure
```
chatterbox/
├── CMakeLists.txt              # CMake build configuration
├── prj.conf                    # Kconfig project configuration
├── Kconfig                     # Kconfig menu definitions
├── boards/
│   └── esp32_devkitc_esp32_procpu.overlay  # Device tree overlay
└── src/
    ├── main.c                  # Main application entry
    ├── tasks.c                 # Task implementations
    └── tasks.h                 # Task header file
```

## License
Apache-2.0

## Course Information
**Assignment 1**: ESP32 Setup and Chatterbox App  
**Course**: Real-time Concepts for Embedded Systems  
**Date**: November 2025
