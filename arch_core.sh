# TODO
# Disk selection
# Clear EFI entries
# Interfaces setup

# German keyboard layout
echo "Loading German keyboard layout..."
loadkeys de-latin1
localectl set-keymap de

# Interpreting the commandline arguments

# Global variables
echo "Initializing global variables..."
DEV="${1}" # Harddisk
LV_ROOT="root" # Label & name of the root partition
LV_SWAP="swap" # Label & name of the swap partition
LVM_LUKS="lvm_luks" # LUKS LVM
PART_EFI="${DEV}p1" # EFI partition
PART_LUKS="${DEV}p2" # LUKS partition
SCRIPT=$(readlink -f "$0")
USER="user" # Username
VG_LUKS="vg_luks" # LUKS volume group

function part_01 {
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
  cryptsetup luksFormat $PART_LUKS --type luks1 -c twofish-xts-plain64 -h sha512 -s 512 --iter-time 10000 # Format LUKS partition
  cryptsetup luksOpen $PART_LUKS $LVM_LUKS # Open LUKS partition
  sleep 1

  # LVM 
  echo "Setting up LVM..."
  pvcreate /dev/mapper/$LVM_LUKS # Create physical volume
  vgcreate $VG_LUKS /dev/mapper/$LVM_LUKS # Create volume group
  lvcreate -L 6144M $VG_LUKS -n $LV_SWAP # Create logical swap volume
  lvcreate -l 100%FREE $VG_LUKS -n $LV_ROOT # Create logical root volume
  sleep 1
  
  # Format partitions
  echo "Formatting the partitions..."
  mkfs.fat -F32 $PART_EFI # EFI partition (FAT32)
  mkfs.ext4 /dev/mapper/$VG_LUKS-$LV_ROOT -L $LV_ROOT # Root partition (ext4)
  mkswap /dev/mapper/$VG_LUKS-$LV_SWAP -L $LV_SWAP # Swap partition
  swapon /dev/$VG_LUKS/$LV_SWAP # Activate swap partition
  sleep 1
  
  # Mount root, boot and swap
  echo "Mounting filesystems..."
  mount /dev/$VG_LUKS/$LV_ROOT /mnt # Mount root partition
  mkdir -p /mnt/boot/efi # Create folder to hold /boot/efi files
  mount $EFI /mnt/boot/efi # Mount EFI partition
  sleep 1
  
  # Install base packages
  echo "Bootstrapping Arch Linux into /mnt with base packages..."
  pacman --noconfirm --disable-download-timeout -Syy
  pacstrap /mnt amd-ucode base base-devel dhcpcd gptfdisk grub gvfs intel-ucode linux-hardened linux-firmware lvm2 mkinitcpio nano networkmanager net-tools p7zip rkhunter sudo thermald tlp unrar unzip wpa_supplicant zip
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
  mkdir /mnt/tmp/
  cp $SCRIPT /mnt/tmp/
  arch-chroot /mnt /bin/bash -c "sh /mnt/tmp/$0 $DEV 1"
}

function 2 {
  
}
