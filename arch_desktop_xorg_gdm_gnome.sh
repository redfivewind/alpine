# Update pacman
sudo pacman --disable-download-timeout -Syu

# Install Xorg
sudo pacman --disable-download-timeout -Sy xorg xorg-server

# Install Gnome & GDM
sudo pacman --disable-download-timeout -noconfirm -Sy gdm gnome-session gnome-shell gnome-shell-extensions gnome-tweaks

# Install Gnome core applications
sudo pacman --disable-download-timeout -noconfirm -Sy baobab eog evince gnome-background gnome-calculator gnome-clocks gnome-console gnome-control-center gnome-disk-utility gnome-keyring gnome-logs gnome-menus gnome-photos gnome-settings-daemon gnome-system-monitor gnome-text-editor nautilus
#gnome-color-manager sushi

# Remove unnecessary packages
#gnome-remote-desktop gnome-software gnome-user-share gnome-video-effects

#TOOLS="gnome-calendar gnome-contacts gnome-maps gnome-music gnome-remote-desktop gnome-tour gnome-user-docs gnome-user-share gnome-weather"
#for Tool in $TOOLS; do
    #pacman -Rs --noconfirm $Tool
#done

# Ensure keyboard layout is German
sudo localectl set-keymap de

# Start GDM service
sudo systemctl enable gdm.service
sudo systemctl start gdm.service

