# Start message
echo "[*] Updating Alpine Linux..."

# Global variables
echo "[*] Initialising global variables..."
TMP_XEN_CFG="/tmp/xen.cfg"
TMP_XEN_EFI="/tmp/xen.efi"
TMP_XSM_CFG="/tmp/xsm.cfg"
USER_NAME=$(whoami)
XEN_EFI="/boot/efi/EFI/xen.efi"
XEN_SECT_NAME_ARRAY=".pad .config .ramdisk .kernel"
#.xsm .ucode
XEN_SECT_PATH_ARRAY="$TMP_XEN_CFG /boot/initramfs-lts /boot/vmlinuz-lts"
#$TMP_XSM_CFG /boot/intel-ucode.img

# Check user rights
if [ $(id --user) == "0" ];
then
    echo "[*] User has elevated rights. Continuing..."
else
    echo "[X] ERROR: The scripts must be run with elevated rights."
    exit 1
fi

# Update packages
echo "[*] Updating packages..."
apk update
apk upgrade

# Generate UEFI Secure Boot bundles
echo "[*] Generating UEFI Secure Boot bundles using sbctl..."
sbctl generate-bundles --sign

# Generate unified Xen kernel image
echo "[*] Generating the Xen configuration file '$TMP_XEN_CFG'..."

shred -f -z -u $TMP_XEN_CFG
echo '[global]' | tee $TMP_XEN_CFG
echo 'default=alpine-linux' | tee -a $TMP_XEN_CFG
echo '' | doas tee -a $TMP_XEN_CFG
echo "[alpine-linux]" | tee -a $TMP_XEN_CFG
echo "options=com1=115200,8n1 console=com1,vga flask=disabled guest_loglvl=all iommu=debug,force,verbose loglvl=all noreboot vga=current,keep" | tee -a $TMP_XEN_CFG
echo "kernel=vmlinuz-lts $(cat /etc/kernel/cmdline) console=hvc0 console=tty0 earlyprintk=xen nomodeset" | tee -a $TMP_XEN_CFG
echo "ramdisk=initramfs-lts" | tee -a $TMP_XEN_CFG
sleep 3

# Generate Xen XSM configuration file
echo "[*] Generating the Xen XSM configuration file '$TMP_XSM_CFG'..."

echo '' | tee $TMP_XSM_CFG #FIXME
sleep 3

# Generate unified Xen kernel image
echo "[*] Generating the unified Xen kernel image (UKI)..."
cp /usr/lib/efi/xen.efi $TMP_XEN_EFI

while [ -n "$XEN_SECT_PATH_ARRAY" ];
do
    # Retrieve parameters
    set -- $XEN_SECT_NAME_ARRAY
    SECT_NAME_CURRENT=$2
    SECT_NAME_PREVIOUS=$1

    set -- $XEN_SECT_PATH_ARRAY
    SECT_PATH=$1

    # Add new section
    echo "[*] Writing '$SECT_PATH' to the new $SECT_NAME_CURRENT section..."
    OBJDUMP=$(doas objdump -h "$TMP_XEN_EFI" | grep "$SECT_NAME_PREVIOUS")
    set -- $OBJDUMP
    VMA=$(printf "0x%X" $((((0x$3 + 0x$4 + 4096 - 1) / 4096) * 4096)))
    doas objcopy --add-section "$SECT_NAME_CURRENT"="$SECT_PATH" --change-section-vma "$SECT_NAME_CURRENT"="$VMA" $TMP_XEN_EFI $TMP_XEN_EFI

    # Update the section name & path array
    XEN_SECT_NAME_ARRAY=$(echo "$XEN_SECT_NAME_ARRAY" | sed 's/^[^ ]* *//')
    XEN_SECT_PATH_ARRAY=$(echo "$XEN_SECT_PATH_ARRAY" | sed 's/^[^ ]* *//')
done

objdump -h $TMP_XEN_EFI
sleep 3

# Copy Xen UKI to EFI partition
echo "[*] Copying the Xen UKI to the EFI partition..."
cp $TMP_XEN_EFI $XEN_EFI

# Sign Xen UKI using sbctl
echo "[*] Signing the Xen UKI using sbctl..."
sbctl sign $XEN_EFI

# Stop message
echo "[*] Work done. Exiting..."
exit 0
