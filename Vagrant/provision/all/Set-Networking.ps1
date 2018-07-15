    # Change NIC priority (metric)
    Set-NetIPInterface -InterfaceAlias 'Ethernet 2' -AddressFamily 'IPv4' -InterfaceMetric 1

    # Fix: restart Network Location Awareness service if Windows Firewall showing "Public" instead of "Domain"
    $serviceNames = 'NlaSvc'
    foreach ($serviceName in $serviceNames)
    {
        Invoke-Expression "sc.exe config $serviceName start=delayed-auto"
        Get-Service -Name $serviceName | Restart-Service -Force
    }
