#FIXME: REVIEW ANYTHING!

# Install Xen packages
yay -S xen xen-qemu
#sudo pacman -S edk2-ovmf # Fur UEFI support in virtual machines
#sudo pacman -S seabios # For BIOS support in virtual machines

# Modificate the bootloader
XEN_CFG_FILE="/boot/efi/xen.cfg"

echo "[global]" > XEN_CFG_FILE
echo "default=xen" >> XEN_CFG_FILE
echo >> XEN_CFG_FILE
echo "[xen]" >> XEN_CFG_FILE
echo "options=console=vga iommu=force:true,qinval:true,debug:true loglvl=all noreboot=true reboot=no vga=ask ucode=scan" >> XEN_CFG_FILE
echo "extra=\"luks lvm\"" >> XEN_CFG_FILE
echo "kernel=vmlinuz-linux root=/dev/$VG_LUKS/$LV_ROOT rw add_efi_memmap earlyprintk=xen" >> XEN_CFG_FILE
echo "ramdisk=initramfs-linux.img" >> XEN_CFG_FILE

# Modificate GRUB
yay -S grub-xen-git

#FIXME: Adjust UEFI settings

#FIXME: Install/configure GRUB for XEN

#FIXME: Create a network brigde between dom0 and domU*

#FIXME: Installation of Xen systemd services???

#FIXME: Confirming succesful installation

#FIXME: Configuring best practices???

#FIXME: Xen Hardening
