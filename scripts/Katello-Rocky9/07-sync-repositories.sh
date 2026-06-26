#!/bin/bash
#
# 07-sync-repositories.sh
#
# Rocky Linux 9 repository synchronization
# Katello 4.16
#
# Run ONLY on Katello server
#

set -euo pipefail


LOGFILE="/var/log/sync-repositories.log"

exec > >(tee -a ${LOGFILE}) 2>&1


ORG="Lab"

PRODUCT="Rocky Linux 9"


echo "=============================================="
echo "Rocky Linux 9 Repository Sync"
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

hammer ping



##################################################
# Create Product
##################################################

echo "Checking Product"



if hammer product list \
--organization "${ORG}" \
| grep -qw "${PRODUCT}"

then

echo "Product already exists"


else


echo "Creating Product"


hammer product create \
--organization "${ORG}" \
--name "${PRODUCT}" \
--description "Rocky Linux 9 Repositories"


fi



##################################################
# Repository Function
##################################################

create_repo()
{

NAME=$1

URL=$2


echo

echo "Checking repository ${NAME}"


if hammer repository list \
--organization "${ORG}" \
--product "${PRODUCT}" \
| grep -qw "${NAME}"

then


echo "${NAME} exists"



else


echo "Creating ${NAME}"


hammer repository create \
--organization "${ORG}" \
--product "${PRODUCT}" \
--name "${NAME}" \
--content-type yum \
--url "${URL}" \
--download-policy immediate \
--publish-via-http true



fi


}



##################################################
# Rocky Linux 9 Repositories
##################################################


BASE_URL="https://dl.rockylinux.org/pub/rocky/9"


create_repo \
"BaseOS" \
"${BASE_URL}/BaseOS/x86_64/os/"


create_repo \
"AppStream" \
"${BASE_URL}/AppStream/x86_64/os/"


create_repo \
"CRB" \
"${BASE_URL}/CRB/x86_64/os/"


create_repo \
"Extras" \
"${BASE_URL}/extras/x86_64/os/"



##################################################
# Synchronize
##################################################


echo

echo "Starting Repository Synchronization"



for REPO in BaseOS AppStream CRB Extras

do


echo

echo "Syncing ${REPO}"


hammer repository synchronize \
--organization "${ORG}" \
--product "${PRODUCT}" \
--name "${REPO}"


done



##################################################
# Show Status
##################################################


echo

echo "Repository List"


hammer repository list \
--organization "${ORG}" \
--product "${PRODUCT}"



echo

echo "=============================================="

echo "Repository Sync Completed"

echo "=============================================="
