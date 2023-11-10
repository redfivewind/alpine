# Ensure German keyboard layout & timezone
sudo loadkeys de-latin1
sudo localectl set-keymap de
sudo timedatectl set-timezone Europe/Berlin

# System update
echo "Updating the system..."
sudo pacman --disable-download-timeout --needed --noconfirm -Syu

# Install Xorg
sudo pacman --disable-download-timeout --needed --noconfirm -S xorg xorg-drivers

# Install LightDM and Xfce
sudo pacman --disable-download-timeout --needed --noconfirm -S lxqt oxygen-icons sddm ttf-freefont xdg-utils

# Custom theme
#

# Install additional applications
sudo pacman --disable-download-timeout --needed --noconfirm -S archlinux-wallpaper leafpead

# Ensure German keyboard layout & timezone
sudo loadkeys de-latin1
sudo localectl set-keymap de
sudo timedatectl set-timezone Europe/Berlin

# Enable services
sudo systemctl enable NetworkManager
sudo systemctl enable sddm

# Start services
sudo systemctl start NetworkManager
sudo systemctl start sddm

# Clean up
sudo pacman --noconfirm -Rns $(pacman -Qdtq)