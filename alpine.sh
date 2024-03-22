# TODO: Review paritioning
# TODO: Review networking
# TODO: Base: Hardening
# TODO: DE Xfce: Automatic sleep/hibernate & resume
# TODO: DE Xfce: Add keyboard shortcut WIN+L
# TODO: DE Xfce: Remove keyboard shortcut CTRL+ALT+L
# TODO: DE ***: Firefox Deployment

arg_parsing() {
    echo "[*] Parsing arguments..."

    # Retrieve all arguments
    for l_arg in "$@"; 
    do
        if [ "$l_arg" == "--audio" ];
        then
            if [ -z "$ARG_AUDIO" ];
            then
                echo "[*] Audio: Enabled"
                ARG_AUDIO=1
            else
                echo "[X] ERROR: The passed argument '--audio' is already set. Exiting..."
                exit 1
            fi
        elif (echo "$l_arg" | grep -q "^--desktop=");
        then
            if [ -z "$ARG_DESKTOP" ];
            then
                ARG_DESKTOP=${l_arg#"--desktop="}
                
                if [ "$ARG_DESKTOP" == "xfce" ];
                then
                    echo "[*] Desktop environment: '$ARG_DESKTOP'"
                else
                    echo "[X] ERROR: The passed desktop environment is '$ARG_DESKTOP' but must be 'xfce'. Exiting..."
                    exit 1
                fi
            else
                echo "[X] ERROR: The passed argument '--desktop' is already set. Exiting..."
                exit 1
            fi
        elif (echo "$l_arg" | grep -q "^--disk=");
        then
            if [ -z "$ARG_DISK" ];
            then
                ARG_DISK=${l_arg#"--disk="}

                if [ -z "$ARG_DISK" ];
                then
                    echo "[X] ERROR: The passed argument 'Disk' is empty. Exiting..."
                    exit 1
                else
                    echo "[*] Disk: '$ARG_DISK'"
                    disk_check
                fi
            else
                echo "[X] ERROR: The passed argument '--disk' is already set. Exiting..."
                exit 1
            fi
        elif (echo "$l_arg" | grep -q "^--hypervisor=");
        then
            if [ -z "$ARG_HYPERVISOR" ];
            then
                ARG_HYPERVISOR=${l_arg#"--hypervisor="}
                
                if [ "$ARG_HYPERVISOR" == "kvm" ];
                then
                    echo "[*] Hypervisor: '$ARG_HYPERVISOR'"
                elif [ "$ARG_HYPERVISOR" == "xen" ];
                then
                    echo "[*] Hypervisor: '$ARG_HYPERVISOR'"
                else
                    echo "[X] ERROR: The passed hypervisor is '$ARG_HYPERVISOR' but must be 'kvm' or 'xen'. Exiting..."
                    exit 1
                fi
            else
                echo "[X] ERROR: The passed argument '--hypervisor' is already set. Exiting..."
                exit 1
            fi
        elif (echo "$l_arg" | grep -q "^--platform=");
        then
            ARG_PLATFORM=${l_arg#"--platform="}
                
            if [ "$ARG_PLATFORM" == "bios" ];
            then
                echo "[*] Platform: '$ARG_PLATFORM'"
                PART_EFI_ENABLED=0
            elif [ "$ARG_PLATFORM" == "uefi" ];
            then
                echo "[*] Platform: '$ARG_PLATFORM'"
                PART_EFI_ENABLED=1
            elif [ "$ARG_PLATFORM" == "uefi-sb" ];
            then
                echo "[*] Platform: '$ARG_PLATFORM'"
                PART_EFI_ENABLED=1
            else
                echo "[X] ERROR: The passed platform is '$ARG_PLATFORM' but must be 'bios', 'uefi' or 'uefi-sb'. Exiting..."
                exit 1
            fi
        else
            echo "[X] ERROR: Unknown argument '$l_arg'. Exiting..."
            exit 1
        fi        
    done

    # Verify, that all mandatory arguments were provided    
    if [ -z "$ARG_DISK" ];
    then
        echo "[X] ERROR: No disk was provided. Exiting..."
        exit 1
    fi

    if [ -z "$ARG_PLATFORM" ];
    then
        echo "[X] ERROR: No platform was provided. Exiting..."
        exit 1
    fi
}

de_xfce_install() {
    echo "[*] Installing the XFCE desktop environment..."
    
    # Install X.Org & Xfce
    echo "[*] Installing X.Org & Xfce..."
    chroot /mnt setup-desktop xfce
    
    # Install required packages
    echo "[*] Installing required packages..."
    chroot /mnt apk add adw-gtk3 mousepad ristretto thunar-archive-plugin xarchiver xfce-polkit xfce4-cpugraph-plugin xfce4-notifyd xfce4-screensaver xfce4-screenshooter xfce4-taskmanager xfce4-whiskermenu-plugin

    if [ "$ARG_AUDIO" == 0 ];
    then
        echo "[*] Audio is disabled. Skipping audio packages..."
    elif [ "$ARG_AUDIO" == 1 ];
    then
        echo "[*] Installing Audio packages..."
        chroot /mnt apk add pavucontrol xfce4-pulseaudio-plugin
    else
        echo "[X] ERROR: Variable 'ARG_AUDIO' is '$ARG_AUDIO' but must be 0 or 1. Exiting..."
        exit 1
    fi
    
    # Configure networking
    echo "[*] Configuring networking..."
    chroot /mnt apk add network-manager-applet networkmanager networkmanager-cli networkmanager-wifi
    chroot /mnt apk del wpa_supplicant
    
    echo "[main]" | tee /mnt/etc/NetworkManager/NetworkManager.conf
    echo "dhcp=internal" | tee -a /mnt/etc/NetworkManager/NetworkManager.conf
    echo "plugins=ifupdown,keyfile" | tee -a /mnt/etc/NetworkManager/NetworkManager.conf
    echo "" | tee -a /mnt/etc/NetworkManager/NetworkManager.conf
    echo "[ifupdown]" | tee -a /mnt/etc/NetworkManager/NetworkManager.conf
    echo "managed=true" | tee -a /mnt/etc/NetworkManager/NetworkManager.conf
    echo "" | tee -a /mnt/etc/NetworkManager/NetworkManager.conf
    echo "[device]" | tee -a /mnt/etc/NetworkManager/NetworkManager.conf
    echo "wifi.scan-rand-mac-address=yes" | tee -a /mnt/etc/NetworkManager/NetworkManager.conf
    echo "wifi.backend=iwd" | tee -a /mnt/etc/NetworkManager/NetworkManager.conf
    
    chroot /mnt rc-update add networkmanager default
    chroot /mnt rc-update del networking boot
    
    # Xfce keyboard layout
    echo "[*] Setting the Xfce keyboard layout to German..."
    doas mkdir -p /mnt/etc/X11/xorg.conf.d/
    echo "Section \"InputClass\"" | tee /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
    echo "  Identifier \"system-keyboard\"" | tee -a /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
    echo "  MatchIsKeyboard \"on\"" | tee -a /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
    echo "  Option \"XkbLayout\" \"de\"" | tee -a /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
    echo "  Option \"XkbVariant\" \"nodeadkeys\"" | tee -a /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
    echo "EndSection" | tee -a /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
    
    # Xfce customisation
    echo "[*] Customising Xfce..."
    chroot /mnt export DISPLAY=:0 && export $(dbus-launch) && xfconf-query -c xsettings -p '/Net/ThemeName' -s 'adw-gtk3-dark'
    chroot /mnt export DISPLAY=:0 && export $(dbus-launch) && xfconf-query -c xfce4-keyboard-shortcuts -p '/commands/custom/<Super><Alt>l' --reset
    chroot /mnt export DISPLAY=:0 && export $(dbus-launch) && xfconf-query -c xfce4-keyboard-shortcuts -n -t 'string' -p '/commands/custom/<Super>l' -s 'xflock4' --create
    
    # Configure services
    echo "[*] Configuring services..."
    chroot /mnt rc-update add lightdm default
    chroot /mnt rc-update add polkit default
}

disk_check() {
    if [ -e "$ARG_DISK" ]; then
        echo "[*] Path '$ARG_DISK' exists."
    
        if [ -b "$ARG_DISK" ]; then
            echo "[*] Path '$ARG_DISK' is a valid block device." 
    
            if [[ $ARG_DISK == "/dev/mmc*" ]]; 
            then
                  echo "[*] Target disk seems to be a MMC disk."
    
                  if [ "$PART_EFI_ENABLED" == 1 ];
                  then             
                      PART_EFI="${ARG_DISK}p1"
                      PART_LUKS="${ARG_DISK}p2"
                  elif [ "$PART_EFI_ENABLED" == 0 ];
                  then
                      PART_EFI="- (BIOS installation)"
                      PART_LUKS="${ARG_DISK}p1"
                  else
                      echo "[X] ERROR: Variable 'PART_EFI_ENABLED' is '$PART_EFI_ENABLED' but must be 0 or 1. This is unexpected behaviour. Exiting..."
                      exit 1
                  fi
            elif [[ "$ARG_DISK" == "/dev/nvme*" ]]; 
            then
                  echo "[*] Target disk seems to be a NVME disk."
    
                  if [ "$PART_EFI_ENABLED" == 1 ];
                  then             
                      PART_EFI="${ARG_DISK}p1"
                      PART_LUKS="${ARG_DISK}p2"
                  elif [ "$PART_EFI_ENABLED" == 0 ];
                  then
                      PART_EFI="- (BIOS installation)"
                      PART_LUKS="${ARG_DISK}p1"
                  else
                      echo "[X] ERROR: Variable 'PART_EFI_ENABLED' is '$PART_EFI_ENABLED' but must be 0 or 1. This is unexpected behaviour. Exiting..."
                      exit 1
                  fi
            else
                  if [ "$PART_EFI_ENABLED" == 1 ];
                  then             
                      PART_EFI="${ARG_DISK}1"
                      PART_LUKS="${ARG_DISK}2"
                  elif [ "$PART_EFI_ENABLED" == 0 ];
                  then
                      PART_EFI="- (BIOS installation)"
                      PART_LUKS="${ARG_DISK}1"
                  else
                      echo "[X] ERROR: Variable 'PART_EFI_ENABLED' is '$PART_EFI_ENABLED' but must be 0 or 1. This is unexpected behaviour. Exiting..."
                      exit 1
                  fi
            fi
    
            echo "[*] Target EFI partition: $PART_EFI."
            echo "[*] Target LUKS partition: $PART_LUKS."
        else
            echo "[X] ERROR: '$4' is not a valid block device. Exiting..."
            exit 1
        fi
    else
        echo "[X] ERROR: Path '$4' does not exist. Exiting..."
        exit 1
    fi
}

disk_layout_bios() {
    echo "[*] Partitioning the target disk using MBR partition layout..."
    parted $ARG_DISK mktable msdos
    
    parted $ARG_DISK mkpart primary ext4 0% 100%
    parted $ARG_DISK set 1 boot on
    parted $ARG_DISK name 1 $PART_LUKS_LABEL

    sync
}

disk_layout_uefi() {
    echo "[*] Partitioning the target disk using GPT partition layout..."
    parted $ARG_DISK mktable gpt
    
    parted $ARG_DISK mkpart primary fat32 1MiB 512MiB 
    parted $ARG_DISK set 1 boot on 
    parted $ARG_DISK set 1 esp on
    parted $ARG_DISK name 1 $PART_EFI_LABEL
    
    parted $ARG_DISK mkpart primary ext4 512MiB 100%
    parted $ARG_DISK name 2 $PART_LUKS_LABEL

    sync
}

grub_install_bios() {
    echo "[*] Installing GRUB for BIOS platform..."
    chroot /mnt grub-install --target=i386-pc $ARG_DISK
}

grub_install_uefi() {
    echo "[*] Installing GRUB for UEFI platform..."
    chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi $ARG_DISK
}

harden_system() {
    # Disable ash history
    # Remove apk
    return
}

hv_kvm_install() {
    echo "[*] Installing the KVM hypervisor infrastructure..."

    # Install required packages
    echo "[*] Installing required packages..."
    doas apk add bridge \
        bridge-utils \
        dmidecode \
        ebtables \
        libvirt \
        libvirt-daemon \
        netcat-openbsd \
        qemu-img \
        qemu-modules \
        qemu-system-x86_64 \
        virt-manager \
        virt-viewer 
    sleep 2
    
    # Enable modules
    echo "[*] Enabling modules..."
    echo "tun" | doas tee -a /etc/modules
    
    # Configure services
    echo "[*] Configuring required services..."
    doas rc-update add libvirt-guests default
    doas rc-update add libvirtd default
    sleep 2
    
    # Add user to the 'libvirt' group
    echo "[*] Adding the user to the 'libvirt' group..."
    doas adduser $(whoami) libvirt
    sleep 2
}

hv_xen_install() {
    echo "[*] Installing the Xen hypervisor infrastructure..."

    # Install required packages
    echo "[*] Installing required packages..."
    doas apk add bridge \
        bridge-utils \
        dmidecode \
        ebtables \
        libvirt \
        libvirt-daemon \
        netcat-openbsd \
        ovmf \
        seabios \
        spice-vdagent \
        virt-manager \
        virt-viewer \
        xen \
        xen-hypervisor \
        xen-qemu
    sleep 2
    
    # Enable modules
    echo "[*] Enabling modules..."
    echo "xen-blkback" | doas tee -a /etc/modules
    echo "xen-netback" | doas tee -a /etc/modules
    echo "tun" | doas tee -a /etc/modules
    
    # Configure services
    echo "[*] Configuring required services..."
    doas rc-update add libvirt-guests default
    doas rc-update add libvirtd default
    doas rc-update add spice-vdagentd default
    doas rc-update add xenconsoled default
    doas rc-update add xendomains default 
    doas rc-update add xenqemu default
    doas rc-update add xenstored default
    sleep 2
    
    # Add user to the 'libvirt' group
    echo "[*] Adding the user to the 'libvirt' group..."
    doas adduser $(whoami) libvirt
    sleep 2
}

print_usage() {
    echo "[*] Usage: ./alpine.sh [--audio] [--desktop=<xfce>] --disk=<DISK> [--hypervisor=<kvm/xen>] --platform=<bios/uefi/uefi-sb>"
}

# Start message
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Global variables
echo "[*] Initializing global variables..."
ARG_AUDIO=0
ARG_DESKTOP=""
ARG_DISK=""
ARG_HYPERVISOR=""
ARG_PLATFORM=""
LUKS_LVM="luks_lvm"
LUKS_PASS=""
LV_ROOT="lv_root"
LV_SWAP="lv_swap"
LVM_VG="lvm_vg"
PART_EFI=""
PART_EFI_ENABLED=""
PART_EFI_LABEL="efi-sp"
PART_LUKS=""
PART_LUKS_LABEL="luks"
USER_NAME="user"
USER_PASS=""

# Argument parsing
arg_parsing "$@"


# Retrieve the LUKS & user password
echo "[*] Please enter the LUKS password: "
read -s luks_pass_a
echo "[*] Please reenter the LUKS password: "
read -s luks_pass_b

if [ "$luks_pass_a" == "$luks_pass_b" ]; 
then
    LUKS_PASS=$luks_pass_a
else
    echo "[X] ERROR: The LUKS passwords do not match."
    exit 1
fi

echo "[*] Please enter the user password: "
read -s user_pass_a
echo "[*] Please reenter the user password: "
read -s user_pass_b

if [ "$user_pass_a" == "$user_pass_b" ]; 
then
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
apk add amd-ucode cryptsetup e2fsprogs file intel-ucode iwd lsblk lvm2 nano parted p7zip tlp unzip zip

if [ "$ARG_AUDIO" == 0 ];
    then
        echo "[*] Audio is disabled. Skipping audio packages..."
    elif [ "$ARG_AUDIO" == 1 ];
    then
        echo "[*] Installing Audio packages..."
        apk add alsa-plugins-pulse pulseaudio pulseaudio-alsa
    else
        echo "[X] ERROR: Variable 'ARG_AUDIO' is '$ARG_AUDIO' but must be 0 or 1. Exiting..."
        exit 1
    fi

sleep 2

# Setup udev as devd
echo "[*] Setting up udev as devd..."
setup-devd udev

# Partitioning
echo "[*] Partitioning the disk..."

if [ "$PART_EFI_ENABLED" == 0 ];
then
    disk_layout_bios
elif [ "$PART_EFI_ENABLED" == 1 ];
then
    disk_layout_uefi
else
    echo "[X] ERROR: Variable 'PART_EFI_ENABLED' is '$PART_EFI_ENABLED' but must be 0 or 1. This is unexpected behaviour. Exiting..."
    exit 1
fi

sync

for i in $(seq 10)
    do echo "[*] Populating the kernel partition tables ($i/10)..." && partprobe $DISK && sleep 1
done

parted $ARG_DISK print

# Setup LUKS partition
echo "[*] Formatting the second partition as a LUKS crypto partition..."
echo -n $LUKS_PASS | cryptsetup luksFormat $PART_LUKS --type luks1 -c twofish-xts-plain64 -h sha512 -s 512 --iter-time 10000 -
echo -n $LUKS_PASS | cryptsetup luksOpen $PART_LUKS $LUKS_LVM -
sleep 2

# Setup LVM within the LUKS partition
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

# Mount required partitions
echo "[*] Mounting required partitions..."

echo "[*] Mounting the target root partition..."
mount -t ext4 /dev/$LVM_VG/$LV_ROOT /mnt

if [ "$PART_EFI_ENABLED" == 0 ];
then
    echo "[*] Skipping the UEFI partition..."
elif [ "$PART_EFI_ENABLED" == 1 ];
then
    echo "[*] Mounting the UEFI partition..."
    mkdir -p /mnt/boot/efi
    mount -t vfat $PART_EFI /mnt/boot/efi
else
    echo "[X] ERROR: Variable 'PART_EFI_ENABLED' is '$PART_EFI_ENABLED' but must be 0 or 1. This is unexpected behaviour. Exiting..."
    exit
fi

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
if [ "$PART_EFI_ENABLED" == 0 ];
then
    grub_install_bios
elif [ "$PART_EFI_ENABLED" == 1 ];
then
    grub_install_uefi
else
    echo "[X] ERROR: Variable 'PART_EFI_ENABLED' is '$PART_EFI_ENABLED' but must be 0 or 1. This is unexpected behaviour. Exiting..."
    exit 1
fi

chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
chroot /mnt chmod 700 /boot
sleep 2

# Install the hypervisor (if applicable)
if [ -z "$ARG_HYPERVISOR" ];
then
    echo "[*] No hypervisor was selected. Skipping..."
else
    if [ "$ARG_HYPERVISOR" == "kvm" ];
    then
        chroot /mnt hv_kvm_install
    elif [ "$ARG_HYPERVISOR" == "xen" ];
    then
        hv_xen_install
    else
        echo "[X] ERROR: Variable 'ARG_HYPERVISOR' is '$ARG_HYPERVISOR' but must be 'kvm' or 'xen'."
    fi
fi

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

# Install the desktop environment (if applicable)
if [ -z "$ARG_DESKTOP" ];
then
    echo "[*] No desktop environment was selected. Skipping..."
else
    if [ "$ARG_DESKTOP" == "xfce" ];
    then
        de_xfce_install
    else
        echo "[X] ERROR: Variable 'ARG_DESKTOP' is '$ARG_DESKTOP' but must be 'xfce'."
    fi
fi

# Stop message
echo "[*] Work done. Exiting..."
exit 0
