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

#echo "GRUB_CMDLINE_XEN=\"console=vga guest_loglvl=all loglvl=all nomodeset noreboot=true\"" >> /mnt/etc/default/grub
#echo "GRUB_CMDLINE_XEN_DEFAULT=\"ucode=scan\"" >> /mnt/etc/default/grub #dom0_max_vcpus=1 dom0_vcpus_pin maxmem=512

# Generate Xen unified kernel image (UKI)
#FIXME
