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
  --initramfs /boot/initramfs-lts \
  --intelucode /boot/intel-ucode.img \
  --kernel-img /boot/vmlinuz-lts \
  --os-release /etc/os-release \
  --save /boot/efi/EFI/alpine/alpine.efi
doas sbctl list-bundles
sleep 3

# Protect Xen with Secure Boot (if applicable)
echo "[*] Generating the UEFI Secure Boot bundle for Xen (if applicable)..."
#FIXME
#doas sbctl list-bundles
#sleep 3

# Finally, show 'sbctl status again'
echo "[*] Finally, verifying the UEFI Secure Boot status again..."
doas sbctl status
sleep 3

# Stop message
echo "[!] ALERT: Please enable & review the UEFI Secure Boot configuration manually! Press any key to continue..."
read
sleep 3
