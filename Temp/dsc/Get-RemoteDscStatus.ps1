# Variables
$vmList = 'dc01', 'ex01', 'fs01'
$domainAdminCredential = New-Object -TypeName 'PSCredential' -ArgumentList ('lab\vagrant', (ConvertTo-SecureString -String 'vagrant' -AsPlainText -Force))

Invoke-Command -ComputerName $vmList -Credential $domainAdminCredential -Verbose -ScriptBlock {
    Get-DscLocalConfigurationManager | Select-Object LCMState, LCMStateDetail
}


#############
$computerName = 'dc01'
Invoke-Command -ComputerName $computerName -Credential $domainAdminCredential -Verbose -ScriptBlock {
    Get-DscLocalConfigurationManager

    $status = Get-DscConfigurationStatus -All
    # $status
    $status[0].ResourcesInDesiredState | Select-Object ResourceId, InDesiredState, StartDate, DurationInSeconds | Format-Table -AutoSize
    $status[0].ResourcesNotInDesiredState | Select-Object ResourceId, InDesiredState, StartDate, DurationInSeconds | Format-Table -AutoSize
}



#############

Get-DscLocalConfigurationManager

$status = Get-DscConfigurationStatus -All
$status
$status[0].ResourcesInDesiredState | Select-Object ResourceId, InDesiredState, StartDate, DurationInSeconds | Format-Table -AutoSize
$status[0].ResourcesNotInDesiredState | Select-Object ResourceId, InDesiredState, StartDate, DurationInSeconds | Format-Table -AutoSize

$statusFailed = $status | Where-Object Status -eq 'Failure' | Select-Object -First 1
$statusFailed | Format-List *

$statusFailed[0].ResourcesNotInDesiredState
$statusFailed[0].ResourcesNotInDesiredState[0].Error

# xDscDiagnostics examples
# Source: https://docs.microsoft.com/en-us/powershell/dsc/troubleshooting#using-xdscdiagnostics-to-analyze-dsc-logs
Get-xDscOperation -Newest 5
Trace-xDscOperation -SequenceID 8
Trace-xDscOperation -JobID 9e0bfb6b-3a3a-11e6-9165-00155d390509

# DSC Events
$DscEvents = [System.Array](Get-WinEvent "Microsoft-Windows-Dsc/Operational") `
    + [System.Array](Get-WinEvent "Microsoft-Windows-Dsc/Analytic" -Oldest) `
    + [System.Array](Get-WinEvent "Microsoft-Windows-Dsc/Debug" -Oldest)

$SeparateDscOperations = $DscEvents | Group-Object {$_.Properties[0].value}
$SeparateDscOperations

# Get verbose messages from analytic log in the last 5
$timestamp = (Get-Date).AddMinutes(-5)
$analyticEvents = [System.Array](Get-WinEvent "Microsoft-Windows-Dsc/Analytic" -Oldest)
$recentAnalyticEvents = $analyticEvents | Where-Object {$_.TimeCreated -gt $timestamp}
$recentAnalyticEvents.Count
$recentAnalyticEvents[-1] | Format-List * -Force
$recentAnalyticEvents | Select-Object TimeCreated, message | Format-Table -Wrap
$recentAnalyticEvents | Select-Object -ExpandProperty message
$recentAnalyticEvents | Select-Object Level -Unique
###

# Start DSC check using current MOF
Start-DscConfiguration -UseExisting -Verbose -Force

###

# Check Open Ports
Get-NetTCPConnection -State Listen
netstat -anob | Select-String 50000 -Context 1
netstat -anob | Select-String sqlservr.exe -Context 1
netstat -anob | Select-String '50200.*LISTENING' -Context 1 # SqlAGL
netstat -anob | Select-String '50\d{3}.*LISTENING' -Context 1 # show all listening ports 50000+
# >   TCP    0.0.0.0:50000          0.0.0.0:0              LISTENING       2196
#    [sqlservr.exe]
# >   TCP    0.0.0.0:50100          0.0.0.0:0              LISTENING       2196
#    [sqlservr.exe]
#    [sqlservr.exe]
# >   TCP    192.168.56.155:50200   0.0.0.0:0              LISTENING       2196
#    [sqlservr.exe]
#    [lsass.exe]
# >   TCP    [::]:50000             [::]:0                 LISTENING       2196
#    [sqlservr.exe]

# Test Cluster
Test-Cluster
