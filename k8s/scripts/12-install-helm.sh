#!/bin/bash
#============================================================
# Script Name : install-helm.sh
# Description : Install Helm 3 on Rocky Linux 9
# Author      : Senthil
#============================================================

set -e

echo "========================================="
echo " Installing Helm"
echo "========================================="

# Check root
if [[ $EUID -ne 0 ]]; then
    echo "Run this script as root."
    exit 1
fi

# Install required packages
dnf install -y curl tar git

# Download Helm install script
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

chmod +x get_helm.sh

# Install Helm
./get_helm.sh

# Cleanup
rm -f get_helm.sh

echo ""
echo "Helm Version:"
helm version

echo ""
echo "========================================="
echo " Helm Installed Successfully"
echo "========================================="
