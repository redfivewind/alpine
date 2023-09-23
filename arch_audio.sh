# System update
pacman --disable-download-timeout -Syu

# Install ALSA and PulseAudio
pacman --disable-download-timeout -Syy --noconfirm alsa-plugins alsa-utils pulseaudio pulseaudio-plugins pulseaudio-utils
