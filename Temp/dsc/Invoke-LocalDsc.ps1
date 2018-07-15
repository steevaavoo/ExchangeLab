<#
    # Use the ISE to debug as VSCode has issues attaching the debugger
    # Debug DSC locally doing these steps:
    Enable-DscDebug -BreakAll
    Invoke-DscResource...
    Follow instructions to "Enter-PSHostProcess" and "Debug-RunSpace"
    Step through code to debug.
    quit (to quit out of runspace)
    CTRL+C (to exit session)
    Disable-DscDebug
#>
throw "Do not run complete script; run sections with F8"


$dscProperties = @{
    Address        = '192.168.56.110'
    InterfaceAlias = 'Ethernet 2'
    AddressFamily  = 'IPv4'
    Validate       = $true
}

# Trigger Get method
$result = Invoke-DscResource -Name 'DnsServerAddress' -Method 'Get' -ModuleName 'NetworkingDsc' -Property $dscProperties -Verbose
$result | Format-List

# Trigger Test method
$result = Invoke-DscResource -Name 'DnsServerAddress' -Method 'Test' -ModuleName 'NetworkingDsc' -Property $dscProperties -Verbose
$result | Format-List

# Trigger Set method
$result = Invoke-DscResource -Name 'DnsServerAddress' -Method 'Set' -ModuleName 'NetworkingDsc' -Property $dscProperties -Verbose
$result | Format-List
