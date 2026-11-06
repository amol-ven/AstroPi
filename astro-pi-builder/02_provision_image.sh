#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run this script with sudo."
  exit 1
fi

# ==========================================
# Configuration Variables
# ==========================================
TARGET_USER="astropi"
TARGET_PASS="astropi"
RAW_IMG="astro-pi-distributable.img"
MOUNT_BOOT="/mnt/astropi_boot"
MOUNT_ROOT="/mnt/astropi_root"
SETUP_SCRIPT="astropi-setup.sh"
FIRE_CAPTURE="firecapture_2.7.15_aarch64.deb"

if [ ! -f "$RAW_IMG" ]; then
  echo "[-] Error: '$RAW_IMG' not found. Run Step 1 first."
  exit 1
fi

if [ ! -f "$SETUP_SCRIPT" ]; then
  echo "[-] Error: '$SETUP_SCRIPT' not found in current directory."
  exit 1
fi

echo "[+] Setting up loop device for offline file injection..."
LOOP_DEV=$(sudo losetup -f --show "$RAW_IMG")
sudo partprobe "$LOOP_DEV"
sudo kpartx -av "$LOOP_DEV"
sleep 2

LOOP_Name=$(basename "$LOOP_DEV")
BOOT_PART="/dev/mapper/${LOOP_Name}p1"
ROOT_PART="/dev/mapper/${LOOP_Name}p2"

mkdir -p "$MOUNT_BOOT" "$MOUNT_ROOT"

echo "[+] Mounting image partitions..."
sudo mount "$BOOT_PART" "$MOUNT_BOOT"
sudo mount "$ROOT_PART" "$MOUNT_ROOT"

# 1. Headless Boot Configuration (SSH & User credentials)
echo "[+] Configuring headless boot access (SSH & userconf.txt for user '${TARGET_USER}')..."
sudo touch "$MOUNT_BOOT/ssh"
echo "${TARGET_USER}:$(openssl passwd -6 "${TARGET_PASS}")" | sudo tee "$MOUNT_BOOT/userconf.txt" > /dev/null

# 2. Ensure target home and desktop directories exist, then copy script
echo "[+] Creating home directory structure and copying setup script..."
sudo mkdir -p "$MOUNT_ROOT/home/${TARGET_USER}/Desktop"
sudo cp "$SETUP_SCRIPT" "$MOUNT_ROOT/home/${TARGET_USER}/astropi-setup.sh"
sudo chmod +x "$MOUNT_ROOT/home/${TARGET_USER}/astropi-setup.sh"
sudo cp "$FIRE_CAPTURE" "$MOUNT_ROOT/home/${TARGET_USER}/${FIRE_CAPTURE}"

# 3. Create Desktop Launcher pointing to home path
echo "[+] Creating prominent Desktop shortcut launcher..."
sudo bash -c "cat << 'EOF' > '$MOUNT_ROOT/home/${TARGET_USER}/Desktop/Run-AstroPi-Setup.desktop'
[Desktop Entry]
Type=Application
Name=Run AstroPi Setup
Comment=Compile KStars, Ekos, and PHD2 from source
Exec=x-terminal-emulator -e \"/home/${TARGET_USER}/astropi-setup.sh\"
Icon=system-run
Terminal=false
Categories=System;
StartupNotify=true
EOF"

# Enforce correct ownership (UID/GID 1000:1000 for astropi)
sudo chown -R 1000:1000 "$MOUNT_ROOT/home/${TARGET_USER}"
sudo chmod +x "$MOUNT_ROOT/home/${TARGET_USER}/Desktop/Run-AstroPi-Setup.desktop"

# Also sync to /etc/skel for template coverage
sudo mkdir -p "$MOUNT_ROOT/etc/skel/Desktop"
sudo cp "$MOUNT_ROOT/home/${TARGET_USER}/Desktop/Run-AstroPi-Setup.desktop" "$MOUNT_ROOT/etc/skel/Desktop/"
sudo chmod +x "$MOUNT_ROOT/etc/skel/Desktop/Run-AstroPi-Setup.desktop"

echo "[+] Syncing changes and unmounting partitions..."
sync
sudo umount "$MOUNT_BOOT"
sudo umount "$MOUNT_ROOT"
sudo kpartx -dv "$LOOP_DEV" || true
sudo losetup -d "$LOOP_DEV" || true

echo "[+] Step 2 Complete: Script placed in home directory and desktop launcher configured."
