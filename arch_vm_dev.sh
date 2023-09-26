# System update
sudo pacman --disable-download-timeout --needed --noconfirm -Syu

# Install audio capabilities
sudo pacman --disable-download-timeout --needed --noconfirm -S alsa-plugins alsa-utils pulseaudio

# Install yay for access to the AUR ecosystem
sudo pacman --disable-download-timeout --needed --noconfirm -S git go

mkdir ~/tools
cd ~/tools
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
yay --version

# Install required tools
yay --disable-download-timeout --needed --noconfirm -Syu
TOOLS="chkrootkit chromium gimp keepass libreoffice librewolf obsidian onboard pinta secure-delete vlc vscodium xmind"
for Tool in $TOOLS; do
    yay --disable-download-timeout --needed --noconfirm -S $Tool
done
#dconf-editor

# Clean up
sudo pacman -Rns $(pacman -Qdtq)
