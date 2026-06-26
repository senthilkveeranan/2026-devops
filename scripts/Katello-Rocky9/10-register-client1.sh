#!/bin/bash
#
# 10-register-client1.sh
#
# Register Rocky Linux 9 client1 to Katello
#
# Run ONLY on client1.lab.example.com
#

set -euo pipefail


LOGFILE="/var/log/register-client1.log"

exec > >(tee -a ${LOGFILE}) 2>&1


KATELLO="katello.lab.example.com"

ORG="Lab"

ACTIVATION_KEY="rocky9"



echo "=============================================="
echo "Registering Client1 to Katello"
echo "=============================================="


##################################################
# Validate Host
##################################################

if [[ "$(hostname -f)" != "client1.lab.example.com" ]]
then

echo "ERROR: Run only on client1"

exit 1

fi



##################################################
# Install Required Packages
##################################################

echo "Installing packages"


dnf install -y \
curl \
wget \
ca-certificates \
subscription-manager \
dnf-plugin-subscription-manager



##################################################
# Install Katello CA
##################################################

echo "Installing Katello CA certificate"


curl -s \
-o /etc/pki/ca-trust/source/anchors/katello-server-ca.crt \
https://${KATELLO}/pub/katello-server-ca.crt



update-ca-trust



##################################################
# Check Existing Registration
##################################################

if subscription-manager identity &>/dev/null

then

echo "Client already registered"

else



##################################################
# Register Client
##################################################


echo "Registering client1"



subscription-manager register \
--org="${ORG}" \
--activationkey="${ACTIVATION_KEY}" \
--serverurl=https://${KATELLO}/rhsm



fi



##################################################
# Enable Repositories
##################################################

echo

echo "Refreshing repositories"


subscription-manager refresh



dnf clean all


dnf repolist



##################################################
# Verify
##################################################

echo

echo "Subscription Status"


subscription-manager status



echo

echo "Identity"


subscription-manager identity



echo

echo "=============================================="

echo "Client1 Registration Completed"

echo "=============================================="
