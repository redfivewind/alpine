# Ensure German keyboard layout & timezone
sudo loadkeys de-latin1
sudo localectl set-keymap de
sudo timedatectl set-timezone Europe/Berlin

# System update
echo "Updating the system..."
sudo pacman --disable-download-timeout --needed --noconfirm -Syu

# Install Xorg
sudo pacman --disable-download-timeout --needed --noconfirm -S xorg xorg-drivers

# Install GDM and Gnome
sudo pacman --disable-download-timeout --needed --noconfirm -S #FIXME

# Set dark theme
#FIXME

# Install additional applications
sudo pacman --disable-download-timeout --needed --noconfirm -S #FIXME

# Configure LightDM service
sudo systemctl enable gdm.service
sudo systemctl start gdm.service

# Clean up
sudo pacman --noconfirm -Rns $(pacman -Qdtq)
