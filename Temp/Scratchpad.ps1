$ConfigurationData = Import-PowerShellDataFile -Path 'D:\Code\GitHub\vagrantlab\Examples\ExchangeLabConfigData.psd1'

$domainName = $ConfigurationData.Role.DomainController.DomainName

$domainName -split '\.'

$exchFQDN = ('ex01.{0}.{1}.{2}' -f ($domainName -split '\.')[1], ($domainName -split '\.')[2], ($domainName -split '\.')[3])

$exchFQDN


Path      = ('DC={0},DC={1},DC={2},DC={3}' -f ($DomainName -split '\.')[0], ($DomainName -split '\.')[1], ($DomainName -split '\.')[2], ($DomainName -split '\.')[3])

$excFQDN = ("$($ConfigurationData.Role.Exchange.ExternalURLTop).{0}.{1}.{2}" -f ($domainName -split '\.')[1], ($domainName -split '\.')[2], ($domainName -split '\.')[3])

$excFQDN

$AutoDiscoverServiceInternalUri = "https://$excFQDN/autodiscover/autodiscover.xml"

$AutoDiscoverServiceInternalUri

$ConfigurationData.Node.NodeName
