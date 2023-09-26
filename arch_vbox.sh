# System update
sudo pacman --disable-download-timeout --noconfirm -Syu

# Install VirtualBox guest addition
sudo pacman --disable-download-timeout --needed--noconfirm -S virtualbox-guest-utils

# Clean up
sudo pacman -Rns $(pacman -Qdtq)
