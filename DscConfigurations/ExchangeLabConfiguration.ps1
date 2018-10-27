Configuration Exchange {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $DomainAdminCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $DSRMAdminCredential
    )

    # Import the module that contains the resources we're using.
    Import-DscResource -ModuleName 'PsDesiredStateConfiguration', 'xExchange', 'xPendingReboot', 'xActiveDirectory',
    'ComputerManagementDsc', 'NetworkingDsc', 'xDnsServer', 'ActiveDirectoryCSDsc', 'CertificateDsc'

    # Global Configuration Data Variables (for ease of reading inside regions)
    $DomainName = $ConfigurationData.Role.DomainController.DomainName


    # The Node statement specifies which targets this configuration will be applied to.
    Node $AllNodes.NodeName {

        #region LCM Config
        LocalConfigurationManager
        {
            ActionAfterReboot  = 'ContinueConfiguration'
            ConfigurationMode  = 'ApplyOnly'
            RebootNodeIfNeeded = $true
            # Remove this when development has complete (This will reload DSC resources automatically - no cache)
            DebugMode          = 'All'
        }
        #endregion


        #region DC
        if ($Node.Role -contains 'DomainController')
        {

            WindowsFeatureSet 'AD-Domain-Services'
            {
                Ensure               = 'Present'
                Name                 = 'AD-Domain-Services', 'RSAT-AD-PowerShell', 'RSAT-ADDS-Tools'
                IncludeAllSubFeature = $true
            }

            xADDomain 'ADDomain'
            {
                DomainName                    = $DomainName
                DomainNetbiosName             = $ConfigurationData.Role.DomainController.NetBIOSName
                DomainAdministratorCredential = $DomainAdminCredential
                SafemodeAdministratorPassword = $DSRMAdminCredential
                DependsOn                     = '[WindowsFeatureSet]AD-Domain-Services'
            }

            xADGroup 'DomainAdmins'
            {
                Ensure           = 'Present'
                GroupName        = 'Domain Admins'
                MembersToInclude = 'vagrant'
                DependsOn        = '[xADDomain]ADDomain'
            }
            xADGroup 'EnterpriseAdmins'
            {
                Ensure           = 'Present'
                GroupName        = 'Enterprise Admins'
                MembersToInclude = 'vagrant'
                DependsOn        = '[xADDomain]ADDomain'
            }
            xADGroup 'SchemaAdmins'
            {
                Ensure           = 'Present'
                GroupName        = 'Schema Admins'
                MembersToInclude = 'vagrant'
                DependsOn        = '[xADDomain]ADDomain'
            }

            @($ConfigurationData.Role.DomainController.OrganizationalUnits).foreach( {
                    xADOrganizationalUnit $_
                    {
                        Ensure    = 'Present'
                        Name      = $_
                        Path      = ('DC={0},DC={1},DC={2},DC={3}' -f ($DomainName -split '\.')[0], ($DomainName -split '\.')[1], ($DomainName -split '\.')[2], ($DomainName -split '\.')[3])
                        DependsOn = '[xADDomain]ADDomain'
                    }
                }
            )

            @($ConfigurationData.Role.DomainController.ADUsers).foreach( {
                    xADUser $_.UserName
                    {
                        Ensure               = 'Present'
                        DomainName           = $DomainName
                        GivenName            = $_.FirstName
                        SurName              = $_.LastName
                        UserName             = $_.UserName
                        Department           = $_.Department
                        Path                 = ("OU={0},DC={1},DC={2},DC={3},DC={4}" -f $_.Department, ($DomainName -split '\.')[0], ($DomainName -split '\.')[1], ($DomainName -split '\.')[2], ($DomainName -split '\.')[3])
                        JobTitle             = $_.Title
                        Password             = $DSRMAdminCredential # Only uses the password part of the credential (xAdUser behaviour)
                        PsDscRunAsCredential = $DomainAdminCredential
                        DependsOn            = "[xADOrganizationalUnit]$($_.Department)"
                    }
                }
            )

            foreach ($adGroup in $($ConfigurationData.Role.DomainController.ADGroups))
            {
                $groupMembers = ($configurationdata.Role.DomainController.AdUsers | Where-Object {$_.Department -eq $adGroup}).UserName
                $dependencyArray = $groupMembers | ForEach-Object {"[xADUser]$_"}
                xADGroup $adGroup
                {
                    Ensure           = 'Present'
                    GroupName        = $adGroup
                    MembersToInclude = $groupMembers
                    DependsOn        = $dependencyArray
                }
            }

            xDnsServerPrimaryZone 'addPrimaryZone'
            {
                Ensure    = 'Present'
                Name      = $ConfigurationData.Role.Exchange.ExternalFqdn
                DependsOn = '[WindowsFeatureSet]AD-Domain-Services'
            }

            xDnsRecord 'ExcExtFqdn'
            {
                Name      = '.'
                Target    = $ConfigurationData.Role.Exchange.Ex01IP
                Zone      = $ConfigurationData.Role.Exchange.ExternalFqdn
                Type      = 'ARecord'
                Ensure    = 'Present'
                DependsOn = '[xDnsServerPrimaryZone]addPrimaryZone'
            }

            # DnsServerAddress 'DnsServerAddress'
            # {
            #     Address        = '192.168.56.110', '127.0.0.1'
            #     InterfaceAlias = 'Ethernet 2'
            #     AddressFamily  = 'IPv4'
            #     #Validate       = $true - this appears to cause an error, and the setting works without it.
            #     DependsOn      = '[xDnsServerPrimaryZone]addPrimaryZone'
            # }

            WaitForAll 'DCAdditional'
            {
                ResourceName     = '[xADDomainController]AdditionalDC'
                NodeName         = 'dc02'
                RetryIntervalSec = 60
                RetryCount       = 60
                DependsOn        = '[xDnsRecord]ExcExtFqdn'
            }

            DnsServerAddress 'DnsServerAddress'
            {
                Address        = '192.168.56.114', '192.168.56.110', '127.0.0.1'
                InterfaceAlias = 'Ethernet 2'
                AddressFamily  = 'IPv4'
                #Validate       = $true - this appears to cause an error, and the setting works without it.
                DependsOn      = '[WaitForAll]DCAdditional'
            }

        }
        #endregion DC

        #region DC-Additional
        if ($Node.Role -contains 'DomainControllerAdditional')
        {
            WindowsFeatureSet 'AD-Domain-Services'
            {
                Ensure               = 'Present'
                Name                 = 'AD-Domain-Services', 'RSAT-AD-PowerShell', 'RSAT-ADDS-Tools'
                IncludeAllSubFeature = $true
            }

            DnsServerAddress 'DnsServerAddress'
            {
                Address        = '192.168.56.110', '192.168.56.114', '127.0.0.1'
                InterfaceAlias = 'Ethernet 2'
                AddressFamily  = 'IPv4'
                #Validate       = $true - this appears to cause an error, and the setting works without it.
                DependsOn      = '[WindowsFeatureSet]AD-Domain-Services'
            }

            xWaitForADDomain 'WaitDomain'
            {
                DomainName       = $DomainName
                RetryCount       = 60
                RetryIntervalSec = 60
                DependsOn        = '[DnsServerAddress]DnsServerAddress'
            }

            Computer 'JoinDomain'
            {
                Name       = $Node.NodeName
                DomainName = $DomainName
                Credential = $DomainAdminCredential # Credential to join to domain
                DependsOn  = '[xWaitForADDomain]WaitDomain'
            }

            xADDomainController 'AdditionalDC'
            {
                DomainName                    = $DomainName
                DomainAdministratorCredential = $DomainAdminCredential
                SafemodeAdministratorPassword = $DSRMAdminCredential
                PsDscRunAsCredential          = $DomainAdminCredential
                DependsOn                     = '[Computer]JoinDomain'
            }

        }
        #endregion DC-Additional


        #region Exchange
        if ($Node.Role -contains 'Exchange')
        {

            DnsServerAddress 'DnsServerAddress'
            {
                Address        = '192.168.56.110'
                InterfaceAlias = 'Ethernet 2'
                AddressFamily  = 'IPv4'
                #Validate       = $true - this appears to cause an error, and the setting works without it.
            }

            xWaitForADDomain 'WaitDomain'
            {
                DomainName       = $DomainName
                RetryCount       = 60
                RetryIntervalSec = 60
                DependsOn        = '[DnsServerAddress]DnsServerAddress'
            }

            Computer 'JoinDomain'
            {
                Name       = $Node.NodeName
                DomainName = $DomainName
                Credential = $DomainAdminCredential # Credential to join to domain
                DependsOn  = '[xWaitForADDomain]WaitDomain'
            }

            # The first resource block ensures that the Web-Server (IIS) feature is enabled.
            WindowsFeatureSet 'ExchangePreReqs'
            {
                Ensure    = 'Present'
                Name      = @('NET-Framework-45-Features', 'NET-WCF-HTTP-Activation45', 'RPC-over-HTTP-proxy', 'RSAT-Clustering', 'RSAT-Clustering-CmdInterface',
                    'RSAT-Clustering-Mgmt', 'RSAT-Clustering-PowerShell', 'Web-Mgmt-Console', 'WAS-Process-Model', 'Web-Asp-Net45',
                    'Web-Basic-Auth', 'Web-Client-Auth', 'Web-Digest-Auth', 'Web-Dir-Browsing', 'Web-Dyn-Compression', 'Web-Http-Errors',
                    'Web-Http-Logging', 'Web-Http-Redirect', 'Web-Http-Tracing', 'Web-ISAPI-Ext', 'Web-ISAPI-Filter', 'Web-Lgcy-Mgmt-Console',
                    'Web-Metabase', 'Web-Mgmt-Console', 'Web-Mgmt-Service', 'Web-Net-Ext45', 'Web-Request-Monitor', 'Web-Server',
                    'Web-Stat-Compression', 'Web-Static-Content', 'Web-Windows-Auth', 'Web-WMI', 'Windows-Identity-Foundation', 'RSAT-ADDS')
                DependsOn = '[Computer]JoinDomain'
            }

            Package 'UCMARuntime'
            {
                Name      = 'Microsoft Unified Communications Managed API 4.0, Runtime'
                Path      = $ConfigurationData.Role.Exchange.UCMAPath
                ProductId = '41D635FE-4F9D-47F7-8230-9B29D6D42D31'
                Arguments = '/q'
                DependsOn = '[WindowsFeatureSet]ExchangePreReqs'
            }

            # Check if a reboot is needed before installing Exchange
            xPendingReboot BeforeExchangeInstall
            {
                Name      = 'BeforeExchangeInstall'
                DependsOn = '[Package]UCMARuntime'
            }

            # Do the Exchange install
            xExchInstall InstallExchange
            {
                Path       = $ConfigurationData.Role.Exchange.BinaryPath
                Arguments  = "/mode:Install /role:Mailbox /OrganizationName $($ConfigurationData.Role.Exchange.OrganisationName) /Iacceptexchangeserverlicenseterms"
                Credential = $DomainAdminCredential
                DependsOn  = '[xPendingReboot]BeforeExchangeInstall'
            }

            # See if a reboot is required after installing Exchange
            xPendingReboot AfterExchangeInstall
            {
                Name      = 'AfterExchangeInstall'
                DependsOn = '[xExchInstall]InstallExchange'
            }

            # # Post-Exchange Configuration - AutoDiscoverURI - WIP
            xExchClientAccessServer 'CAS'
            {
                Identity                       = $Node.NodeName
                Credential                     = $DomainAdminCredential
                AutoDiscoverServiceInternalUri = "https://$($ConfigurationData.Role.Exchange.ExternalFqdn)/autodiscover/autodiscover.xml"
                DependsOn                      = '[xPendingReboot]AfterExchangeInstall'
            }


            #region GeneratingCertificateRequest
            WaitForAll 'CertServices'
            {
                ResourceName     = '[AdcsWebEnrollment]WebEnrollment'
                NodeName         = 'adcs01'
                RetryIntervalSec = 60
                RetryCount       = 60
                DependsOn        = '[xExchClientAccessServer]CAS'
            }

            CertReq SSLCert
            {
                CARootName          = 'lab-ADCS01-CA'
                CAServerFQDN        = 'adcs01.lab.milliondollar.me.uk'
                Subject             = $ConfigurationData.Role.Exchange.ExternalFqdn
                KeyLength           = '2048'
                Exportable          = $true
                ProviderName        = '"Microsoft RSA SChannel Cryptographic Provider"'
                OID                 = '1.3.6.1.5.5.7.3.1'
                KeyUsage            = '0xa0'
                CertificateTemplate = 'WebServer'
                SubjectAltName      = 'dns=webmail.milliondollar.me.uk&dns=ex01.lab.milliondollar.me.uk'
                AutoRenew           = $true
                FriendlyName        = 'SSL Cert for Exchange Server'
                Credential          = $DomainAdminCredential
            }

            #endregion GeneratingCertificateRequest

        }
        #endregion Exchange


        #region ADCS
        if ($Node.Role -contains 'ADCS')
        {
            DnsServerAddress 'DnsServerAddress'
            {
                Address        = '192.168.56.110'
                InterfaceAlias = 'Ethernet 2'
                AddressFamily  = 'IPv4'
                #Validate       = $true - this appears to cause an error, and the setting works without it.
            }

            xWaitForADDomain 'WaitDomain'
            {
                DomainName       = $DomainName
                RetryCount       = 30
                RetryIntervalSec = 60
                DependsOn        = '[DnsServerAddress]DnsServerAddress'
            }

            Computer 'JoinDomain'
            {
                Name       = $Node.NodeName
                DomainName = $DomainName
                Credential = $DomainAdminCredential # Credential to join to domain
                DependsOn  = '[xWaitForADDomain]WaitDomain'
            }

            WindowsFeature 'ADCS-Cert-Authority'
            {
                Ensure    = 'Present'
                Name      = 'ADCS-Cert-Authority'
                DependsOn = '[Computer]JoinDomain'
            }

            AdcsCertificationAuthority 'CertificateAuthority'
            {
                IsSingleInstance = 'Yes'
                Ensure           = 'Present'
                Credential       = $DomainAdminCredential
                CAType           = 'EnterpriseRootCA'
                DependsOn        = '[WindowsFeature]ADCS-Cert-Authority'
            }

            WindowsFeature 'ADCS-Web-Enrollment'
            {
                Ensure    = 'Present'
                Name      = 'ADCS-Web-Enrollment'
                DependsOn = '[AdcsCertificationAuthority]CertificateAuthority'
            }

            AdcsWebEnrollment 'WebEnrollment'
            {
                Ensure           = 'Present'
                IsSingleInstance = 'Yes'
                Credential       = $DomainAdminCredential
                DependsOn        = '[WindowsFeature]ADCS-Web-Enrollment'
            }

            WindowsFeature 'RSAT-ADCS'
            {
                Ensure    = 'Present'
                Name      = 'RSAT-ADCS'
                DependsOn = '[AdcsWebEnrollment]WebEnrollment'
            }
        }
        #endregion ADCS

    }
}
