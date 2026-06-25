#!/bin/bash
################################################################################
# Script Name : 10-metallb.sh
# Description : Install MetalLB for Kubernetes Bare Metal Cluster
# Kubernetes : v1.29.15
# Rocky Linux : 9.8
################################################################################

set -euo pipefail

################################################################################
# Variables
################################################################################

METALLB_VERSION="v0.15.2"

# Change this based on your lab network
POOL_START="192.168.56.240"
POOL_END="192.168.56.250"

################################################################################
# Colors
################################################################################

GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
NC="\033[0m"

################################################################################
# Root Check
################################################################################

if [[ $EUID -ne 0 ]]; then
    echo "Run as root"
    exit 1
fi

export KUBECONFIG=/etc/kubernetes/admin.conf

################################################################################
# Verify Cluster
################################################################################

echo
echo -e "${BLUE}"
echo "Checking Kubernetes Cluster..."
echo -e "${NC}"

kubectl get nodes

################################################################################
# Install MetalLB
################################################################################

echo
echo "Installing MetalLB..."

kubectl apply -f \
https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml

################################################################################
# Wait Namespace
################################################################################

kubectl wait \
--for=condition=Established \
crd/ipaddresspools.metallb.io \
--timeout=180s

sleep 20

################################################################################
# Verify Installation
################################################################################

kubectl get pods -n metallb-system
################################################################################
# Create IPAddressPool
################################################################################

echo
echo -e "${BLUE}"
echo "Creating MetalLB IP Address Pool..."
echo -e "${NC}"

cat <<EOF >/tmp/metallb-pool.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: production-pool
  namespace: metallb-system
spec:
  addresses:
  - ${POOL_START}-${POOL_END}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: production-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - production-pool
EOF

kubectl apply -f /tmp/metallb-pool.yaml

################################################################################
# Wait for MetalLB Controller
################################################################################

echo
echo "Waiting for MetalLB Components..."

kubectl rollout status deployment/controller \
-n metallb-system \
--timeout=180s

################################################################################
# Verify Pods
################################################################################

echo
echo "MetalLB Pods"

kubectl get pods -n metallb-system -o wide

################################################################################
# Verify DaemonSet
################################################################################

echo

kubectl get daemonset -n metallb-system

################################################################################
# Verify IPAddressPool
################################################################################

echo

kubectl get ipaddresspool -n metallb-system

################################################################################
# Verify L2Advertisement
################################################################################

echo

kubectl get l2advertisement -n metallb-system

################################################################################
# Create Test Deployment
################################################################################

echo

kubectl create deployment nginx-metallb \
--image=nginx \
--dry-run=client -o yaml | kubectl apply -f -

################################################################################
# Expose as LoadBalancer
################################################################################

kubectl expose deployment nginx-metallb \
--port=80 \
--type=LoadBalancer

################################################################################
# Wait for External IP
################################################################################

echo

echo "Waiting for External IP..."

sleep 30

kubectl get svc nginx-metallb

################################################################################
# Generate Report
################################################################################

cat >/root/metallb-info.txt <<EOF

===========================================
MetalLB Installation Report
===========================================

Date

$(date)

Nodes

$(kubectl get nodes)

Pods

$(kubectl get pods -n metallb-system)

IPAddressPool

$(kubectl get ipaddresspool -n metallb-system)

Services

$(kubectl get svc)

===========================================

EOF

################################################################################
# Success Banner
################################################################################

echo
echo -e "${GREEN}"
echo "=================================================="
echo " MetalLB Installed Successfully"
echo "=================================================="
echo
echo "Verify using:"
echo
echo "kubectl get svc"
echo
echo "kubectl get ipaddresspool -n metallb-system"
echo
echo "kubectl get pods -n metallb-system"
echo
echo "Report:"
echo "/root/metallb-info.txt"
echo
echo "=================================================="
echo -e "${NC}"
