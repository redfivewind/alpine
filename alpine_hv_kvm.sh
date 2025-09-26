# Start message
echo "[*] This script installs the KVM virtualisation infrastructure on this Alpine Linux system."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Global variables
echo "[*] Initialising global variables..."
USER_NAME=$(whoami)

# Install required packages
echo "[*] Installing required packages..."
sudo apk add bridge \
    bridge-utils \
    dmidecode \
    ebtables \
    libvirt \
    libvirt-daemon \
    netcat-openbsd \
    ovmf \
    qemu-img \
    qemu-modules \
    qemu-system-x86_64 \
    seabios \
    virt-manager \
    virt-viewer 
sleep 2

# Enable modules
echo "[*] Enabling required modules..."
echo "tun" | sudo tee -a /etc/modules

# Add user to the 'libvirt' group
echo "[*] Adding user '$USER_NAME' to required groups.."
sudo adduser $USER_NAME kvm
sudo adduser $USER_NAME libvirt
sudo adduser $USER_NAME qemu
sleep 2

# Configure services
echo "[*] Configuring required services..."
sudo rc-update add libvirt-guests default
sudo rc-update add libvirtd default
sleep 2

# Start services
echo "[*] Starting required services..."
sudo rc-service libvirt-guests start
sudo rc-service libvirtd start
sleep 2

# Cleanup
echo "[*] Should this script be deleted? (yes/no)"
read delete_script

if [ "$delete_script" == "yes" ];
then
    echo "[*] Deleting the script..."
    shred -f -z -u $(readlink -f $0)
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
