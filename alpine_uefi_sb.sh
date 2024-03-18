# Warning message
echo "[!] ALERT: Make sure that the UEFI is in setup mode. Press any key to continue..."
read
sleep 3

# Install required packages
echo "[*] Installing required packages..."
doas apk add gummiboot-efistub sbctl
sleep 3

# Initially show 'sbctl status'
echo "[*] Retrieving the UEFI Secure Boot status..."
doas sbctl status
sleep 3

# Generate & enroll UEFI keys using sbctl
echo "[*] Generating signing keys using sbctl..."
doas sbctl create-keys
doas sbctl status
sleep 3

echo "[*] Enrolling the signing keys using sbctl..."
doas sbctl enroll-keys --ignore-immutable --microsoft
doas sbctl status
sleep 3

# Protect Alpine Linux with Secure Boot
echo "[*] Generating the UEFI Secure Boot bundle for Alpine Linux..."
doas sbctl bundle --amducode /boot/amd-ucode.img \
  --cmdline /proc/cmdline \
  --efi-stub /usr/lib/gummiboot/linuxx64.efi.stub \
  --esp /boot/efi \
  --initramfs /boot/initramfs-lts \
  --intelucode /boot/intel-ucode.img \
  --kernel-img /boot/vmlinuz-lts \
  --os-release /etc/os-release \
  --save \
  /boot/efi/EFI/alpine/alpine.efi
doas sbctl list-bundles

echo "[*] Generating an UEFI entry for Alpine Linux using efibootmgr..."
efibootmgr --disk $DISK --part 1 --create --label 'alpine' --load /alpine.efi --verbose
efibootmgr -v
sleep 3

# Protect Xen with Secure Boot (if applicable)
echo "[*] Generating the UEFI Secure Boot bundle for Xen (if applicable)..."

if [[ #FIXME ]]; then
    #FIXME
    doas sbctl list-bundles
    #sleep 3
else
    #FIXME
fi

# Finally, show 'sbctl status again'
echo "[*] Finally, verifying the UEFI Secure Boot status again..."
doas sbctl status
sleep 3

# Uninstall GRUB2
echo "[*] Uninstalling GRUB2..."
#FIXME
#sleep 3

# Stop message
echo "[!] ALERT: Please enable & review the UEFI Secure Boot configuration manually! Press any key to continue..."
read
sleep 3
