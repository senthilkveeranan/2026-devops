#!/bin/bash
#
# 01-common.sh
# Enterprise Common Configuration for DevOps Lab
#

set -euo pipefail

LOGFILE="/var/log/devops-lab.log"

exec > >(tee -a "$LOGFILE") 2>&1

echo "========================================="
echo " DevOps Lab - Common Setup Started"
echo "========================================="

###############################
# Root Validation
###############################

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Please run as root."
    exit 1
fi

###############################
# Refresh PATH
###############################

export PATH="/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
hash -r

###############################
# Update System
###############################

echo "Updating system..."

dnf clean all
rm -rf /var/cache/dnf

dnf makecache
dnf -y update

###############################
# Enable CRB & EPEL
###############################

echo "Configuring CRB and EPEL repositories..."

dnf install -y dnf-plugins-core

dnf config-manager --set-enabled crb

dnf install -y \
https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

dnf makecache

###############################
# Install Common Packages
###############################

echo "Installing common packages..."

dnf install -y \
curl \
wget \
vim-enhanced \
nano \
git \
tar \
zip \
unzip \
jq \
tree \
bash-completion \
net-tools \
bind-utils \
telnet \
traceroute \
lsof \
htop \
make \
gcc \
gcc-c++ \
python3 \
python3-pip

###############################
# Install Java 21
###############################

echo "Installing Java 21..."

dnf install -y \
java-21-openjdk \
java-21-openjdk-devel

java -version

###############################
# Timezone
###############################

echo "Setting timezone..."

timedatectl set-timezone Asia/Kolkata

###############################
# Hostname
###############################

echo "Setting hostname..."

hostnamectl set-hostname devops-lab

###############################
# SELinux
###############################

echo "Configuring SELinux..."

setenforce 0 || true

sed -i 's/^SELINUX=.*/SELINUX=permissive/' \
/etc/selinux/config

###############################
# Firewall
###############################

echo "Disabling Firewall..."

systemctl disable --now firewalld || true

###############################
# Swap
###############################

echo "Disabling Swap..."

swapoff -a

sed -i '/swap/d' /etc/fstab

###############################
# Useful Aliases
###############################

echo "Configuring shell aliases..."

grep -q "alias ll=" /root/.bashrc || cat <<EOF >> /root/.bashrc

# DevOps Lab Aliases
alias ll='ls -lh'
alias la='ls -la'
alias k='kubectl'
alias d='docker'
alias dc='docker compose'

EOF

###############################
# Create Directories
###############################

echo "Creating directories..."

mkdir -p \
/opt/devops \
/opt/scripts \
/var/log/devops \
/data

###############################
# Python Packages
###############################

echo "Installing Python packages..."

pip3 install --upgrade pip

pip3 install \
requests \
PyYAML \
jmespath

###############################
# Refresh PATH
###############################

export PATH="/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
hash -r

###############################
# Summary
###############################

echo
echo "========================================="
echo " DevOps Lab - Common Setup Completed"
echo "========================================="

echo
echo "Hostname : $(hostname)"
echo "Timezone : $(timedatectl show --property=Timezone --value)"
echo "Java     : $(java -version 2>&1 | head -1)"
echo "Python   : $(python3 --version)"
echo "PIP      : $(pip3 --version)"
echo