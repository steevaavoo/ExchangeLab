param(
    $Members = 'vagrant',
    $DomainName = 'lab.local',
    $DomainController = 'dc01'
)

# Update Service as per this issue: https://www.interfacett.com/blogs/problem-using-active-directory-web-services-in-powershell/
try {
    $serviceName = 'ADWS'
    & cmd /c "sc config $serviceName start= delayed-auto"
}
catch {
    Write-Error "ERROR: Updating StartMode of [$serviceName] to [Automatic (Delayed Start)]" -ErrorAction 'Continue'
    throw $_
}

# Restart service
try {
    Restart-Service -Name $serviceName -Verbose
}
catch {
    Write-Error "ERROR: Restarting service [$serviceName]" -ErrorAction 'Continue'
    throw $_
}

# Import AD module
try {
    $env:ADPS_LoadDefaultDrive = 0
    $WarningPreference = 'SilentlyContinue'
    Import-Module 'ActiveDirectory' -ErrorAction 'Stop'
}
catch {
    Write-Error "ERROR: Importing ActiveDirectory module" -ErrorAction 'Continue'
    throw $_
}

# Wait for Active Directory to be responsive
do {
    Write-Host "`nWaiting for Active Directory to become available..." -ForegroundColor 'Yellow'
    Start-Sleep -Seconds 10

    # Query Active Directory
    try {
        $adDomainController = (Get-ADDomainController -Server $DomainController -ErrorAction 'Stop')
    }
    catch {
        Write-Host "Active Directory not yet responsive..." -ForegroundColor 'Gray'
    }

}
until ($null -ne $adDomainController)

Write-Host "`nActive Directory now available on $($adDomainController)" -ForegroundColor 'Green'
$adDomainController | Format-List *


# Add vagrant to Domain Admins, Schema Admins and Enterprise Admins (allowing for Exchange Setup Org Prep)
Write-Host "Adding these Users to Domain Admins group: $($Members -join ', ')" -ForegroundColor 'Yellow'
Add-ADGroupMember -Identity "Domain Admins" -Members $Members -Server $DomainController
Add-ADGroupMember -Identity "Schema Admins" -Members $Members -Server $DomainController
Add-ADGroupMember -Identity "Enterprise Admins" -Members $Members -Server $DomainController


# Relax password policy for domain
Set-ADDefaultDomainPasswordPolicy -ComplexityEnabled:$false -Identity $DomainName -Server $DomainController
