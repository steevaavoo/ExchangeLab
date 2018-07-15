$domainName = 'lab.milliondollar.me.uk'
$InterfaceAlias = 'Ethernet'
$ipAddressToRemove = '10.0.2.15'
$hostnames = '@', 'DomainDnsZones', 'ForestDnsZones'

Test-ComputerSecureChannel
nltest /sc_verify:$domainName
nltest /dsgetdc:$domainName /force

ipconfig /flushdns

nslookup $domainName
nslookup 'dc01.lab.milliondollar.me.uk'
nslookup dc01

$aRecords = Get-DnsServerResourceRecord -ZoneName $domainName -RRType "A" 
$aRecords
$aRecords[1] | fl * 

Get-DnsServerResourceRecord -ZoneName 'lab.milliondollar.me.uk' -RRType "A"


# Remove all DNS A records for the first NIC used by Vagrant on '10.0.2.15'
foreach ($hostname in $hostnames) {
    Remove-DnsServerResourceRecord -ZoneName $domainName -RRType 'A' -Name $hostname -RecordData $ipAddressToRemove -Force -Verbose
}

# Remove DNS server IP from first NIC
#Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ResetServerAddresses -Verbose
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $null -Verbose


Get-DNSClient -InterfaceAlias $InterfaceAlias
Set-DnsClient -InterfaceAlias $InterfaceAlias -RegisterThisConnectionsAddress $false -Verbose

# Change NIC priority (metric)
Get-NetIPInterface | Sort-Object Interfacemetric
Set-NetIPInterface -InterfaceAlias 'Ethernet 2' -AddressFamily IPv4 -InterfaceMetric 10


Restart-Computer
