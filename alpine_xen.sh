# Alpine wallpaper
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

    # User management
    echo "[*] Setting up a standard user..."
    setup-user -a -f $USER_NAME $USER_NAME
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

    # Setup udev as devd
    echo "[*] Setting up udev as devd..."
    setup-devd udev

    # Disable SSHD
    echo "[*] Disabling SSHD..."
    setup-sshd none

    # Configure apk
    echo "[*] Configuring apk & enabling the Alpine community repository..."
    setup-apkrepos -c -f

    # Install required packages
    echo "[*] Installing required packages..."
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
    sleep 2

    # Configure Alpine Linux as Xen dom0
    echo "[*] Configuring Alpine Linux as Xen dom0..."
    setup-xen-dom0
    sleep 2

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
    #echo "GRUB_CMDLINE_XEN=\"console=vga guest_loglvl=all loglvl=all nomodeset noreboot=true\"" >> /mnt/etc/default/grub
    echo "GRUB_CMDLINE_XEN_DEFAULT=\"ucode=scan\"" >> /mnt/etc/default/grub #dom0_max_vcpus=1 dom0_vcpus_pin maxmem=512
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
    
    # Install base packages
    echo "[*] Installing base packages..."
    chroot /mnt apk add alsa-plugins-pulse \
        iptables \
        iwd \
        network-manager-applet \
        networkmanager \
        networkmanager-cli \
        networkmanager-wifi \
        pulseaudio \
        pulseaudio-alsa \
        p7zip \
        tlp \
        unzip \
        zip
    #ATTENTION: CPU microcode must be handled at Xen kernel level, not at dom0 level (amd-ucode / intel-ucode)
    #AUDIO: alsa-plugins-pulse pavucontrol(???) pulseaudio pulseaudio-alsa pulseaudio-bluez(???)
    #BASE: p7zip tlp unzip zip
    #NETWORK: iptables iwd networkmanager networkmanager-tui networkmanager-wifi
    sleep 2

    # Remove unnecessary packages
    echo "[*] Removing unnecessary packages..."
    chroot /mnt apk del wpa_supplicant
    sleep 2
    
    # Configure services
    echo "[*] Configuring required services..."
    chroot /mnt rc-update add iwd default
    chroot /mnt rc-update add networkmanager default
    chroot /mnt rc-update add tlp default
    chroot /mnt rc-update del networking boot
    sleep 2

    # Install virt-manager infrastructure
    echo "[*] Installing the virt-manager infrastructure..."
    chroot /mnt apk add bridge-utils \
        dmidecode \
        ebtables \
        libvirt \
        libvirt-daemon \
        netcat-openbsd \
        ovmf \
        seabios \
        virt-manager \
        virt-viewer
    #libguestfs (Edge), vde2 (~libwolfssl.so)
    sleep 2

    echo "[*] Configuring required services..."
    chroot /mnt rc-update add libvirt-guests default
    chroot /mnt rc-update add libvirtd default

    echo "[*] Adding the user to the 'libvirt' group..."
    chroot /mnt adduser $USER_NAME libvirt    

    # User security
    echo "[*] Disabling the root account..."
    chroot /mnt passwd -l root

    echo "[*] Setting the user password..."
    echo -n "$USER_NAME:$USER_PASS" | chpasswd -R /mnt

    echo "[*] Adding the user to the 'plugdev' group..."
    chroot /mnt adduser $USER_NAME plugdev
    
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
DEV="$1"
LUKS_PASS=""
LV_ROOT="lv_root"
LV_SWAP="lv_swap"
LVM_VG="lvm_vg"
LUKS_LVM="luks_lvm"
PART_EFI="${DEV}p1"
PART_LUKS="${DEV}p2"
SCRIPT=$(readlink -f "$0")
USER_NAME="user"
USER_PASS=""

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
