# ARGUMENT: Platform (bios, uefi, uefi-sb)
# ARGUMENT: Disk
# ARGUMENT: Mode (core, core_kvm, core_xen, core_virt)
# ARGUMENT: Desktop Environment (none, xfce)

# ARGUMENT: Audio
# ARGUMENT: Bluetooth
# ARGUMENT: Network (Broadband, Ethernet, General, WiFi, ...)

# TODO: Core: Automatic sleep/hibernate & resume
# TODO: Core: HARDENING!!!
# TODO: DE: Xfce (Add keyboard shortcut WIN+L, Remove keyboard shortcut CTRL+ALT+L)

# Start message
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Global variables
echo "[*] Initializing global variables..."
DISK=""
LUKS_PASS=""
LV_ROOT="lv_root"
LV_SWAP="lv_swap"
LVM_VG="lvm_vg"
LUKS_LVM="luks_lvm"
PART_EFI=""
PART_LUKS=""
PLATFORM=""
SCRIPT=$(readlink -f "$0")
USER_NAME="user"
USER_PASS=""

# Argument parsing


# German keyboard layout
echo "[*] Loading German keyboard layout..."
setup-keymap de de

#FIXME

# Stop message
echo "[*] Work done. Returning..."
return
