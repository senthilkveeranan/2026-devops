#!/bin/bash
#
# 12-verify-lab.sh
#
# Katello Rocky Linux 9 Lab Verification
#
# Run ONLY on Katello server
#

set -euo pipefail


LOGFILE="/var/log/verify-katello-lab.log"

exec > >(tee -a ${LOGFILE}) 2>&1



ORG="Lab"

CONTENT_VIEW="Rocky9-CV"

PRODUCT="Rocky Linux 9"

ACTIVATION_KEY="rocky9"



echo
echo "=============================================="
echo "Katello Lab Verification"
echo "Hostname: $(hostname)"
echo "Date: $(date)"
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
# Foreman/Katello Health
##################################################

echo
echo "1. Foreman/Katello Health"
echo "--------------------------------"


foreman-maintain health check || true



##################################################
# Hammer Connection
##################################################

echo
echo "2. Hammer API Test"
echo "--------------------------------"


hammer ping



##################################################
# Organization
##################################################

echo
echo "3. Organization"
echo "--------------------------------"


hammer organization list



##################################################
# Lifecycle Environment
##################################################

echo
echo "4. Lifecycle Environments"
echo "--------------------------------"


hammer lifecycle-environment list \
--organization "${ORG}"



##################################################
# Repository Check
##################################################

echo
echo "5. Rocky Linux Repositories"
echo "--------------------------------"



hammer repository list \
--organization "${ORG}" \
--product "${PRODUCT}"



##################################################
# Content View
##################################################

echo
echo "6. Content View"
echo "--------------------------------"



hammer content-view list \
--organization "${ORG}"



hammer content-view version list \
--organization "${ORG}" \
--content-view "${CONTENT_VIEW}"



##################################################
# Activation Key
##################################################

echo
echo "7. Activation Key"
echo "--------------------------------"



hammer activation-key list \
--organization "${ORG}"



hammer activation-key info \
--organization "${ORG}" \
--name "${ACTIVATION_KEY}"



##################################################
# Registered Hosts
##################################################

echo
echo "8. Registered Hosts"
echo "--------------------------------"



hammer host list



##################################################
# Check Client Connectivity
##################################################

echo
echo "9. Client Connectivity"
echo "--------------------------------"



for HOST in client1.lab.example.com client2.lab.example.com

do


echo

echo "Testing ${HOST}"


ping -c 2 ${HOST}



done



##################################################
# Check HTTPS
##################################################

echo
echo "10. Katello HTTPS Test"
echo "--------------------------------"



curl -k -I \
https://katello.lab.example.com



##################################################
# Final Result
##################################################


echo
echo "=============================================="
echo "Katello Rocky Linux 9 Lab Verification Done"
echo "=============================================="

echo

echo "Expected Managed Hosts:"
echo

echo "client1.lab.example.com"

echo "client2.lab.example.com"

echo

echo "Katello URL:"
echo

echo "https://katello.lab.example.com"

echo

echo "Admin User:"
echo

echo "admin"

echo

echo "Password:"
echo

echo "changeme"

echo

echo "=============================================="
