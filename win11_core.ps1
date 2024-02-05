# Administrator check

# Windows Explorer

# Dark mode
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'SystemUsesLightTheme' -Value '0' -PropertyType DWORD -Force
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -Value '0' -PropertyType DWORD -Force

# Chocolate software

# Base packages
#FIXME: LibreWolf VSCodium CCleaner 7zip

# Windows Updates
