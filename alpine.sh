# ARGUMENT: Platform (bios, uefi, uefi-sb)
# ARGUMENT: Mode (none, hv_kvm, hv_xen, virt)
# ARGUMENT: Switch (audio, ethernet, network, wireless)
# ARGUMENT: Hardening
# ARGUMENT: Desktop Environment (none, xfce)

# Start message
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."

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
