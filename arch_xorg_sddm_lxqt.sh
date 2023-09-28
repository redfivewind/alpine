# Ensure German keyboard layout & timezone
sudo loadkeys de-latin1
sudo localectl set-keymap de
sudo timedatectl set-timezone Europe/Berlin

# System update
echo "Updating the system..."
pacman --disable-download-timeout --needed --noconfirm -Syu

# Install Xorg
sudo pacman --disable-download-timeout --needed --noconfirm -S xorg xorg-drivers

# Install LightDM and Xfce
sudo pacman --disable-download-timeout --needed --noconfirm -S lxqt sddm ttf-freefont xdg-utils

# Set dark theme
#

# Install additional applications
sudo pacman --disable-download-timeout --needed --noconfirm -S 

# Configure LightDM service
sudo systemctl enable lightdm.service
sudo systemctl start lightdm.service

# Clean up
sudo pacman --noconfirm -Rns $(pacman -Qdtq)
