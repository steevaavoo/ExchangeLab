param(
    [string]$ModuleName
)

# Pre-empting the NuGet upgrade prompt in the following section...
Install-PackageProvider -Name "Nuget" -Force

# Prepping for DSC by installing required modules
$moduleNames = $ModuleName -split ','
Write-Host "Installing Modules:$($moduleNames | Out-String)"
Install-Module -Name $moduleNames -Force -Verbose -Scope 'AllUsers'
Write-Host 'Done!'
