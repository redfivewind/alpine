# System update
pacman --disable-download-timeout --noconfirm -Syu

# Install ALSA and PulseAudio
pacman --disable-download-timeout --needed --noconfirm -Sy alsa-plugins alsa-utils pulseaudio pulseaudio-plugins pulseaudio-utils

# Remove packages that are no longer required
sudo pacman --noconfirm -Rns $(pacman -Qdtq)
