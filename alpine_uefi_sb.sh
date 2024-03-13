# Warning message
echo "[!] ALERT: Make sure that the UEFI is in setup mode. Press any key to continue..."
read
sleep 3

# Install required packages
echo "[*] Installing required packages..."
doas apk add sbctl
sleep 3

# Make the 'cmdline" available in '/etc/kernel/cmdline'
echo "[*] Making the 'cmdline' available in '/etc/kernel/cmdline'..."
doas cat /proc/cmdline | doas tee /etc/kernel/cmdline
sleep 3

# Initially show 'sbctl status'
echo "[*] Retrieving the UEFI Secure Boot status..."
doas sbctl status
sleep 3

# Generate & enroll UEFI keys using sbctl
echo "[*] Generating signing keys using sbctl..."
doas sbctl create-keys
sleep 3

echo "[*] Enrolling the signing keys using sbctl..."
doas sbctl enroll-keys
sleep 3

# Protect Alpine Linux with Secure Boot
#FIXME

# Protect Xen with Secure Boot (if applicable)
#FIXME

# Finally, show 'sbctl status again'
echo "[*] Finally, verifying the UEFI Secure Boot status again..."
doas sbctl status
sleep 3
