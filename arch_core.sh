function arg_err {
    echo "[X] ERROR: The target hard disk must be passed as the first argument, while the second argument is optional and specifies the mode (0/1)."
    echo "[*] Usage: sh $0 <target_disk> [<mode (0/1)>]"
    exit 1
}

function fn_01 {
    # German keyboard layout
    echo "[*] Loading German keyboard layout..."
    loadkeys de-latin1
    localectl set-keymap de
  
    # Network time synchronisation
    echo "[*] Enabling network time synchronization..."
    timedatectl set-ntp true # Enable network time synchronization
    
    # Partitioning (GPT parititon table)
    echo "[*] Partitioning the HDD/SSD with GPT partition layout..."
    sgdisk --zap-all $DEV # Wipe verything
    sgdisk --new=1:0:+512M $DEV # Create EFI partition
    sgdisk --new=2:0:0 $DEV # Create LUKS partition
    sgdisk --typecode=1:ef00 --typecode=2:8309 $DEV # Write partition type codes
    sgdisk --change-name=1:efi-sp --change-name=2:luks $DEV # Label partitions
    sgdisk --print $DEV # Print partition table
    sleep 2
    
    # LUKS 
    echo "[*] Formatting the second partition as LUKS crypto partition..."
    cryptsetup luksFormat $PART_LUKS --type luks1 -c twofish-xts-plain64 -h sha512 -s 512 --iter-time 10000 # Format LUKS partition
    cryptsetup luksOpen $PART_LUKS $LVM_LUKS # Open LUKS partition
    sleep 2
  
    # LVM 
    echo "[*] Setting up LVM..."
    pvcreate /dev/mapper/$LVM_LUKS # Create physical volume
    vgcreate $VG_LUKS /dev/mapper/$LVM_LUKS # Create volume group
    lvcreate -L 6144M $VG_LUKS -n $LV_SWAP # Create logical swap volume
    lvcreate -l 100%FREE $VG_LUKS -n $LV_ROOT # Create logical root volume
    sleep 2
    
    # Format partitions
    echo "[*] Formatting the partitions..."
    mkfs.fat -F32 $PART_EFI # EFI partition (FAT32)
    mkfs.ext4 /dev/mapper/$VG_LUKS-$LV_ROOT -L $LV_ROOT # Root partition (ext4)
    mkswap /dev/mapper/$VG_LUKS-$LV_SWAP -L $LV_SWAP # Swap partition
    swapon /dev/$VG_LUKS/$LV_SWAP # Activate swap partition
    sleep 2
    
    # Mount root, boot and swap
    echo "[*] Mounting filesystems..."
    mount /dev/$VG_LUKS/$LV_ROOT /mnt # Mount root partition
    mkdir -p /mnt/boot/efi # Create folder to hold /boot/efi files
    mount $PART_EFI /mnt/boot/efi # Mount EFI partition
    sleep 2
    
    # Install base packages
    echo "[*] Bootstrapping Arch Linux into /mnt with base packages..."
    pacman --disable-download-timeout --noconfirm -Scc
    pacman --disable-download-timeout --noconfirm -Syy
    pacstrap /mnt amd-ucode base base-devel dhcpcd gptfdisk grub gvfs intel-ucode iptables-nft iwd linux-hardened linux-firmware lvm2 mkinitcpio nano networkmanager net-tools p7zip pavucontrol pulseaudio pulseaudio-alsa rkhunter sudo thermald tlp unrar unzip wpa_supplicant zip
    sleep 2
    
    # Mount or create necessary entry points
    echo "[*] Mounting necessary filesystems..."
    mount -t proc proc /mnt/proc
    mount -t sysfs sys /mnt/sys
    mount -o bind /dev /mnt/dev
    mount -t devpts /dev/pts /mnt/dev/pts/
    mount -o bind /sys/firmware/efi/efivars /mnt/sys/firmware/efi/efivars    
    sleep 2
    
    # fstab
    echo "[*] Generating fstab file and setting 'noatime'..."
    genfstab -U /mnt > /mnt/etc/fstab # Generate fstab file
    sed -i 's/relatime/noatime/g' /mnt/etc/fstab # Replace 'relatime' with 'noatime' (Access time will not be saved in files)
    sleep 2

    # Enter new system root
    echo "[!] ALERT: Entering the new system root..."
    cp $SCRIPT /mnt
    SCRIPT=$(basename $SCRIPT)
    arch-chroot /mnt /bin/bash -c "sh $SCRIPT $DEV 1"
}

function fn_02 {
    # Securely overwrite the script file
    echo "[*] Securely overwriting the temporary script file..."    
    SIZE=$(stat -c%s $0)
    dd if=/dev/urandom of=$0 bs=1 count=$SIZE status=progress
    rm -f $0
    sleep 2
    
    # German keyboard layout
    echo "[*] Loading German keyboard layout..."
    loadkeys de-latin1
    localectl set-keymap de
    sleep 2
  
    # Network time synchronisation
    echo "[*] Enabling network time synchronization..."
    timedatectl set-ntp true # Enable network time synchronization
    
    # System update
    echo "[*] Updating the system..."
    pacman --disable-download-timeout --noconfirm -Scc
    pacman --disable-download-timeout --noconfirm -Syyu
    
    # Time
    echo "[*] Setting the timezone and hardware clock..."
    timedatectl set-timezone Europe/Berlin # Berlin timezone
    ln /usr/share/zoneinfo/Europe/Berlin /etc/localtime # Berlin timezone
    hwclock --systohc --utc # Assume hardware clock is UTC
    
    # Locale
    echo "[*] Initializing the locale..."
    timedatectl set-ntp true # Enable NTP time synchronization again
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen # en-US (UTF-8)
    locale-gen # Generate locale
    echo "LANG=en_US.UTF-8" > /etc/locale.conf # Save locale to locale configuration
    export LANG=en_US.UTF-8 # Export LANG variable
    echo "KEYMAP=de-latin1" > /etc/vconsole.conf # Set keyboard layout
    echo "FONT=lat9w-16" >> /etc/vconsole.conf # Set console font
    
    # Network
    echo "[*] Setting hostname and /etc/hosts..."
    echo $HOSTNAME > /etc/hostname # Set hostname
    echo "127.0.0.1 localhost" > /etc/hosts # Hosts file: Localhost (IP4)
    echo "::1 localhost" >> /etc/hosts # Hosts file: Localhost (IP6) 
    systemctl enable dhcpcd

    # mkinitcpio
    echo "[*] Adding the LUKS partition to /etc/crypttab..."
    printf "${LVM_LUKS}\tUUID=%s\tnone\tluks\n" "$(cryptsetup luksUUID $PART_LUKS)" | tee -a /etc/crypttab
    cat /etc/crypttab
    
    echo "[*] Rebuilding initramfs image using mkinitcpio..."
    echo "MODULES=()" > /etc/mkinitcpio.conf
    echo "BINARIES=()" >> /etc/mkinitcpio.conf
    echo "HOOKS=(base udev autodetect modconf kms block filesystems keyboard fsck encrypt lvm2)" >> /etc/mkinitcpio.conf
    mkinitcpio -p linux-hardened # Rebuild initramfs image
    sleep 2
    
    # Users
    echo "[*] Adding a generic home user: '$USER'..."
    useradd -m -G wheel,users $USER # Add new user
    echo "[!] ALERT: Set the home user password!"
    passwd $USER # Set user password
    echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers # Users of group wheel may execute any command
    echo "@includedir /etc/sudoers.d" >> /etc/sudoers
    sleep 2
    
    # efibootmgr & GRUB
    echo "[*] Configuring GRUB for encrypted boot..."
    pacman --noconfirm --disable-download-timeout -Syyu efibootmgr grub # Install packages required for UEFI boot
    echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub # Enable booting from encrypted /boot
    sed -i 's/GRUB_CMDLINE_LINUX=""/#GRUB_CMDLINE_LINUX=""/' /etc/default/grub # Disable default value
    echo "GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$(cryptsetup luksUUID $PART_LUKS):$LVM_LUKS root=/dev/$VG_LUKS/$LV_ROOT\"" >> /etc/default/grub # Add encryption hook to GRUB
    echo "GRUB_PRELOAD_MODULES=\"cryptodisk part_gpt part_msdos\"" >> /etc/default/grub
    tail /etc/default/grub
    sleep 2

    echo "[*] Installing GRUB..."
    mkinitcpio -P linux-hardened
    grub-install --target=x86_64-efi --efi-directory=/boot/efi # Install GRUB --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg # Generate GRUB configuration file
    chmod 700 /boot # Protect /boot
    sleep 2
    
    # Start services
    echo "Starting system services..."
    sudo systemctl enable dhcpcd.service # DHCP
    sudo systemctl enable fstrim.timer # TRIM timer for SSDs
    sudo systemctl enable NetworkManager.service # Network managament
    sudo systemctl enable systemd-timesyncd.service # Time synchronization
    sudo systemctl enable thermald # Thermald
    sudo systemctl enable tlp.service # TLP
    sudo systemctl enable wpa_supplicant.service # Required for WPAx connections
    sleep 2
    
    # Add user paths & scripts
    mkdir -p /home/$USER/tools
    chown -R user:users /home/$USER/tools
    
    echo "# Update all packages" > /home/$USER/tools/update.sh
    echo "sudo pacman --disable-download-timeout --needed --noconfirm -Syyu" >> /home/$USER/tools/update.sh
    echo "yay --disable-download-timeout --needed --noconfirm -Syyu" >> /home/$USER/tools/update.sh
    echo "" >> /home/$USER/tools/update.sh
    echo "# Autoremove packages that are no longer required" >> /home/$USER/tools/update.sh
    echo "sudo pacman --noconfirm -Rns $(pacman -Qdtq)" >> /home/$USER/tools/update.sh
    echo "" >> /home/$USER/tools/update.sh
    echo "# Fix the VSCodium bug" >> /home/$USER/tools/update.sh
    echo "sudo chmod 4755 /opt/vscodium-bin/chrome-sandbox" >> /home/$USER/tools/update.sh
    
    mkdir -p /home/$USER/workspace
    chown -R user:users /home/$USER/workspace
    
    # Synchronise & exit
    sync
    exit
}

# Global variables
echo "[*] Initializing global variables..."
DEV="$1" # Harddisk
LV_ROOT="root" # Label & name of the root partition
LV_SWAP="swap" # Label & name of the swap partition
LVM_LUKS="lvm_luks" # LUKS LVM
PART_EFI="${DEV}p1" # EFI partition
PART_LUKS="${DEV}p2" # LUKS partition
SCRIPT=$(readlink -f "$0")
USER="user" # Username
VG_LUKS="vg_luks" # LUKS volume group

# Interpreting the commandline arguments
if [ "$#" -le 0 ]; then
    arg_err
elif [ "$#" -eq 1 ]; then
    DEV="$1"
    MODE=0
elif [ "$#" -eq 2 ]; then
    DEV="$1"
    MODE=$2
else
    arg_err
fi

if [ -e $DEV ]; then
    if [ -b $DEV ]; then
        echo "[*] Target block device: '$DEV'."

        if [[ $DEV == "/dev/nvme"* ]]; then
            PART_EFI="${DEV}p1"
            PART_LUKS="${DEV}p2"
        elif [[ $DEV == "/dev/sd"* ]]; then
            PART_EFI="${DEV}1"
            PART_LUKS="${DEV}2"
        else
            echo "[X] ERROR: Currently only nvme* and sd* harddisks are allowed. Please edit the script manually."
            exit 1
        fi
    else
        echo "[X] ERROR: The target block device '$DEV' is not a block device."
        exit 1
    fi
else
    echo "[X] ERROR: The target block device '$DEV' doesn't exist."
    exit 1
fi

if [ $MODE -eq 0 ]; then
    echo "[*] Selected mode: $MODE."
    fn_01
elif [ $MODE -eq 1 ]; then
    echo "[*] Selected mode: $MODE."
    fn_02
else
    echo "[X] ERROR: The selected mode is $MODE but must be 0 or 1."
    exit 1
fi
