#!/bin/bash
#
# 01-common.sh
#
# Common configuration for all lab systems
#

set -euo pipefail

LOGFILE=/var/log/katello-common.log

exec > >(tee -a ${LOGFILE}) 2>&1

echo "====================================================="
echo "Starting Common Configuration"
echo "====================================================="

###############################
# Update hosts file
###############################

/vagrant/scripts/update-hosts.sh

###############################
# Set Timezone
###############################

timedatectl set-timezone Asia/Kolkata

###############################
# Enable NTP
###############################

systemctl enable --now chronyd

###############################
# DNF Update
###############################

dnf -y clean all
dnf -y makecache
dnf -y update

###############################
# Install Common Packages
###############################

dnf install -y \
vim \
wget \
curl \
git \
tar \
zip \
unzip \
net-tools \
bind-utils \
bash-completion \
lsof \
tcpdump \
traceroute \
rsync \
jq \
tree \
nano \
tmux \
screen \
openssl \
policycoreutils-python-utils

###############################
# Disable Firewall
###############################

systemctl stop firewalld || true
systemctl disable firewalld || true

###############################
# SELinux
###############################

if command -v getenforce >/dev/null; then
    setenforce 0 || true
fi

sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

###############################
# Enable Useful Services
###############################

systemctl enable sshd
systemctl restart sshd

###############################
# SSH Optimization
###############################

grep -q "^UseDNS no" /etc/ssh/sshd_config || \
echo "UseDNS no" >> /etc/ssh/sshd_config

grep -q "^GSSAPIAuthentication no" /etc/ssh/sshd_config || \
echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config

systemctl restart sshd

###############################
# Kernel Parameters
###############################

cat >/etc/sysctl.d/99-katello.conf <<EOF
vm.swappiness=10
net.ipv4.ip_forward=1
fs.file-max=2097152
EOF

sysctl --system

###############################
# Disable IPv6 (Optional)
###############################

cat >/etc/sysctl.d/98-ipv6.conf <<EOF
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF

sysctl --system

###############################
# Verify Hostname
###############################

hostnamectl

###############################
# Verify Connectivity
###############################

ping -c2 katello.lab.example.com || true
ping -c2 client1.lab.example.com || true
ping -c2 client2.lab.example.com || true

###############################
# Display Network
###############################

ip addr

###############################
# Display Hosts File
###############################

cat /etc/hosts

###############################
# Cleanup
###############################

dnf autoremove -y
dnf clean all

echo
echo "====================================================="
echo "Common Configuration Completed Successfully"
echo "====================================================="
