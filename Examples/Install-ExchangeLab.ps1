# Variables
$ComputerNames = 'dc01', 'ex01'
$ConfigurationPath = Join-Path -Path $PSScriptRoot -ChildPath '\..\DscConfigurations\ExchangeLab.ps1'
$ConfigurationDataPath = "$PSScriptRoot\ExchangeLabConfigData.psd1"
$DscOutputPath = 'C:\Source\DSC\MOFs'
# Credentials
$DomainAdminCredential = New-Object -TypeName 'PSCredential' -ArgumentList ('LAB\vagrant', (ConvertTo-SecureString -String 'vagrant' -AsPlainText -Force))
$DSRMAdminCredential = New-Object -TypeName 'PSCredential' -ArgumentList ('LAB\vagrant', (ConvertTo-SecureString -String 'P@ssw0rd!"£' -AsPlainText -Force))
$VagrantCredential = New-Object -TypeName 'PSCredential' -ArgumentList ('vagrant', (ConvertTo-SecureString -String 'vagrant' -AsPlainText -Force))

# Load DSC configuration into memory
. $ConfigurationPath

# Build MOF
$exchangeParams = @{
    DomainAdminCredential = $DomainAdminCredential
    DSRMAdminCredential   = $DSRMAdminCredential
    ConfigurationData     = $ConfigurationDataPath
    OutputPath            = $DscOutputPath
    Verbose               = $true
}

# Calls the Exchange "Configuration (Function)" which creates the MOF files - here "Exchange" follows the term "Function" in the
# above referenced $ConfigurationPath
Exchange @exchangeParams

# Set LCM path and push configuration (looks for MOFs and applies them)
Set-DscLocalConfigurationManager -Path $DscOutputPath -ComputerName $ComputerNames -Credential $VagrantCredential -Verbose -Force
Start-DscConfiguration -Path $DscOutputPath -ComputerName $ComputerNames -Credential $VagrantCredential -Verbose -Force -Wait
