# Start message
echo "[*] This script installs GNOME on Alpine Linux."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# System update
echo "[*] Updating the system..."
sudo apk update
sudo apk upgrade

# Install Wayland
echo "[*] Installing Wayland..."
sudo setup-wayland-base

# Install Hyprland
echo "[*] Installing required GNOME packages..."
sudo apk add elogind gdm gnome-control-center gnome-session gnome-settings-daemon gnome-shell gnome-terminal gnome-tweaks libva mesa mutter spice-vdagent

# Install required packages
echo "[*] Installing further packages..."
sudo apk add baobab evince gnome-calculator gnome-clocks gnome-disk-utility gnome-screenshot gnome-system-monitor gnome-text-editor loupe

# Configure networking
echo "[*] Configuring networking..."

echo "[*] Removing package 'wpa_supplicant'..."
sudo apk del wpa_supplicant

echo "[*] Configuring package 'NetworkManager'..."
echo "[main]" | sudo tee /etc/NetworkManager/NetworkManager.conf
echo "dhcp=internal" | sudo tee -a /etc/NetworkManager/NetworkManager.conf
echo "plugins=ifupdown,keyfile" | sudo tee -a /etc/NetworkManager/NetworkManager.conf
echo "" | sudo tee -a /etc/NetworkManager/NetworkManager.conf
echo "[ifupdown]" | sudo tee -a /etc/NetworkManager/NetworkManager.conf
echo "managed=true" | sudo tee -a /etc/NetworkManager/NetworkManager.conf
echo "" | sudo tee -a /etc/NetworkManager/NetworkManager.conf
echo "[device]" | sudo tee -a /etc/NetworkManager/NetworkManager.conf
echo "wifi.scan-rand-mac-address=yes" | sudo tee -a /etc/NetworkManager/NetworkManager.conf
echo "wifi.backend=iwd" | sudo tee -a /etc/NetworkManager/NetworkManager.conf

# Configure services
echo "[*] Configuring services..."
sudo rc-update add elogind
sudo rc-update add gdm
sudo rc-update add networkmanager

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
