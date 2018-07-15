param(
    $DomainName,
    $NetbiosName,
    $SafeModeAdministratorPassword,
    $IPAddress
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Check domain exists in case provisioner is ran again
if (-not (Get-WmiObject win32_computersystem).partofdomain)
{
    Install-WindowsFeature -Name AD-Domain-Services
    Import-Module ADDSDeployment

    Write-Host "Starting ADDS Forest installation at $(Get-Date). This clears NIC DNS settings..."
    $adForestParams = @{
        DomainName                    = $DomainName
        InstallDns                    = $true
        NoDnsOnNetwork                = $true
        CreateDnsDelegation           = $false
        SafeModeAdministratorPassword = (ConvertTo-SecureString $SafeModeAdministratorPassword -AsPlainText -Force)
        NoRebootOnCompletion          = $true
        Force                         = $true
        Verbose                       = $true
    }
    Install-ADDSForest @adForestParams

    Write-Host "Finished ADDS Forest installation at $(Get-Date)"

    Write-Host "Resetting NIC DNS settings..."
    #Set-DnsClientServerAddress -InterfaceAlias 'Ethernet' -ResetServerAddresses -Verbose
    Set-DnsClientServerAddress -InterfaceAlias 'Ethernet' -ServerAddresses $null -Verbose
    Set-DnsClient -InterfaceAlias 'Ethernet' -RegisterThisConnectionsAddress $false -Verbose
    Set-DnsClientServerAddress -InterfaceAlias 'Ethernet 2' -ServerAddresses $IPAddress, '127.0.0.1' -Verbose

    # Change NIC priority (metric)
    Set-NetIPInterface -InterfaceAlias 'Ethernet 2' -AddressFamily 'IPv4' -InterfaceMetric 10

    # Fix: restart Network Location Awareness service if Windows Firewall showing "Public" instead of "Domain"
    $serviceNames = 'NlaSvc'
    foreach ($serviceName in $serviceNames)
    {
        Invoke-Expression "sc.exe config $serviceName start=delayed-auto"
        Get-Service -Name $serviceName | Restart-Service -Force
    }
}
else
{
    Write-Host 'Domain exists already - skipping forest installation'
}
