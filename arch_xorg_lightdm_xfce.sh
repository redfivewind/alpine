# System update
sudo pacman --disable-download-timeout --noconfirm -Syu

# Install Xorg, LightDM and Xfce
sudo pacman --disable-download-timeout --noconfirm lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4 xorg xorg-server

# Install additional applications


# Configure LightDM service
sudo systemctl enable lightdm
sudo systemctl start lightdm

# Remove packages that are no longer required
sudo pacman -Rns $(pacman -Qdtq)
