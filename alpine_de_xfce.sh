# German keyboard layout
echo "[*] Loading German keyboard layout..."
doas setup-keymap de de

# Install X.Org & Xfce
echo "[*] Installing X.Org & Xfce..."
doas setup-desktop xfce

# Install base packages
echo "[*] Installing base packages..."
doas apk add adw-gtk3 mousepad network-manager-applet pavucontrol ristretto thunar-archive-plugin xarchiver xfce4-cpugraph-plugin xfce4-notifyd xfce4-pulseaudio-plugin xfce4-screenshooter xfce4-taskmanager xfce4-whiskermenu-plugin
#thunar-media-tags-plugin

# Xfce keyboard layout
echo "[*] Setting the Xfce keyboard layout to German..."
xfconf-query -c keyboard-layout -p /Default/XkbLayout -s de

# Dark mode
echo "[*] Enabling dark mode..."
xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-dark"

# Configure services
echo "[*] Enabling LightDM..."
doas rc-update add lightdm default

# Stop message
echo "[*] Installation finished. Please reboot manually."


