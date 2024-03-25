# Start message
Write-Output "[*] Configuring Windows 11..."

# Administrator check
Write-Output "[*] Checking whether the current user has adminstrator rights..."
$l_current_user = [Security.Principal.WindowsIdentity]::GetCurrent()
$l_windows_principal = New-Object Security.Principal.WindowsPrincipal($l_current_user)

if ($l_windows_principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "[*] The current user has administrator rights..."
} else {
    Write-Output "[X] ERROR: The current user does not have Administrator rights. Returning..."
    return
}

# Windows Explorer
Write-Output "[*] Configuring Windows Explorer..."
#FIXME

# Dark mode
Write-Output "[*] Enabling dark mode..."
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'SystemUsesLightTheme' -Value '0' -PropertyType DWORD -Force
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -Value '0' -PropertyType DWORD -Force

# Chocolate software management
Write-Output "[*] Installing Chocolate software management..."
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Base packages
Write-Output "[*] Installing base packages..."
choco install 7zip ccleaner librewolf vlc vscodium --acceptlicence --confirm --ignoredetectedreboot

# Windows Updates
#Write-Output "[*] Enabling optional Windows updates..."
#Set-GPRegistryValue -Name "LocalMachine" -Key "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\System" -ValueName "DisableCMD" -Type DWORD -Value 1

Write-Output "[*] Installing Windows updates..."
Install-Module -Name PSWindowsUpdate -Force
Update-WUModule
Get-WUList -MicrosoftUpdate
Install-WindowsUpdate -AcceptAll -IgnoreReboot -MicrosoftUpdate
