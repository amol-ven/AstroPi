#!/usr/bin/env bash
set -e

# Ensure script is invoked, but handle root checks where appropriate
LOCKFILE="/etc/astropi_initialized"
if [ -f "$LOCKFILE" ]; then
    echo "[-] AstroPi setup has already been executed."
    read -p "Press Enter to exit..."
    exit 0
fi

LOGFILE="/var/log/astropi_setup.log"
exec > >(sudo tee -a "$LOGFILE") 2>&1

echo "[+] Starting Manual AstroPi Setup & Astronomy Suite Configuration..."

# 1. Enable VNC natively (Requires root)
sudo raspi-config nonint do_vnc 0

# 1.5. Configure Udev rule to guarantee internal Wi-Fi is always wlan0
echo "[+] Configuring udev rule for internal Wi-Fi interface (wlan0)..."
sudo tee /etc/udev/rules.d/70-persistent-net.rules > /dev/null << 'EOF'
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="brcmfmac", NAME="wlan0"
EOF

# 2. Setup Dual NetworkManager Hotspots (Requires root)
sudo nmcli radio wifi on
sudo nmcli connection add type wifi ifname wlan0 con-name Hotspot-Internal autoconnect yes ssid Pi-Astro-Internal  mode ap 802-11-wireless.band a 802-11-wireless.channel 149 wifi-sec.key-mgmt wpa-psk wifi-sec.psk astrophotography ipv4.method shared ipv6.method ignore || true
sudo nmcli connection add type wifi ifname wlan1 con-name Hotspot-External autoconnect yes ssid Pi-Astro-HighPower mode ap 802-11-wireless.band a 802-11-wireless.channel 165 wifi-sec.key-mgmt wpa-psk wifi-sec.psk astrophotography ipv4.method shared ipv6.method ignore || true

BUILD_DIR="/home/astropi/astropi_build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# 3. Download and Execute the Official KStars/INDI Installer Script
echo "[+] Fetching and executing official KStars/INDI installer script..."
wget -qO kstars.sh https://raw.githubusercontent.com/ikarustechnologies/indi-firmware/main/kstars.sh
chmod +x kstars.sh
bash kstars.sh
cd "$BUILD_DIR"

# 4. Install PHD2 Guiding Dependencies (excluding libindi-dev)
echo "[+] Installing PHD2 build prerequisites..."
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    git \
    cmake \
    pkg-config \
    libwxgtk3.2-dev \
    wx-common \
    wx3.2-i18n \
    libnova-dev \
    gettext \
    zlib1g-dev \
    libx11-dev \
    libcurl4-gnutls-dev \
    libopencv-dev \
    libeigen3-dev \
    libcfitsio-dev \
    libgtest-dev

# 5. Clone, Configure, and Build PHD2 (letting PHD2 bundle/build INDI automatically)
echo "[+] Cloning and building PHD2..."
git clone https://github.com/OpenPHDGuiding/phd2.git
cd phd2
mkdir -p tmp
cd tmp
cmake -DCMAKE_EXE_LINKER_FLAGS="-Wl,--allow-multiple-definition" ..
make -j$(nproc)
sudo make install
cd "$BUILD_DIR"

# 6. Download and Install FireCapture (AArch64 DEB) (Requires root)
echo "[+] Downloading and installing FireCapture..."
#wget -qO firecapture.deb "http://www.firecapture.de/download.php?file=firecapture_2.7.15_aarch64.deb"
sudo dpkg -i ./firecapture_2.7.15_aarch64.deb

# 7. Create Desktop and System Shortcuts for KStars & FireCapture
echo "[+] Creating application shortcuts and desktop launchers..."
mkdir -p /home/astropi/Desktop

# 7. Create Desktop and System Shortcuts for KStars & FireCapture
#echo "[+] Creating application shortcuts and desktop launchers..."
#mkdir -p /home/astropi/Desktop

## KStars Desktop Shortcut
#cat << 'EOF' > /home/astropi/Desktop/KStars.desktop
#[Desktop Entry]
#Type=Application
#Name=KStars
#Comment=Planetarium and Astronomy Suite
#Exec=flatpak run --user org.kde.kstars//stable
#Icon=kstars
#Terminal=false
#Categories=Education;Science;Astronomy;
#StartupNotify=true
#EOF

## KStars System Menu Entry
#sudo tee /usr/share/applications/org.kde.kstars.desktop > /dev/null << 'EOF'
#[Desktop Entry]
#Type=Application
#Name=KStars
#Comment=Planetarium and Astronomy Suite
#Exec=flatpak run --user org.kde.kstars//stable
#Icon=kstars
#Terminal=false
#Categories=Education;Science;Astronomy;
#StartupNotify=true
#EOF

## FireCapture Desktop Shortcut
#cat << 'EOF' > /home/astropi/Desktop/FireCapture.desktop
#[Desktop Entry]
#Type=Application
#Name=FireCapture
#Comment=Planetary and Lunar Imaging
#Exec=firecapture
#Icon=system-run
#Terminal=false
#Categories=AudioVideo;Video;Science;Astronomy;
#StartupNotify=true
#EOF

## FireCapture System Menu Entry
#sudo tee /usr/share/applications/firecapture.desktop > /dev/null << 'EOF'
#[Desktop Entry]
#Type=Application
#Name=FireCapture
#Comment=Planetary and Lunar Imaging
#Exec=firecapture
#Icon=system-run
#Terminal=false
#Categories=AudioVideo;Video;Science;Astronomy;
#StartupNotify=true
#EOF

#sudo chown -R 1000:1000 /home/astropi/Desktop
#chmod +x /home/astropi/Desktop/*.desktop
#sudo update-desktop-database || true

# 8. Cleanup build directories and package lists
echo "[+] Cleaning up build directories..."
rm -rf "$BUILD_DIR"
sudo apt-get clean
sudo apt-get autoremove -y

# 9. Mark initialization complete
sudo touch "$LOCKFILE"

echo "[+] AstroPi Setup & Installation Complete!"
