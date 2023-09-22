# German keyboard layout
echo "Loading German keyboard layout..."
loadkeys de-latin1
localectl set-keymap de

# Global variables
echo "Initializing global variables..."
DEV="/dev/sda" # Harddisk
EFI="/dev/sda1" # EFI partition
LUKS="/dev/sda2" # LUKS partition
LUKS_LVM="lukslvm"
LUKS_VG="luksvg"
ROOT_LABEL="root"
ROOT_NAME="root"
SWAP_LABEL="swap"
SWAP_NAME="swap"
USER="user" # Username

# Connect to network
sudo ip link set enp0s3 up
sudo dhclient enp0s3

# System clock
echo "Enable network time synchronization..."
timedatectl set-ntp true # Enable network time synchronization

# Partitioning (GPT parititon table)
echo "Partitioning the HDD/SSD with GPT partition layout..."
sgdisk --zap-all $DEV # Wipe verything
sgdisk --new=1:0:+512M $DEV # Create EFI partition
sgdisk --new=2:0:0 $DEV # Create LUKS partition
sgdisk --typecode=1:ef00 --typecode=2:8309 $DEV # Write partition type codes
sgdisk --change-name=1:efi-sp --change-name=2:luks $DEV # Label partitions
sgdisk --print $DEV # Print partition table
sleep 1

# LUKS 
echo "Formatting the second partition as LUKS crypto partition..."
cryptsetup luksFormat $LUKS --type luks1 -c twofish-xts-plain64 -h sha512 -s 512 --iter-time 10000 # Format LUKS partition
cryptsetup luksOpen $LUKS $LUKS_LVM # Open LUKS partition
sleep 1

# LVM 
echo "Setting up LVM..."
pvcreate /dev/mapper/$LUKS_LVM # Create physical volume
vgcreate $LUKS_VG /dev/mapper/$LUKS_LVM # Create volume group
lvcreate -L 6144M $LUKS_VG -n $SWAP_NAME # Create logical swap volume
lvcreate -l 100%FREE $LUKS_VG -n $ROOT_NAME # Create logical root volume
sleep 1

# Format partitions
echo "Formatting the partitions..."
mkfs.fat -F32 $EFI # EFI partition (FAT32)
mkfs.ext4 /dev/mapper/$LUKS_VG/$ROOT_NAME -L $ROOT_LABEL # Root partition (ext4)
mkswap /dev/mapper/$LUKS_VG/$SWAP_NAME -L $SWAP_LABEL # Swap partition
sleep 1

# Mount root, boot and swap
echo "Mounting filesystems..."
mount /dev/$LUKS_VG/$ROOT_NAME /mnt # Mount root partition
mkdir -p /mnt/boot/efi # Create folder to hold /boot/efi files
mount $EFI /mnt/boot/efi # Mount EFI partition
swapon /dev/$LUKS_VG/$SWAP_NAME # Activate swap partition
sleep 1

# Install base packages
echo "Bootstrapping Arch Linux into /mnt with base packages..."
pacman --noconfirm --disable-download-timeout -Syy
pacstrap /mnt amd-ucode base base-devel dhcpcd gptfdisk grub intel-ucode linux-hardened linux-firmware lvm2 mkinitcpio nano networkmanager net-tools p7zip rkhunter sudo thermald tlp unrar unzip wpa_supplicant zip
sleep 1

# Mount or create necessary entry points
mount -t proc proc /mnt/proc
mount -t sysfs sys /mnt/sys
mount -o bind /dev /mnt/dev
mount -t devpts /dev/pts /mnt/dev/pts/
mount -o bind /sys/firmware/efi/efivars /mnt/sys/firmware/efi/efivars
sleep 1

# fstab
echo "Generating fstab file and setting 'noatime'..."
genfstab -U /mnt > /mnt/etc/fstab # Generate fstab file
sed -i 's/relatime/noatime/g' /mnt/etc/fstab # Replace 'relatime' with 'noatime' (Access time will not be saved in files)
sleep 1

# Enter new system chroot
echo "Entering new system root... Run 'arch_base_02.sh' manually!" 
arch-chroot /mnt # /mnt becomes temporary root directory
