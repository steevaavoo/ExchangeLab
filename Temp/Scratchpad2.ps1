$excludemodulenames = 'PackageManagement', 'PSDesiredStateConfiguration'

# Creating a variable with all DSCResources not in $excludemodulenames
$dscmodules = Get-DscResource | Where-Object { $_.ModuleName -notin $excludemodulenames } | Select-Object -ExpandProperty ModuleName -Unique

# Uninstalling all discovered modules
$dscmodules | ForEach-Object  { Uninstall-Module -Name $_ -Verbose -AllVersions }

# Installing latest versions of above modules
Install-Module -Name $dscmodules -Verbose
