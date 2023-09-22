# Install yay for access to the AUR ecosystem
mkdir ~/tools
cd ~/tools
git clone https://aur.archlinux.org/yay.git
makepkg -si
yay --version


# Install required tools
sudo yay -Syu
TOOLS="chkrootkit secure-delete"
for Tool in $TOOLS; do
    yay -Sy --noconfirm $Tool
done