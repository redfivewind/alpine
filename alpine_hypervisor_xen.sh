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
    virt-viewer \
    xen \
    xen-hypervisor \
    xen-qemu
sleep 2

# Configure Alpine Linux as Xen dom0
echo "[*] Configuring Alpine Linux as Xen dom0..."
setup-xen-dom0
sleep 2

# Configure services
echo "[*] Configuring required services..."
chroot /mnt rc-update add libvirt-guests default
chroot /mnt rc-update add libvirtd default

echo "[*] Adding the user to the 'libvirt' group..."
chroot /mnt adduser $USER_NAME libvirt

# Generate Xen unified kernel image (UKI)
#FIXME
