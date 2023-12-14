# NOTES
# Reference: https://wiki.archlinux.org/title/xen
# FIXME: Everything!

# Global variables
LV_ROOT="root" # Label & name of the root partition
USER_NAME="user" # Home user
VG_LUKS="vg_luks" # LUKS volume group
XEN_CFG_FILE="/boot/efi/xen.cfg" # Xen EFI boot configuration file

# Install required packages
sudo pacman --disable-download-timeout --needed --noconfirm -S bridge-utils dmidecode ebtables libguestfs libvirt openbsd-netcat virt-manager virt-viewer
#dnsmasq vde2
yay --disable-download-timeout --needed --noconfirm -S xen xen-qemu
#xen-pvhgrub
sudo pacman -S edk2-ovmf # For UEFI support in virtual machines
sudo pacman -S seabios # For BIOS support in virtual machines

# Configure the libvirt service
echo "unix_sock_group = \"libvirt\"" >> /etc/libvirt/libvirtd.conf
echo "unix_sock_rw_perms = \"0770\"" >> /etc/libvirt/libvirtd.conf

sudo usermod -aG libvirt $USER_NAME
newgrp libvirt

sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service

# Modificate the bootloader
echo "[global]" > XEN_CFG_FILE
echo "default=xen" >> XEN_CFG_FILE
echo >> XEN_CFG_FILE
echo "[xen]" >> XEN_CFG_FILE
echo "options=console=vga iommu=force:true,qinval:true,debug:true loglvl=all noreboot=true reboot=no vga=ask ucode=scan" >> XEN_CFG_FILE
echo "extra=\"luks lvm\"" >> XEN_CFG_FILE
echo "kernel=vmlinuz-linux root=/dev/$VG_LUKS/$LV_ROOT rw add_efi_memmap earlyprintk=xen" >> XEN_CFG_FILE
echo "ramdisk=initramfs-linux.img" >> XEN_CFG_FILE

# Modificate GRUB
yay --disable-download-timeout --needed --noconfirm -S grub-xen-git
sudo echo "GRUB_CMDLINE_XEN_DEFAULT=\"dom0_mem=512M\"" >> /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

#FIXME: Adjust UEFI settings

#FIXME: Install/configure GRUB for XEN

#FIXME: Create a network brigde between dom0 and domU*

#FIXME: Installation of Xen systemd services???

#FIXME: Confirming succesful installation

#FIXME: Configuring best practices???

#FIXME: Xen Hardening
