# Get-WinEventTail testing
# Get-WinEventTail_Controller.ps1 -ComputerName dc01 -Verbose
# \\VBOXSVR\vagrant\Temp\DSC\Get-WinEventTail_Controller.ps1 -ComputerName ex01 -Verbose
[cmdletbinding()]
Param(
    [Parameter(Mandatory = $true)][string]$ComputerName
)

# Vars
$credential = New-Object -TypeName 'PSCredential' -ArgumentList ('.\administrator', (ConvertTo-SecureString -String 'vagrant' -AsPlainText -Force))

# Load function
. (Join-Path -Path $PSScriptRoot -ChildPath Get-WinEventTail.ps1)

# Test remote event collection
Get-WinEventTail -LogName "Microsoft-Windows-DSC/Operational" -ComputerName $ComputerName -Credential $credential -Verbose | Format-Table -Wrap

<# Testing DSC logs
Get-WinEventTail -LogName "Application" -ComputerName $ComputerName -Credential $credential | Format-Table -Wrap

Get-WinEventTail -LogName "Microsoft-Windows-DSC/Operational" | Format-Table -Wrap
Get-WinEventTail -LogName "Microsoft-Windows-DSC/Analytic" | Format-Table -Wrap # needs work as no support for -Oldest
Get-WinEventTail -LogName "Microsoft-Windows-DSC/Debug" | Format-Table -Wrap # needs work as no support for -Oldest
#>
