#!/bin/bash
#
# 08-create-content-view.sh
#
# Create Rocky Linux 9 Content View
# Katello 4.16
#
# Run ONLY on Katello server
#

set -euo pipefail


LOGFILE="/var/log/create-content-view.log"

exec > >(tee -a ${LOGFILE}) 2>&1


ORG="Lab"

PRODUCT="Rocky Linux 9"

CONTENT_VIEW="Rocky9-CV"


echo "=============================================="
echo "Creating Content View"
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
# Check Content View
##################################################

echo "Checking Content View"


if hammer content-view list \
--organization "${ORG}" \
| grep -qw "${CONTENT_VIEW}"

then

echo "Content View already exists"


else


echo "Creating Content View"


hammer content-view create \
--organization "${ORG}" \
--name "${CONTENT_VIEW}" \
--description "Rocky Linux 9 Base Content View"


fi



##################################################
# Add repositories
##################################################

echo

echo "Adding repositories"


for REPO in BaseOS AppStream CRB Extras

do


echo "Adding ${REPO}"


hammer content-view add-repository \
--organization "${ORG}" \
--content-view "${CONTENT_VIEW}" \
--product "${PRODUCT}" \
--repository "${REPO}" || true


done



##################################################
# Publish Content View
##################################################

echo

echo "Publishing Content View"



hammer content-view publish \
--organization "${ORG}" \
--name "${CONTENT_VIEW}" \
--description "Initial Rocky Linux 9 Publish"



##################################################
# Promote to DEV
##################################################

echo

echo "Promoting Content View to DEV"



VERSION=$(hammer content-view version list \
--organization "${ORG}" \
--content-view "${CONTENT_VIEW}" \
--latest \
--fields Version \
| tail -1)



hammer content-view version promote \
--organization "${ORG}" \
--content-view "${CONTENT_VIEW}" \
--version "${VERSION}" \
--to-lifecycle-environment DEV



##################################################
# Verify
##################################################

echo

echo "Content View List"


hammer content-view list \
--organization "${ORG}"



echo

echo "Content View Versions"


hammer content-view version list \
--organization "${ORG}" \
--content-view "${CONTENT_VIEW}"



echo

echo "=============================================="

echo "Content View Created Successfully"

echo "=============================================="
