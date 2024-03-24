# Start message
Write-Output "[*] Configuring Windows 11..."

# Administrator check
$l_current_user = [Security.Principal.WindowsIdentity]::GetCurrent()
$l_windows_principal = New-Object Security.Principal.WindowsPrincipal($l_current_user)

if ($l_windows_principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "[*] The current user has Administrator rights..."
} else {
    Write-Output "[X] ERROR: The current user does not have Administrator rights. Returning..."
    return
}

# Windows Explorer

# Dark mode
Write-Output "[*] Enabling dark mode..."
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'SystemUsesLightTheme' -Value '0' -PropertyType DWORD -Force
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -Value '0' -PropertyType DWORD -Force

# Chocolate software management
Write-Output "[*] Installing Chocolate software management..."
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Base packages
choco install 

# Windows Updates
Install-Module -Name PSWindowsUpdate -Force
Update-WUModule
Get-WUList -MicrosoftUpdate
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot
