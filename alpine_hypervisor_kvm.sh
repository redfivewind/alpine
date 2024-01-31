# TODO: Everything!

# Install required packages
echo "[*] Installing required packages..."
apk add bridge \
    bridge-utils \
    dmidecode \
    ebtables \
    libvirt \
    libvirt-daemon \
    netcat-openbsd \
    ovmf \
    seabios \
    virt-manager \
    virt-viewer
sleep 2

# Configure services
echo "[*] Configuring required services..."
chroot /mnt rc-update add libvirt-guests default
chroot /mnt rc-update add libvirtd default

echo "[*] Adding the user to the 'libvirt' group..."
chroot /mnt adduser $USER_NAME libvirt

# KVM nested virtualisation
#FIXME
