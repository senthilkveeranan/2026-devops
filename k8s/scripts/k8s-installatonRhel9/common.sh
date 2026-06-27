#!/bin/bash

set -e

echo "=============================="
echo " Kubernetes Common Setup"
echo "=============================="

hostnamectl

echo "Disable SELinux"
setenforce 0 || true
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

echo "Disable Swap"
swapoff -a
sed -i '/swap/d' /etc/fstab

echo "Enable kernel modules"

cat <<EOF >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

echo "Kernel Parameters"

cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sysctl --system

echo "Disable Firewall"

systemctl disable --now firewalld || true

echo "Install packages"

dnf install -y \
curl \
wget \
vim \
git \
bash-completion \
tar \
conntrack \
socat

echo "Install containerd"

dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

dnf install -y containerd.io

mkdir -p /etc/containerd

containerd config default >/etc/containerd/config.toml

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' \
/etc/containerd/config.toml

systemctl enable containerd
systemctl restart containerd

echo "Install Kubernetes"

cat <<EOF >/etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF

dnf install -y kubelet kubeadm kubectl

systemctl enable kubelet

echo "Completed"
