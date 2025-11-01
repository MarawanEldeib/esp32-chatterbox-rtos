# Windows Setup Guide - Step by Step

## Time Required
- Total: ~30-45 minutes
- Downloads: ~5GB (Zephyr + SDK)

## Step 1: Install Basic Tools (5 minutes)

### Install Chocolatey (Package Manager) - Optional but Recommended
```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### Install Prerequisites
```powershell
# Using winget (comes with Windows 11)
winget install Python.Python.3.13
winget install Kitware.CMake
winget install Git.Git
winget install 7zip.7zip

# Restart your terminal after installation
```

### Install Ninja Build System
```powershell
# Download Ninja
Invoke-WebRequest -Uri "https://github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-win.zip" -OutFile "$env:TEMP\ninja.zip"

# Extract to a permanent location
Expand-Archive -Path "$env:TEMP\ninja.zip" -DestinationPath "C:\ninja" -Force

# Add to PATH (System-wide - requires admin)
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\ninja", "Machine")

# OR Add to PATH (User only - no admin required)
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\ninja", "User")

# Verify
ninja --version
```

## Step 2: Create Zephyr Workspace (10-15 minutes)

```powershell
# Create workspace directory (adjust path as needed)
mkdir F:\RTOS
cd F:\RTOS

# Create Python virtual environment
python -m venv venv

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# If you get execution policy error, run:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install West meta-tool
pip install west

# Initialize Zephyr (this downloads ~4GB - takes 5-10 minutes)
west init -m https://github.com/zephyrproject-rtos/zephyr --mr v4.2-branch

# Update all modules (downloads additional modules)
west update

# Install Python dependencies
pip install -r zephyr\scripts\requirements.txt

# Fetch ESP32 binary blobs (WiFi, Bluetooth, etc.)
west blobs fetch hal_espressif
```

## Step 3: Install Zephyr SDK (10-15 minutes)

```powershell
# Still in F:\RTOS directory
cd F:\RTOS

# Download SDK (~1.3GB - takes 5-10 minutes depending on internet)
# Using BITS for reliable download with resume capability
Start-BitsTransfer -Source "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.0/zephyr-sdk-0.17.0_windows-x86_64.7z" -Destination "zephyr-sdk.7z"

# Extract SDK to C:\ (requires ~3GB space, takes 2-3 minutes)
& 'C:\Program Files\7-Zip\7z.exe' x zephyr-sdk.7z -o"C:\"

# Run SDK setup
cd C:\zephyr-sdk-0.17.0
.\setup.cmd

# Set environment variable (User level)
[Environment]::SetEnvironmentVariable("ZEPHYR_SDK_INSTALL_DIR", "C:\zephyr-sdk-0.17.0", "User")
```

## Step 4: Clone This Project (1 minute)

```powershell
cd F:\RTOS
mkdir apps
cd apps
git clone https://github.com/MarawanEldeib/esp32-chatterbox-rtos.git chatterbox
```

## Step 5: Build the Project (2-5 minutes)

```powershell
# Go to workspace root
cd F:\RTOS

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Set environment variables for current session
$env:ZEPHYR_SDK_INSTALL_DIR = "C:\zephyr-sdk-0.17.0"
$env:ZEPHYR_BASE = "F:\RTOS\zephyr"

# Build (first build takes 2-5 minutes)
west build -p always -b esp32_devkitc/esp32/procpu --sysbuild apps/chatterbox

# Should see: "west build: building application" and "[205/205] Linking C executable"
```

## Step 6: Flash to ESP32 (1 minute)

```powershell
# Connect ESP32 DevKitC via USB
# Windows should install CP210x USB-to-UART driver automatically

# Flash the firmware
west flash

# If flash fails with port error, specify port manually:
west flash --esp-device COM3  # Replace COM3 with your port

# To find your COM port:
# Device Manager → Ports (COM & LPT) → Look for "Silicon Labs CP210x" or "USB Serial Port"
```

## Step 7: Monitor Serial Output (Optional)

```powershell
# Monitor serial output
west espressif monitor

# OR use any serial monitor tool at 115200 baud
```

## Common Issues & Solutions

### Issue: "west: command not found"
**Solution:** Activate virtual environment first: `.\venv\Scripts\Activate.ps1`

### Issue: "Cannot run script - execution policy"
**Solution:** Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Issue: "CMake not found"
**Solution:** Restart terminal or add to PATH manually

### Issue: "Permission denied during installation"
**Solution:** 
- Use user-level installations instead of system-level
- OR Run PowerShell as Administrator
- OR Install to user directories (e.g., `C:\Users\YourName\tools\`)

### Issue: "west update very slow"
**Solution:** This is normal. It downloads 50+ Git repositories (~4GB total). Use stable internet connection.

### Issue: "Flash fails - serial port not found"
**Solution:** 
- Install CP210x driver: https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers
- Check Device Manager for COM port number
- Try different USB cable (some are charge-only)

## Quick Reference - Environment Setup for Future Sessions

Create a file `setup_env.ps1` in `F:\RTOS\`:

```powershell
# setup_env.ps1
.\venv\Scripts\Activate.ps1
$env:ZEPHYR_SDK_INSTALL_DIR = "C:\zephyr-sdk-0.17.0"
$env:ZEPHYR_BASE = "F:\RTOS\zephyr"
$env:PATH += ";C:\Program Files\CMake\bin;C:\ninja"
Write-Host "✅ Zephyr environment ready!" -ForegroundColor Green
```

Then just run: `.\setup_env.ps1` before building.

## Disk Space Requirements
- Zephyr source + modules: ~4-5 GB
- Zephyr SDK: ~3 GB
- Build artifacts: ~500 MB
- **Total: ~8 GB**

## Need Help?
- Zephyr Documentation: https://docs.zephyrproject.org/latest/
- Zephyr Discord: https://chat.zephyrproject.org/
- GitHub Issues: https://github.com/MarawanEldeib/esp32-chatterbox-rtos/issues
