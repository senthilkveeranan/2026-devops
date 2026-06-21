# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure("2") do |config|

  # Disable default synced folder
  config.vm.synced_folder ".", "/vagrant", disabled: true

  COMMON_SCRIPT = <<-SHELL
#!/bin/bash

# Create jack user if not exists
id jack &>/dev/null || useradd -m jack

# Passwordless sudo
echo "jack ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jack
chmod 440 /etc/sudoers.d/jack

# Update hosts file
grep -q kmaster1 /etc/hosts || cat <<EOF >> /etc/hosts
192.168.56.101 kmaster1
192.168.56.201 kworker1
192.168.56.202 kworker2
EOF
  SHELL

  # ==================================================
  # Kubernetes Master Node
  # ==================================================
  config.vm.define "kmaster1" do |node|

    node.vm.box = "generic/rhel9"
    node.vm.hostname = "kmaster1"

    node.vm.network "private_network",
      ip: "192.168.56.101"

    node.vm.provider "virtualbox" do |vb|
      vb.name   = "kmaster1"
      vb.memory = 6144
      vb.cpus   = 2
    end

    node.vm.provision "shell", inline: COMMON_SCRIPT
  end

  # ==================================================
  # Kubernetes Worker Node 1
  # ==================================================
  config.vm.define "kworker1" do |node|

    node.vm.box = "generic/rhel9"
    node.vm.hostname = "kworker1"

    node.vm.network "private_network",
      ip: "192.168.56.201"

    node.vm.provider "virtualbox" do |vb|
      vb.name   = "kworker1"
      vb.memory = 10240
      vb.cpus   = 3
    end

    node.vm.provision "shell", inline: COMMON_SCRIPT
  end

  # ==================================================
  # Kubernetes Worker Node 2
  # ==================================================
  config.vm.define "kworker2" do |node|

    node.vm.box = "generic/rhel9"
    node.vm.hostname = "kworker2"

    node.vm.network "private_network",
      ip: "192.168.56.202"

    node.vm.provider "virtualbox" do |vb|
      vb.name   = "kworker2"
      vb.memory = 10240
      vb.cpus   = 3
    end

    node.vm.provision "shell", inline: COMMON_SCRIPT
  end

end