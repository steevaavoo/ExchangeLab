@{
    AllNodes    = @(

        # This will be run on all nodes
        @{
            NodeName                    = '*'
            # Local Configuration Manager
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
            DebugMode                   = 'All'
            RebootNodeIfNeeded          = $true
        }

        # DC Node
        @{
            NodeName = 'dc01'
            # Wrap in an array for consistency
            Role     = @('DomainController')
        }

        # Exchange Node
        @{
            NodeName = 'ex01'
            # Wrap in an array for consistency
            Role     = @('Exchange')
        }

        # ADCS Node
        @{
            NodeName = 'adcs01'
            # Wrap in an array for consistency
            Role     = @('ADCS')
        }
    )

    # Define role data here to ensure role and node are not tightly coupled
    Role        = @{
        Exchange         = @{
            UCMAPath         = 'C:\Source\installers\exchange\pre-reqs\UcmaRuntimeSetup.exe'
            BinaryPath       = 'C:\Source\Installers\exchange\2016\Setup.EXE'
            OrganisationName = 'MillionDollarEnterprises'
            ExternalFqdn     = 'mail.milliondollar.me.uk' #Make sure to update this if you change the AD Domain name!
            Ex01IP           = '192.168.56.112'
            DBName           = 'MDDatabase1'
        }

        DomainController = @{
            DomainName          = 'lab.milliondollar.me.uk'
            NetBIOSName         = 'LAB'
            AdGroups            = 'Information Technology'
            OrganizationalUnits = 'Information Technology'
            AdUsers             = @(
                @{
                    FirstName  = 'Steve'
                    LastName   = 'Baker'
                    UserName   = 'Steve.Baker'
                    Department = 'Information Technology'
                    Title      = 'Manager of IT'
                }
                @{
                    FirstName  = 'Adam'
                    LastName   = 'Rush'
                    UserName   = 'Adam.Rush'
                    Department = 'Information Technology'
                    Title      = 'King of IT'
                }
                @{
                    FirstName  = 'Phil'
                    LastName   = 'Changeur'
                    UserName   = 'Phil.Changeur'
                    Department = 'Information Technology'
                    Title      = 'Proof Reader'
                }
            )
        }
    }

    # Parameters shared across multiple nodes
    NonNodeData = @{
        # WinSXS Sources
        WinSxsSource     = 'C:\Source\Win2016-ISO-Sources-sxs'

        # Wait resource parameters
        RetryCount       = 50
        RetryIntervalSec = 30
    }
}
