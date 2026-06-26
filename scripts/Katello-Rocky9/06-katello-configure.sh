#!/bin/bash
#
# 06-katello-configure.sh
#
# Basic Katello configuration
# Rocky Linux 9 + Katello 4.16
#
# Run ONLY on Katello server
#

set -euo pipefail


LOGFILE="/var/log/katello-configure.log"

exec > >(tee -a ${LOGFILE}) 2>&1


ORG="Lab"

LOCATION="Madurai"


echo "=============================================="
echo "Katello Configuration"
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
# Verify Hammer
##################################################

echo "Checking Hammer"

hammer ping



##################################################
# Create Lifecycle Environments
##################################################

echo
echo "Creating Lifecycle Environments"



create_env()
{

ENV_NAME=$1

PRIOR=$2


if hammer lifecycle-environment list \
--organization "${ORG}" \
| grep -qw "${ENV_NAME}"

then

echo "${ENV_NAME} already exists"

else


echo "Creating ${ENV_NAME}"


hammer lifecycle-environment create \
--organization "${ORG}" \
--name "${ENV_NAME}" \
--prior "${PRIOR}"


fi

}



create_env DEV Library

create_env TEST DEV

create_env PROD TEST



##################################################
# Create Host Collection
##################################################

echo

echo "Creating Host Collection"



if hammer host-collection list \
--organization "${ORG}" \
| grep -qw LinuxServers

then

echo "Host Collection exists"


else


hammer host-collection create \
--organization "${ORG}" \
--name LinuxServers \
--description "Rocky Linux 9 Managed Servers"


fi



##################################################
# Configure Remote Execution
##################################################

echo

echo "Installing Remote Execution plugin"


dnf install -y \
tfm-rubygem-foreman_remote_execution



systemctl restart foreman



##################################################
# Verify Lifecycle
##################################################

echo

echo "Lifecycle Environments"

hammer lifecycle-environment list \
--organization "${ORG}"



echo

echo "Host Collections"

hammer host-collection list \
--organization "${ORG}"



echo

echo "=============================================="

echo "Katello Basic Configuration Completed"

echo "=============================================="
