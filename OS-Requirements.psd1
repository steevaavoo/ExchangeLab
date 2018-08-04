@{
    # Defaults for all dependencies
    PSDependOptions             = @{
        Scope      = 'AllUsers'
        Parameters = @{
            # Use a local repository for offline support
            Repository = 'LocalPSRepository'
        }
    }

    # Use SkipPublisherCheck as later versions of Pester are not signed by Microsoft
    Pester                      = @{
        Name       = 'Pester'
        Version    = '4.3.1'
        Parameters = @{
            SkipPublisherCheck = $true
        }
    }

    # Common modules
    cNtfsAccessControl          = '1.3.1'
    'posh-git'                  = '0.7.3'
    psake                       = '4.7.1'
    ComputerManagementDsc       = '5.2.0.0'
    NetworkingDsc               = '6.0.0.0'
    PackageManagement           = '1.0.0.1'
    PSDesiredStateConfiguration = '1.1'
    xActiveDirectory            = '2.19.0.0' #2.20.0.0 exists but has bugs
    xDnsServer                  = '1.11.0.0'
    xExchange                   = '1.21.0.0' #1.22.0.0 exists but has a fatal bug
    xPendingReboot              = '0.4.0.0'

}
