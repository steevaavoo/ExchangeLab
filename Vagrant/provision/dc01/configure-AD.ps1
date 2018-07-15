param(
    $DomainName = 'lab.local',
    $DomainController = 'dc01',
    $SiteName = 'Default-First-Site-Name',
    $Subnet = '192.168.56.0/24',
    $ReverseZone = '56.168.192.in-addr.arpa'
)

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
    Start-Sleep -Seconds 3

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


# Create a new Active Directory Site
# Use try/catch as ErrorAction 'Ignore' does not work
try {
    $adReplicationSubnet = Get-ADReplicationSubnet -Identity $Subnet -ErrorAction 'Stop' -Verbose
}
catch {}

if (-not $adReplicationSubnet) {
    #New-ADReplicationSubnet seems to have a bug and reports Access Denied.
    #New-ADReplicationSubnet -Name $subnetName -Site $defaultSite -PassThru -Server localhost

    #$defaultSite = Get-ADReplicationSite -Identity Default-First-Site-Name -Server localhost
    $ctx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext([System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Forest)
    $defaultSite = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::FindByName($ctx, 'Default-First-Site-Name')

    $adSubnet = New-Object System.DirectoryServices.ActiveDirectory.ActiveDirectorySubnet($ctx, $Subnet)
    $adSubnet.Site = $defaultSite
    $adSubnet.Save()

    Write-Host "`nCOMPLETED: Creating subnet [$Subnet]." -ForegroundColor 'Green'
}
else {
    Write-Host "SKIPPING: [$Subnet] subnet already exists." -ForegroundColor 'Gray'
}


# Configure DNS Reverse Lookup
if (-not (Get-DnsServerZone -Name $ReverseZone -ErrorAction 'SilentlyContinue' -Verbose)) {
    Add-DnsServerPrimaryZone -DynamicUpdate 'Secure' -NetworkId $Subnet -ReplicationScope 'Domain' -ComputerName $DomainController -Verbose
    Write-Host "`nCOMPLETED: Creating zone [$ReverseZone]." -ForegroundColor 'Green'
}
else {
    Write-Host "SKIPPING: [$ReverseZone] zone already exists." -ForegroundColor 'Gray'
}
