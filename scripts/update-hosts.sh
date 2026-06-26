#!/bin/bash
#
# update-hosts.sh
# Updates /etc/hosts on all lab systems.
#

set -euo pipefail

HOSTS_FILE="/etc/hosts"
TMP_FILE="/tmp/hosts.$$"

cat > "${TMP_FILE}" <<EOF
127.0.0.1   localhost localhost.localdomain
::1         localhost localhost.localdomain

192.168.56.10   katello.lab.example.com   katello
192.168.56.11   client1.lab.example.com   client1
192.168.56.12   client2.lab.example.com   client2
EOF

# Preserve any existing non-lab entries.
grep -Ev 'katello\.lab\.example\.com|client1\.lab\.example\.com|client2\.lab\.example\.com|192\.168\.56\.(10|11|12)' \
    "${HOSTS_FILE}" >> "${TMP_FILE}" || true

cp "${TMP_FILE}" "${HOSTS_FILE}"
rm -f "${TMP_FILE}"

chmod 644 "${HOSTS_FILE}"

echo "--------------------------------------------------"
echo "/etc/hosts updated successfully"
echo "--------------------------------------------------"

cat "${HOSTS_FILE}"
