# Plugin checker by DevNIX: https://github.com/DevNIX/Vagrant-dependency-manager
# vagrant-reload is required to solve issues with rebooting Windows machines after domain join
require File.dirname(__FILE__)+'./Vagrant/dependency_manager'
check_plugins ['vagrant-reload']

# Variables
# Domain / Network
# This is the default subnet for Virtualbox (not the special communications one for Vagrant>Box WinRM stuff)
subnet_prefix         = '192.168.56'
box_name              = 'adamrushuk/win2016-datacenter-dev'
box_version           = '1807.0.0'
dc01_ip               = "#{subnet_prefix}.110"
dc_hostname           = 'dc01'
# domain_name           = 'lab.milliondollar.me.uk'
# netbios_name          = 'LAB'
# safemode_admin_pw     = 'Passw0rds123'
# domain_admins         = 'vagrant' #, 'mdadmin'
fs_hostname           = 'fs01'
fs01_ip               = "#{subnet_prefix}.111"
ex_hostname           = 'ex01'
ex01_ip               = "#{subnet_prefix}.112"
# domain_admin_un       = 'vagrant'
# domain_admin_pw       = 'vagrant'
module_names          = 'xExchange,xPendingReboot,xActiveDirectory,ComputerManagementDsc,NetworkingDsc,xDnsServer,xDSCDiagnostics'

Vagrant.configure('2') do |config|

  # The below section defines Global parameters for all VMs
  # Box - this defines which Box (template) and version will be Deployed (variables defined above) - further
  # down are settings for individual VMs
  config.vm.box         = box_name
  config.vm.box_version = box_version

  # VirtualBox global box settings
  # The below should be self-explanatory.
  config.vm.provider 'virtualbox' do |vb|
    # The VM will be a linked clone
    vb.linked_clone = true
    # When the VM is powered on, it will display a console window for the VM - if false, it would run in "Headless" mode
    # and you would have to RDP to the machine. Not good if there is an issue during boot.
    vb.gui          = true
    # Modify the VM - enabling the bidirectional clipboard in this case (allowing copying and pasting from host to vm)
    vb.customize ['modifyvm', :id, '--clipboard', 'bidirectional']
    # Without these, a banner appears with messages at the top of the GUI window
    vb.customize ['setextradata', 'global', 'GUI/SuppressMessages', 'all']
  end

  # WinRM plaintext is required for the domain to build properly (These settings should NOT be used on production machines)
  # Because when a machine becomes a DC/Domain Member, Kerberos will stop non-domain "machines" such as Vagrant from using WinRM (as you
  # would hope!)
  # Defining communication method between Vagrant and the OS
  config.vm.communicator       = 'winrm'
  config.winrm.transport       = :plaintext
  config.winrm.basic_auth_only = true

  # Increase timeout in case VMs joining the domain take a while to boot
  config.vm.boot_timeout = 600
  config.vm.provision 'shell', path: 'Vagrant/provision/all/Install-Modules.ps1', args: [module_names]
  config.vm.provision 'shell', path: 'Vagrant/provision/all/Set-Networking.ps1'
  config.vm.provision 'shell', path: 'Vagrant/provision/all/Environment-Setup.ps1'

  # The below settings are for individual VMs
  # DC
  config.vm.define 'dc01' do |machine|
    # CPU and RAM
    machine.vm.provider 'virtualbox' do |vb|
      vb.cpus = '2'
      vb.memory = '2048'
    end

    # Hostname and networking
    machine.vm.hostname = dc_hostname
    machine.vm.network 'private_network', ip: dc01_ip
    machine.vm.network 'forwarded_port', guest: 3389, host: 34000, auto_correct: true

    # # Provisioning - this calls the Scripts below on the target VM, passing the arguments (args) to their parameters (positional)
    # machine.vm.provision 'shell', path: 'Vagrant/provision/dc01/install-AD.ps1', args: [dc01_ip]
    # machine.vm.provision 'shell', path: 'Vagrant/provision/dc01/install-forest.ps1', args: [domain_name, netbios_name, safemode_admin_pw, dc01_ip]
    # # Reboot after resetting DNS (as we suppresses reboot using Install-ADDSForest)
    # machine.vm.provision :reload
    # machine.vm.provision 'shell', path: 'Vagrant/provision/dc01/AD-Groups-Users.ps1', args: [domain_admins, domain_name, dc_hostname]

    # # Sleep due to DC configuring computer after reboot for ~8 mins
    # machine.vm.provision 'shell', inline: 'Start-Sleep -Seconds 480'
    # machine.vm.provision 'shell', path: 'Vagrant/provision/dc01/configure-AD.ps1', args: [domain_name, dc_hostname]
  end


  # File Server
  config.vm.define fs_hostname do |machine|
    # CPU and RAM
    machine.vm.provider 'virtualbox' do |vb|
      vb.cpus = '2'
      vb.memory = '2048'
    end

    # Hostname and networking
    machine.vm.hostname = fs_hostname
    machine.vm.network 'private_network', ip: fs01_ip
    machine.vm.network 'forwarded_port', guest: 3389, host: 34001, auto_correct: true

    # Provisioning - this calls the Scripts below on the target VM, passing the arguments (args) to their parameters (positional)

    # Setting the IP Address of the File Server and Joining it to the Domain
    # machine.vm.provision 'shell', path: 'Vagrant/provision/all/Join-Domain.ps1', args: [domain_name, domain_admin_un, domain_admin_pw, dc01_ip]
    # machine.vm.provision :reload

  end


  # Exchange Server
  config.vm.define ex_hostname do |machine|
    # CPU and RAM
    machine.vm.provider 'virtualbox' do |vb|
      vb.cpus = '2'
      vb.memory = '4096'
    end

    # Hostname and networking
    machine.vm.hostname = ex_hostname
    machine.vm.network 'private_network', ip: ex01_ip
    machine.vm.network 'forwarded_port', guest: 3389, host: 34002, auto_correct: true

    # Provisioning - this calls the Scripts below on the target VM, passing the arguments (args) to their parameters (positional)

    # Setting the IP Address of the File Server and Joining it to the Domain
    # machine.vm.provision 'shell', path: 'Vagrant/provision/all/Join-Domain.ps1', args: [domain_name, domain_admin_un, domain_admin_pw, dc01_ip]
    # machine.vm.provision :reload

    # Staging Installers
    machine.vm.provision 'shell', path: 'Vagrant/provision/ex01/stage-Installers.ps1'

    # Rebooting to make sure Exchange ready to be installed
    machine.vm.provision :reload

  end

end
