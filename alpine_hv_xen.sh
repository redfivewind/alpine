# Start message
echo "[*] This script installs the Xen virtualisation infrastructure on Arch Linux."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Global variables
echo "[*] Initialising global variables..."
USER_NAME=$(whoami)
XEN_CFG="/boot/xen.cfg"
XEN_EFI="/boot/xen.efi"

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
    spice-vdagent \
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

# Enable non-root access to libvirtd
echo "[*] Enabling libvirt access for user '$USER_NAME'..."

echo "[*] Granting non-root access to libvirt to the 'libvirt' group..."
echo "unix_sock_group = \"libvirt\"" | doas tee -a /etc/libvirt/libvirtd.conf
echo "unix_sock_rw_perms = \"0770\"" | doas tee -a /etc/libvirt/libvirtd.conf

echo "[*] Adding user '$USER_NAME' to the 'libvirt' group..."
doas adduser $(whoami) libvirt

echo "[*] Enabling the 'libvirtd' service..."
sudo systemctl enable libvirtd.service

# Configure services
echo "[*] Configuring required services..."
doas rc-update add libvirt-guests default
doas rc-update add libvirtd default
doas rc-update add spice-vdagentd default
doas rc-update add xenconsoled default
doas rc-update add xendomains default 
doas rc-update add xenqemu default
doas rc-update add xenstored default
sleep 2

# Clean up
echo "[*] Cleaning up..."

echo "[*] Removing the temporary Xen UKI..."
sudo shred --force --remove=wipesync --verbose --zero /tmp/xen.efi

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
echo "[*] Work done. Exiting..."
exit 0
