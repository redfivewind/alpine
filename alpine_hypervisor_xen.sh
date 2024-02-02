# Install required packages
echo "[*] Installing required packages..."
doas apk add bridge \
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

# Enable modules
echo "[*] Enabling modules..."
echo "xen-blkback" | doas tee -a /etc/modules
echo "xen-netback" | doas tee -a /etc/modules
echo "tun" | doas tee -a /etc/modules

# Configure services
echo "[*] Configuring required services..."
doas rc-update add libvirt-guests default
doas rc-update add libvirtd default
doas rc-update add xenconsoled default
doas rc-update add xendomains default 
doas rc-update add xenqemu default
doas rc-update add xenstored default
sleep 2

# Add user to the 'libvirt' group
echo "[*] Adding the user to the 'libvirt' group..."
doas adduser $(whoami) libvirt
sleep 2

# Generate Xen unified kernel image (UKI)
#FIXME
