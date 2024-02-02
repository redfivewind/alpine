# Warning message
echo "[!] ALERT: This script will potentially wipe all of your data."

# Global variables
echo "[*] Initializing global variables..."
DEV=""
LUKS_PASS=""
LV_ROOT="lv_root"
LV_SWAP="lv_swap"
LVM_VG="lvm_vg"
LUKS_LVM="luks_lvm"
PART_EFI=""
PART_LUKS=""
SCRIPT=$(readlink -f "$0")
USER_NAME="user"
USER_PASS=""

# German keyboard layout
echo "[*] Loading German keyboard layout..."
setup-keymap de de

# Retrieve the target disk
echo "[*] Please enter the target disk: "
read dev

if [ -e "$dev" ]; then
    echo "[*] Path '$dev' exists."

    if [ -b "$dev" ]; then
        echo "[*] '$dev' is a valid block device."        
        echo "[*] Setting the EFI-SP & LUKS partition..."
        DEV=$dev

        if [[ $DEV == "/dev/nvme*" ]]; then
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
        echo "[X] ERROR: '$dev' is not a valid block device."
        exit 1
    fi
else
    echo "[*] Path '$dev' does not exist."
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
    efibootmgr \
    file \
    grub \
    grub-efi \
    iwd \
    lsblk \
    lvm2 \
    nano \
    sgdisk
sleep 2

# Setup udev as devd
echo "[*] Setting up udev as devd..."
setup-devd udev

# GPT partitioning
echo "[*] Partitioning the target disk using GPT partition layout..."
sgdisk --zap-all $DEV
sgdisk --new=1:0:+512M $DEV
sgdisk --new=2:0:0 $DEV
sgdisk --typecode=1:ef00 --typecode=2:8309 $DEV
sgdisk --change-name=1:efi-sp --change-name=2:luks $DEV
sgdisk --print $DEV
for i in $(seq 10)
    do echo "[*] Populating the kernel partition tables ($i/10)..." && partprobe $DEV && sleep 1
done        
sleep 2

# Setup LUKS partition
echo "[*] Formatting the second partition as LUKS crypto partition..."
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

# Mount root, EFI and swap volume
echo "[*] Mounting filesystems..."
mount -t ext4 /dev/$LVM_VG/$LV_ROOT /mnt
mkdir -p /mnt/boot/efi
mount -t vfat $PART_EFI /mnt/boot/efi
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
chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi
chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
chroot /mnt chmod 700 /boot
sleep 2

# Install base packages
echo "[*] Installing base packages..."
chroot /mnt apk add alsa-plugins-pulse \
    iptables \
    iwd \
    pulseaudio \
    pulseaudio-alsa \
    p7zip \
    tlp \
    unzip \
    zip
sleep 2

# Configure services
echo "[*] Configuring required services..."
chroot /mnt rc-update add iwd default    
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
mkdir -p /mnt/home/$USER_NAME/Pictures
mkdir -p /mnt/home/$USER_NAME/tools
mkdir -p /mnt/home/$USER_NAME/workspace
chroot /mnt chown -R $USER_NAME:users /home/$USER_NAME/    

# Synchronise & signal completion
sync
echo "[*] Work done. Returning..."
