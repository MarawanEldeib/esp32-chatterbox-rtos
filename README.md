# Chatterbox Application - ESP32 RTOS Assignment

## Overview
This is a Zephyr RTOS application for ESP32 DevKitC that demonstrates multi-threaded task scheduling with LED indicators.

## Hardware Requirements
- ESP32 DevKitC board
- 3 LEDs (Red, Green, Blue)
- Appropriate current-limiting resistors (220Ω - 330Ω)
- Breadboard and jumper wires

## Pin Configuration
- GPIO 16 → Red LED (Task 1)
- GPIO 17 → Green LED (Task 2)
- GPIO 18 → Blue LED (Task 3)

## Task Configuration
- **Task 1**: Priority 1, Period 3000ms, Execution 1000ms, Release 1000ms
- **Task 2**: Priority 2, Period 4000ms, Execution 2000ms, Release 0ms
- **Task 3**: Priority 3, Period 6000ms, Execution 1000ms, Release 0ms

---

## 🚀 Quick Start (Automated Setup)

### ⚠️ Important
This repository contains **ONLY the application code**. You need the complete Zephyr RTOS development environment (~8GB download).

### Run ONE Command:

#### Windows:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MarawanEldeib/esp32-chatterbox-rtos/master/setup.ps1" -OutFile "setup.ps1"; .\setup.ps1
```

#### macOS/Linux:
```bash
curl -O https://raw.githubusercontent.com/MarawanEldeib/esp32-chatterbox-rtos/master/setup.sh && chmod +x setup.sh && ./setup.sh
```

**The script automatically:**
- ✅ Installs all tools (Python, CMake, Ninja, Git, etc.)
- ✅ Downloads Zephyr RTOS (~4GB)
- ✅ Downloads Zephyr SDK (~1.3GB)
- ✅ Clones this project
- ✅ Builds the firmware

**Time:** ~30-45 minutes | **Space:** ~8GB

---

## 📚 Advanced Setup

For manual installation or troubleshooting, see:
- [Windows Setup Guide](SETUP_WINDOWS.md)
- [macOS/Linux Setup Guide](SETUP_MACOS_LINUX.md)

---

## Building After Setup

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
