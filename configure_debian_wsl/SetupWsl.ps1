# Run PowerShell as Administrator
# Enable WSL
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Enable Virtual Machine Platform
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart


# Enable-WindowsOptionalFeature requires Administrator privileges
if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell -Verb runAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList ''-NoProfile -ExecutionPolicy Bypass -File "$PSCommandPath"'' -Verb RunAs}"'
    exit
}

# Enable WSL feature if not already enabled
if ((Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux").State -eq "Disabled") {
    Write-Host "Installing WSL2..."
    Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -NoRestart
    Write-Host "Downloading WSL2 kernel update..."
    Invoke-WebRequest -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -OutFile "wsl_update_x64.msi"
    Write-Host "Installing WSL2 kernel update..."
    Start-Process "msiexec.exe" -ArgumentList "/i wsl_update_x64.msi /quiet" -Wait -NoNewWindow
    Remove-Item "wsl_update_x64.msi"
    wsl --set-default-version 2
} else {
    $wslVersion = $(wsl.exe --list --verbose 2>&1)
    if ($wslVersion -match 2) {
        Write-Host "WSL2 is already installed. Checking for kernel updates..."
        Write-Host "Downloading WSL2 kernel update..."
        Invoke-WebRequest -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -OutFile "wsl_update_x64.msi"
        Write-Host "Installing WSL2 kernel update..."
        Start-Process "msiexec.exe" -ArgumentList "/i wsl_update_x64.msi /quiet" -Wait -NoNewWindow
        Remove-Item "wsl_update_x64.msi"
    } elseif ($wslVersion -match 1) {
        Write-Host "Updating WSL1 to WSL2..."
        Enable-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -NoRestart
        Write-Host "Downloading WSL2 kernel update..."
        Invoke-WebRequest -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -OutFile "wsl_update_x64.msi"
        Write-Host "Installing WSL2 kernel update..."
        Start-Process "msiexec.exe" -ArgumentList "/i wsl_update_x64.msi /quiet" -Wait -NoNewWindow
        Remove-Item "wsl_update_x64.msi"
        wsl --set-default-version 2
    } else {
        Write-Host "WSL is installed, but no distributions are listed."
    }
}
