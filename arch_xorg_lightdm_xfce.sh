# Ensure German keyboard layout
sudo loadkeys de-latin1
sudo localectl set-keymap de

# System update
echo "Updating the system..."
pacman --disable-download-timeout --noconfirm -Syu

# Install Xorg
sudo pacman --disable-download-timeout --noconfirm -S xorg xorg-drivers

# Install LightDM and Xfce
sudo pacman --disable-download-timeout --noconfirm -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4

# Install additional applications
sudo pacman --disable-download-timeout --noconfirm -S mousepad ristretto thunar-archive-plugin thunar-media-tags-plugin xarchiver xfce4-artwork xfce4-cpugraph-plugin xfce4-mount-plugin xfce4-notifyd xfce4-pulseaudio-plugin xfce4-screenshooter xfce4-taskmanager

# Configure LightDM service
sudo systemctl enable lightdm.service
sudo systemctl start lightdm.service

# Remove packages that are no longer required
sudo pacman -Rns $(pacman -Qdtq)
