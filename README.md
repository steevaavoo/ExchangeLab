# ExchangeLab

## TODO

1. ~~Create new repo called ExchangeLab, and transfer these files.~~
1. ~~Create A-Record for the Exchange Server Autodiscover URI and other internal URLs using DSC, see [https://github.com/PowerShell/xDnsServer/blob/dev/README.md](https://github.com/PowerShell/xDnsServer/blob/dev/README.md)~~
1. ~~Troubleshoot DNS DSC setting - there appears to be a bug causing a cimexception error during DSC. For now, set EX01 DNS server manually before invoking Install-ExchangeLab.ps1~~
1. Continue the Exchange Post-Configuration configuration started at the bottom of the ExchangeLabConfiguration.ps1 (currently remarked out) - need to set the URLs for all the Web-based services for Exchange so that a potential SSL Cert can be applied and tested successfully.
1. Create an Exchange SAN cert utilising the ADCS server and the resource from the following link: https://github.com/PowerShell/CertificateDsc/blob/dev/Examples/Resources/CertReq/1-CertReq_RequestAltSSLCert_Config.ps1
