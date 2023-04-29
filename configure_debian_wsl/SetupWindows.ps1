# Install Chocolatey
if (!(Test-Path "$env:ProgramData\chocolatey")) {
    Set-ExecutionPolicy Bypass -Scope Process -Force;
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
} else {
    choco upgrade chocolatey
}

# Force close Visual Studio Code before installing or updating it
$VSCodeProcesses = Get-Process code -ErrorAction SilentlyContinue
if ($VSCodeProcesses) {
    $VSCodeProcesses | Stop-Process
}

# Install or update MS VS Code
choco upgrade vscode -y

# Install or update PuTTY if it is not already installed
choco upgrade putty -y

# Install common dependencies
wsl -d Debian sudo apt-get install gtk+-3.0
wsl -d Debian sudo apt-get install gstreamer0.10-plugins-base
wsl -d Debian sudo apt-get install libappindicator1
wsl -d Debian sudo apt-get install libnss3
wsl -d Debian sudo apt-get install libx11-6
wsl -d Debian sudo apt-get install libxcb-icccm4
wsl -d Debian sudo apt-get install libxcb-image0
wsl -d Debian sudo apt-get install libxcb-keysyms1
wsl -d Debian sudo apt-get install libxcb-randr0
wsl -d Debian sudo apt-get install libxcb-render-util0
wsl -d Debian sudo apt-get install libxcb-shape0
wsl -d Debian sudo apt-get install libxcb-shm0
wsl -d Debian sudo apt-get install libxcb-sync1
wsl -d Debian sudo apt-get install libxcb-xfixes0
wsl -d Debian sudo apt-get install libxcb-xtest0
wsl -d Debian sudo apt-get install libxcursor1
wsl -d Debian sudo apt-get install libxi6
wsl -d Debian sudo apt-get install libxrandr2
wsl -d Debian sudo apt-get install libxxf86vm1
wsl -d Debian sudo apt-get install dbus


# Install common plugins for MS VS Code for Java, Scala, Python, Powershell, Javascript, and Ruby
code --install-extension vscjava.vscode-java-pack
code --install-extension scalameta.metals
code --install-extension ms-python.python
code --install-extension ms-vscode.powershell
code --install-extension dbaeumer.vscode-eslint
code --install-extension rebornix.ruby

# Install or update WinRAR
choco upgrade winrar -y

# Install or update NPM and Yarn
choco upgrade nodejs-lts -y
choco upgrade yarn -y

# Install or update Git and Git Credential Manager for Windows
choco upgrade git -y
choco upgrade git-credential-manager-for-windows -y

# Install or update Bash for Windows (Windows Subsystem for Linux)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

# Install or update Java and the JDK for dev work
choco upgrade jdk8 -y

# Install or update WinDirStat and Beyond Compare
choco upgrade windirstat -y

choco upgrade beyondcompare -y


# Install or update VcXsrv, then create a windows with  properties’ in it's target that tells X Server the configuriations it needs to allow connections from the WSL Instance:
choco upgrade vcxsrv

$TargetFile = "C:\Program Files\VcXsrv\vcxsrv.exe"
$Arguments = ":0 -ac -terminate -lesspointer -multiwindow -clipboard -wgl -dpi auto"
$MyDocuments = [Environment]::GetFolderPath("MyDocuments")
$ShortcutFile = Join-Path $MyDocuments "VcxsrvForWsl.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Arguments = $Arguments
$Shortcut.Save()

$StartupFolder = [Environment]::GetFolderPath("Startup")
Copy-Item $ShortcutFile $StartupFolder

$Shell = New-Object -ComObject Shell.Application
$Folder = $Shell.Namespace((Split-Path $ShortcutFile))
$Item = $Folder.ParseName((Split-Path $ShortcutFile -Leaf))
$Item.InvokeVerb("Pintotaskbar")
$Item.InvokeVerb("PinToStartMenu")

# Enable systemd
if (Test-Path "%USERPROFILE%.wslconfig") {
    # Append the distribution name and init=systemd to the file.
    Get-Content "%USERPROFILE%.wslconfig" | Add-Content -Value "
    [install]
    distribution = $distributionName
    init = systemd"
    } else {
    # Create the .wslconfig file in the current user's directory.
    New-Item "%USERPROFILE%.wslconfig" -Type File
    Get-Content "%USERPROFILE%.wslconfig" | Add-Content -Value "
    [install]
    distribution = $distributionName
    init = systemd"
    }
    
    
    # Check if the .wslconfig file exists in the system directory.
$wslconfigPath = "C:\ProgramData\Microsoft\WSL.wslconfig"
if (Test-Path $wslconfigPath) {
    # Append the distribution name and init=systemd to the file.
    $wslconfigContent = Get-Content $wslconfigPath
    $wslconfigContent += "
    [install]
    distribution = $distributionName
    init = systemd"
    Set-Content $wslconfigPath $wslconfigContent
} else {
    # Create the .wslconfig file in the system directory.
    New-Item $wslconfigPath -Type File
    Set-Content $wslconfigPath "
    [install]
    distribution = $distributionName
    init = systemd"
}

# Restart the distribution.
wsl --shutdown $distributionName
wsl --start $distributionName