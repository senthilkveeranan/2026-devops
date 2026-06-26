#!/bin/bash
#
# 03-katello-configure.sh
#

set -euo pipefail

LOGFILE=/var/log/katello-configure.log

exec > >(tee -a ${LOGFILE}) 2>&1

echo "=============================================="
echo "Configuring Katello"
echo "=============================================="

ORG="Lab"
LOCATION="Madurai"

ADMIN="admin"
PASSWORD="changeme"

#########################################################
# Configure Hammer
#########################################################

mkdir -p ~/.hammer

cat > ~/.hammer/cli.modules.d/foreman.yml <<EOF
:foreman:
  :host: 'https://katello.lab.example.com'
  :username: '${ADMIN}'
  :password: '${PASSWORD}'
EOF

chmod 600 ~/.hammer/cli.modules.d/foreman.yml

#########################################################
# Verify Connection
#########################################################

hammer ping

#########################################################
# Create Lifecycle Environments
#########################################################

for ENV in DEV TEST PROD
do

if ! hammer lifecycle-environment list \
--organization "${ORG}" | grep -qw "${ENV}"
then

hammer lifecycle-environment create \
--organization "${ORG}" \
--name "${ENV}" \
--prior Library

fi

done

#########################################################
# Create Content View
#########################################################

CV="RHEL9"

if ! hammer content-view list \
--organization "${ORG}" | grep -qw "${CV}"
then

hammer content-view create \
--organization "${ORG}" \
--name "${CV}" \
--description "RHEL9 Base Content View"

fi

#########################################################
# Publish Content View
#########################################################

hammer content-view publish \
--organization "${ORG}" \
--name "${CV}" \
--description "Initial Publish" || true

#########################################################
# Promote Content View
#########################################################

for ENV in DEV TEST PROD
do

hammer content-view version promote \
--organization "${ORG}" \
--content-view "${CV}" \
--to-lifecycle-environment "${ENV}" || true

done

#########################################################
# Create Host Collection
#########################################################

if ! hammer host-collection list \
--organization "${ORG}" | grep -qw LinuxServers
then

hammer host-collection create \
--organization "${ORG}" \
--name LinuxServers

fi

#########################################################
# Create Activation Key
#########################################################

if ! hammer activation-key list \
--organization "${ORG}" | grep -qw rhel9
then

hammer activation-key create \
--organization "${ORG}" \
--name rhel9 \
--lifecycle-environment DEV \
--content-view "${CV}"

fi

#########################################################
# Set Release Version
#########################################################

hammer activation-key update \
--organization "${ORG}" \
--name rhel9 \
--release-version 9

#########################################################
# Enable Auto Attach
#########################################################

hammer activation-key update \
--organization "${ORG}" \
--name rhel9 \
--auto-attach true

#########################################################
# Verify Configuration
#########################################################

echo
echo "Organizations"
hammer organization list

echo
echo "Lifecycle Environments"
hammer lifecycle-environment list \
--organization "${ORG}"

echo
echo "Content Views"
hammer content-view list \
--organization "${ORG}"

echo
echo "Activation Keys"
hammer activation-key list \
--organization "${ORG}"

echo
echo "Host Collections"
hammer host-collection list \
--organization "${ORG}"

echo
echo "=============================================="
echo "Katello Configuration Completed"
echo "=============================================="
