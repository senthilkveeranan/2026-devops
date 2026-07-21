#!/bin/bash
#
# Script Name : 08-longhorn.sh
# Description : Install Longhorn on K3s
# Author      : Senthil Kumar
#

set -e

echo "======================================"
echo " Installing Longhorn Storage"
echo "======================================"

# Check kubectl
if ! command -v kubectl &>/dev/null; then
    echo "ERROR: kubectl not found."
    exit 1
fi

# Check Helm
if ! command -v helm &>/dev/null; then
    echo "ERROR: Helm not installed."
    exit 1
fi

# Check node status
echo "Checking Kubernetes node..."
kubectl get nodes

# Verify iSCSI
if ! command -v iscsiadm &>/dev/null; then
    echo "Installing iscsi-initiator-utils..."
    dnf install -y iscsi-initiator-utils
fi

systemctl enable --now iscsid

echo "Adding Longhorn Helm repository..."
helm repo add longhorn https://charts.longhorn.io
helm repo update

echo "Creating namespace..."
kubectl create namespace longhorn-system --dry-run=client -o yaml | kubectl apply -f -

echo "Installing Longhorn..."

helm upgrade --install longhorn longhorn/longhorn \
    --namespace longhorn-system

echo "Waiting for Longhorn Pods..."

kubectl wait \
    --namespace longhorn-system \
    --for=condition=Ready pod \
    --all \
    --timeout=600s

echo
echo "======================================"
echo " Installed Successfully"
echo "======================================"

echo
echo "Namespaces"
kubectl get ns

echo
echo "Pods"
kubectl get pods -n longhorn-system

echo
echo "Services"
kubectl get svc -n longhorn-system

echo
echo "Storage Classes"
kubectl get sc

echo
echo "Done."
