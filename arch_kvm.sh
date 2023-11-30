# Update the system
echo "[*] Updating the system..."
sudo pacman -Syyu
sleep 1

# Install KVM-related packages
echo "[*] Installing KVM-related packages..."
sudo pacman --disable-download-timeout --needed --noconfirm -S bridge-utils dmidecode dnsmasq ebtables iptables-nft libguestfs libvirt openbsd-netcat ovmf qemu-full vde2 virt-manager virt-viewer
sleep 1

# Enable & start the libvirt service
echo "[*] Enabling & starting the libvirtd service..."
sudo systemctl enable --now libvirtd
sudo systemctl status libvirtd
sleep 1

# Allow the standard user to use KVM
echo "[*] Configuring KVM to be used by standard users..."
echo "unix_sock_group = \"libvirt\"" | sudo tee -a /etc/libvirt/libvirtd.conf
echo "unix_sock_rw_perms = \"0770\"" | sudo tee -a /etc/libvirt/libvirtd.conf
tail /etc/libvirt/libvirtd.conf
sleep 1

# Add the standard user to the libvirt group
echo "[*] Adding the current user to the 'libvirt' group..."
sudo usermod -a -G libvirt $(whoami)
sleep 1

# Restart the libvirt service
echo "[*] Restarting the libvirtd service..."
sudo systemctl restart libvirtd
sudo systemctl status libvirtd
sleep 1

# Enable nested virtualisation
echo "[*] Enabling nested virtualisation..."
echo "options kvm-amd nested=1" | sudo tee -a /etc/modprobe.d/kvm.conf
echo "options kvm-intel nested=1" | sudo tee -a /etc/modprobe.d/kvm.conf
#cat /etc/modprobe.d/kvm.conf
sleep 1

# Create a network bridge
echo "[*] Creating the network bridge 'br0'..."
echo "<network><name>br0</name><forward mode='nat'><nat><port start='1024' end='65535'/></nat></forward><bridge name='br0' stp='on' delay='0'/><ip address='10.0.0.1' netmask='255.255.255.0'><dhcp><range start='10.0.0.2' end='10.0.0.254'/></dhcp></ip></network>" > /tmp/br0.xml
sudo virsh net-define /tmp/br0.xml
sudo virsh net-start br0
sudo virsh net-autostart br0

# Correct folder ownership
sudo chown -R user:users ~/tools
sudo chown -R user:users ~/workspace

# Install yay for access to the AUR ecosystem
sudo pacman --disable-download-timeout --needed --noconfirm -S git go

sudo mkdir -p ~/tools
cd ~/tools
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
yay --version
