# Install yay for access to the AUR ecosystem
mkdir ~/tools
cd ~/tools
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
yay --version

# Install required tools
sudo yay --disable-download-timeout --noconfirm -Syu
TOOLS="chkrootkit secure-delete"
for Tool in $TOOLS; do
    sudo yay --disable-download-timeout --noconfirm -Sy $Tool
done

# Clean up
sudo pacman -Rns $(pacman -Qdtq)
