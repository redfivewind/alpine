# System update
sudo pacman --disable-download-timeout --needed --noconfirm -Syyu

# Correct folder ownership
sudo chown -R user:users ~/tools
sudo chown -R user:users ~/workspace

# Install yay for access to the AUR ecosystem
sudo pacman --disable-download-timeout --needed --noconfirm -S git go

sudo mkdir -p ~/tools
cd ~/tools
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
yay --version
yay --disable-download-timeout --needed --noconfirm -Syu

# Install required tools
TOOLS="alsa-plugins alsa-utils chkrootkit choosenim chromium cmake gimp git go keepass libreoffice librewolf-bin magic-wormhole make mingw-w64 miniconda3 monodevelop-bin nasm nim onboard pinta pulseaudio python3 python3-pip python3-virtualenv python3-wheel rustup secure-delete vlc vscodium-bin"

for Tool in $TOOLS; do
    sudo pacman --disable-download-timeout --needed --noconfirm -S $Tool
    yay --disable-download-timeout --needed --noconfirm -S $Tool
done

# Miniconda3
echo "export PATH=\"/opt/miniconda3/condabin:$PATH\"" >> ~/.bash_profile
echo "export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1" >> ~/.bash_profile
echo "export PATH=\"/opt/miniconda3/condabin:$PATH\"" >> ~/.bashrc
echo "export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1" >> ~/.bashrc

conda init

# Rustup
rustup default stable
rustup default nightly

# VSCodium
sudo chmod 4755 /opt/vscodium-bin/chrome-sandbox

codium --install-extension bungcip.better-toml
codium --install-extension nimsaem.nimvscode
codium --install-extension canadaduane.notes
codium --install-extension ms-python.python
codium --install-extension rust-lang.rust-analyzer

# Clean up
sudo pacman --noconfirm -Rns $(pacman -Qdtq)
