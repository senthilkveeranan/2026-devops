#!/bin/bash
#
# 05-configure-hammer.sh
#
# Configure Hammer CLI for Katello automation
#
# Run ONLY on Katello server
#

set -euo pipefail


LOGFILE="/var/log/configure-hammer.log"

exec > >(tee -a ${LOGFILE}) 2>&1


FOREMAN_URL="https://katello.lab.example.com"

USERNAME="admin"

PASSWORD="changeme"

ORG="Lab"

LOCATION="Madurai"



echo "=============================================="
echo "Configuring Hammer CLI"
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
# Install Hammer Packages
##################################################

echo "Installing Hammer packages"



dnf install -y \
tfm-rubygem-hammer_cli \
tfm-rubygem-hammer_cli_foreman \
tfm-rubygem-hammer_cli_foreman_tasks \
tfm-rubygem-hammer_cli_katello



##################################################
# Create Hammer Configuration
##################################################

echo "Creating Hammer configuration"


mkdir -p ~/.hammer/cli.modules.d



cat > ~/.hammer/cli.modules.d/foreman.yml <<EOF

:foreman:

  :host: ${FOREMAN_URL}

  :username: ${USERNAME}

  :password: ${PASSWORD}

  :request_timeout: 120


EOF



cat > ~/.hammer/cli.modules.d/katello.yml <<EOF

:katello:

  :use_cache: true


EOF



chmod 600 ~/.hammer/cli.modules.d/*.yml



##################################################
# Test Hammer
##################################################

echo

echo "Testing Foreman API"

hammer ping



##################################################
# Set Default Context
##################################################

echo

echo "Setting default organization"


hammer defaults add \
--param-name organization \
--param-value "${ORG}" || true



hammer defaults add \
--param-name location \
--param-value "${LOCATION}" || true



##################################################
# Verify Defaults
##################################################

echo

echo "Hammer defaults"

hammer defaults list



##################################################
# Test Katello Commands
##################################################

echo

echo "Testing Katello"


hammer product list

hammer repository list

hammer lifecycle-environment list



echo

echo "=============================================="

echo "Hammer configuration completed"

echo "=============================================="
