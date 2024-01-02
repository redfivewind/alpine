# Global variables
USER="user"

# System update
echo "Updating the system..."
sudo pacman --disable-download-timeout --needed --noconfirm -Syu

# Install required packages
pacman --disable-download-timeout --needed --noconfirm -S \
  bridge-utils \
  dnsmasq \
  ebptables \
  libguestfs \
  libvirt \
  openbsd-netcat \
  qemu \
  vde2 \
  virt-manager \
  virt-viewer
#dmidecode ebtables edk2-ovmf seabios

# Enable libvirtd service
sudo systemctl enable --now libvirtd
sudo systemctl status libvirtd

# Allow standard user to use libvirtd service
echo "unix_sock_group = \"libvirt\"" | sudo tee -a /etc/libvirt/libvirtd.conf
echo "unix_sock_rw_perms = \"0770\"" | sudo tee -a /etc/libvirt/libvirtd.conf

sudo usermod -a -G libvirt $USER

sudo systemctl restart libvirtd
sudo systemctl status libvirtd
