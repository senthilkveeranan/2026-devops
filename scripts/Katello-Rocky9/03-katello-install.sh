#!/bin/bash
#
# 03-katello-install.sh
#
# Install Foreman + Katello 4.16
# Rocky Linux 9
#
# Run ONLY on katello.lab.example.com
#

set -euo pipefail


LOGFILE="/var/log/katello-install.log"

exec > >(tee -a ${LOGFILE}) 2>&1


echo "=============================================="
echo "Installing Foreman + Katello"
echo "Hostname: $(hostname)"
echo "=============================================="


##################################################
# Validate Host
##################################################

if [[ "$(hostname -f)" != "katello.lab.example.com" ]]
then

echo "ERROR: This script must run on Katello server"

exit 1

fi



##################################################
# Install Required Tools
##################################################

dnf install -y \
wget \
curl \
dnf-utils \
ca-certificates \
epel-release



##################################################
# Enable EPEL
##################################################

dnf config-manager \
--set-enabled crb || true



##################################################
# Add Foreman Repository
##################################################

echo "Adding Foreman Repository"


cat >/etc/yum.repos.d/foreman.repo <<EOF

[foreman]
name=Foreman Repo
baseurl=https://yum.theforeman.org/releases/3.14/el9/x86_64/
enabled=1
gpgcheck=0

EOF



##################################################
# Add Katello Repository
##################################################

echo "Adding Katello Repository"


cat >/etc/yum.repos.d/katello.repo <<EOF

[katello]
name=Katello Repo
baseurl=https://yum.theforeman.org/katello/4.16/katello/el9/x86_64/
enabled=1
gpgcheck=0

##################################################
# Add Puppet 7 Repository
##################################################

echo "Adding Puppet 7 Repository"


dnf install -y \
https://yum.puppet.com/puppet7-release-el-9.noarch.rpm

EOF



##################################################
# Refresh Metadata
##################################################

dnf clean all

dnf makecache



##################################################
# Install Installer Package
##################################################

echo "Installing Foreman Installer Katello"


dnf install -y \
foreman-installer-katello



##################################################
# Run Foreman Installer
##################################################

echo "Running Foreman Installer"


foreman-installer \
--scenario katello \
--foreman-initial-organization "Lab" \
--foreman-initial-location "Madurai" \
--foreman-initial-admin-username admin \
--foreman-initial-admin-password changeme



##################################################
# Enable Services
##################################################

systemctl enable --now \
foreman \
httpd \
postgresql \
redis \
pulpcore-api \
pulpcore-content



##################################################
# Verify Services
##################################################

echo
echo "Checking services"

systemctl --no-pager status foreman

systemctl --no-pager status httpd

systemctl --no-pager status postgresql



##################################################
# Check Katello
##################################################

echo

foreman-maintain service status



##################################################
# Display Access Details
##################################################

echo
echo "=============================================="
echo "Katello Installation Completed"
echo "=============================================="

echo

echo "URL:"
echo

echo "https://katello.lab.example.com"

echo

echo "Username:"
echo "admin"

echo

echo "Password:"
echo "changeme"

echo

echo "=============================================="
