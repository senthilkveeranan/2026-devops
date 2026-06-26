#!/bin/bash
#
# 01-update-hosts.sh
#
# Configure static hostname resolution for the Katello lab.
#

set -euo pipefail

HOSTS_FILE="/etc/hosts"
TMP_FILE=$(mktemp)

echo "=========================================="
echo "Updating /etc/hosts"
echo "=========================================="

# Detect hostname
HOSTNAME_FQDN=$(hostname -f 2>/dev/null || hostname)

# Remove previous lab entries while preserving everything else
grep -Ev \
'katello\.lab\.example\.com|client1\.lab\.example\.com|client2\.lab\.example\.com|192\.168\.56\.(10|11|12)' \
"${HOSTS_FILE}" > "${TMP_FILE}" || true

cat >> "${TMP_FILE}" <<EOF

###################################################
# Katello Lab
###################################################
192.168.56.10   katello.lab.example.com   katello
192.168.56.11   client1.lab.example.com   client1
192.168.56.12   client2.lab.example.com   client2
EOF

cp "${TMP_FILE}" "${HOSTS_FILE}"

chmod 644 "${HOSTS_FILE}"

rm -f "${TMP_FILE}"

echo
echo "Current hostname:"
hostnamectl

echo
echo "Verifying name resolution..."

getent hosts katello.lab.example.com
getent hosts client1.lab.example.com
getent hosts client2.lab.example.com

echo
echo "Updated /etc/hosts:"
echo "------------------------------------------"
cat /etc/hosts
echo "------------------------------------------"

echo
echo "01-update-hosts.sh completed successfully."
