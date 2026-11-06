# AstroPi Minimal Build & Provisioning Framework

A streamlined, modular framework for building, provisioning, and setting up a Raspberry Pi (Debian Trixie) astrophotography workstation. This setup relies on a clean two-step execution model: 
1. **Host-Side Preparation & Image Injection**: Setting up the custom boot image and system configurations (username/ssh).
2. **Target-Side Provisioning (`astropi-setup.sh`)**: Running the modular installation script directly on the target Raspberry Pi to fetch tools, configure access points, and build binaries.

---

## Architecture & Components

* **Dual NetworkManager Hotspots**: Automatically provisions dual-band Wi-Fi access points (`Pi-Astro-Internal` on `wlan0` and `Pi-Astro-HighPower` on `wlan1`) on boot for reliable field connectivity.
* **Global Wi-Fi Radio Management**: Automatically enables the Wi-Fi radio globally on system startup (`nmcli radio wifi on`).
* **KStars / INDI (Flatpak)**: Deploys the latest astronomy suite via official installer scripts.
* **PHD2 Guiding**: Clones and builds PHD2 directly from source, allowing PHD2 to automatically manage its own required INDI dependencies.
* **FireCapture**: Installs the native AArch64 Debian package for planetary and lunar imaging.

---

## Two-Step Execution Workflow

### Step 1: Host-Side Preparation & Rootfs Injection
Before booting the target SD card, your host-side build orchestrator injects necessary configurations, user credentials, and the payload script (`astropi-setup.sh`) and binary files (`firecapture deb file`) into the target root filesystem.

### Step 2: Target-Side Provisioning (`astropi-setup.sh`)
Once the Raspberry Pi has booted, the provisioning script runs locally to enable VNC, bring up wireless hotspots, compile and install software packages.

---


## Image Preparation Quickstart
To begin the build process, download your official Raspberry Pi OS image (such as Debian Trixie ARM64) from the Raspberry Pi Software Page and place it in your project workspace directory.

Run the master orchestrator script with sudo, passing your downloaded base image filename as a command-line parameter. The framework will automatically decompress the archive, create a pristine working copy, and execute the modular preparation and injection pipeline:

```
sudo ./build_astro_image.sh <your-raspios-image.img.xz>
```

## Deployment Quickstart

1. Log in to the target Raspberry Pi over SSH or terminal:
   ```bash
   ssh astropi@<pi-ip-address>
   ```
2. Make the script executable:
   ```
   chmod +x astropi-setup.sh
   ```
3. Execute the setup:
   ```
   ./astropi-setup.sh
   ```
