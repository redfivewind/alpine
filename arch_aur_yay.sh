# System update
sudo pacman --disable-download-timeout --needed --noconfirm -Syu

# Install dependencies
sudo pacman --disable-download-timeout --needed --noconfirm -S git go

# Install yay for access to the AUR ecosystem
mkdir ~/tools
cd ~/tools
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
yay --version

# Install required tools
yay --disable-download-timeout --needed --noconfirm -Syu
TOOLS="chkrootkit secure-delete"
for Tool in $TOOLS; do
    yay --disable-download-timeout --needed --noconfirm -S $Tool
done

# Clean up
sudo pacman -Rns $(pacman -Qdtq)
