#!/usr/bin/env bash
###############################################################################
# Ultimate DevOps Lab
# Module      : 04-helm.sh
# Description : Install Helm Package Manager
# Platform    : Rocky Linux 9.x
# Version     : Enterprise Edition v2.0
###############################################################################

set -Eeuo pipefail

############################################
# Variables
############################################

HELM_VERSION="v3.21.3"
ARCH="amd64"

TMP_DIR="/tmp/helm"

############################################
# Logging
############################################

log() {

    echo -e "[INFO] $1"

}

warn() {

    echo -e "[WARN] $1"

}

error() {

    echo -e "[ERROR] $1"

    exit 1

}

############################################
# Root Check
############################################

[[ $EUID -eq 0 ]] || error "Run as root."

############################################
# Dependencies
############################################

for cmd in curl tar; do

    command -v "$cmd" >/dev/null || error "$cmd not installed."

done

############################################
# Already Installed
############################################

if command -v helm >/dev/null 2>&1; then

    log "Helm already installed."

    helm version

    exit 0

fi

############################################
# Download Helm
############################################

log "Downloading Helm..."

mkdir -p "$TMP_DIR"

cd "$TMP_DIR"

curl -LO \
https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz

############################################
# Extract
############################################

tar -xzf helm-${HELM_VERSION}-linux-${ARCH}.tar.gz

############################################
# Install
############################################

install -m 755 linux-${ARCH}/helm /usr/local/bin/helm

############################################
# Refresh PATH
############################################

export PATH="/usr/local/bin:$PATH"

hash -r

############################################
# Verify
############################################

if [[ ! -x /usr/local/bin/helm ]]; then

    error "Helm binary installation failed."

fi

############################################
# Add Repositories
############################################

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo add prometheus-community \
https://prometheus-community.github.io/helm-charts

helm repo add grafana \
https://grafana.github.io/helm-charts

helm repo add jenkins \
https://charts.jenkins.io

helm repo add sonarqube \
https://SonarSource.github.io/helm-chart-sonarqube

helm repo add argo \
https://argoproj.github.io/argo-helm

helm repo update

############################################
# Verification
############################################

echo

echo "======================================"

echo " Helm Version"

echo "======================================"

helm version

echo

echo "======================================"

echo " Helm Binary"

echo "======================================"

which helm

echo

echo "======================================"

echo " Repositories"

echo "======================================"

helm repo list

echo

echo "======================================"

echo " Installation Completed Successfully"

echo "======================================"
