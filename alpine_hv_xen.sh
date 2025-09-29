# Start message
echo "[*] This script installs the Xen virtualisation infrastructure on Alpine Linux."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Global variables
echo "[*] Initialising global variables..."
DISK=""
KERNEL_INITRAMFS=""
KERNEL_VMLINUZ=""
TMP_XEN_CFG="/tmp/xen.cfg"
TMP_XEN_EFI="/tmp/xen.efi"
TMP_XSM_CFG="/tmp/xsm.cfg"
USER_NAME=$(whoami)
XEN_EFI="/boot/efi/EFI/xen.efi"

# Check user rights
if [ $(id -u) == "0" ];
then
    echo "[*] User has elevated rights. Continuing..."
else
    echo "[X] ERROR: The scripts must be run with elevated rights."
    exit 1
fi

# Prompt for the system disk
echo "[*] Please enter the system disk: "
read disk
disk=$(echo "$disk" | tr '[:upper:]' '[:lower:]')

if [ -z "$disk" ];
then
    echo "[X] ERROR: No disk was selected. Exiting..."
    exit 1
else
    DISK="$disk"
    
    if [ -e "$DISK" ]; 
    then
        echo "[*] Path '$DISK' exists."
    
        if [ -b "$DISK" ];
        then
            echo "[*] Path '$DISK' is a valid block device." 
        else
            echo "[X] ERROR: '$DISK' is not a valid block device. Exiting..."
            exit 1
        fi
    else
        echo "[X] ERROR: Path '$DISK' does not exist. Exiting..."
        exit 1
    fi
fi

# Prompt for the Alpine Linux kernel
echo "[*] Please select the kernel ('lts' or 'virt'): "
read kernel
kernel=$(echo "$kernel" | tr '[:upper:]' '[:lower:]')

if [ "$kernel" == "lts" ];
then
    echo "[*] Kernel: '$kernel'..."
    KERNEL_INITRAMFS="initramfs-lts"
    KERNEL_VMLINUZ="vmlinuz-lts"
elif [ "$kernel" == "virt" ];
then
    echo "[*] Kernel: '$kernel'..."
    KERNEL_INITRAMFS="initramfs-virt"
    KERNEL_VMLINUZ="vmlinuz-virt"
else
    echo "[X] ERROR: Variable 'kernel' is '$kernel' but must be 'lts' or 'virt'. Exiting..."
    exit 1
fi

# Install required packages
echo "[*] Installing required packages..."
apk add binutils \
    bridge \
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
echo "xen-blkback" | tee -a /etc/modules
echo "xen-netback" | tee -a /etc/modules
echo "tun" | tee -a /etc/modules

# Enable non-root access to libvirtd
echo "[*] Enabling libvirt access for user '$USER_NAME'..."

echo "[*] Granting non-root access to libvirt to the 'libvirt' group..."
echo "unix_sock_group = \"libvirt\"" | tee -a /etc/libvirt/libvirtd.conf
echo "unix_sock_rw_perms = \"0770\"" | tee -a /etc/libvirt/libvirtd.conf

echo "[*] Adding user '$USER_NAME' to the 'libvirt' group..."
adduser $USER_NAME libvirt

# Configure services
echo "[*] Configuring required services..."
rc-update add libvirt-guests default
rc-update add libvirtd default
rc-update add spice-vdagentd default
rc-update add xenconsoled default
rc-update add xendomains default 
rc-update add xenqemu default
rc-update add xenstored default
sleep 2

# Generate Xen configuration file
echo "[*] Generating the Xen configuration file '$TMP_XEN_CFG'..."

shred -f -z -u $TMP_XEN_CFG
echo '[global]' | tee $TMP_XEN_CFG
echo 'default=alpine-linux' | tee -a $TMP_XEN_CFG
echo '' | tee -a $TMP_XEN_CFG
echo "[alpine-linux]" | tee -a $TMP_XEN_CFG
echo "options=com1=115200,8n1 console=com1,vga flask=disabled guest_loglvl=all iommu=debug,force,verbose loglvl=all noreboot ucode=scan vga=current,keep" | tee -a $TMP_XEN_CFG
#echo "options=console=vga flask=disabled guest_loglvl=all iommu=force,verbose loglvl=all noreboot ucode=scan vga=current,keep" | tee -a $TMP_XEN_CFG
echo "kernel=$KERNEL_VMLINUZ $(cat /etc/kernel/cmdline) console=hvc0 console=tty0 earlyprintk=xen nomodeset" | tee -a $TMP_XEN_CFG
echo "ramdisk=$KERNEL_INITRAMFS" | tee -a $TMP_XEN_CFG
sleep 3

# Generate Xen XSM configuration file
echo "[*] Generating the Xen XSM configuration file '$TMP_XSM_CFG'..."

echo '' | tee $TMP_XSM_CFG #FIXME
sleep 3

# Generate unified Xen kernel image
echo "[*] Generating the unified Xen kernel image (UKI)..."
XEN_SECT_NAME_ARRAY=".pad .config .ramdisk .kernel .ucode"
#.xsm
XEN_SECT_PATH_ARRAY="$TMP_XEN_CFG /boot/$KERNEL_INITRAMFS /boot/$KERNEL_VMLINUZ /boot/intel-ucode.img"
#$TMP_XSM_CFG
cp /usr/lib/efi/xen.efi $TMP_XEN_EFI

while [ -n "$XEN_SECT_PATH_ARRAY" ];
do
    # Retrieve parameters
    set -- $XEN_SECT_NAME_ARRAY
    SECT_NAME_CURRENT=$2
    SECT_NAME_PREVIOUS=$1

    set -- $XEN_SECT_PATH_ARRAY
    SECT_PATH=$1

    # Add new section
    echo "[*] Writing '$SECT_PATH' to the new $SECT_NAME_CURRENT section..."
    OBJDUMP=$(objdump -h "$TMP_XEN_EFI" | grep "$SECT_NAME_PREVIOUS")
    set -- $OBJDUMP
    VMA=$(printf "0x%X" $((((0x$3 + 0x$4 + 4096 - 1) / 4096) * 4096)))
    objcopy --add-section "$SECT_NAME_CURRENT"="$SECT_PATH" --change-section-vma "$SECT_NAME_CURRENT"="$VMA" $TMP_XEN_EFI $TMP_XEN_EFI

    # Update the section name & path array
    XEN_SECT_NAME_ARRAY=$(echo "$XEN_SECT_NAME_ARRAY" | sed 's/^[^ ]* *//')
    XEN_SECT_PATH_ARRAY=$(echo "$XEN_SECT_PATH_ARRAY" | sed 's/^[^ ]* *//')
done

objdump -h $TMP_XEN_EFI
sleep 3

# Copy Xen UKI to EFI partition
echo "[*] Copying the Xen UKI to the EFI partition..."
cp $TMP_XEN_EFI $XEN_EFI

# Sign Xen UKI using sbctl
echo "[*] Signing the Xen UKI using sbctl..."
sbctl sign $XEN_EFI

# Create a UEFI boot entry
echo "[*] Creating a UEFI boot entry for Xen..."
efibootmgr --disk $DISK --part 1 --create --label 'xen' --load '\EFI\xen.efi' --unicode

# Clean up
echo "[*] Cleaning up..."

echo "[*] Removing temporary files..."
#shred -f -z -u $TMP_XEN_CFG
shred -f -z -u $TMP_XEN_EFI
shred -f -z -u $TMP_XSM_CFG

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
echo "[*] Work done. Exiting..."
exit 0
