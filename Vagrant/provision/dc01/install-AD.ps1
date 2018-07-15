param (
    $IPAddress
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Install AD features
# Add-WindowsFeature 'RSAT-AD-Tools' (not required due to -IncludeManagementTools)
Add-WindowsFeature -Name 'ad-domain-services' -IncludeAllSubFeature -IncludeManagementTools
Add-WindowsFeature -Name 'dns' -IncludeAllSubFeature -IncludeManagementTools
Add-WindowsFeature -Name 'gpmc' -IncludeAllSubFeature -IncludeManagementTools

# Set Primary DNS Address for DC to "find" itself
Set-DnsClientServerAddress -InterfaceAlias 'Ethernet 2' -ServerAddresses $IPAddress

# Force the DNS server to bind to $IPAddress
dnscmd $env:COMPUTERNAME /ResetListenAddresses $IPAddress

# Set Primary DNS Address for DC to "find" itself
Set-DnsClientServerAddress -InterfaceAlias 'Ethernet 2' -ServerAddresses $IPAddress, '127.0.0.1' -Verbose
