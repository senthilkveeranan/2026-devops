#!/bin/bash
#
# 05-metallb.sh
# Install MetalLB for k3s
#

set -euo pipefail

LOGFILE="/var/log/devops/metallb.log"

mkdir -p /var/log/devops

exec > >(tee -a "$LOGFILE") 2>&1

echo "========================================="
echo " Installing MetalLB"
echo "========================================="

export PATH="/usr/local/bin:$PATH"
hash -r

command -v kubectl >/dev/null || {
    echo "[ERROR] kubectl not found."
    exit 1
}

echo "[INFO] Installing MetalLB..."

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml

echo
echo "[INFO] Waiting for MetalLB..."

kubectl wait \
--namespace metallb-system \
--for=condition=Available \
deployment/controller \
--timeout=300s

echo
echo "[INFO] Creating IPAddressPool..."

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.56.210-192.168.56.220
EOF

echo
echo "[INFO] Creating L2Advertisement..."

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
EOF

echo
echo "========================================="
echo " MetalLB Pods"
echo "========================================="

kubectl get pods -n metallb-system

echo
echo "========================================="
echo " IPAddressPool"
echo "========================================="

kubectl get ipaddresspool -n metallb-system

echo
echo "========================================="
echo " L2Advertisement"
echo "========================================="

kubectl get l2advertisement -n metallb-system

echo
echo "========================================="
echo " MetalLB Installed Successfully"
echo "========================================="
