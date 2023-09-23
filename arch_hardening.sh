# Update the system
sudo pacman --disable-download-timeout --noconfirm -Syu 


# Remove software
#


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
sudo pacman --disable-download-timeout --noconfirm -Sy macchanger


# New hostname at each reboot


# Disable auto-mounting
sudo systemctl stop autofs
sudo systemctl disable autofs


# Enable automatic updates


# Disable file access timestamps to be saved (noatime)


# Disable further logs (forensic mode)


# Restrict SSH (no remote access, no root login, NO SSHD)
echo "PermitRootLogin no" >> /etc/ssh/ssh_config

# Remove Avahi
