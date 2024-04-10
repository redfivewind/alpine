# Start message
echo "[*] This script installs the KVM virtualisation infrastructure on this Alpine Linux system."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

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
echo "[*] Enabling required modules..."
echo "tun" | doas tee -a /etc/modules

# Add user to the 'libvirt' group
echo "[*] Adding user '$USER_NAME' to required groups.."
doas adduser $(whoami) kvm
doas adduser $(whoami) libvirt
doas adduser $(whoami) qemu
sleep 2

# Configure services
echo "[*] Configuring required services..."
doas rc-update add libvirt-guests default
doas rc-update add libvirtd default
sleep 2

# Cleanup
echo "[*] Should this script be deleted? (yes/no)"
read delete_script

if [ "$delete_script" == "yes" ];
then
    echo "[*] Deleting the script..."
    shred --force --remove=wipesync --verbose --zero $(readlink -f $0)
elif [ "$delete_script" == "no" ];
then
    echo "[*] Skipping script deletion..."
else
    echo "[!] ALERT: Variable 'delete_script' is '$delete_script' but must be 'yes' or 'no'."
fi

# Stop message
echo "[*] Installation of the KVM virtualisation infrastructure is finished. You may reboot now."
echo "[*] Work done. Exiting..."
exit 0
