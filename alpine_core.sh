#TODO: Lowercase

# Warning message
echo "[!] ALERT: This script will potentially wipe all of your data."

# Global variables
echo "[*] Initializing global variables..."
DEV=""
EFI_UKI="/boot/efi/EFI/alpine.efi"
LUKS_PASS=""
LV_ROOT="lv_root"
LV_SWAP="lv_swap"
LVM_VG="lvm_vg"
LUKS_LVM="luks_lvm"
PART_EFI=""
PART_EFI_LABEL="efi-sp"
PART_LUKS=""
PART_LUKS_LABEL="luks"
UEFI=""
USER_NAME="user"
USER_PASS=""

# German keyboard layout
echo "[*] Loading German keyboard layout..."
setup-keymap de de

# Select platform
echo "[*] Please select the plaform ('bios' or 'uefi'): "
read platform
platform=$(echo "$platform" | tr '[:upper:]' '[:lower:]')

if [ "$platform" == "bios" ];
then
    echo "[*] Platform: '$platform'..."
    UEFI=0
elif [ "$platform" == "uefi" ];
then
    echo "[*] Platform: '$platform'..."
    UEFI=1
else
    echo "[X] ERROR: Variable 'platform' is '$platform' but must be 'bios' or 'uefi'. Exiting..."
    exit 1
fi

# Select disk
echo "[*] Retrieving available disks..."
echo
fdisk -l
echo
echo "[*] Please select the disk where Alpine Linux should be installed into: "
read disk

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
    
            if (echo "$DISK" | grep -q "^/dev/mmc"); 
            then
                echo "[*] Target disk seems to be a MMC disk."

                if [ "$UEFI" == 0 ];
                then
                    PART_EFI="- (BIOS installation)"
                    PART_LUKS="${DISK}p1"
                elif [ "$UEFI" == 1 ];
                then
                    PART_EFI="${DISK}p1"
                    PART_LUKS="${DISK}p2"
                else
                    echo "[X] ERROR: Variable 'UEFI' is '$UEFI' but must be 0 or 1. This is unexpected behaviour. Exiting..."
                    exit 1
                fi
            elif (echo "$DISK" | grep -q "^/dev/nvme"); 
            then
                echo "[*] Target disk seems to be a NVME disk."
    
                if [ "$UEFI" == 0 ];
                then
                    PART_EFI="- (BIOS installation)"
                    PART_LUKS="${DISK}p1"
                elif [ "$UEFI" == 1 ];
                then
                    PART_EFI="${DISK}p1"
                    PART_LUKS="${DISK}p2"
                else
                    echo "[X] ERROR: Variable 'UEFI' is '$UEFI' but must be 0 or 1. This is unexpected behaviour. Exiting..."
                    exit 1
                fi
            else
                if [ "$UEFI" == 0 ];
                then
                    PART_EFI="- (BIOS installation)"
                    PART_LUKS="${DISK}1"
                elif [ "$UEFI" == 1 ];
                then
                    PART_EFI="${DISK}1"
                    PART_LUKS="${DISK}2"
                else
                    echo "[X] ERROR: Variable 'UEFI' is '$UEFI' but must be 0 or 1. This is unexpected behaviour. Exiting..."
                    exit 1
                fi
            fi
    
            echo "[*] Target EFI partition: $PART_EFI."
            echo "[*] Target LUKS partition: $PART_LUKS."
        else
            echo "[X] ERROR: '$DISK' is not a valid block device. Exiting..."
            exit 1
        fi
    else
        echo "[X] ERROR: Path '$DISK' does not exist. Exiting..."
        exit 1
    fi
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

# Setup udev as devd
echo "[*] Setting up udev as devd..."
setup-devd udev

# Install required packages
echo "[*] Installing required packages..."
apk add amd-ucode \
    cryptsetup \
    e2fsprogs \
    file \
    intel-ucode \
    iwd \
    lsblk \
    lvm2 \
    nano \
    parted
sleep 2

# Disk partitioning
echo "[*] Partitioning the disk..."

if [ "$UEFI" == 0 ];
then
    echo "[*] Partitioning the target disk using MBR partition layout..."
    parted $DISK --script mktable msdos

    echo "[*] Creating the LUKS partition..."
    parted $DISK --script mkpart primary ext4 0% 100%
    parted $DISK --script set 1 boot on

    echo "[*] Formatting the LUKS partition..."
    echo -n $LUKS_PASS | cryptsetup luksFormat $PART_LUKS --type luks1 -c twofish-xts-plain64 -h sha512 -s 512 --iter-time 10000 -
    echo -n $LUKS_PASS | cryptsetup luksOpen $PART_LUKS $LUKS_LVM -
    sleep 2

    echo "[*] Synchronising..."
    sync
elif [ "$UEFI" == 1 ];
then
    echo "[*] Partitioning the target disk using GPT partition layout..."
    parted $DISK --script mktable gpt

    echo "[*] Creating the EFI partition..."
    parted $DISK --script mkpart primary fat32 1MiB 512MiB 
    parted $DISK --script set 1 boot on 
    parted $DISK --script set 1 esp on
    parted $DISK --script name 1 $PART_EFI_LABEL

    echo "[*] Formatting the EFI partition..."
    mkfs.vfat $PART_EFI

    echo "[*] Creating the LUKS partition..."
    parted $DISK --script mkpart primary ext4 512MiB 100%
    parted $DISK --script name 2 $PART_LUKS_LABEL

    echo "[*] Formatting the LUKS partition..."
    echo -n $LUKS_PASS | cryptsetup luksFormat $PART_LUKS --type luks2 -c twofish-xts-plain64 -h sha512 -s 512 --iter-time 10000 -
    echo -n $LUKS_PASS | cryptsetup luksOpen $PART_LUKS $LUKS_LVM -
    sleep 2

    echo "[*] Synchronising..."
    sync
else
    echo "[X] ERROR: Variable 'UEFI' is '$UEFI' but must be 0 or 1. Exiting..."
    exit 1
fi

for i in $(seq 10)
do 
    echo "[*] Populating the kernel partition tables ($i/10)..."
    partprobe $DISK
    sync
    sleep 1
done

parted $DISK print

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

# SETUP BOOT ENVIRONMENT
echo "[*] Setting up the boot environment..."

echo "[*] Updating the kernel cmdline..."
KERNEL_CMDLINE="cryptdevice=UUID=$(cryptsetup luksUUID $PART_LUKS):$LUKS_LVM root=/dev/$LVM_VG/$LV_ROOT rw"
mkdir -p /mnt/etc/kernel
echo "$KERNEL_CMDLINE" > /mnt/etc/kernel/cmdline
    
if [ "$UEFI" == 0 ];
then    
    echo "[*] Installing the GRUB2 package..."
    chroot /mnt grub grub-efi

    echo "[*] Preapring GRUB2 to support booting from the LUKS partition..."
    echo "GRUB_ENABLE_CRYPTODISK=y" >> /mnt/etc/default/grub
    sed -i 's/GRUB_CMDLINE_LINUX=""/#GRUB_CMDLINE_LINUX=""/' /mnt/etc/default/grub
    #echo "GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$(cryptsetup luksUUID $PART_LUKS):$LUKS_LVM root=/dev/$LVM_VG/$LV_ROOT\"" >> /mnt/etc/default/grub
    echo "GRUB_CMDLINE_LINUX=\"$KERNEL_CMDLINE\"" >> /mnt/etc/default/grub
    echo "GRUB_PRELOAD_MODULES=\"cryptodisk part_msdos\"" >> /mnt/etc/default/grub
    tail /mnt/etc/default/grub
    sleep 2
    
    echo "[*] Installing GRUB2 to disk...\"
    chroot /mnt grub-install $DISK
    
    echo "[*] Generating a GRUB2 configuration file..."
    chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg"
elif [ "$UEFI" == 1 ];
then
    echo "[*] Installing required packages..."
    chroot /mnt apk add efibootmgr gummiboot sbctl

    echo "[*] Generating signing keys for UEFI Secure Boot..."
    chroot /mnt sbctl create-keys

    echo '[*] Enrolling the signing keys for UEFI Secure Boot...'
    chroot /mnt sbctl enroll-keys --ignore-immutable --microsoft
    
    echo '[*] Generating a unified kernel image for Alpine Linux...'
    chroot /mnt sbctl bundle --amducode /boot/amd-ucode.img \
        --cmdline /etc/kernel/cmdline \
        --initramfs /boot/initramfs-lts \
        --intelucode /boot/intel-ucode.img \
        --kernel-img /boot/vmlinuz-lts \
        --save \
        $EFI_UKI

    echo '[*] Signing the unified kernel image...'
    chroot /mnt sbctl sign $EFI_UKI
    
    echo '[*] Creating a boot entry...'
    chroot /mnt efibootmgr --disk $DISK --part 1 --create --label 'alpine' --load '\EFI\alpine.efi' --unicode --verbose
    chroot /mnt efibootmgr -v
    sleep 3"
else
    echo "[X] ERROR: Variable 'UEFI' is "$UEFI" but must be 0 or 1. Exiting..."
    exit 1
fi

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
chroot /mnt rc-update add hwdrivers sysinit
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

echo "doas apk upgrade" > /mnt/home/$USER_NAME/tools/update.sh
echo "doas sbctl generate-bundles" >> /mnt/home/$USER_NAME/tools/update.sh
echo "doas sbctl sign $EFI_UKI" >> /mnt/home/$USER_NAME/tools/update.sh

chroot /mnt chown -R $USER_NAME:users /home/$USER_NAME/    

# Synchronise & signal completion
sync
echo "[*] Work done. Returning..."
