# TODO: Auto-Lock
# TODO: Auto-Suspend???
# TODO: Wallpaper
# TODO: Dark mode
# TODO: Keyboard shutcut WIN for whiskersmenu
# TODO: Keyboard shortcut WIN+L for locking
# TODO: Hardening (e.g., Power)

# German keyboard layout
echo "[*] Loading German keyboard layout..."
doas setup-keymap de de

# Install X.Org & Xfce
echo "[*] Installing X.Org & Xfce..."
doas setup-desktop xfce

# Install required packages
echo "[*] Installing required packages..."
doas apk add adw-gtk3 mousepad pavucontrol ristretto thunar-archive-plugin xarchiver xfce4-cpugraph-plugin xfce4-notifyd xfce4-pulseaudio-plugin xfce4-screensaver xfce4-screenshooter xfce4-taskmanager xfce4-whiskermenu-plugin

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

# Dark mode
echo "[*] Enabling dark mode..."
xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-dark"

# Enable LightDM
echo "[*] Enabling LightDM..."
doas rc-update add lightdm default

# Stop message
echo "[*] Installation finished. Please reboot manually."


