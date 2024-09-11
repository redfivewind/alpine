# Start message
echo "[*] This script installs the Sway desktop environment on Alpine Linux."

# Global variables
echo "[*] Initialising global variables..."
GREETD_CFG="/etc/greetd/config.toml"

# German keyboard layout
echo "[*] Loading German keyboard layout..."
doas setup-keymap de de

# System update
echo "[*] Updating the system..."
doas apk update
doas apk upgrade

# Install Sway
echo "[*] Installing Sway..."
doas setup-desktop sway

# Configure Sway
echo "[*] Configuring Sway..."


# Install required packages
echo "[*] Installing required packages..."
doas apk add greetd greetd-tuigreet
#adw-gtk3 
#mousepad 
#pavucontrol 
#ristretto 
#thunar-archive-plugin 
#xarchiver  
#xfce4-cpugraph-plugin 
#xfce4-notifyd 
#xfce4-pulseaudio-plugin 
#xfce4-screensaver 
#xfce4-screenshooter 
#xfce4-taskmanager 
#xfce4-whiskermenu-plugin

# Configure greetd
echo "[*] Configuring greetd..."
echo "[terminal]" | doas tee $GREETD_CFG
echo "vt = 7" | doas tee -a $GREETD_CFG
echo "" | doas tee -a $GREETD_CFG
echo "[default_session]" | doas tee -a $GREETD_CFG
echo "command = \"tuigreet --cmd 'exec sway'\"" | doas tee -a $GREETD_CFG
echo "user = \"greetd\"" | doas tee -a $GREETD_CFG

# Configure networking
echo "[*] Configuring networking..."
doas apk add iwd network-manager-applet networkmanager networkmanager-cli networkmanager-wifi
doas apk del wpa_supplicant

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
doas rc-update add greetd default
doas rc-update add networkmanager default
doas rc-update del networking boot

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

