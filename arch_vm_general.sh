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
TOOLS="chkrootkit chromium gimp keepass libreoffice librewolf-bin obsidian onboard pinta secure-delete thunderbird vlc vscodium-bin xmind"
for Tool in $TOOLS; do
    yay --disable-download-timeout --needed --noconfirm -S $Tool
done
#cheese dconf-editor gimp okular simple-scan

# VSCodium
sudo chmod 4755 /opt/vscodium-bin/chrome-sandbox
codium --install-extension bungcip.better-toml
codium --install-extension nimsaem.nimvscode
codium --install-extension canadaduane.notes
codium --install-extension ms-python.python
codium --install-extension rust-lang.rust-analyzer

# Clean up
sudo pacman --noconfirm -Rns $(pacman -Qdtq)
