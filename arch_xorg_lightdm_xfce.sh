# Ensure German keyboard layout
sudo loadkeys de-latin1
sudo localectl set-keymap de

# System update
sudo pacman --disable-download-timeout --noconfirm -Syu

# Install Xorg
sudo pacman --disable-download-timeout --noconfirm xorg xorg-drivers

# Install LightDM and Xfce
sudo pacman --disable-download-timeout --noconfirm lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4

# Install additional applications
sudo pacman --disable-download-timeout --noconfirm mousepad ristretto thunar-archive-plugin thunar-media-tags-plugin xfce4-artwork xfce4-battery-plugin xfce4-cpugraph-plugin xfce4-fsguard-plugin xfce4-mount-plugin xfce4-netload-plugin xfce4-notifyd xfce4-pulseaudio-plugin xfce4-screenshooter xfce4-taskmanager xfce4-timer-plugin xfce4-xkb-plugin

# Remove unnecessary applications
#

# Configure LightDM service
sudo systemctl enable lightdm.service
sudo systemctl start lightdm.service

# Remove packages that are no longer required
sudo pacman -Rns $(pacman -Qdtq)
