# macOS/Linux Setup Guide - Step by Step

## Time Required
- Total: ~30-45 minutes
- Downloads: ~5GB (Zephyr + SDK)

## Prerequisites Check

Run these commands to check what's already installed:
```bash
python3 --version  # Need 3.10+
cmake --version    # Need 3.20+
git --version
```

## Step 1: Install Basic Tools (5 minutes)

### For macOS (using Homebrew)

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install prerequisites
brew install cmake ninja python3 dtc wget

# Verify installations
cmake --version
ninja --version
python3 --version
```

### For Ubuntu/Debian Linux

```bash
# Update package list
sudo apt update

# Install all prerequisites
sudo apt install --no-install-recommends git cmake ninja-build gperf \
  ccache dfu-util device-tree-compiler wget \
  python3-dev python3-pip python3-setuptools python3-tk python3-wheel \
  xz-utils file make gcc gcc-multilib g++-multilib libsdl2-dev libmagic1

# Verify installations
cmake --version
ninja --version
python3 --version
```

### For Fedora/RHEL Linux

```bash
# Update packages
sudo dnf update

# Install prerequisites
sudo dnf install git cmake ninja-build gperf ccache dfu-util dtc wget \
  python3-pip python3-tkinter xz file make gcc gcc-c++ SDL2-devel

# Verify installations
cmake --version
ninja --version
python3 --version
```

## Step 2: Create Zephyr Workspace (10-15 minutes)

```bash
# Create workspace directory
mkdir ~/zephyrproject
cd ~/zephyrproject

# Create Python virtual environment
python3 -m venv .venv

# Activate virtual environment
source .venv/bin/activate

# Install West meta-tool
pip install west

# Initialize Zephyr (downloads ~4GB - takes 5-10 minutes)
west init -m https://github.com/zephyrproject-rtos/zephyr --mr v4.2-branch

# Update all modules (downloads additional modules)
west update

# Install Python dependencies
pip install -r zephyr/scripts/requirements.txt

# Fetch ESP32 binary blobs
west blobs fetch hal_espressif
```

## Step 3: Install Zephyr SDK (10-15 minutes)

### For macOS (x86_64)

```bash
cd ~/zephyrproject

# Download SDK (~1.2GB)
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.0/zephyr-sdk-0.17.0_macos-x86_64.tar.xz

# Extract
tar -xvf zephyr-sdk-0.17.0_macos-x86_64.tar.xz

# Run setup
cd zephyr-sdk-0.17.0
./setup.sh

# Add to shell profile (bash)
echo 'export ZEPHYR_SDK_INSTALL_DIR=~/zephyrproject/zephyr-sdk-0.17.0' >> ~/.bashrc
echo 'export ZEPHYR_BASE=~/zephyrproject/zephyr' >> ~/.bashrc

# OR for zsh (macOS default)
echo 'export ZEPHYR_SDK_INSTALL_DIR=~/zephyrproject/zephyr-sdk-0.17.0' >> ~/.zshrc
echo 'export ZEPHYR_BASE=~/zephyrproject/zephyr' >> ~/.zshrc

# Reload shell
source ~/.zshrc  # or source ~/.bashrc
```

### For macOS (Apple Silicon M1/M2)

```bash
cd ~/zephyrproject

# Download SDK for ARM64
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.0/zephyr-sdk-0.17.0_macos-aarch64.tar.xz

# Extract
tar -xvf zephyr-sdk-0.17.0_macos-aarch64.tar.xz

# Run setup
cd zephyr-sdk-0.17.0
./setup.sh

# Add to shell profile (zsh is default on Apple Silicon Macs)
echo 'export ZEPHYR_SDK_INSTALL_DIR=~/zephyrproject/zephyr-sdk-0.17.0' >> ~/.zshrc
echo 'export ZEPHYR_BASE=~/zephyrproject/zephyr' >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

### For Linux (x86_64)

```bash
cd ~/zephyrproject

# Download SDK (~1.3GB)
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.0/zephyr-sdk-0.17.0_linux-x86_64.tar.xz

# Extract
tar -xvf zephyr-sdk-0.17.0_linux-x86_64.tar.xz

# Run setup
cd zephyr-sdk-0.17.0
./setup.sh

# Add to shell profile
echo 'export ZEPHYR_SDK_INSTALL_DIR=~/zephyrproject/zephyr-sdk-0.17.0' >> ~/.bashrc
echo 'export ZEPHYR_BASE=~/zephyrproject/zephyr' >> ~/.bashrc

# Reload shell
source ~/.bashrc
```

## Step 4: Clone This Project (1 minute)

```bash
cd ~/zephyrproject
mkdir -p apps
cd apps
git clone https://github.com/MarawanEldeib/esp32-chatterbox-rtos.git chatterbox
```

## Step 5: Build the Project (2-5 minutes)

```bash
# Go to workspace root
cd ~/zephyrproject

# Activate virtual environment
source .venv/bin/activate

# Verify environment
echo $ZEPHYR_SDK_INSTALL_DIR
echo $ZEPHYR_BASE

# Build (first build takes 2-5 minutes)
west build -p always -b esp32_devkitc/esp32/procpu --sysbuild apps/chatterbox

# Should see: "west build: building application" and "[205/205] Linking C executable"
```

## Step 6: Flash to ESP32 (1 minute)

```bash
# Connect ESP32 DevKitC via USB

# Flash the firmware
west flash

# If flash fails, specify port manually:
# macOS:
west flash --esp-device /dev/cu.usbserial-*

# Linux:
west flash --esp-device /dev/ttyUSB0

# To find your port:
# macOS:
ls /dev/cu.*

# Linux:
ls /dev/ttyUSB* /dev/ttyACM*
```

## Step 7: Monitor Serial Output (Optional)

```bash
# Monitor using west
west espressif monitor

# OR use screen (macOS/Linux built-in)
# macOS:
screen /dev/cu.usbserial-* 115200

# Linux:
screen /dev/ttyUSB0 115200

# Exit screen: Ctrl+A, then K, then Y
```

## Common Issues & Solutions

### Issue: "west: command not found"

**Solution:** Activate virtual environment first: `source .venv/bin/activate`

### Issue: "Permission denied" on serial port (Linux)

**Solution:** Add your user to dialout group:
```bash
sudo usermod -a -G dialout $USER
# Log out and log back in for changes to take effect
```

### Issue: "CMake not found" or "Ninja not found"

**Solution:** Ensure tools are in PATH. Check with:
```bash
which cmake
which ninja
```

### Issue: "west update very slow"

**Solution:** This is normal. It downloads 50+ Git repositories (~4GB total). Use stable internet connection. You can speed up with:
```bash
west update --narrow  # Shallow clones
```

### Issue: "No module named 'serial'" during flash

**Solution:** Install pyserial:
```bash
pip install pyserial
```

### Issue: Flash fails - "Could not open port"

**Solution:**
- **macOS:** Install CP210x driver from https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers
- **Linux:** Add user to dialout group (see above)
- Try different USB cable
- Check device is detected: `ls /dev/tty*` or `ls /dev/cu.*`

### Issue: "xcrun: error" on macOS

**Solution:** Install Xcode Command Line Tools:
```bash
xcode-select --install
```

## Quick Reference - Environment Setup Script

Create a file `setup_env.sh` in `~/zephyrproject/`:

```bash
#!/bin/bash
# setup_env.sh

source .venv/bin/activate
export ZEPHYR_SDK_INSTALL_DIR=~/zephyrproject/zephyr-sdk-0.17.0
export ZEPHYR_BASE=~/zephyrproject/zephyr
echo "✅ Zephyr environment ready!"
```

Make it executable and use it:
```bash
chmod +x setup_env.sh
source ./setup_env.sh
```

## Disk Space Requirements

- Zephyr source + modules: ~4-5 GB
- Zephyr SDK: ~3 GB
- Build artifacts: ~500 MB
- **Total: ~8 GB**

## USB Permissions (Linux Only)

Create udev rules for ESP32 without needing sudo:

```bash
# Create udev rules file
sudo nano /etc/udev/rules.d/99-esp32.rules

# Add this line:
SUBSYSTEMS=="usb", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE:="0666"

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Unplug and replug ESP32
```

## Performance Tips

### Speed up builds with ccache

```bash
# Install ccache (if not already installed)
# macOS:
brew install ccache

# Linux:
sudo apt install ccache  # Ubuntu/Debian
sudo dnf install ccache  # Fedora

# Enable in Zephyr
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export USE_CCACHE=1
```

### Parallel builds

```bash
# Use all CPU cores for faster builds
west build -- -j$(nproc)  # Linux
west build -- -j$(sysctl -n hw.ncpu)  # macOS
```

## Need Help?

- Zephyr Documentation: https://docs.zephyrproject.org/latest/
- Zephyr Discord: https://chat.zephyrproject.org/
- GitHub Issues: https://github.com/MarawanEldeib/esp32-chatterbox-rtos/issues

## Troubleshooting Checklist

Before asking for help, verify:
- [ ] Virtual environment is activated (`(.venv)` in prompt)
- [ ] ZEPHYR_SDK_INSTALL_DIR is set: `echo $ZEPHYR_SDK_INSTALL_DIR`
- [ ] ZEPHYR_BASE is set: `echo $ZEPHYR_BASE`
- [ ] West is installed: `west --version`
- [ ] ESP32 is connected: `ls /dev/tty* | grep -i usb`
- [ ] Build completed successfully (no errors in build output)
