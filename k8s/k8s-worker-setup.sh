k8s-worker-setup.sh
====================

#!/bin/bash

##############################################################################

# Script Name : k8s-worker-setup.sh

# Description : Common Kubernetes Worker Node Preparation Script

# OS          : Rocky Linux 9

# Kubernetes  : 1.29.x

##############################################################################

set -e

HOSTNAME=$1

if [ -z "$HOSTNAME" ]; then
echo "Usage: $0 <worker-hostname>"
echo "Example:"
echo "  $0 kworker1"
echo "  $0 kworker2"
exit 1
fi

echo "==================================================="
echo " Kubernetes Worker Node Preparation Started"
echo " Hostname : ${HOSTNAME}.example.com"
echo "==================================================="

# Hostname Configuration

hostnamectl set-hostname ${HOSTNAME}

# Update OS

dnf update -y

# Disable SELinux

setenforce 0 || true

sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

# Disable Swap

swapoff -a

sed -i '/swap/d' /etc/fstab

# Load Required Kernel Modules

cat <<EOF >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Kubernetes Kernel Parameters

cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# Install Required Packages

dnf install -y 
yum-utils 
device-mapper-persistent-data 
lvm2 
curl 
wget 
vim 
git 
bash-completion 
net-tools 
telnet 
nfs-utils 
iproute-tc 
tar 
unzip 
rsync 
socat 
conntrack-tools

# Containerd Repository

dnf config-manager --add-repo 
https://download.docker.com/linux/centos/docker-ce.repo

# Install Container Runtime

dnf install -y containerd.io

# Configure Containerd

mkdir -p /etc/containerd

containerd config default > /etc/containerd/config.toml

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' 
/etc/containerd/config.toml

systemctl daemon-reload
systemctl enable --now containerd

# Kubernetes Repository

cat <<EOF >/etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl
EOF

# Install Kubernetes Components

dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# Enable Kubelet

systemctl enable kubelet

# Firewall Configuration

systemctl enable --now firewalld

firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=30000-32767/tcp
firewall-cmd --reload

# Common Hosts File

cat >/etc/hosts <<EOF
127.0.0.1 localhost localhost.localdomain
::1 localhost localhost.localdomain

192.168.56.201 kmaster1.example.com kmaster1
192.168.56.202 kmaster2.example.com kmaster2
192.168.56.203 kworker1.example.com kworker1
192.168.56.204 kworker2.example.com kworker2
EOF

echo "127.0.1.1 ${HOSTNAME}.example.com ${HOSTNAME}" >> /etc/hosts

echo
echo "==================================================="
echo " Kubernetes Worker Node Preparation Completed"
echo "==================================================="

echo
echo "Verification Commands:"
echo "------------------------------------------------"
echo "hostname"
echo "hostname -f"
echo "containerd --version"
echo "kubeadm version"
echo "kubectl version --client"
echo "systemctl status containerd"
echo "systemctl status kubelet"
echo "------------------------------------------------"
