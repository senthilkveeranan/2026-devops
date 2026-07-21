# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  ##############################################
  # Base Box
  ##############################################
  
  config.vm.box = "generic/rocky9"
  config.vm.box_check_update = false


  ##############################################
  # VM Settings
  ##############################################

  config.vm.hostname = "devops-lab"

  config.vm.network "private_network", ip: "192.168.56.100"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "Devops-Lab"

    vb.gui = true

    vb.memory = 12288
    vb.cpus = 6

    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--clipboard-mode", "bidirectional"]
    vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]

    vb.customize ["modifyvm", :id, "--audio-enabled", "off"]
    vb.customize ["modifyvm", :id, "--usb", "off"]
    vb.customize ["modifyvm", :id, "--usbehci", "off"]
  end

  ##############################################
  # Synced Folder
  ##############################################

#  config.vm.synced_folder ".", "/vagrant",disabled: false"
#  config.vm.synced_folder ".", "/vagrant", disabled: false, type: "virtualbox"
    config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  

  ##############################################
  # SSH
  ##############################################

  config.ssh.insert_key = false

  config.ssh.keep_alive = true

  config.ssh.forward_agent = true

  ##############################################
  # Provision Scripts
  ##############################################

#  config.vm.provision "shell",
#    path: "scripts/01-common.sh"

#  config.vm.provision "shell",
#    path: "scripts/02-docker.sh"

#  config.vm.provision "shell",
#    path: "scripts/03-k3s.sh"

#  config.vm.provision "shell",
#    path: "scripts/04-helm.sh"

#  config.vm.provision "shell",
#    path: "scripts/05-ansible.sh"

#  config.vm.provision "shell",
#    path: "scripts/06-terraform.sh"

#  config.vm.provision "shell",
#    path: "scripts/07-jenkins.sh"

#  config.vm.provision "shell",
#    path: "scripts/08-sonarqube.sh"

#  config.vm.provision "shell",
#    path: "scripts/09-nexus.sh"

#  config.vm.provision "shell",
#    path: "scripts/10-monitoring.sh"

#  config.vm.provision "shell",
#    path: "scripts/11-verify.sh"
  config.vm.provision "shell", path: "scripts/01-common.sh"
  config.vm.provision "shell", path: "scripts/02-docker.sh"
  config.vm.provision "shell", path: "scripts/03-k3s.sh"
  config.vm.provision "shell", path: "scripts/04-helm.sh"
  config.vm.provision "shell", path: "scripts/05-metallb.sh"
  config.vm.provision "shell", path: "scripts/09-ansible-core.sh"
 
end
