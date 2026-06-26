#!/bin/bash
#
# 02-katello-install.sh
#
# Install Foreman + Katello 4.16 on RHEL 9
#

set -euo pipefail

LOGFILE=/var/log/katello-install.log
exec > >(tee -a "${LOGFILE}") 2>&1

echo "========================================"
echo "Installing Katello 4.16"
echo "========================================"

# Skip if already installed
if rpm -q rubygem-foreman >/dev/null 2>&1; then
    echo "Katello/Foreman already appears to be installed."
    exit 0
fi

# ------------------------------------------------------------------
# Register with Red Hat (if not already registered)
# ------------------------------------------------------------------
subscription-manager status || true

# ------------------------------------------------------------------
# Enable the required RHEL and Katello repositories.
#
# This section must match:
#   - Your RHEL 9 minor release
#   - Your Red Hat subscription entitlements
#   - The current Katello 4.16 documentation
# ------------------------------------------------------------------

# Example placeholder:
# subscription-manager repos --enable=<required-repo>
# subscription-manager repos --enable=<required-repo>
# ...

# Refresh metadata
dnf clean all
dnf makecache

# Install the Katello installer package(s)
#
# Replace the package names below with the ones documented for your
# environment if they differ.
#
dnf -y install foreman-installer-katello

echo "Running foreman-installer..."

foreman-installer \
  --scenario katello \
  --foreman-initial-organization "Lab" \
  --foreman-initial-location "Madurai" \
  --foreman-initial-admin-username admin \
  --foreman-initial-admin-password changeme

echo "Waiting for services..."

systemctl is-active httpd
systemctl is-active pulpcore-api
systemctl is-active pulpcore-content
systemctl is-active candlepin
systemctl is-active postgresql

echo
echo "Katello installation completed successfully."
