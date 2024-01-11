# Desktop Environment
# Secure Boot
# Resume from hibernation
# Hardening

function arg_err {
    echo "[X] ERROR: The target hard disk must be passed as the first and only argument."
    echo "[*] Usage: sh $0 <target_disk>"
    exit 1
}

function fn_01 {
    # German keyboard layout
    echo "[*] Loading German keyboard layout..."
    setup-keymap de de
    
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
    apk add bridge \
        cryptsetup \
        e2fsprogs \
        efibootmgr \
        file \
        grub \
        grub-efi \
        iwd \
        lsblk \
        lvm2 \
        nano \
        sgdisk \
        xen-qemu

    # Configure Alpine Linux as Xen dom0
    echo "[*] Configuring Alpine Linux as Xen dom0..."
    setup-xen-dom0

    # Set udev as devd
    echo "[*] Setting udev as devd..."
    setup-devd -C udev

    # Setup desktop environment
    echo "[*] Installing Xfce..."
    setup-desktop xfce
    apk add pavucontrol xfce4-pulseaudio-plugin    

    # Setup a standard user
    echo "[*] Setting up a standard user..."
    setup-user -a -g users $USER_NAME
    
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
    vgcreate $VG_LVM /dev/mapper/$LUKS_LVM
    lvcreate -L 6144M $VG_LVM -n $LV_SWAP
    lvcreate -l 100%FREE $VG_LVM -n $LV_ROOT
    sleep 2
    
    # Format logical volumes
    echo "[*] Formatting the partitions..."
    mkfs.vfat $PART_EFI
    mkfs.ext4 /dev/mapper/$VG_LVM-$LV_ROOT
    mkswap /dev/mapper/$VG_LVM-$LV_SWAP -L $LV_SWAP
    swapon /dev/$VG_LVM/$LV_SWAP
    sleep 2
    
    # Mount root, EFI and swap volume
    echo "[*] Mounting filesystems..."
    mount -t ext4 /dev/$VG_LVM/$LV_ROOT /mnt
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
    tail /mnt/etc/default/grub
    sleep 2

    echo "[*] Installing GRUB..."
    chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi
    chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    chroot /mnt chmod 700 /boot
    sleep 2

    # Configure Secure Boot
    #echo "[*] Configuring Secure Boot..."
    #chroot /mnt apk add sbctl
    #chroot /mnt sbctl status
    #chroot /mnt sbctl create-keys
    #chroot /mnt sbctl sign /boot/efi/Alpine/linux-lts.efi
    #chroot /mnt sbctl enroll-keys -m
    sleep 2
    
    # User security
    echo "[*] Disabling the root account..."
    chroot /mnt passwd -l root

    echo "[*] Setting the user password..."
    echo -n "$USER_NAME:$USER_PASS" | chpasswd -R /mnt
    
    # Install base packages
    chroot /mnt apk add alsa-plugins-pulse \
        amd-ucode \
        intel-ucode \
        iptables \
        iwd \
        networkmanager \
        networkmanager-wifi \
        pulseaudio \
        pulseaudio-alsa \
        p7zip \
        tlp \
        unzip \
        zip    
    #AUDIO: alsa-plugins-pulse pavucontrol(???) pulseaudio pulseaudio-alsa pulseaudio-bluez(???)
    #BASE: p7zip tlp unzip zip
    #CPU MICROCODE: amd-ucode intel-ucode
    #NETWORK: iptables iwd networkmanager networkmanager-applet networkmanager-tui networkmanager-wifi

    # Remove unnecessary packages
    chroot /mnt apk del wpa_supplicant
    
    # Configure services
    echo "[*] Configuring services..."
    chroot /mnt rc-update add iwd default
    chroot /mnt rc-update add networkmanager default
    chroot /mnt rc-update add tlp default

    chroot /mnt rc-update del networking boot

    # Install virt-manager infrastructure
    echo "[*] Installing virt-manager infrastructure..."
    chroot /mnt apk add bridge-utils \
        dmidecode \
        ebtables \
        libvirt \
        netcat-openbsd \
        ovmf \
        seabios \
        virt-manager \
        virt-viewer
        #libguestfs (Edge)
        #vde2 (~libwolfssl.so)
    
    # Add user paths & scripts
    echo "[*] Adding user paths & scripts..."
    mkdir -p /mnt/home/$USER_NAME/tools
    mkdir -p /mnt/home/$USER_NAME/workspace
    chroot /mnt chown -R $USER_NAME:users /home/$USER_NAME/    

    # Synchronise & unmount everything
    sync
    #umount -a

    # Exit message
    echo "[*] Work done. Returning..."
}

# Global variables
echo "[*] Initializing global variables..."
DEV="$1" # Harddisk
LUKS_PASS="" # LUKS FDE password
LV_ROOT="root" # Label & name of the root partition
LV_SWAP="swap" # Label & name of the swap partition
LUKS_LVM="luks_lvm" # LUKS LVM
PART_EFI="${DEV}p1" # EFI partition
PART_LUKS="${DEV}p2" # LUKS partition
SCRIPT=$(readlink -f "$0") # Absolute script path
USER_NAME="user" # Username
USER_PASS="" # Home user password
VG_LVM="vg_lvm" # LUKS volume group

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
