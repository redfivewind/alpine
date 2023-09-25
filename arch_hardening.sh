# Update the system
sudo pacman --disable-download-timeout --needed --noconfirm -Syu 

# Remove software
#FIXME

# Disable history for bash
echo "export HISTFILESIZE=0" >> /etc/profile
echo "export HISTSIZE=0" >> /etc/profile
echo "set +o history" >> /etc/profile
echo "unset HISTFILE" >> /etc/profile

echo "export HISTFILESIZE=0" >> /etc/profile.d/disable.history.sh
echo "export HISTSIZE=0" >> /etc/profile.d/disable.history.sh
echo "set +o history" >> /etc/profile.d/disable.history.sh
echo "unset HISTFILE" >> /etc/profile.d/disable.history.sh

echo "export HISTFILESIZE=0" >> ~/.bashrc
echo "export HISTSIZE=0" >> ~/.bashrc
echo "set +o history" >> ~/.bashrc
echo "unset HISTFILE" >> ~/.bashrc

echo "export HISTFILESIZE=0" >> ~/.bash_profile
echo "export HISTSIZE=0" >> ~/.bash_profile
echo "set +o history" >> ~/.bash_profile
echo "unset HISTFILE" >> ~/.bash_profile

# New MAC address at each reboot
sudo pacman --disable-download-timeout --needed --noconfirm -Sy macchanger

# New hostname at each reboot
#FIXME

# Disable auto-mounting
sudo systemctl stop autofs
sudo systemctl disable autofs

# TODO: Enable automatic updates
# TODO: Disable file access timestamps to be saved (noatime)
# TODO: No automount
# TODO: Disable further logs (forensic mode)
# TODO: Periodical checks (file integrity, rkhunter, chkrootkit, ...)
# TODO: No open ports
# TODO: Control Startup Applications

# Restrict SSH (no remote access, no root login, NO SSHD)
echo "PermitRootLogin no" >> /etc/ssh/ssh_config

# Clean up
sudo pacman -Rns $(pacman -Qdtq)
sudo paccache -r
