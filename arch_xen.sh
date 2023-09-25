# System update
echo "Updating the system..."
pacman --disable-download-timeout --needed --noconfirm -Syu


# Install Xen via yay from AUR ecosystem
sudo yay --disable-download-timeout --needed --noconfirm -Sy grub-xen-git xen


# Configure Xen (xen.cfg)
sudo echo "[global]"
sudo echo "default=xen"

sudo echo "[xen]"
sudo echo "options=console=vga iommu=force:true,qinval:true,debug:true loglvl=all noreboot=true reboot=no vga=ask ucode=scan"
sudo echo "kernel=vmlinuz-linux root=/dev/sdaX rw add_efi_memmap #earlyprintk=xen"
sudo echo "ramdisk=initramfs-linux.img"


# 
