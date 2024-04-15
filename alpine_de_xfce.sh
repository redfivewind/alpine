# German keyboard layout
echo "[*] Loading German keyboard layout..."
doas setup-keymap de de

# Install X.Org & Xfce
echo "[*] Installing X.Org & Xfce..."
doas setup-desktop xfce

# Install required packages
echo "[*] Installing required packages..."
doas apk add adw-gtk3 mousepad pavucontrol ristretto thunar-archive-plugin xarchiver xfce-polkit xfce4-cpugraph-plugin xfce4-notifyd xfce4-pulseaudio-plugin xfce4-screensaver xfce4-screenshooter xfce4-taskmanager xfce4-whiskermenu-plugin

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

doas rc-update add networkmanager default
doas rc-update del networking boot

# Xfce keyboard layout
echo "[*] Setting the Xfce keyboard layout to German..."
doas mkdir -p /etc/X11/xorg.conf.d/
echo "Section \"InputClass\"" | doas tee /etc/X11/xorg.conf.d/00-keyboard.conf
echo "  Identifier \"system-keyboard\"" | doas tee -a /etc/X11/xorg.conf.d/00-keyboard.conf
echo "  MatchIsKeyboard \"on\"" | doas tee -a /etc/X11/xorg.conf.d/00-keyboard.conf
echo "  Option \"XkbLayout\" \"de\"" | doas tee -a /etc/X11/xorg.conf.d/00-keyboard.conf
echo "  Option \"XkbVariant\" \"nodeadkeys\"" | doas tee -a /etc/X11/xorg.conf.d/00-keyboard.conf
echo "EndSection" | doas tee -a /etc/X11/xorg.conf.d/00-keyboard.conf

# Xfce customisation
echo "[*] Customising Xfce..."
export DISPLAY=:0
export $(dbus-launch)
xfconf-query -c xsettings -p '/Net/ThemeName' -s 'adw-gtk3-dark'
xfconf-query -c xfce4-keyboard-shortcuts -p '/commands/custom/<Super><Alt>l' --reset
xfconf-query -c xfce4-keyboard-shortcuts -n -t 'string' -p '/commands/custom/<Super>l' -s 'xflock4' --create

# Configure services
echo "[*] Configuring services..."
doas rc-update add lightdm default
doas rc-update add polkit default

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
