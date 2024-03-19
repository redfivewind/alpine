# ARGUMENT: Platform (bios, uefi, uefi-sb)
# ARGUMENT: Mode (none, hv_kvm, hv_xen, virt)
# ARGUMENT: Enable LUKS?
# ARGUMENT: Switch (audio, ethernet, network, wireless)
# ARGUMENT: Hardening
# ARGUMENT: Desktop Environment (none, xfce)

# Start message
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."

# Global variables
echo "[*] Initializing global variables..."
DEV=""
LUKS_PASS=""
LV_ROOT="lv_root"
LV_SWAP="lv_swap"
LVM_VG="lvm_vg"
LUKS_LVM="luks_lvm"
PART_EFI=""
PART_LUKS=""
SCRIPT=$(readlink -f "$0")
USER_NAME="user"
USER_PASS=""

# Argument parsing
