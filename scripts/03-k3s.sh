#!/usr/bin/env bash
###############################################################################
# Ultimate DevOps Lab
# Module      : 03-k3s.sh
# Description : Install & Configure K3s Kubernetes
# Platform    : Rocky Linux 9.x
# Version     : Enterprise Edition v2.0
###############################################################################

set -Eeuo pipefail

############################################
# Variables
############################################

K3S_CHANNEL="stable"
INSTALL_SCRIPT="https://get.k3s.io"

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
# Required Commands
############################################

for cmd in curl ip systemctl; do
    command -v "$cmd" >/dev/null || error "$cmd not installed."
done

############################################
# Detect Private IP
############################################

PRIVATE_IP=$(ip -4 addr show | awk '/192\.168\./{
sub(/\/.*/,"",$2)
print $2
exit
}')

if [[ -z "$PRIVATE_IP" ]]; then
    PRIVATE_IP=$(hostname -I | awk '{print $1}')
fi

log "Detected Node IP : $PRIVATE_IP"

############################################
# Install K3s
############################################

if command -v k3s >/dev/null 2>&1; then

    log "K3s already installed."

else

    log "Installing K3s..."

    curl -sfL ${INSTALL_SCRIPT} | \
    INSTALL_K3S_CHANNEL=${K3S_CHANNEL} \
    INSTALL_K3S_EXEC="server \
        --node-ip=${PRIVATE_IP} \
        --advertise-address=${PRIVATE_IP} \
        --tls-san=${PRIVATE_IP}" \
    sh -

fi

############################################
# PATH Refresh
############################################

export PATH=$PATH:/usr/local/bin

hash -r

############################################
# kubectl Resolution
############################################

if command -v kubectl >/dev/null 2>&1; then

    KUBECTL="kubectl"

elif command -v k3s >/dev/null 2>&1; then

    KUBECTL="k3s kubectl"

else

    error "kubectl not found."

fi

############################################
# Enable Service
############################################

systemctl enable k3s

if ! systemctl is-active --quiet k3s; then

    log "Starting k3s..."

    systemctl start k3s

fi

############################################
# Wait for API
############################################

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

log "Waiting for Kubernetes API..."

for i in {1..60}; do

    if $KUBECTL get nodes >/dev/null 2>&1; then
        break
    fi

    sleep 2

done

############################################
# Configure kubeconfig
############################################

mkdir -p /root/.kube

cp -f /etc/rancher/k3s/k3s.yaml /root/.kube/config

chmod 600 /root/.kube/config

sed -i "s#https://127.0.0.1:6443#https://${PRIVATE_IP}:6443#g" \
/root/.kube/config

export KUBECONFIG=/root/.kube/config

############################################
# Verification
############################################

echo
echo "========================================="
echo " K3s Cluster Information"
echo "========================================="

$KUBECTL cluster-info

echo
echo "========================================="
echo " Nodes"
echo "========================================="

$KUBECTL get nodes -o wide

echo
echo "========================================="
echo " System Pods"
echo "========================================="

$KUBECTL get pods -A

echo
echo "========================================="
echo " Storage Class"
echo "========================================="

$KUBECTL get sc

echo
echo "========================================="
echo " Metrics"
echo "========================================="

$KUBECTL top nodes 2>/dev/null || warn "Metrics Server not installed."

echo
echo "========================================="
echo " Versions"
echo "========================================="

k3s --version

$KUBECTL version

echo
echo "========================================="
echo " Installation Completed Successfully"
echo "========================================="