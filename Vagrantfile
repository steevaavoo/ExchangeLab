# Plugin checker by DevNIX: https://github.com/DevNIX/Vagrant-dependency-manager
# vagrant-reload is required to solve issues with rebooting Windows machines after domain join
require File.dirname(__FILE__)+'./Vagrant/dependency_manager'
check_plugins ['vagrant-reload']

# Variables
# Domain / Network
# This is the default subnet for Virtualbox (not the special communications one for Vagrant>Box WinRM stuff)
subnet_prefix         = '192.168.56'
box_name              = 'adamrushuk/win2016-std-dev'
box_version           = '1809.1.0'
dc01_ip               = "#{subnet_prefix}.110"
dc_hostname           = 'dc01'
dc02_hostname           = 'dc02'
# domain_name           = 'lab.milliondollar.me.uk'
# netbios_name          = 'LAB'
# safemode_admin_pw     = 'Passw0rds123'
# domain_admins         = 'vagrant' #, 'mdadmin'
fs_hostname           = 'fs01'
fs01_ip               = "#{subnet_prefix}.111"
ex_hostname           = 'ex01'
ex01_ip               = "#{subnet_prefix}.112"
adcs_hostname           = 'adcs01'
adcs_ip               = "#{subnet_prefix}.113"
dc02_ip               = "#{subnet_prefix}.114"
# domain_admin_un       = 'vagrant'
# domain_admin_pw       = 'vagrant'
module_names          = 'xExchange,xPendingReboot,xActiveDirectory,ComputerManagementDsc,NetworkingDsc,xDnsServer,xDSCDiagnostics,ActiveDirectoryCSDsc'

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
  config.vm.define dc_hostname do |machine|
    # CPU and RAM
    machine.vm.provider 'virtualbox' do |vb|
      vb.cpus = '2'
      vb.memory = '2048'
    end

    # Hostname and networking
    machine.vm.hostname = dc_hostname
    machine.vm.network 'private_network', ip: dc01_ip
    machine.vm.network 'forwarded_port', guest: 3389, host: 34000, auto_correct: true
  end


  # DC 2
  config.vm.define dc02_hostname do |machine|
    # CPU and RAM
    machine.vm.provider 'virtualbox' do |vb|
      vb.cpus = '2'
      vb.memory = '2048'
    end

    # Hostname and networking
    machine.vm.hostname = dc02_hostname
    machine.vm.network 'private_network', ip: dc02_ip
    machine.vm.network 'forwarded_port', guest: 3389, host: 34004, auto_correct: true
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

    # Staging Installers
    machine.vm.provision 'shell', path: 'Vagrant/provision/ex01/stage-Installers.ps1'

    # Rebooting to make sure Exchange ready to be installed
    machine.vm.provision :reload
  end


  # ADCS Server
  config.vm.define adcs_hostname do |machine|
    # CPU and RAM
    machine.vm.provider 'virtualbox' do |vb|
      vb.cpus = '2'
      vb.memory = '2048'
    end

    # Hostname and networking
    machine.vm.hostname = adcs_hostname
    machine.vm.network 'private_network', ip: adcs_ip
    machine.vm.network 'forwarded_port', guest: 3389, host: 34003, auto_correct: true
  end

end
