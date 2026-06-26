#!/bin/bash
#
# 09-create-activation-key.sh
#
# Create Katello Activation Key
# Rocky Linux 9 + Katello 4.16
#
# Run ONLY on Katello server
#

set -euo pipefail


LOGFILE="/var/log/create-activation-key.log"

exec > >(tee -a ${LOGFILE}) 2>&1


ORG="Lab"

CONTENT_VIEW="Rocky9-CV"

LIFECYCLE="DEV"

ACTIVATION_KEY="rocky9"



echo "=============================================="
echo "Creating Activation Key"
echo "=============================================="


##################################################
# Validate Host
##################################################

if [[ "$(hostname -f)" != "katello.lab.example.com" ]]
then

echo "ERROR: Run only on Katello server"

exit 1

fi



##################################################
# Check Activation Key
##################################################

echo "Checking Activation Key"



if hammer activation-key list \
--organization "${ORG}" \
| grep -qw "${ACTIVATION_KEY}"

then

echo "Activation Key already exists"


else


echo "Creating Activation Key"



hammer activation-key create \
--organization "${ORG}" \
--name "${ACTIVATION_KEY}" \
--description "Rocky Linux 9 Client Registration Key" \
--lifecycle-environment "${LIFECYCLE}" \
--content-view "${CONTENT_VIEW}"


fi



##################################################
# Enable Auto Attach
##################################################

echo

echo "Updating Activation Key"



hammer activation-key update \
--organization "${ORG}" \
--name "${ACTIVATION_KEY}" \
--auto-attach true



##################################################
# Set Release Version
##################################################

hammer activation-key update \
--organization "${ORG}" \
--name "${ACTIVATION_KEY}" \
--release-version 9



##################################################
# Verify
##################################################

echo

echo "Activation Key Details"


hammer activation-key info \
--organization "${ORG}" \
--name "${ACTIVATION_KEY}"



echo

echo "=============================================="

echo "Activation Key Created Successfully"

echo "=============================================="
