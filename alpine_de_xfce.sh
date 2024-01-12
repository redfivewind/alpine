#FIXME: xfconf-query -c xfce4-session -p /general/LockCommand -s "light-locker-command -l"

# German keyboard layout
echo "[*] Loading German keyboard layout..."
doas setup-keymap de de

# Xfce basic installation
echo "[*] Installing Xfce..."
doas setup-xorg-base adw-gtk3 \
	consolekit2 \
	dbus \
	dbus-x11 \
	font-dejavu \
	firefox \
	gvfs \
	lightdm \
	lightdm-gtk-greeter \
	mousepad \
	pavucontrol \
	polkit \
	ristretto \
	thunar-archive-plugin \
	xarchiver \ 
	xfce4-cpugraph-plugin \
	xfce4-notifyd \
	xfce4-pulseaudio-plugin \
	xfce4-screenshooter \
	xfce4-taskmanager \
	xfce4-terminal \
	xfce4-whiskermenu-plugin
#thunar-media-tags-plugin

# Xfce keyboard layout
echo "[*] Setting the Xfce keyboard layout to German..."
xfconf-query -c keyboard-layout -p /Default/XkbLayout -s de

# Dark mode
echo "[*] Enabling dark mode..."
xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-dark"

# Configure services
echo "[*] Configuring services..."
doas rc-update add dbus default
doas rc-update add lightdm default

# Start services
echo "[*] Starting services..."
doas rc-service dbus start
doas rc-service lightdm start


