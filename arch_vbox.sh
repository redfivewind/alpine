# Install the VirtualBox guest additions
sudo pacman --disable-download-timeout --needed --noconfirm virtualbox-guest-utils

# Enable & start the VirtualBox service
sudo systemctl enable vboxservice.service
sudo systemctl start vboxservice.service
