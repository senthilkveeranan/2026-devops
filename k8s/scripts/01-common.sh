#!/bin/bash
################################################################################
# Script Name : 01-common.sh
# Purpose     : Common Kubernetes Prerequisites
# OS          : Rocky Linux 9.8
# Kubernetes  : v1.29.15
################################################################################

set -e

GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${GREEN}"
echo "======================================================="
echo " Kubernetes Common Configuration"
echo "======================================================="
echo -e "${NC}"

################################################################################
# Root Check
################################################################################

if [ "$EUID" -ne 0 ]; then
    echo "Run as root"
    exit 1
fi

################################################################################
# Update OS
################################################################################

echo -e "${BLUE}Updating Rocky Linux...${NC}"

dnf clean all
dnf makecache
dnf -y update

################################################################################
# Install Packages
################################################################################

echo -e "${BLUE}Installing Common Packages...${NC}"

dnf install -y \
vim \
curl \
wget \
tar \
git \
bash-completion \
net-tools \
bind-utils \
iproute \
iputils \
socat \
conntrack-tools \
nmap-ncat \
chrony

################################################################################
# Disable SELinux
################################################################################

echo -e "${BLUE}Disabling SELinux...${NC}"

setenforce 0 || true

sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

################################################################################
# Disable Swap
################################################################################

echo -e "${BLUE}Disabling Swap...${NC}"

swapoff -a

sed -ri '/swap/s/^/#/' /etc/fstab

################################################################################
# Enable IP Forwarding
################################################################################

echo -e "${BLUE}Enabling IPv4 Forwarding...${NC}"

cat <<EOF >/etc/sysctl.d/99-kubernetes.conf
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
net.ipv4.conf.all.forwarding=1
net.ipv6.conf.all.forwarding=1
vm.swappiness=0
EOF

################################################################################
# Kernel Modules
################################################################################

cat <<EOF >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

################################################################################
# Apply sysctl
################################################################################

sysctl --system

################################################################################
# Firewalld
################################################################################

echo -e "${BLUE}Configuring Firewall...${NC}"

systemctl enable firewalld
systemctl restart firewalld

firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10257/tcp
firewall-cmd --permanent --add-port=10259/tcp
firewall-cmd --permanent --add-port=30000-32767/tcp
firewall-cmd --permanent --add-masquerade

firewall-cmd --reload

################################################################################
# Chrony
################################################################################

echo -e "${BLUE}Configuring Time Sync...${NC}"

systemctl enable chronyd
systemctl restart chronyd

################################################################################
# Hosts File
################################################################################

echo -e "${BLUE}Updating /etc/hosts...${NC}"

cat <<EOF >> /etc/hosts

192.168.56.101 kmaster kmaster.example.com
192.168.56.201 kworker1 kworker1.example.com
192.168.56.202 kworker2 kworker2.example.com
EOF

################################################################################
# Disable Firewall for Lab (Optional)
################################################################################

# Uncomment below if preferred for a lab environment.
# systemctl disable firewalld
# systemctl stop firewalld

################################################################################
# Network Verification
################################################################################

echo

hostnamectl

echo

ip addr

echo

free -h

echo

df -h

echo

lsmod | grep br_netfilter

echo

sysctl net.ipv4.ip_forward

################################################################################

echo -e "${GREEN}"
echo "======================================================="
echo " Common Configuration Completed Successfully"
echo "======================================================="
echo -e "${NC}"
