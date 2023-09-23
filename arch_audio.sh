# System update
pacman --disable-download-timeout --noconfirm -Syu

# Install ALSA and PulseAudio
pacman --disable-download-timeout -Syy --noconfirm alsa-plugins alsa-utils pulseaudio pulseaudio-plugins pulseaudio-utils

# Remove packages that are no longer required
sudo pacman -Rns $(pacman -Qdtq)
