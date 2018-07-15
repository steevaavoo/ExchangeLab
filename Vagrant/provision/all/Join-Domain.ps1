param (
    $DomainName,
    $UserName,
    $Password,
    $DomainControllerIP
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Creds
Write-Host 'Creating credential object'
$securePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential($UserName, $securePassword)

# Set DNS IP Address
Write-Host 'Setting DNS IP address'
$networkAddress = $DomainControllerIP.Remove($DomainControllerIP.LastIndexOf('.'))
Get-NetIPAddress -IPAddress "$networkAddress*" | Set-DnsClientServerAddress -ServerAddresses $DomainControllerIP
Set-DnsClientGlobalSetting -SuffixSearchList $DomainName

# Change NIC priority (metric)
Set-NetIPInterface -InterfaceAlias 'Ethernet 2' -AddressFamily 'IPv4' -InterfaceMetric 10

# Join domain
if ((Get-WmiObject win32_computersystem).partofdomain -eq $false)
{
    Write-Host "Joining computer to domain $DomainName"
    Add-Computer -ComputerName 'localhost' -Credential $creds -DomainName $DomainName -Restart:$false
}
