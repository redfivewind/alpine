# Install yay for access to the AUR ecosystem
mkdir ~/tools
cd ~/tools
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
yay --version

# System update
sudo pacman --disable-download-timeout --needed --noconfirm -Syu
yay --disable-download-timeout --needed --noconfirm -Syu

# Install tools using pacman
sudo pacman --disable-download-timeout --needed --noconfirm -S alsa-plugins alsa-utils git go pulseaudio python3 python3-pip python3-virtualenv python3-wheel rustup virtualbox-guest-utils vlc

# Install tools using yay
yay --disable-download-timeout --needed --noconfirm -Syu
yay --disable-download-timeout --needed --noconfirm -S chkrootkit choosenim chromium cmake go keepass libreoffice librewolf-bin magic-wormhole make mingw miniconda3 monodevelop-bin nasm nim onboard pinta secure-delete vscodium-bin

# Miniconda3
echo "export PATH=\"/opt/miniconda3/condabin:$PATH\"" >> ~/.bash_profile
echo "export PATH=\"/opt/miniconda3/condabin:$PATH\"" >> ~/.bashrc

# VSCodium
sudo chmod 4755 /opt/vscodium-bin/chrome-sandbox
codium --install-extension bungcip.better-toml
codium --install-extension nimsaem.nimvscode
codium --install-extension canadaduane.notes
codium --install-extension ms-python.python
codium --install-extension rust-lang.rust-analyzer

# Clean up
sudo pacman --noconfirm -Rns $(pacman -Qdtq)
