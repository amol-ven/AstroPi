#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run this master orchestrator with sudo: sudo ./build_astro_image.sh <base_image.img.xz>"
  exit 1
fi

# Require the base image as the first argument
BASE_IMAGE="$1"

if [ -z "$BASE_IMAGE" ]; then
  echo "[-] Error: No base image specified."
  echo "Usage: sudo $0 </path/to/raspios-image.img.xz>"
  exit 1
fi

echo "=================================================="
echo " Starting AstroPi Modular Build Orchestrator"
echo " Target Base Image: $BASE_IMAGE"
echo "=================================================="

# 1. Verify all required files exist in the workspace
REQUIRED_FILES=(
  "01_prepare_image.sh"
  "02_provision_image.sh"
  "03_compress_image.sh"
  "astropi-setup.sh"
  "$BASE_IMAGE"
  "firecapture_2.7.15_aarch64.deb"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "[-] Error: Required file '$file' is missing from the current directory."
    exit 1
  fi
done

# Ensure all scripts are executable
chmod +x 01_prepare_image.sh 02_provision_image.sh 03_compress_image.sh astropi-setup.sh

# Export BASE_IMAGE so downstream scripts can read it
export BASE_IMAGE

# 2. Execute Step 1: Base Image Preparation
echo ""
echo "--------------------------------------------------"
echo " STEP 1/3: Extracting and Preparing Base Image"
echo "--------------------------------------------------"
./01_prepare_image.sh "$BASE_IMAGE"

# 3. Execute Step 2: Provisioning & File Injection
echo ""
echo "--------------------------------------------------"
echo " STEP 2/3: Injecting Credentials & Desktop Launcher"
echo "--------------------------------------------------"
./02_provision_image.sh

# 4. Execute Step 3: Final Compression & Checksum
echo ""
echo "--------------------------------------------------"
echo " STEP 3/3: Compressing Final Image & Generating Checksum"
echo "--------------------------------------------------"
./03_compress_image.sh

echo ""
echo "=================================================="
echo " Build Complete Successfully!"
echo " Output Archive: astro-pi-distributable.img(.xz)"
echo "=================================================="
