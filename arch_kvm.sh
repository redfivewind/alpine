# Update the system
sudo pacman -Syyu
sleep 1

# Install KVM-related packages
sudo pacman --disable-download-timeout --needed --noconfirm -S bridge-utils dnsmasq ebtables iptables-nft libguestfs libvirt openbsd-netcat ovmf qemu-full vde2 virt-manager virt-viewer
sleep 1

# Allow the standard user to use KVM
echo "unix_sock_group = \"libvirt\"" >> /etc/libvirt/libvirtd.conf
echo "unix_sock_rw_perms = \"0770\"" >> /etc/libvirt/libvirtd.conf
#cat /etc/libvirt/libvirtd.conf
sleep 1

# Add the standard user to the libvirt group
sudo newgrp libvirt
sudo usermod -a -G libvirt $(whoami)
sleep 1

# Start the libvirt service
sudo systemctl enable --now libvirtd.service
sudo systemctl status libvirtd.service
sleep 1

# Enable nested virtualisation
echo "options kvm-amd nested=1" | sudo tee -a /etc/modprobe.d/kvm.conf
echo "options kvm-intel nested=1" | sudo tee -a /etc/modprobe.d/kvm.conf
#cat /etc/modprobe.d/kvm.conf
sleep 1

# Create a network bridge
echo "<network><name>br0</name><forward mode='nat'><nat><port start='1024' end='65535'/></nat></forward><bridge name='br0' stp='on' delay='0'/><ip address='10.0.0.1' netmask='255.255.255.0'><dhcp><range start='10.0.0.2' end='10.0.0.254'/></dhcp></ip></network>" > /tmp/br0.xml
sudo virsh net-define /tmp/br0.xml
sudo virsh net-start br0
sudo virsh net-autostart br0
