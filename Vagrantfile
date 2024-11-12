# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  ### solving centos issue: https://serverfault.com/questions/1161816/mirrorlist-centos-org-no-longer-resolve
  config.vm.box = "CentOS7-with-chef"
  # config.vm.box_version = "2004.01"
  config.vm.disk :disk, size: "200GB", primary: true

  
  ### Plugin configuration for vagrant-vbguest
  # config.vbguest.auto_reboot = true
  # config.vbguest.installer_option = { allow_kernel_upgrade: true, auto_reboot: true}

  ### Box location: https://portal.cloud.hashicorp.com/vagrant/discover/mrlesmithjr/rhel-7
  # config.vm.box = "mrlesmithjr/rhel-7"
  # config.vm.box_version = "20160421.0"

  ### Box location: https://portal.cloud.hashicorp.com/vagrant/discover/generic/rhel7
  # config.vm.box = "generic/rhel7"
  # config.vm.box_version = "4.3.12"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  config.vm.network "forwarded_port", guest: 8080, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"
  # config.vm.synced_folder "./cookbooks", "/vagrant_data/cookbooks"

  # Disable the default share of the current code directory. Doing this
  # provides improved isolation between the vagrant box and your host
  # by making sure your Vagrantfile isn't accessible to the vagrant box.
  # If you use this you may want to enable additional shared subfolders as
  # shown above.
  # config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "C:/Users/alvin/OneDrive/Desktop/Clients/Orion/HERE Geocoder 6.2.255.1 092024/geocoder", "/vagrant/here_bits",  mount_options: ["ro"] # disabled: false, readonly: true # :mount_options => ["ro"]
  config.vm.synced_folder "C:/Users/alvin/Documents/Code/server-pre-req-binaries", "/vagrant/here_pre-reqs", disabled: false,  mount_options: ["ro"] #readonly: true # mount_options: ["ro"]

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = false

    # Customize the amount of memory on the VM:
    vb.memory = "2048"

    # #### Set the Guest Additions ISO path based on the host OS   <---- works
    # storage_url = Vagrant::Util::Platform.windows? ? "C:/Program Files/Oracle/VirtualBox/VBoxGuestAdditions.iso" :
    #               Vagrant::Util::Platform.mac? ? "/Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso" :
    #               "/usr/share/virtualbox/VBoxGuestAdditions.iso"

    ### Attempting to mount guest additions
    # vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", "emptydrive"]
    # Create an IDE controller
    # vb.customize ["storagectl", :id, "--name", "IDE Controller", "--add", "ide"]
    # Define post-boot action to insert Guest Additions
    # vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", "additions"]
    # vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", "/usr/share/virtualbox/VBoxGuestAdditions.iso"]

    ### more hackery to make adding drive idempotent
    #vboxmanage_path = Vagrant::Util::Which.which("VBoxManage")


    # Define a method to check if the controller exists
    # controller_exists = `VBoxManage showvminfo "#{config.vm.hostname || 'vagrant'}" | grep -q "SATA Controller"`
    # controller_exists = system("#{vboxmanage_path} showvminfo \"#{config.vm.hostname || 'vagrant'}\" | grep -q \"SATA Controller\"")

    ## in case the VM already comes with a CD, we can try another drive
    # vb.customize ["storagectl", :id, "--name", "SATA Controller", "--remove"] #unless controller_exists
    # vb.customize ["storagectl", :id, "--name", "SATA Controller", "--add", "sata"] #unless controller_exists

    ############# Works, but disabled in favor of vagrant-vbguest plugin <--- works
    # vb.customize ["storageattach", :id, "--storagectl", "IDE", "--port", "0", "--device", "1", "--type", "dvddrive", "--medium", storage_url]
  
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  #### Solving old OS error
  #### https://serverfault.com/questions/1161816/mirrorlist-centos-org-no-longer-resolve
  config.vm.provision "shell", name: "Pre-Provision Setup", inline: <<-SHELL
    sudo sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/CentOS-*.repo
    sudo sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/CentOS-*.repo
    sudo sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/CentOS-*.repo
    # Update packages
    # yum update -y
  SHELL

  # config.vm.provision "shell", name: "Install Virtual Box Guest Additions", run: "always", inline: <<-SHELL
  #   ## install guest additions as part of the prep. Way faster if the box already has them pre-installed
  #   ## or the box is recaptured after this command is executed for the first time
   
  #   # ##### Manually installing Guest Additions - V1 --
  #   # # Install dependencies for Guest Additions
  #   sudo yum install -y gcc kernel-devel kernel-headers gcc # dkms make bzip2 perl
  #   # sudo yum install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r)

  #   # # Mount the Guest Additions ISO
  #   # GA_VERSION=$(VBoxManage --version | cut -d'r' -f1)
  #   # wget https://download.virtualbox.org/virtualbox/$GA_VERSION/VBoxGuestAdditions_$GA_VERSION.iso -P /tmp
  #   # sudo mkdir -p /mnt/vbox
  #   # sudo mount -o loop /tmp/VBoxGuestAdditions_$GA_VERSION.iso /mnt/vbox
  #   # # Install Guest Additions
  #   # sudo sh /mnt/vbox/VBoxLinuxAdditions.run || true
  #   # # Clean up
  #   # sudo umount /mnt/vbox
  #   # rm -f /tmp/VBoxGuestAdditions_$GA_VERSION.iso

  #   # ##### Manually installing Guest Additions - V2 --
  #   # Check if Guest Additions are installed and active
  #   if pgrep -x "VBoxService" >/dev/null 2>&1; then
  #     echo "VirtualBox Guest Additions are fully installed and running. Skipping installation."
  #   else
  #     sudo yum install -y gcc kernel-devel kernel-headers gcc # dkms make bzip2 perl    <---- works
      # sudo mkdir -p /mnt/vbox
      # sudo mount /dev/cdrom /mnt/vbox
      # sudo sh /mnt/vbox/VBoxLinuxAdditions.run #|| true
      # sudo umount /mnt/vbox
  #   fi
  # SHELL

  # config.vm.provision "chef_zero" do | chef_zero |
  #   chef_zero.arguments = "--chef-license accept --run_lock_timeout 0"
  #   chef_zero.cookbooks_path = "./cookbooks"
  #   # chef.chef_server_url = nil  ## some kind of hack from stackoverlow
  #   # chef_solo.chef_server_url = "chefzero://localhost:8889"  ## some kind of hack from stackoverlow
  #   # chef.nodes_path = "./nodes"
  #   # chef_zero.add_recipe "hello_web"
  #   chef_zero.run_list = ["recipe[HERE]"]
  #   chef_zero.nodes_path = "./nodes"
  # end

  config.vm.provision "chef_solo" do | chef_solo | #<---- works but suddenly slow
    chef_solo.arguments = "--chef-license accept --run_lock_timeout 0"
    chef_solo.cookbooks_path = "./cookbooks"
    # chef.chef_server_url = nil  ## some kind of hack from stackoverlow
    # chef_solo.chef_server_url = "chefzero://localhost:8889"  ## some kind of hack from stackoverlow
    # chef.nodes_path = "./nodes"
    chef_solo.run_list = ["recipe[HERE]"]
  end

  # config.vm.provision "chef_apply" do |chef|
  #   chef.recipe = "HERE::default"
  #   # chef.arguments = "--chef-license accept"
  # end
end
