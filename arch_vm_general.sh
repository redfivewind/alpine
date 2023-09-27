# System update
sudo pacman --disable-download-timeout --needed --noconfirm -Syu

# Install yay for access to the AUR ecosystem
sudo pacman --disable-download-timeout --needed --noconfirm -S git go

mkdir ~/tools
cd ~/tools
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
yay --version

# Install required tools
TOOLS="alsa-plugins alsa-utils chkrootkit chromium gimp keepass libreoffice librewolf-bin obsidian onboard pinta pulseaudio secure-delete thunderbird vlc vscodium-bin xmind"

for Tool in $TOOLS; do
    sudo pacman --disable-download-timeout --needed --noconfirm -S $Tool
    yay --disable-download-timeout --needed --noconfirm -S $Tool
done

# VSCodium
sudo chmod 4755 /opt/vscodium-bin/chrome-sandbox
codium --install-extension bungcip.better-toml
codium --install-extension nimsaem.nimvscode
codium --install-extension canadaduane.notes
codium --install-extension ms-python.python
codium --install-extension rust-lang.rust-analyzer

# Clean up
sudo pacman --noconfirm -Rns $(pacman -Qdtq)
