# Warning message
echo "[!] ALERT: Make sure that the UEFI is in setup mode. Press any key to continue..."
read
sleep 3

# Install required packages
echo "[*] Installing required packages..."
doas apk add efibootmgr gummiboot-efistub secureboot-hook
sleep 3

# Adjust the 'cmdline' in '/etc/kernel-hooks.d/secureboot.conf'
echo "[*] Adjusting the 'cmdline' in '/etc/kernel-hooks.d/secureboot.conf'..."

sleep 3

# Run the kernel hooks
echo "[*] Running the kernel hooks..."
doas apk fix kernel-hooks
sleep 3

# Disable the mkinitfs trigger
echo "[*] Disabling the mkinitfs trigger..."
echo 'disable_trigger=yes' >> /etc/mkinitfs/mkinitfs.conf
sleep 3
