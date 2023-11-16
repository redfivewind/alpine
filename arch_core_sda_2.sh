# Global variables
echo "Initializing global variables..."
DEV="/dev/sda" # Harddisk
EFI="/dev/sda1" # EFI partition
LUKS="/dev/sda2" # LUKS partition
LUKS_LVM="lukslvm" # LUKS LVM
LUKS_VG="luksvg" # LUKS volume group
ROOT_LABEL="root" # Label of root partition
ROOT_NAME="root" # Name of root partition
SWAP_LABEL="swap" # Label of swap partition
SWAP_NAME="swap" # Name of swap partition
USER="user" # Username

# System update
echo "Updating the system..."
pacman --disable-download-timeout --noconfirm -Syyu

# Time
echo "Setting timezone and hardware clock..."
timedatectl set-timezone Europe/Berlin # Berlin timezone
ln /usr/share/zoneinfo/Europe/Berlin /etc/localtime # Berlin timezone
hwclock --systohc --utc # Assume hardware clock is UTC

# Locale
echo "Initializing the locale..."
timedatectl set-ntp true # Enable NTP time synchronization again
echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen # Change en-US (UTF-8) to en-GB (UTF-8)
locale-gen # Generate locale
echo "LANG=en_GB.UTF-8" > /etc/locale.conf # Save locale to locale configuration
export LANG=en_GB.UTF-8 # Export LANG variable
echo "KEYMAP=de-latin1" > /etc/vconsole.conf # Set keyboard layout
echo "FONT=lat9w-16" >> /etc/vconsole.conf # Set console font

# Network
echo "Setting hostname and /etc/hosts..."
echo $HOSTNAME > /etc/hostname # Set hostname
echo "127.0.0.1 localhost" > /etc/hosts # Hosts file: Localhost (IP4)
echo "::1 localhost" >> /etc/hosts # Hosts file: Localhost (IP6)
#echo "127.0.1.1 $HOSTNAME >> /etc/hosts # Hosts file: This host (IP4) #FIXME

systemctl enable dhcpcd

# initramfs
echo "Rebuilding initramfs image using mkinitcpio..."
echo "MODULES=()" > /etc/mkinitcpio.conf
echo "BINARIES=()" >> /etc/mkinitcpio.conf
#echo "FILES=()" >> /etc/mkinitcpio.conf
echo "HOOKS=(base udev autodetect modconf block filesystems keyboard fsck encrypt lvm2)" >> /etc/mkinitcpio.conf
mkinitcpio -p linux-hardened # Rebuild initramfs image

# Users
echo "Adding a generic home user: '$USER'..."
useradd -m -G wheel,users $USER # Add new user
echo "SET HOME USER PASSWORD!"
passwd $USER # Set user password
#echo "EDITOR=nano visudo" > /etc/sudoers #FIXME
#echo "root ALL=(ALL) ALL" > /etc/sudoers # Root account may execute any command
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers # Users of group wheel may execute any command
echo "@includedir /etc/sudoers.d" >> /etc/sudoers

# efibootmgr & GRUB
echo "Installing GRUB with CRYPTODISK flag..."
pacman --noconfirm --disable-download-timeout -Syyu efibootmgr grub # Install packages required for UEFI boot
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub # Enable booting from encrypted /boot
sed -i 's/GRUB_CMDLINE_LINUX=""/#GRUB_CMDLINE_LINUX=""/' /etc/default/grub # Disable default value
#echo GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$(cryptsetup luksUUID $LUKS):lukslvm root=/dev/$LUKS_VG/$ROOT_NAME cryptkey=rootfs:/root/keyfiles/boot.keyfile\" >> /etc/default/grub # Add encryption hook to GRUB
echo "GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$(cryptsetup luksUUID $LUKS):lukslvm root=/dev/$LUKS_VG/$ROOT_NAME\"" >> /etc/default/grub # Add encryption hook to GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi # Install GRUB --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg # Generate GRUB configuration file
chmod 700 /boot # Protect /boot

# Start services
echo "Starting system services..."
sudo systemctl enable dhcpcd.service # DHCP
sudo systemctl enable fstrim.timer # TRIM timer for SSDs
sudo systemctl enable NetworkManager.service # Network managament
sudo systemctl enable systemd-timesyncd.service # Time synchronization
sudo systemctl enable thermald # Thermald
sudo systemctl enable tlp.service # TLP
sudo systemctl enable wpa_supplicant.service # Required for WPAx connections

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

# Unmount previously required mount points
exit
umount /mnt/dev/pts
umount /mnt/dev
umount /mnt/sys
umount /mnt/proc
umount /mnt/boot/efi
umount /mnt/boot
umount /mnt
sync
