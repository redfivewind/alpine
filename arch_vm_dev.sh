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
TOOLS="anaconda chkrootkit choosenim chromium cmake go keepass libreoffice librewolf magic-wormhole make mingw nasm nim onboard pinta python3 python3-pip python3-virtualenv python3-wheel rustup secure-delete vlc vscodium"
for Tool in $TOOLS; do
    yay --disable-download-timeout --needed --noconfirm -S $Tool
done
#dconf-editor

# Install VSCodium extensions

# Clean up
sudo pacman -Rns $(pacman -Qdtq)
