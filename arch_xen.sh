#FIXME: REVIEW ANYTHING!

# Notes
# Reference: https://wiki.archlinux.org/title/xen

# Global variables
LV_ROOT="root" # Label & name of the root partition
VG_LUKS="vg_luks" # LUKS volume group
XEN_CFG_FILE="/boot/efi/xen.cfg" # Xen EFI boot configuration file

# Install Xen packages
yay -S xen xen-qemu
sudo pacman -S edk2-ovmf # For UEFI support in virtual machines
sudo pacman -S seabios # For BIOS support in virtual machines

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
