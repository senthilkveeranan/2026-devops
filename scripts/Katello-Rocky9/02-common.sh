#!/bin/bash
#
# 02-common.sh
#
# Common Rocky Linux 9 configuration
# Runs on Katello + Clients
#

set -euo pipefail

LOGFILE="/var/log/katello-common.log"

exec > >(tee -a ${LOGFILE}) 2>&1


echo "=============================================="
echo "Starting Common Configuration"
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo "=============================================="


##################################################
# Update hosts file
##################################################

if [ -f /vagrant/scripts/01-update-hosts.sh ]; then

chmod +x /vagrant/scripts/01-update-hosts.sh

/vagrant/scripts/01-update-hosts.sh

fi



##################################################
# System Update
##################################################

echo "Updating Rocky Linux..."

dnf clean all

dnf makecache

dnf -y update



##################################################
# Time Configuration
##################################################

echo "Configuring Chrony..."

dnf install -y chrony

systemctl enable chronyd

systemctl restart chronyd

timedatectl set-timezone Asia/Kolkata



##################################################
# Install Common Packages
##################################################

echo "Installing packages..."


dnf install -y \
vim \
nano \
wget \
curl \
git \
net-tools \
bind-utils \
tcpdump \
traceroute \
lsof \
telnet \
rsync \
zip \
unzip \
tar \
bash-completion \
jq \
tree \
tmux \
screen \
policycoreutils-python-utils \
firewalld \
openssl \
python3 \
python3-pip



##################################################
# SELinux Configuration
##################################################

echo "Configuring SELinux"


setenforce 0 || true


sed -i \
's/^SELINUX=.*/SELINUX=permissive/' \
/etc/selinux/config



##################################################
# Firewall Configuration
##################################################

echo "Configuring Firewall"


systemctl enable firewalld

systemctl start firewalld


# Allow required services

firewall-cmd --permanent --add-service=http || true

firewall-cmd --permanent --add-service=https || true

firewall-cmd --permanent --add-service=ssh || true


firewall-cmd --reload



##################################################
# SSH Optimization
##################################################

echo "Updating SSH settings"


grep -q "^UseDNS no" /etc/ssh/sshd_config || \
echo "UseDNS no" >> /etc/ssh/sshd_config


grep -q "^GSSAPIAuthentication no" /etc/ssh/sshd_config || \
echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config


systemctl restart sshd



##################################################
# Kernel Parameters
##################################################

echo "Applying kernel tuning"


cat >/etc/sysctl.d/99-katello.conf <<EOF

vm.swappiness=10

fs.file-max=2097152

net.ipv4.ip_forward=1

EOF


sysctl --system



##################################################
# Limits Configuration
##################################################

cat >/etc/security/limits.d/99-katello.conf <<EOF

* soft nofile 65535

* hard nofile 65535

EOF



##################################################
# Disable IPv6 (Lab)
##################################################

cat >/etc/sysctl.d/98-disable-ipv6.conf <<EOF

net.ipv6.conf.all.disable_ipv6=1

net.ipv6.conf.default.disable_ipv6=1

EOF


sysctl --system



##################################################
# Verify Environment
##################################################

echo
echo "System Information"
echo "===================="


hostnamectl

echo

ip addr

echo

df -h



##################################################
# Cleanup
##################################################

dnf clean all



echo
echo "=============================================="
echo "Common Configuration Completed"
echo "Hostname: $(hostname)"
echo "=============================================="
