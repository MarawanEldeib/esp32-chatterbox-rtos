#!/bin/bash
# Automated Zephyr ESP32 Setup Script for macOS/Linux
# This script will set up everything needed to build the chatterbox project

set -e  # Exit on error

echo "========================================"
echo "  ESP32 Chatterbox - Automated Setup"
echo "========================================"
echo ""

# Configuration
WORKSPACE_DIR=~/zephyrproject
SDK_DIR=$WORKSPACE_DIR/zephyr-sdk-0.17.0
ZEPHYR_VERSION="v4.2-branch"

# Detect OS and architecture
OS=$(uname -s)
ARCH=$(uname -m)

if [ "$OS" = "Darwin" ]; then
    if [ "$ARCH" = "arm64" ]; then
        SDK_URL="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.0/zephyr-sdk-0.17.0_macos-aarch64.tar.xz"
        SDK_FILE="zephyr-sdk-0.17.0_macos-aarch64.tar.xz"
    else
        SDK_URL="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.0/zephyr-sdk-0.17.0_macos-x86_64.tar.xz"
        SDK_FILE="zephyr-sdk-0.17.0_macos-x86_64.tar.xz"
    fi
    PLATFORM="macOS"
elif [ "$OS" = "Linux" ]; then
    SDK_URL="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.0/zephyr-sdk-0.17.0_linux-x86_64.tar.xz"
    SDK_FILE="zephyr-sdk-0.17.0_linux-x86_64.tar.xz"
    PLATFORM="Linux"
else
    echo "Error: Unsupported operating system: $OS"
    exit 1
fi

echo "Platform detected: $PLATFORM ($ARCH)"
echo ""
echo "This script will:"
echo "  1. Install required tools"
echo "  2. Create Zephyr workspace (~5GB download)"
echo "  3. Download and install Zephyr SDK (~1.3GB)"
echo "  4. Clone this project"
echo "  5. Build the firmware"
echo ""
echo "Workspace directory: $WORKSPACE_DIR"
echo "SDK directory: $SDK_DIR"
echo ""
echo "Total downloads: ~6-7 GB"
echo "Time required: ~30-45 minutes"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo "========================================"
echo "Step 1: Installing Prerequisites"
echo "========================================"

if [ "$OS" = "Darwin" ]; then
    # macOS
    echo "Installing Homebrew packages..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install prerequisites
    brew install cmake ninja python3 dtc wget 2>/dev/null || echo "Some packages already installed"
    echo "✓ Prerequisites installed"
    
elif [ "$OS" = "Linux" ]; then
    # Linux
    if command -v apt &> /dev/null; then
        # Debian/Ubuntu
        echo "Installing packages via apt..."
        sudo apt update
        sudo apt install -y --no-install-recommends git cmake ninja-build gperf \
            ccache dfu-util device-tree-compiler wget \
            python3-dev python3-pip python3-setuptools python3-venv \
            xz-utils file make gcc gcc-multilib g++-multilib libsdl2-dev libmagic1
        echo "✓ Prerequisites installed"
        
    elif command -v dnf &> /dev/null; then
        # Fedora/RHEL
        echo "Installing packages via dnf..."
        sudo dnf install -y git cmake ninja-build gperf ccache dfu-util dtc wget \
            python3-pip python3-tkinter xz file make gcc gcc-c++ SDL2-devel
        echo "✓ Prerequisites installed"
        
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        echo "Installing packages via pacman..."
        sudo pacman -S --noconfirm git cmake ninja python python-pip wget xz dtc
        echo "✓ Prerequisites installed"
        
    else
        echo "Warning: Unknown package manager. Please install dependencies manually."
        echo "Required: git, cmake, ninja, python3, pip, wget, xz, dtc"
        read -p "Press Enter to continue if you have these installed..."
    fi
fi

echo ""
echo "========================================"
echo "Step 2: Creating Zephyr Workspace"
echo "========================================"

# Create workspace directory
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# Create virtual environment
if [ ! -d "$WORKSPACE_DIR/.venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv .venv
    echo "✓ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source .venv/bin/activate

# Upgrade pip and install West
echo "Installing West meta-tool..."
pip install --quiet --upgrade pip
pip install --quiet west
echo "✓ West installed"

# Initialize Zephyr workspace
if [ ! -d "$WORKSPACE_DIR/zephyr" ]; then
    echo "Initializing Zephyr workspace (downloading ~4GB, may take 5-10 minutes)..."
    west init -m https://github.com/zephyrproject-rtos/zephyr --mr $ZEPHYR_VERSION
    echo "✓ Zephyr workspace initialized"
else
    echo "✓ Zephyr workspace already initialized"
fi

# Update Zephyr modules
echo "Updating Zephyr modules (downloading dependencies, may take 10-15 minutes)..."
west update
echo "✓ Zephyr modules updated"

# Install Python dependencies
echo "Installing Python dependencies..."
pip install --quiet -r zephyr/scripts/requirements.txt
echo "✓ Python dependencies installed"

# Fetch ESP32 blobs
echo "Fetching ESP32 binary blobs..."
west blobs fetch hal_espressif
echo "✓ ESP32 blobs fetched"

echo ""
echo "========================================"
echo "Step 3: Installing Zephyr SDK"
echo "========================================"

if [ ! -d "$SDK_DIR" ]; then
    SDK_ARCHIVE="$WORKSPACE_DIR/$SDK_FILE"
    
    if [ ! -f "$SDK_ARCHIVE" ]; then
        echo "Downloading Zephyr SDK (~1.2GB, may take 5-10 minutes)..."
        wget -q --show-progress "$SDK_URL" -O "$SDK_ARCHIVE"
        echo "✓ SDK downloaded"
    fi
    
    echo "Extracting SDK (this may take 2-3 minutes)..."
    tar -xf "$SDK_ARCHIVE" -C "$WORKSPACE_DIR"
    echo "✓ SDK extracted to $SDK_DIR"
    
    echo "Running SDK setup..."
    cd "$SDK_DIR"
    ./setup.sh
    echo "✓ SDK setup complete"
    
    cd "$WORKSPACE_DIR"
    
    # Clean up archive
    rm "$SDK_ARCHIVE"
else
    echo "✓ Zephyr SDK already installed at $SDK_DIR"
fi

# Add environment variables to shell profile
SHELL_PROFILE=""
if [ -f ~/.zshrc ]; then
    SHELL_PROFILE=~/.zshrc
elif [ -f ~/.bashrc ]; then
    SHELL_PROFILE=~/.bashrc
fi

if [ -n "$SHELL_PROFILE" ]; then
    if ! grep -q "ZEPHYR_SDK_INSTALL_DIR" "$SHELL_PROFILE"; then
        echo "" >> "$SHELL_PROFILE"
        echo "# Zephyr RTOS environment variables" >> "$SHELL_PROFILE"
        echo "export ZEPHYR_SDK_INSTALL_DIR=$SDK_DIR" >> "$SHELL_PROFILE"
        echo "export ZEPHYR_BASE=$WORKSPACE_DIR/zephyr" >> "$SHELL_PROFILE"
        echo "✓ Environment variables added to $SHELL_PROFILE"
    else
        echo "✓ Environment variables already in $SHELL_PROFILE"
    fi
fi

# Set for current session
export ZEPHYR_SDK_INSTALL_DIR=$SDK_DIR
export ZEPHYR_BASE=$WORKSPACE_DIR/zephyr

echo ""
echo "========================================"
echo "Step 4: Cloning Chatterbox Project"
echo "========================================"

mkdir -p "$WORKSPACE_DIR/apps"
cd "$WORKSPACE_DIR/apps"

if [ ! -d "$WORKSPACE_DIR/apps/chatterbox" ]; then
    echo "Cloning chatterbox project..."
    git clone https://github.com/MarawanEldeib/esp32-chatterbox-rtos.git chatterbox
    echo "✓ Project cloned"
else
    echo "✓ Project already cloned"
fi

echo ""
echo "========================================"
echo "Step 5: Building Firmware"
echo "========================================"

cd "$WORKSPACE_DIR"

echo "Building chatterbox application (first build may take 5-10 minutes)..."
if west build -p always -b esp32_devkitc/esp32/procpu --sysbuild apps/chatterbox; then
    echo ""
    echo "========================================"
    echo "✓ SUCCESS! Setup Complete!"
    echo "========================================"
    echo ""
    echo "Firmware built successfully!"
    echo "Build output: $WORKSPACE_DIR/build/"
    echo ""
    echo "Next steps:"
    echo "  1. Connect your ESP32 DevKitC via USB"
    echo "  2. Run: west flash"
    echo "  3. Connect LEDs to GPIO 16 (Red), 17 (Green), 18 (Blue)"
    echo ""
    echo "To build again in the future:"
    echo "  cd $WORKSPACE_DIR"
    echo "  source .venv/bin/activate"
    echo "  west build -p always -b esp32_devkitc/esp32/procpu --sysbuild apps/chatterbox"
    echo ""
    
    if [ "$OS" = "Linux" ]; then
        echo "Linux users: Add yourself to dialout group for USB access:"
        echo "  sudo usermod -a -G dialout \$USER"
        echo "  (then log out and log back in)"
        echo ""
    fi
else
    echo ""
    echo "========================================"
    echo "✗ Build Failed"
    echo "========================================"
    echo "Please check the error messages above."
    echo "You can try building manually with:"
    echo "  cd $WORKSPACE_DIR"
    echo "  source .venv/bin/activate"
    echo "  west build -b esp32_devkitc/esp32/procpu --sysbuild apps/chatterbox"
    exit 1
fi
