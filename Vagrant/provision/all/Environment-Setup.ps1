# Enable ping
$firewallRules = 'FPS-ICMP4-ERQ-In', 'FPS-ICMP4-ERQ-Out'
Set-NetFirewallRule -Name $firewallRules -Enabled 'True'
# Enable Remote xdscdiagnostics use
if ((Get-NetFirewallRule -Name 'Service RemoteAdmin' -ErrorAction 'SilentlyContinue') -eq $null)
{
    Write-Host "Creating new Firewall Rule 'Service RemoteAdmin'"
    New-NetFirewallRule -Name "Service RemoteAdmin" -DisplayName "Remote" -Action 'Allow'
}
# Enable Remote Events collection
Set-NetFirewallRule -Name 'RemoteEventLogSvc*' -Enabled 'True'

# Update-xDSCEventLogStatus
Write-Host 'Enabling DSC Analytic/Debug logs...' -ForegroundColor 'Yellow'
# Log names
$logNames = 'Operational', 'Analytic', 'Debug'
# Disable logs first
foreach ($logName in $logNames)
{
    Update-xDscEventLogStatus -Channel $logName -Status 'Disabled' -ComputerName $computerName -Verbose
}
# Enable logs
foreach ($logName in $logNames)
{
    Update-xDscEventLogStatus -Channel $logName -Status 'Enabled' -ComputerName $computerName -Verbose
}
