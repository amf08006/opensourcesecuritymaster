
# Install or update Chocolatey
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
} else {
    choco upgrade chocolatey
}


# Install wget
wsl -d Debian sudo apt-get install wget

# Enable WSL
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Enable Virtual Machine Platform
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Install Debian
wsl --install -d Debian -q 

# Update Debian
wsl -d Debian sudo apt-get update
wsl -d Debian sudo apt-get upgrade -y

# Update packawsl -d Debian -- sudo dpkg -i $downloadPath
wsl -d Debian -- sudo apt update

# Create new user with same username as current Windows user and add to sudo group if it does not already exist
$username = [Environment]::UserName
wsl -d Debian sh -c "id -u $username &>/dev/null || (sudo adduser $username && sudo adduser $username sudo)"

# Configure sudo to not require a password for your user
wsl -d Debian sudo sh -c "echo '$username ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"


# Install shells: Zsh (and Oh My Zsh), Fish, and Git
# Install required packages using apt-get
wsl -d sudo apt-get install wget
wsl -d Debian sudo apt-get update
wsl -d Debian sudo apt-get install -y zsh fish curl wget git

# Define the WSL distribution name, replace 'Debian' with your WSL distribution's name if it's different
    $wslDistroName = "Debian"

    # Update package lists and install required dependencies
    Invoke-Expression "wsl -d Debian sudo apt-get update"
    Invoke-Expression "wsl -d Debian sudo apt-get install -y curl libsecret-1-0"

 # Set up VcXsrv for use with WSL (Should not be needed anymore with new Windows Subsystem for Linux (wslG))
    choco upgrade vcxsrv
    $display = "export DISPLAY=$(wsl -d Debian cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0"
    wsl -d Debian sh -c "echo $display >> ~/.bashrc"
    wsl -d Debian sh -c "echo $display >> ~/.zshrc"
    wsl -d Debian 'sh -c "mkdir -p ~/.config/fish && echo ''set -x DISPLAY (cat /etc/resolv.conf | grep nameserver | awk \"{print \\$2}\"):0'' >> ~/.config/fish/config.fish"'
    $libgl = "export LIBGL_ALWAYS_INDIRECT=1"
    wsl -d Debian sh -c "echo $libgl >> ~/.bashrc"
    wsl -d Debian sh -c "echo $libgl >> ~/.zshrc"
    wsl -d Debian sudo sh -c "mkdir -p ~/.config/fish && echo 'set -x LIBGL_ALWAYS_INDIRECT 1' >> ~/.config/fish/config.fish"

# Install oh-my-zsh
    wsl -d Debian sh -c '$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)'

# Get the Debian WSL IP address
$debianIP = wsl -d Debian -- ip addr show eth0 | Select-String -Pattern 'inet\s' | %{ $_.Matches.Groups[2].Value }

# Check if IP was found
if ($debianIP -ne $null) {
    # Update the TrustedHosts configuration
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $debianIP -Force
    Write-Host "TrustedHosts updated with IP address: $debianIP"
} else {
    Write-Host "Debian WSL IP address not found"
}

# Forward common ports used for developing web applications
    Write-Output("Forward common ports used for developing web applications and other development work from the Windows host to the WSL instance")
    $ports = 3000, 3001, 5000, 8000, 8080, 8888
    $wslIp = wsl hostname -I
    $wslIp = $wslIp.Trim()
    foreach ($port in $ports) {
        # Allow incoming connections on the port in the Windows Firewall
        New-NetFirewallRule `
            -DisplayName "WSL Port Forwarding (TCP-In) Port $port"
    }

# Install common build essentials
    Write-Output("Install build essentials")
    wsl -d Debian sudo apt-get install build-essential autoconf libtool -y
    wsl -d Debian sudo apt-get install build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev python3-pip python3-setuptools python3-wheel python3-dev -y
    wsl -d Debian sudo apt-get install libcups2 libpangocairo-1.0-0 libatk-adaptor libxss1 libnss3 libxcb-keysyms1 x11-apps libgbm1 -y


# Get the IP address of your Debian instance
$debianIp = wsl -d Debian -- ip addr show | Where-Object { $_ -match 'inet\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})' } | ForEach-Object { $Matches[1] }

# Run the commands to create the xorg.conf file and restart the X server
Invoke-Command -ScriptBlock {
    $xorgconf = @"
Section "ServerFlags"
    Option "Xinerama" "on"
EndSection

Section "Device"
    Identifier    "Configured Video Device"
    Driver        "vesa"
EndSection

Section "Screen"
    Identifier    "Default Screen"
    Device        "Configured Video Device"
    Monitor        "Configured Monitor"
    DefaultDepth    16
    SubSection "Display"
        Modes      "1024x768_60.00"
    EndSubSection
EndSection
"@

# Write the xorg.conf file to disk
$xorgconfPath = "/etc/X11/xorg.conf"

If (-not (Test-Path $xorgconfPath)) {
    # Create the xorg.conf file
    wsl -d Debian -- sh -c "echo '$xorgconf' > '$xorgconfPath'"
}

# Restart the X server
Start-Process "C:\Program Files\VcXsrv\vcxsrv.exe" -ArgumentList ":0 -ac -terminate -lesspointer -multiwindow -clipboard -wgl -dpi auto"
}

# Install your Nautilus to navigate the WSL Linux file directory
    Write-Output("Install a linux GUI File Explorer")
    wsl -d Debian sudo apt-get install nautilus -y
    wsl -d Debian sudo apt-get update nautilus -y

# Install JetBrains Toolboox. Use the app to upgrade itself and install the IDEs on your WSL that you actually want
    Write-Output("Install JetBrains toolbox")
    wsl -d Debian -- wget -O ~/jetbrains-toolbox.tar.gz https://download.jetbrains.com/toolbox/jetbrains-toolbox-1.21.9712.tar.gz
    wsl -d Debian -- mkdir -p ~/opt
    wsl -d Debian -- sudo tar -xzf ~/jetbrains-toolbox.tar.gz -C ~/opt

    Write-Output("Find the jetbrains-toolbox application and put it into an Applications folder")
    $FilePath = wsl -d Debian -- sh -c 'find ~ -maxdepth 3 -name "jetbrains-toolbox" -type f | sort -r | head -n 1'
    if ($FilePath) {
        wsl -d Debian -- sh -c "sudo cp '$FilePath' ~/Applications"
    }

# Setup Microsoft Edge internet browser
    wsl -d Debian gpg --keyserver keys.gnupg.net --recv-key D2C19886
    wsl -d Debian sudo apt-get install microsoft-edge-dev -y

# Install x11 apps
    wsl -d Debian sudo apt install x11-apps -y

# Install VLC
    wsl -d Debian sudo apt install vlc -y

# Install GIMP
    wsl -d Debian sudo apt install gimp -y


# This script downloads and installs Git Credential Manager for Windows (GCMC)
# and sets it as the default credential manager for Git.

    # Check if GCMC is already installed.
    if (Get-Command "git-credential-manager-core" -ErrorAction SilentlyContinue) {
        # GCMC is already installed. Exit.
        exit 0;
    }
  
    # Download GCMC.
    Write-Host "Downloading GCMC..."
    Invoke-WebRequest "https://github.com/microsoft/Git-Credential-Manager-Core/releases/download/v2.0.452.3248/git-credential-manager-core.exe" -OutFile "git-credential-manager-core.exe"
    
    # Switch to the Debiasn WSL instance.
    Write-Host "Switching to the Debian WSL instance..."
    wsl -d Debian -y
    
    # Install GCMC.
    Write-Host "Installing GCMC..."
    Start-Process "git-credential-manager-core.exe" /S /V
    
    # Set GCMC as the default credential manager for Git.
    Write-Host "Setting GCMC as the default credential manager for Git..."
    git config --global credential.helper manager
    
    # Success!
    Write-Host "GCMC has been successfully installed and set as the default credential manager for Git."

    Write-Host("Line 141")

# Install Google Chrome For Linux
Write-Host "Changing directory"
wsl -d Debian -e "cd /tmp"
Write-Host "Runniing wget google chrome"
wsl -d Debian -e "sudo wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"

Write-Host "Installing Google Chrome..."
wsl -d Debian sudo dpkg -i google-chrome-stable_current_amd64.deb
wsl -d Debian -e "sudo apt install --fix-broken -y"
wsl -d Debian sudo dpkg -i google-chrome-stable_current_amd64.deb