#!/bin/bash
#
# 11-register-client2.sh
#
# Register Rocky Linux 9 client2 to Katello
#
# Run ONLY on client2.lab.example.com
#

set -euo pipefail


LOGFILE="/var/log/register-client2.log"

exec > >(tee -a ${LOGFILE}) 2>&1


KATELLO="katello.lab.example.com"

ORG="Lab"

ACTIVATION_KEY="rocky9"



echo "=============================================="
echo "Registering Client2 to Katello"
echo "=============================================="


##################################################
# Validate Host
##################################################

if [[ "$(hostname -f)" != "client2.lab.example.com" ]]
then

echo "ERROR: Run only on client2"

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


echo "Registering client2"



subscription-manager register \
--org="${ORG}" \
--activationkey="${ACTIVATION_KEY}" \
--serverurl=https://${KATELLO}/rhsm



fi



##################################################
# Refresh Subscription
##################################################

echo

echo "Refreshing subscription"


subscription-manager refresh



##################################################
# Verify Repositories
##################################################

echo

echo "Available repositories"



dnf clean all


dnf repolist



##################################################
# Verify Registration
##################################################

echo

echo "Subscription Status"


subscription-manager status



echo

echo "Identity"


subscription-manager identity



echo

echo "=============================================="

echo "Client2 Registration Completed"

echo "=============================================="
