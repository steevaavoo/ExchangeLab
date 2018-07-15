# VSCode
# Extensions
Write-Host 'Installing VS Code extensions...' -ForegroundColor 'Yellow'
$codeCmdPath = Join-Path -Path $env:ProgramFiles -ChildPath 'Microsoft VS Code\bin\code.cmd'
$extensions = 'ms-vscode.PowerShell', 'eamodio.gitlens', 'DotJoshJohnson.xml', 'robertohuertasm.vscode-icons', 'CoenraadS.bracket-pair-colorizer'

foreach ($extension in $extensions) {
    Write-Host "`nInstalling extension $extension..." -ForegroundColor 'Yellow'
    & $codeCmdPath --install-extension $extension
}

# Copy config settings
$copyScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'vscode\Copy-Settings.ps1'
& $copyScriptPath


# Configure Folder Options
$singleClickRegPath = Join-Path -Path $PSScriptRoot -ChildPath 'Single-click-to-open.reg'
& regedit.exe /s $singleClickRegPath

$key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

Write-Host "Enabling showing hidden files"
Set-ItemProperty $key Hidden 1

Write-Host "Disabling hiding extensions for known files"
Set-ItemProperty $key HideFileExt 0

Write-Host "Disabling showing hidden operation system files"
Set-ItemProperty $key ShowSuperHidden 0

Write-Host "Uncheck sharing wizard"
Set-ItemProperty $key SharingWizardOn 0

Write-Host "Restore previous folder windows at logon"
Set-ItemProperty $key PersistBrowsers 1

Write-Host "Disabling explorer Quick View"
Set-ItemProperty $key LaunchTo 1

Write-Host "Restarting explorer shell to apply registry changes"
Stop-Process -ProcessName 'explorer' -Force


# Open common folders
$folderNames = 'C:\vagrant', 'C:\Program Files\WindowsPowerShell\Modules', 'C:\Windows\System32\Configuration\ConfigurationStatus'
$folderNames | ForEach-Object {explorer.exe $_}


# Open useful apps
$controlPanels = 'appwiz.cpl' #, 'Ncpa.cpl'
$controlPanels | ForEach-Object {control $_}
regedit.exe
services.msc
ServerManager.exe


# Disable firewall during dev
Set-NetFirewallProfile -Profile 'Domain', 'Public', 'Private' -Enabled 'False'


# Set max computer password age - this fix bug when you rollback a snapshot and lose secure computer channel
$maxCompPasswordAgePath = Join-Path -Path $PSScriptRoot -ChildPath 'Set-MaximumComputerPasswordAge.reg'
& regedit.exe /s $maxCompPasswordAgePath
