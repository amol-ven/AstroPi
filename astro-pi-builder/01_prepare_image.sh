#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run this script with sudo."
  exit 1
fi

# Accept the archive/image path as the first argument from the master orchestrator
ARCHIVE_IMG="$1"

if [ -z "$ARCHIVE_IMG" ]; then
  echo "[-] Error: No base image argument provided to prepare script."
  echo "Usage: $0 <path/to/base-image.img.xz>"
  exit 1
fi

# Derive uncompressed base image name dynamically
# If passed 'path/to/image.img.xz', BASE_IMG becomes 'path/to/image.img' or we can extract basename.
# Let's keep it in the current working directory or respect the path.
BASE_IMG="${ARCHIVE_IMG%.xz}"
OUTPUT_IMG="astro-pi-distributable.img"

# 1. Decompress .img.xz if the uncompressed base image does not exist yet
if [ ! -f "$BASE_IMG" ]; then
    if [ -f "$ARCHIVE_IMG" ]; then
        echo "[+] Found compressed archive '$ARCHIVE_IMG'. Decompressing base image..."
        xz -dk -T0 "$ARCHIVE_IMG"
    else
        echo "[-] Error: Compressed archive '$ARCHIVE_IMG' not found."
        exit 1
    fi
else
    echo "[+] Base image '$BASE_IMG' already exists. Skipping decompression."
fi

# 2. Create a pristine working copy for Step 2 injection
echo "[+] Creating working copy for configuration injection..."
cp "$BASE_IMG" "$OUTPUT_IMG"

echo "[+] Step 1 Complete: Clean raw image prepared (partition expansion will happen natively on first boot)."
