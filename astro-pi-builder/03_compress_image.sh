#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run this script with sudo."
  exit 1
fi

RAW_IMG="astro-pi-distributable.img"
FINAL_ARCHIVE="astro-pi-distributable.img.xz"

if [ ! -f "$RAW_IMG" ]; then
  echo "[-] Error: $RAW_IMG not found. Run previous build steps first."
  exit 1
fi

rm -f "$FINAL_ARCHIVE" "${FINAL_ARCHIVE}.sha256"

echo "[+] Compressing finalized image to $FINAL_ARCHIVE (using xz)..."
xz -z -v -T0 "$RAW_IMG"

echo "[+] Generating SHA256 checksum..."
sha256sum "${FINAL_ARCHIVE}" > "${FINAL_ARCHIVE}.sha256"

echo "[+] Packaging Complete! Ready for distribution: ${FINAL_ARCHIVE}"
