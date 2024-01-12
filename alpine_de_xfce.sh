# German keyboard layout
echo "[*] Loading German keyboard layout..."
doas setup-keymap de de

# Xfce basic installation
echo "[*] Installing Xfce..."
doas setup-desktop xfce
sleep 2

# Further required packages
echo "[*] Installing further required packages..."
doas apk add adw-gtk3 \
    elogind \
    gvfs \
    mousepad \
    pavucontrol \
    polkit-elogind \
    ristretto \
    thunar-archive-plugin \
    xarchiver \ 
    xfce4-cpugraph-plugin \
    xfce4-notifyd \
    xfce4-pulseaudio-plugin \
    xfce4-screenshooter \
    xfce4-taskmanager \
    xfce4-whiskermenu-plugin
#thunar-media-tags-plugin

# Configure services
echo "[*] Configuring services..."
doas rc-update add elogind default

# Start services
echo "[*] Starting services..."
doas rc-service elogind start

# Xfce keyboard layout
echo "[*] Setting the Xfce keyboard layout to German..."
xfconf-query -c keyboard-layout -p /Default/XkbLayout -s de

# Dark mode
echo "[*] Enabling dark mode..."
xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-dark"

