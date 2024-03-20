# ARGUMENT: ---Audio---
# ARGUMENT: ---Bluetooth---
# ARGUMENT: ---Network (Broadband, Ethernet, General, WiFi, ...)---

# TODO: Base: Hardening
# TODO: DE Xfce: Automatic sleep/hibernate & resume
# TODO: DE Xfce: Add keyboard shortcut WIN+L
# TODO: DE Xfce: Remove keyboard shortcut CTRL+ALT+L

disk_layout_bios() {
    echo "[*] Partitioning the target disk using MBR partition layout..."
    parted $DISK mktable msdos
    sudo parted $DISK mkpart primary ext4 0% 100%
    sudo parted $DISK name 1 $LUKS_LABEL
}

disk_layout_uefi() {
    echo "[*] Partitioning the target disk using GPT partition layout..."
    parted $DISK mktable gpt
    sudo parted $DISK mkpart primary fat32 1MiB 512MiB set 1 boot on set 1 esp on
    sudo parted $DISK name 1 $EFI_LABEL
    sudo parted $DISK mkpart primary ext4 512MiB 100%
    sudo parted $DISK name 2 $LUKS_LABEL
}

grub_install_bios() {
    chroot /mnt grub-install --target=i386-pc $DISK
}

grub_install_uefi() {
    chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi $DISK
}

print_usage() {
    echo "[*] Usage: ./alpine.sh <Platform: bios/uefi/uefi-sb> <Mode: host/virt> <Hypervisor: none/kvm/xen> <Disk> <Environment: none/xfce>"
}

# Start message
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Global variables
echo "[*] Initializing global variables..."
DISK=""
EFI_LABEL="efi-sp"
LUKS_LABEL="luks"
LUKS_LVM="luks_lvm"
LUKS_PASS=""
LV_ROOT="lv_root"
LV_SWAP="lv_swap"
LVM_VG="lvm_vg"
MODE=""
PART_EFI=""
PART_LUKS=""
PLATFORM=""
USER_NAME="user"
USER_PASS=""

# Argument parsing
if [ $0 == "bios" ];
then
    disk_layout_bios
elif [ $0 == "uefi" ];
then
    disk_layout_uefi
elif [ $0 == "uefi-sb" ];
then
    disk_layout_uefi
else
    echo "[X] ERROR: The passed platform is '$0' must be 'bios', 'uefi' oder 'uefi-sb'. Returning..."
    print_usage
    return
fi

if [ $1 == "core" ];
then
    echo "[*] Mode: '$1'"
    #FIXME
elif [ $1 == "virt" ];
then
    echo "[*] Mode: '$1'"
    #FIXME
else
    echo "[X] ERROR: The passed mode is '$1' but must be 'core' or 'virt'."
    print_usage
    return
fi

if [ $2 == "none" ];
then
    echo "[*] Hypervisor: '$2'"
    #FIXME
elif [ $2 == "kvm" ];
then
    echo "[*] Hypervisor: '$2'"
    #FIXME
elif [ $2 == "xen" ];
then
    echo "[*] Hypervisor: '$2'"
    #FIXME
else
    echo "[X] ERROR: The passed hypervisor is '$2' but must be 'none', 'kvm' or 'xen'."
    print_usage
    return
fi

if [ -e "$3" ]; then
    echo "[*] Path '$3' exists."

    if [ -b "$3" ]; then
        echo "[*] '$3' is a valid block device."     
        DISK=$3

        if [[ $DISK == "/dev/nvme*" ]]; then
              echo "[*] Target disk seems to be a NVME disk."
              PART_EFI="${DEV}p1"
              PART_LUKS="${DEV}p2"
        else
              PART_EFI="${DEV}1"
              PART_LUKS="${DEV}2"
        fi

        echo "[*] Target EFI partition: $PART_EFI."
        echo "[*] Target LUKS partition: $PART_LUKS."
    else
        echo "[X] ERROR: '$3' is not a valid block device."
        exit 1
    fi
else
    echo "[X] ERROR: Path '$3' does not exist."
fi

# Retrieve the LUKS & user password
echo "[*] Please enter the LUKS password: "
read -s luks_pass_a
echo "[*] Please reenter the LUKS password: "
read -s luks_pass_b

if [ "$luks_pass_a" == "$luks_pass_b" ]; then
    LUKS_PASS=$luks_pass_a
else
    echo "[X] ERROR: The LUKS passwords do not match."
    exit 1
fi

echo "[*] Please enter the user password: "
read -s user_pass_a
echo "[*] Please reenter the user password: "
read -s user_pass_b

if [ "$user_pass_a" == "$user_pass_b" ]; then
    USER_PASS=$user_pass_a
else
    echo "[X] ERROR: The user passwords do not match."
    exit 1
fi

# User management
echo "[*] Setting up a standard user..."
setup-user -a -f "$USER_NAME" $USER_NAME
sleep 2

# Set the hostname
echo "[*] Setting the hostname..."
setup-hostname workstation

# Set the timezone
echo "[*] Setting the timezone..."
setup-timezone Europe/Berlin

# Network time synchronisation
echo "[*] Enabling network time synchronization..."
setup-ntp busybox

# Disable SSHD
echo "[*] Disabling SSHD..."
setup-sshd none

# Configure apk
echo "[*] Configuring apk & enabling the Alpine community repository..."
setup-apkrepos -c -f

# Install required packages
echo "[*] Installing required packages..."
apk add cryptsetup \
    e2fsprogs \
    file \    
    lsblk \
    lvm2 \
    nano \
    parted \
    p7zip \
    tlp \
    unzip \
    zip
sleep 2

# Setup udev as devd
echo "[*] Setting up udev as devd..."
setup-devd udev

# Partitioning
if [ $MODE == "bios" ];
then
    disk_layout_bios
elif [ $MODE == "uefi" ];
then
    disk_layout_uefi
elif [ $MODE == "uefi-sb" ];
then
    disk_partitioning_uefi
else
    echo "[X] ERROR: Provided mode is '$MODE', but must be 'bios', 'uefi' or 'uefi-sb'. This is unexpected behaviour. Returning..."
    return
fi

for i in $(seq 10)
    do echo "[*] Populating the kernel partition tables ($i/10)..." && partprobe $DISK && sleep 1
done

# Setup LUKS partition
echo "[*] Formatting the second partition as a LUKS crypto partition..."
echo -n $LUKS_PASS | cryptsetup luksFormat $PART_LUKS --type luks1 -c twofish-xts-plain64 -h sha512 -s 512 --iter-time 10000 -
echo -n $LUKS_PASS | cryptsetup luksOpen $PART_LUKS $LUKS_LVM -
sleep 2

# Setup LVM within LUKS partition
echo "[*] Setting up LVM..."
pvcreate /dev/mapper/$LUKS_LVM
vgcreate $LVM_VG /dev/mapper/$LUKS_LVM
lvcreate -L 6144M $LVM_VG -n $LV_SWAP
lvcreate -l 100%FREE $LVM_VG -n $LV_ROOT
sleep 2

# Format logical volumes
echo "[*] Formatting the partitions..."
mkfs.vfat $PART_EFI
mkfs.ext4 /dev/mapper/$LVM_VG-$LV_ROOT
mkswap /dev/mapper/$LVM_VG-$LV_SWAP -L $LV_SWAP
swapon /dev/$LVM_VG/$LV_SWAP
sleep 2

# Mount #FIXME
echo "#FIXME"
#FIXME
sleep 2

# Install Alpine
echo "[*] Installing Alpine Linux..."
setup-disk -m sys /mnt/

# Set mkinitfs settings & modules
echo "[*] Adding LVM and crypto modules to mkinitfs..."
echo "features=\"ata base ide scsi usb virtio ext4 lvm nvme keymap cryptsetup cryptkey resume\"" | tee /mnt/etc/mkinitfs/mkinitfs.conf
mkinitfs -c /mnt/etc/mkinitfs/mkinitfs.conf -b /mnt/ $(ls /mnt/lib/modules/)

# Mount required filesystems
echo "[*] Mounting required filesystems..."
mount -t proc /proc /mnt/proc
mount --rbind /dev /mnt/dev
mount --make-rslave /mnt/dev
mount --rbind /sys /mnt/sys

# Set 'noatime' within the fstab
echo "[*] Setting 'noatime' within the fstab file..."
sed -i 's/relatime/noatime/g' /mnt/etc/fstab
cat /mnt/etc/fstab
sleep 2

# Setup GRUB
echo "[*] Configuring GRUB for encrypted boot..."
chroot /mnt apk add efibootmgr grub grub-efi
echo "GRUB_ENABLE_CRYPTODISK=y" >> /mnt/etc/default/grub
echo "GRUB_PRELOAD_MODULES=\"cryptodisk luks lvm part_gpt\"" >> /mnt/etc/default/grub
sed -i 's/GRUB_TIMEOUT=2/GRUB_TIMEOUT=10/' /mnt/etc/default/grub
tail /mnt/etc/default/grub
sleep 2

echo "[*] Installing GRUB..."
if [ $MODE == "bios" ];
then
    grub_install_bios
elif [ $MODE == "uefi" ];
then
    grub_install_uefi
elif [ $MODE == "uefi-sb" ];
then
    grub_install_uefi
else
    echo "[X] ERROR: Provided mode is '$MODE', but must be 'bios', 'uefi' or 'uefi-sb'. This is unexpected behaviour. Returning..."
    return
fi

chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
chroot /mnt chmod 700 /boot
sleep 2

# Configure required services
echo "[*] Configuring required services..."
chroot /mnt rc-update add tlp default
sleep 2  

# User security
echo "[*] Disabling the root account..."
chroot /mnt passwd -l root

echo "[*] Setting the user password..."
echo -n "$USER_NAME:$USER_PASS" | chpasswd -R /mnt

echo "[*] Adding the user to required groups..."
chroot /mnt addgroup -S netdev
chroot /mnt adduser $USER_NAME netdev
chroot /mnt addgroup -S plugdev
chroot /mnt adduser $USER_NAME plugdev

# Add user paths & scripts
echo "[*] Adding user paths & scripts..."
mkdir -p /mnt/home/$USER_NAME/pictures
mkdir -p /mnt/home/$USER_NAME/tools
mkdir -p /mnt/home/$USER_NAME/workspace
chroot /mnt chown -R $USER_NAME:users /home/$USER_NAME/   

# Stop message
echo "[*] Work done. Returning..."
return
