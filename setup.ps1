# Automated Zephyr ESP32 Setup Script for Windows
# This script will set up everything needed to build the chatterbox project

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ESP32 Chatterbox - Automated Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$WORKSPACE_DIR = "F:\RTOS"
$SDK_DIR = "C:\zephyr-sdk-0.17.0"
$ZEPHYR_VERSION = "v4.2-branch"

Write-Host "This script will:" -ForegroundColor Yellow
Write-Host "  1. Install required tools (Python, CMake, Ninja, etc.)" -ForegroundColor Yellow
Write-Host "  2. Create Zephyr workspace (~5GB download)" -ForegroundColor Yellow
Write-Host "  3. Download and install Zephyr SDK (~1.3GB)" -ForegroundColor Yellow
Write-Host "  4. Clone this project" -ForegroundColor Yellow
Write-Host "  5. Build the firmware" -ForegroundColor Yellow
Write-Host ""
Write-Host "Workspace directory: $WORKSPACE_DIR" -ForegroundColor Cyan
Write-Host "SDK directory: $SDK_DIR" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total downloads: ~6-7 GB" -ForegroundColor Yellow
Write-Host "Time required: ~30-45 minutes" -ForegroundColor Yellow
Write-Host ""

$continue = Read-Host "Continue? (Y/N)"
if ($continue -ne "Y" -and $continue -ne "y") {
    Write-Host "Setup cancelled." -ForegroundColor Red
    exit
}

# Function to check if command exists
function Test-CommandExists {
    param($command)
    $null = Get-Command $command -ErrorAction SilentlyContinue
    return $?
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 1: Installing Prerequisites" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Check and install Python
Write-Host "Checking Python..." -ForegroundColor Cyan
if (-not (Test-CommandExists python)) {
    Write-Host "Installing Python 3.13..." -ForegroundColor Yellow
    winget install --id Python.Python.3.13 --silent --accept-source-agreements --accept-package-agreements
    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "✓ Python already installed" -ForegroundColor Green
}

# Check and install CMake
Write-Host "Checking CMake..." -ForegroundColor Cyan
if (-not (Test-CommandExists cmake)) {
    Write-Host "Installing CMake..." -ForegroundColor Yellow
    winget install --id Kitware.CMake --silent --accept-source-agreements --accept-package-agreements
    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "✓ CMake already installed" -ForegroundColor Green
}

# Check and install Git
Write-Host "Checking Git..." -ForegroundColor Cyan
if (-not (Test-CommandExists git)) {
    Write-Host "Installing Git..." -ForegroundColor Yellow
    winget install --id Git.Git --silent --accept-source-agreements --accept-package-agreements
    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "✓ Git already installed" -ForegroundColor Green
}

# Check and install 7-Zip
Write-Host "Checking 7-Zip..." -ForegroundColor Cyan
if (-not (Test-Path "C:\Program Files\7-Zip\7z.exe")) {
    Write-Host "Installing 7-Zip..." -ForegroundColor Yellow
    winget install --id 7zip.7zip --silent --accept-source-agreements --accept-package-agreements
} else {
    Write-Host "✓ 7-Zip already installed" -ForegroundColor Green
}

# Install Ninja
Write-Host "Checking Ninja..." -ForegroundColor Cyan
$ninjaDir = "$WORKSPACE_DIR\tools\ninja"
if (-not (Test-Path "$ninjaDir\ninja.exe")) {
    Write-Host "Installing Ninja..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $ninjaDir | Out-Null
    Invoke-WebRequest -Uri "https://github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-win.zip" -OutFile "$env:TEMP\ninja.zip"
    Expand-Archive -Path "$env:TEMP\ninja.zip" -DestinationPath $ninjaDir -Force
    Remove-Item "$env:TEMP\ninja.zip"
    Write-Host "✓ Ninja installed to $ninjaDir" -ForegroundColor Green
} else {
    Write-Host "✓ Ninja already installed" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 2: Creating Zephyr Workspace" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Create workspace directory
if (-not (Test-Path $WORKSPACE_DIR)) {
    New-Item -ItemType Directory -Force -Path $WORKSPACE_DIR | Out-Null
    Write-Host "✓ Created workspace directory: $WORKSPACE_DIR" -ForegroundColor Green
}

Set-Location $WORKSPACE_DIR

# Create virtual environment
if (-not (Test-Path "$WORKSPACE_DIR\venv")) {
    Write-Host "Creating Python virtual environment..." -ForegroundColor Cyan
    python -m venv venv
    Write-Host "✓ Virtual environment created" -ForegroundColor Green
} else {
    Write-Host "✓ Virtual environment already exists" -ForegroundColor Green
}

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Cyan
& "$WORKSPACE_DIR\venv\Scripts\Activate.ps1"

# Install West
Write-Host "Installing West meta-tool..." -ForegroundColor Cyan
pip install --quiet --upgrade pip
pip install --quiet west
Write-Host "✓ West installed" -ForegroundColor Green

# Initialize Zephyr workspace
if (-not (Test-Path "$WORKSPACE_DIR\zephyr")) {
    Write-Host "Initializing Zephyr workspace (this downloads ~4GB, may take 5-10 minutes)..." -ForegroundColor Yellow
    west init -m https://github.com/zephyrproject-rtos/zephyr --mr $ZEPHYR_VERSION
    Write-Host "✓ Zephyr workspace initialized" -ForegroundColor Green
} else {
    Write-Host "✓ Zephyr workspace already initialized" -ForegroundColor Green
}

# Update Zephyr modules
Write-Host "Updating Zephyr modules (downloading dependencies, may take 10-15 minutes)..." -ForegroundColor Yellow
west update
Write-Host "✓ Zephyr modules updated" -ForegroundColor Green

# Install Python dependencies
Write-Host "Installing Python dependencies..." -ForegroundColor Cyan
pip install --quiet -r zephyr\scripts\requirements.txt
Write-Host "✓ Python dependencies installed" -ForegroundColor Green

# Fetch ESP32 blobs
Write-Host "Fetching ESP32 binary blobs..." -ForegroundColor Cyan
west blobs fetch hal_espressif
Write-Host "✓ ESP32 blobs fetched" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 3: Installing Zephyr SDK" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

if (-not (Test-Path $SDK_DIR)) {
    $sdkArchive = "$WORKSPACE_DIR\zephyr-sdk.7z"
    
    if (-not (Test-Path $sdkArchive)) {
        Write-Host "Downloading Zephyr SDK (~1.3GB, may take 5-10 minutes)..." -ForegroundColor Yellow
        Start-BitsTransfer -Source "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.0/zephyr-sdk-0.17.0_windows-x86_64.7z" -Destination $sdkArchive
        Write-Host "✓ SDK downloaded" -ForegroundColor Green
    }
    
    Write-Host "Extracting SDK (this may take 2-3 minutes)..." -ForegroundColor Yellow
    & 'C:\Program Files\7-Zip\7z.exe' x $sdkArchive -o"C:\" -y | Out-Null
    Write-Host "✓ SDK extracted to $SDK_DIR" -ForegroundColor Green
    
    Write-Host "Running SDK setup..." -ForegroundColor Cyan
    $env:PATH += ";C:\Program Files\7-Zip"
    & "$SDK_DIR\setup.cmd"
    Write-Host "✓ SDK setup complete" -ForegroundColor Green
    
    # Clean up archive
    Remove-Item $sdkArchive
} else {
    Write-Host "✓ Zephyr SDK already installed at $SDK_DIR" -ForegroundColor Green
}

# Set environment variables permanently
[Environment]::SetEnvironmentVariable("ZEPHYR_SDK_INSTALL_DIR", $SDK_DIR, "User")
[Environment]::SetEnvironmentVariable("ZEPHYR_BASE", "$WORKSPACE_DIR\zephyr", "User")
Write-Host "✓ Environment variables set" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 4: Cloning Chatterbox Project" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

$appsDir = "$WORKSPACE_DIR\apps"
if (-not (Test-Path $appsDir)) {
    New-Item -ItemType Directory -Force -Path $appsDir | Out-Null
}

Set-Location $appsDir

if (-not (Test-Path "$appsDir\chatterbox")) {
    Write-Host "Cloning chatterbox project..." -ForegroundColor Cyan
    git clone https://github.com/MarawanEldeib/esp32-chatterbox-rtos.git chatterbox
    Write-Host "✓ Project cloned" -ForegroundColor Green
} else {
    Write-Host "✓ Project already cloned" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 5: Building Firmware" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Set-Location $WORKSPACE_DIR

# Set up environment for build
$env:ZEPHYR_SDK_INSTALL_DIR = $SDK_DIR
$env:ZEPHYR_BASE = "$WORKSPACE_DIR\zephyr"
$env:PATH += ";C:\Program Files\CMake\bin;$ninjaDir;C:\Program Files\7-Zip"

Write-Host "Building chatterbox application (first build may take 5-10 minutes)..." -ForegroundColor Yellow
west build -p always -b esp32_devkitc/esp32/procpu --sysbuild apps/chatterbox

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✓ SUCCESS! Setup Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Firmware built successfully!" -ForegroundColor Green
    Write-Host "Build output: $WORKSPACE_DIR\build\" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Connect your ESP32 DevKitC via USB" -ForegroundColor White
    Write-Host "  2. Run: west flash" -ForegroundColor White
    Write-Host "  3. Connect LEDs to GPIO 16 (Red), 17 (Green), 18 (Blue)" -ForegroundColor White
    Write-Host ""
    Write-Host "To build again in the future:" -ForegroundColor Yellow
    Write-Host "  cd $WORKSPACE_DIR" -ForegroundColor White
    Write-Host "  .\venv\Scripts\Activate.ps1" -ForegroundColor White
    Write-Host "  west build -p always -b esp32_devkitc/esp32/procpu --sysbuild apps/chatterbox" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "✗ Build Failed" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Please check the error messages above." -ForegroundColor Red
    Write-Host "You can try building manually with:" -ForegroundColor Yellow
    Write-Host "  cd $WORKSPACE_DIR" -ForegroundColor White
    Write-Host "  .\venv\Scripts\Activate.ps1" -ForegroundColor White
    Write-Host "  west build -b esp32_devkitc/esp32/procpu --sysbuild apps/chatterbox" -ForegroundColor White
}
