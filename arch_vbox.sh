# System update
sudo pacman --disable-download-timeout --noconfirm -Syu

# Install VirtualBox guest addition
sudo pacman --disable-download-timeout --needed--noconfirm -S virtualbox-guest-utils

# Remove packages that are no longer required
sudo pacman --noconfirm -Rns $(pacman -Qdtq)
