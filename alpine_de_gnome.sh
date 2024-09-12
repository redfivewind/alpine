# Start message
echo "[*] This script installs GNOME on Alpine Linux."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# System update
echo "[*] Updating the system..."
doas apk update
doas apk upgrade

# Install Wayland
echo "[*] Installing Wayland..."
doas setup-wayland-base

# Install Hyprland
echo "[*] Installing GNOME..."
doas apk add gnome-control-center gnome-session gnome-settings-daemon gnome-shell gnome-terminal gnome-tweaks mutter

# Install required packages
echo "[*] Installing further packages..."
doas apk add baobab evince gnome-calculator gnome-clocks gnome-disk-utility gnome-screenshot gnome-system-monitor gnome-text-editor loupe spice-vdagent xf86-video-qxl

# Configure networking
echo "[*] Configuring networking..."

echo "[*] Removing package 'wpa_supplicant'..."
doas apk del wpa_supplicant

echo "[*] Configuring package 'NetworkManager'..."
echo "[main]" | doas tee /etc/NetworkManager/NetworkManager.conf
echo "dhcp=internal" | doas tee -a /etc/NetworkManager/NetworkManager.conf
echo "plugins=ifupdown,keyfile" | doas tee -a /etc/NetworkManager/NetworkManager.conf
echo "" | doas tee -a /etc/NetworkManager/NetworkManager.conf
echo "[ifupdown]" | doas tee -a /etc/NetworkManager/NetworkManager.conf
echo "managed=true" | doas tee -a /etc/NetworkManager/NetworkManager.conf
echo "" | doas tee -a /etc/NetworkManager/NetworkManager.conf
echo "[device]" | doas tee -a /etc/NetworkManager/NetworkManager.conf
echo "wifi.scan-rand-mac-address=yes" | doas tee -a /etc/NetworkManager/NetworkManager.conf
echo "wifi.backend=iwd" | doas tee -a /etc/NetworkManager/NetworkManager.conf

# Configure services
echo "[*] Configuring services..."
doas rc-update add gdm default

# Clean up
echo "[*] Cleaning up..."

echo "[*] Should this script be deleted? (yes/no)"
read delete_script

if [ "$delete_script" == "yes" ];
then
    echo "[*] Deleting the script..."
    shred -f -z -u $(readlink -f $0)
elif [ "$delete_script" == "no" ];
then
    echo "[*] Skipping script deletion..."
else
    echo "[!] ALERT: Variable 'delete_script' is '$delete_script' but must be 'yes' or 'no'."
fi

# Stop message
echo "[*] Work done. Exiting..."
exit 0
