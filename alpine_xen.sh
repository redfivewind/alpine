function arg_err {
    echo "[X] ERROR: The target hard disk must be passed as the first and only argument."
    echo "[*] Usage: sh $0 <target_disk>"
    exit 1
}

function fn_01 {
    # German keyboard layout
    echo "[*] Loading German keyboard layout..."
    setup-keymap de de

    # Network time synchronisation
    echo "[*] Enabling network time synchronization..."
    setup-ntp busybox
    
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

    # Configure apk
    echo "[*] Configuring apk enabling the Alpine community repository..."
    setup-apkrepos -c -f

    # Install required packages
    apk add bridge cryptsetup e2fsprogs efibootmgr grub grub-efi lsblk lvm2 sgdisk xen-hypervisor
    
    # Partitioning (GPT parititon table)
    echo "[*] Partitioning the HDD/SSD with GPT partition layout..."
    sgdisk --zap-all $DEV # Wipe verything
    sgdisk --new=1:0:+512M $DEV # Create EFI partition
    sgdisk --new=2:0:0 $DEV # Create LUKS partition
    sgdisk --typecode=1:ef00 --typecode=2:8309 $DEV # Write partition type codes
    sgdisk --change-name=1:efi-sp --change-name=2:luks $DEV # Label partitions
    sgdisk --print $DEV # Print partition table
    partprobe $DEV
    sleep 2
    
    # LUKS 
    echo "[*] Formatting the second partition as LUKS crypto partition..."
    echo -n $LUKS_PASS | cryptsetup luksFormat $PART_LUKS --type luks1 -c twofish-xts-plain64 -h sha512 -s 512 --iter-time 10000 -
    echo -n $LUKS_PASS | cryptsetup luksOpen $PART_LUKS $LVM_LUKS -
    sleep 2
  
    # LVM 
    echo "[*] Setting up LVM..."
    pvcreate /dev/mapper/$LVM_LUKS
    vgcreate $VG_LUKS /dev/mapper/$LVM_LUKS
    lvcreate -L 6144M $VG_LUKS -n $LV_SWAP
    lvcreate -l 100%FREE $VG_LUKS -n $LV_ROOT
    sleep 2
    
    # Format partitions
    echo "[*] Formatting the partitions..."
    mkfs.vfat $PART_EFI
    mkfs.ext4 /dev/mapper/$VG_LUKS-$LV_ROOT
    mkswap /dev/mapper/$VG_LUKS-$LV_SWAP -L $LV_SWAP
    swapon /dev/$VG_LUKS/$LV_SWAP
    sleep 2
    
    # Mount root, boot and swap
    echo "[*] Mounting filesystems..."
    mount -t ext4 /dev/$VG_LUKS/$LV_ROOT /mnt
    mkdir -p /mnt/boot/efi
    mount -t vfat $PART_EFI /mnt/boot/efi
    sleep 2

    # Install Alpine
    setup-disk -m sys /mnt/

    # Set mkinitfs settings & modules
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

    # FIXME: efibootmgr & GRUB
    echo "[*] Configuring GRUB for encrypted boot..."
    chroot /mnt apk add efibootmgr grub grub-efi
    echo "GRUB_ENABLE_CRYPTODISK=y" >> /mnt/etc/default/grub
    echo "GRUB_PRELOAD_MODULES=\"cryptodisk luks lvm part_gpt\"" >> /mnt/etc/default/grub
    tail /mnt/etc/default/grub
    sleep 2

    '''echo "set crypto_uuid=$(cryptsetup luksUUID $PART_LUKS)" > /mnt/root/grub-pre.cfg
    echo "cryptomount -u $crypto_uuid" >> /mnt/root/grub-pre.cfg
    echo "set root='lvmid/<YYYY>/<ZZZZ>'" >> /mnt/root/grub-pre.cfg
    echo "set prefix=($root)/boot/grub" >> /mnt/root/grub-pre.cfg
    echo "insmod normal" >> /mnt/root/grub-pre.cfg
    echo "normal" >> /mnt/root/grub-pre.cfg'''

    echo "[*] Installing GRUB..."
    arch-chroot /mnt /bin/bash -c "\
        mkinitcpio -P $KERNEL;\
        grub-install --target=x86_64-efi --efi-directory=/boot/efi;\
        grub-mkconfig -o /boot/grub/grub.cfg;\
        chmod 700 /boot"
    sleep 2
    
    # FIXME: Install base packages
    echo "[*] Bootstrapping Arch Linux into /mnt with base packages..."
    ''':pacstrap /mnt \
        amd-ucode \
        base \
        base-devel \
        dhcpcd \
        gptfdisk \
        grub \
        gvfs \
        intel-ucode \
        iptables-nft \
        iwd \
        $KERNEL \
        linux-firmware \
        lvm2 \
        mkinitcpio \
        nano \
        networkmanager \
        net-tools \
        p7zip \
        pavucontrol \
        pulseaudio \
        pulseaudio-alsa \
        rkhunter \
        sudo \
        thermald \
        tlp \
        unrar \
        unzip \
        wpa_supplicant \
        zip
    sleep 2'''
    
    # FIXME: German keyboard layout
    '''echo "[*] Loading German keyboard layout..."
    arch-chroot /mnt /bin/bash -c "\
        loadkeys de-latin1;\
        localectl set-keymap de"
    sleep 2'''
  
    # FIXME: Network time synchronisation
    '''echo "[*] Enabling network time synchronization..."
    arch-chroot /mnt /bin/bash -c "\
        timedatectl set-ntp true"
    sleep 2'''

    # FIXME: System update
    '''echo "[*] Updating the system..."
    arch-chroot /mnt /bin/bash -c "\
        pacman --disable-download-timeout --noconfirm -Scc;\
        pacman --disable-download-timeout --noconfirm -Syyu"
    sleep 2'''
    
    # FIXME: Time
    '''echo "[*] Setting the timezone and hardware clock..."
    arch-chroot /mnt /bin/bash -c "\
        timedatectl set-timezone Europe/Berlin;\
        ln /usr/share/zoneinfo/Europe/Berlin /etc/localtime;\
        hwclock --systohc --utc"
    sleep 2'''
    
    # FIXME: Locale
    '''echo "[*] Initializing the locale..."
    arch-chroot /mnt /bin/bash -c "\
        echo \"en_US.UTF-8 UTF-8\" > /etc/locale.gen;\
        locale-gen;\
        echo \"LANG=en_US.UTF-8\" > /etc/locale.conf;\
        export LANG=en_US.UTF-8;\
        echo \"KEYMAP=de-latin1\" > /etc/vconsole.conf;\
        echo \"FONT=lat9w-16\" >> /etc/vconsole.conf"'''
    
    # FIXME: Network
    '''echo "[*] Setting hostname and /etc/hosts..."
    echo $HOSTNAME > /mnt/etc/hostname
    echo "127.0.0.1 localhost" > /mnt/etc/hosts
    echo "::1 localhost" >> /mnt/etc/hosts
    arch-chroot /mnt /bin/bash -c "\
        systemctl enable dhcpcd"'''

    # FIXME: mkinitcpio
    '''echo "[*] Adding the LUKS partition to /etc/crypttab..."
    printf "${LVM_LUKS}\tUUID=%s\tnone\tluks\n" "$(cryptsetup luksUUID $PART_LUKS)" | tee -a /mnt/etc/crypttab
    cat /mnt/etc/crypttab

    # FIXME: Home user
    '''echo "[*] Adding a generic home user: '$USER_NAME'..."
    arch-chroot /mnt /bin/bash -c "\
        useradd -m -G wheel,users $USER_NAME"
    
    echo "[*] Granting sudo rights to the home user..."
    echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers
    echo "@includedir /etc/sudoers.d" >> /mnt/etc/sudoers

    echo "[*] Setting the home user password..."
    echo -n "$USER_NAME:$USER_PASS" | chpasswd -R /mnt
    sleep 2'''

    # FIXME: Start services
    '''echo "Enabling system services..."
    arch-chroot /mnt /bin/bash -c "\
        sudo systemctl enable dhcpcd.service;\
        sudo systemctl enable fstrim.timer;\
        sudo systemctl enable NetworkManager.service;\
        sudo systemctl enable systemd-timesyncd.service;\
        sudo systemctl enable thermald;\
        sudo systemctl enable tlp.service;\
        sudo systemctl enable wpa_supplicant.service"
    sleep 2'''
    
    # Add user paths & scripts
    mkdir -p /mnt/home/$USER_NAME/tools
    mkdir -p /mnt/home/$USER_NAME/workspace

    #FIXME: Update script

    '''arch-chroot /mnt /bin/bash -c "\
        chown -R $USER_NAME:users /home/$USER_NAME"'''

    # Synchronise & unmount everything
    sync
    umount -a

    # Exit message
    echo "[*] Work done. Returning..."
}

# Global variables
echo "[*] Initializing global variables..."
DEV="$1" # Harddisk
LUKS_PASS="" # LUKS FDE password
LV_ROOT="root" # Label & name of the root partition
LV_SWAP="swap" # Label & name of the swap partition
LVM_LUKS="lvm_luks" # LUKS LVM
PART_EFI="${DEV}p1" # EFI partition
PART_LUKS="${DEV}p2" # LUKS partition
SCRIPT=$(readlink -f "$0") # Absolute script path
USER_NAME="user" # Username
USER_PASS="" # Home user password
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
        elif [[ $DEV == "/dev/hd"* ]]; then
            PART_EFI="${DEV}1"
            PART_LUKS="${DEV}2"
        elif [[ $DEV == "/dev/sd"* ]]; then
            PART_EFI="${DEV}1"
            PART_LUKS="${DEV}2"
        elif [[ $DEV == "/dev/vd"* ]]; then
            PART_EFI="${DEV}1"
            PART_LUKS="${DEV}2"
        else
            echo "[X] ERROR: Currently only nvme*, hd*, sd* and vd* harddisks are allowed. Please edit the script manually."
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

fn_01
