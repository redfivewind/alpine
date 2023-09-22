# German keyboard layout
echo "Loading German keyboard layout..."
loadkeys de-latin1
localectl set-keymap de

# Global variables
echo "Initializing global variables..."
DEV="/dev/sda" # Harddisk
EFI="/dev/sda1" # EFI partition
LUKS="/dev/sda2" # LUKS partition
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

# LUKS 
echo "Formatting the second partition as LUKS crypto partition..."
cryptsetup luksFormat $LUKS --type luks1 -c twofish-xts-plain64 -h sha512 -s 512 --iter-time 10000 # Format LUKS partition
cryptsetup luksOpen $LUKS lukslvm # Open LUKS partition

# LVM 
echo "Setting up LVM..."
pvcreate /dev/mapper/lukslvm # Create physical volume
vgcreate luksvg /dev/mapper/lukslvm # Create volume group
lvcreate -L 6144M luksvg -n swap # Create logical swap volume
lvcreate -l 100%FREE luksvg -n root # Create logical root volume

# Format partitions
echo "Formatting the partitions..."
mkfs.fat -F32 $EFI # EFI partition (FAT32)
mkfs.ext4 /dev/mapper/luksvg-root -L root # Root partition (EXT4)
mkswap /dev/mapper/luksvg-swap -L swap # Swap partition

# Mount root, boot and swap
echo "Mounting filesystems..."
mount /dev/luksvg/root /mnt # Mount root partition
mkdir -p /mnt/boot/efi # Create folder to hold /boot/efi files
mount $EFI /mnt/boot/efi # Mount EFI partition
swapon /dev/luksvg/swap # Activate swap partition

# Install base packages
echo "Bootstrapping Arch Linux into /mnt with base packages..."
pacman --noconfirm --disable-download-timeout -Syy
pacstrap --noconfirm --disable-download-timeout /mnt amd-ucode base base-devel dhcpcd gptfdisk grub intel-ucode linux-hardened linux-firmware lvm2 mkinitcpio nano networkmanager net-tools p7zip rkhunter sudo thermald tlp unrar unzip wpa_supplicant zip

# Mount or create necessary entry points
mount -t proc proc /mnt/proc
mount -t sysfs sys /mnt/sys
mount -o bind /dev /mnt/dev
mount -t devpts /dev/pts /mnt/dev/pts/
mount -o bind /sys/firmware/efi/efivars /mnt/sys/firmware/efi/efivars

# fstab
echo "Generating fstab file and setting 'noatime'..."
genfstab -U /mnt > /mnt/etc/fstab # Generate fstab file
sed -i 's/relatime/noatime/g' /mnt/etc/fstab # Replace 'relatime' with 'noatime' (Access time will not be saved in files)

# Enter new system chroot
echo "Entering new system root... Run 'arch_base_02.sh' manually!" 
arch-chroot /mnt # /mnt becomes temporary root directory