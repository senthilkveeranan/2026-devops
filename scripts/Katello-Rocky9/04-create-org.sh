#!/bin/bash
#
# 04-create-org.sh
#
# Create Foreman/Katello Organization and Location
#
# Run ONLY on Katello server
#

set -euo pipefail


LOGFILE="/var/log/katello-create-org.log"

exec > >(tee -a ${LOGFILE}) 2>&1


ORG="Lab"
LOCATION="Madurai"


echo "=============================================="
echo "Creating Katello Organization and Location"
echo "=============================================="



##################################################
# Validate Host
##################################################

if [[ "$(hostname -f)" != "katello.lab.example.com" ]]
then

echo "ERROR: Run this script only on Katello server"

exit 1

fi



##################################################
# Configure Hammer
##################################################

echo "Checking Hammer"


hammer ping



##################################################
# Create Organization
##################################################

echo
echo "Checking Organization ${ORG}"


ORG_EXISTS=$(hammer organization list \
--search "name=${ORG}" \
--csv | grep "${ORG}" || true)


if [ -z "${ORG_EXISTS}" ]

then

echo "Creating Organization ${ORG}"


hammer organization create \
--name "${ORG}" \
--label "Lab" \
--description "Rocky Linux 9 Katello Lab"


else

echo "Organization already exists"

fi



##################################################
# Create Location
##################################################

echo

echo "Checking Location ${LOCATION}"


LOC_EXISTS=$(hammer location list \
--search "name=${LOCATION}" \
--csv | grep "${LOCATION}" || true)



if [ -z "${LOC_EXISTS}" ]

then

echo "Creating Location ${LOCATION}"


hammer location create \
--name "${LOCATION}" \
--description "Katello Lab Location"


else

echo "Location already exists"

fi



##################################################
# Associate Location + Organization
##################################################

echo

echo "Associating Organization and Location"


hammer organization add-location \
--name "${ORG}" \
--location "${LOCATION}" || true



hammer location add-organization \
--name "${LOCATION}" \
--organization "${ORG}" || true



##################################################
# Set Default Context
##################################################

echo

echo "Setting Hammer defaults"



mkdir -p ~/.hammer


cat > ~/.hammer/cli.modules.d/foreman.yml <<EOF

:foreman:
  :host: https://katello.lab.example.com
  :username: admin
  :password: changeme

EOF



chmod 600 ~/.hammer/cli.modules.d/foreman.yml



##################################################
# Verify
##################################################

echo
echo "Organizations"

hammer organization list



echo

echo "Locations"

hammer location list



echo

echo "=============================================="

echo "Organization and Location setup completed"

echo "=============================================="
