# System update
sudo pacman --disable-download-timeout --needed --noconfirm -Syu

# Install required tools
yay --disable-download-timeout --needed --noconfirm -Syu
TOOLS="chkrootkit chromium gimp keepass libreoffice librewolf obsidian onboard secure-delete thunderbird vlc vscodium xmind"
for Tool in $TOOLS; do
    yay --disable-download-timeout --needed --noconfirm -S $Tool
done
#cheese dconf-editor gimp okular pinta simple-scan

# Clean up
sudo pacman -Rns $(pacman -Qdtq)
