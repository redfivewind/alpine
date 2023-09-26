# System update
sudo pacman --disable-download-timeout --noconfirm -Syu

# Install ALSA and PulseAudio
sudo pacman --disable-download-timeout --needed --noconfirm -Sy alsa-plugins alsa-utils pulseaudio

# Clean up
sudo pacman -Rns $(pacman -Qdtq)
