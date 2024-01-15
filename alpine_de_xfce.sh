# German keyboard layout
echo "[*] Loading German keyboard layout..."
doas setup-keymap de de

# Install X.Org & Xfce
echo "[*] Installing X.Org & Xfce..."
doas setup-desktop xfce

# Install required packages
echo "[*] Installing required packages..."
doas apk add adw-gtk3 mousepad pavucontrol ristretto thunar-archive-plugin xarchiver xfce4-cpugraph-plugin xfce4-notifyd xfce4-pulseaudio-plugin xfce4-screenshooter xfce4-taskmanager xfce4-whiskermenu-plugin
#thunar-media-tags-plugin

# Configure networking
echo "[*] Configuring networking..."
doas apk add iwd network-manager-applet networkmanager networkmanager-cli networkmanager-wifi
doas apk del wpa_supplicant

echo "[main]" > /etc/NetworkManager/NetworkManager.conf
echo "dhcp=internal" >> /etc/NetworkManager/NetworkManager.conf
echo "plugins=ifupdown,keyfile" >> /etc/NetworkManager/NetworkManager.conf
echo "\n" >> /etc/NetworkManager/NetworkManager.conf
echo "[ifupdown]" >> /etc/NetworkManager/NetworkManager.conf
echo "managed=true" >> /etc/NetworkManager/NetworkManager.conf
echo "\n" >> /etc/NetworkManager/NetworkManager.conf
echo "[device]" >> /etc/NetworkManager/NetworkManager.conf
echo "wifi.scan-rand-mac-address=yes" >> /etc/NetworkManager/NetworkManager.conf
echo "wifi.backend=iwd" >> /etc/NetworkManager/NetworkManager.conf

doas rc-update add networkmanager default
doas rc-update del networking boot

# Xfce keyboard layout
echo "[*] Setting the Xfce keyboard layout to German..."
mkdir -p /etc/X11/xorg.conf.d/
echo "Section \"InputClass\"" > /etc/X11/xorg.conf.d/00-keyboard.conf
echo "\tIdentifier \"system-keyboard\"" >> /etc/X11/xorg.conf.d/00-keyboard.conf
echo "\tMatchIsKeyboard \"on\"" >> /etc/X11/xorg.conf.d/00-keyboard.conf
echo "\tOption \"XkbLayout\" \"de\"" >> /etc/X11/xorg.conf.d/00-keyboard.conf
echo "\tOption \"XkbVariant\" \"nodeadkeys\"" >> /etc/X11/xorg.conf.d/00-keyboard.conf
echo "EndSection" >> /etc/X11/xorg.conf.d/00-keyboard.conf

# Dark mode
echo "[*] Enabling dark mode..."
xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-dark"

# Enable LightDM
echo "[*] Enabling LightDM..."
doas rc-update add lightdm default

# Stop message
echo "[*] Installation finished. Please reboot manually."


