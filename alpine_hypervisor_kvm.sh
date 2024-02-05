# Install required packages
echo "[*] Installing required packages..."
doas apk add bridge \
    bridge-utils \
    dmidecode \
    ebtables \
    libvirt \
    libvirt-daemon \
    netcat-openbsd \
    qemu-img \
    qemu-modules \
    qemu-system-x86_64 \
    virt-manager \
    virt-viewer 
sleep 2

# Enable modules
echo "[*] Enabling modules..."
echo "tun" | doas tee -a /etc/modules

# Configure services
echo "[*] Configuring required services..."
doas rc-update add libvirt-guests default
doas rc-update add libvirtd default
sleep 2

# Add user to the 'libvirt' group
echo "[*] Adding the user to the 'libvirt' group..."
doas adduser $(whoami) libvirt
sleep 2
