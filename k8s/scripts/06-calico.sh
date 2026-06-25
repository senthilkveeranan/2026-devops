#!/bin/bash

set -euo pipefail

GREEN="\033[1;32m"
BLUE="\033[1;34m"
RED="\033[1;31m"
NC="\033[0m"

echo -e "${GREEN}"
echo "======================================================"
echo " Installing Calico CNI"
echo "======================================================"
echo -e "${NC}"

################################################################################
# Verify kubectl
################################################################################

if ! command -v kubectl &>/dev/null; then
    echo "kubectl not found."
    exit 1
fi

################################################################################
# Verify Cluster
################################################################################

kubectl cluster-info >/dev/null

################################################################################
# Install Calico
################################################################################

echo -e "${BLUE}Installing Calico...${NC}"

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml

################################################################################
# Wait for Calico
################################################################################

echo
echo "Waiting for Calico Pods..."

kubectl rollout status daemonset/calico-node \
-n kube-system \
--timeout=300s

kubectl rollout status deployment/calico-kube-controllers \
-n kube-system \
--timeout=300s

################################################################################
# Wait for CoreDNS
################################################################################

echo
echo "Waiting for CoreDNS..."

kubectl wait \
--for=condition=Ready \
pod \
-l k8s-app=kube-dns \
-n kube-system \
--timeout=300s

################################################################################
# Verify Cluster
################################################################################

echo
echo "Nodes"

kubectl get nodes -o wide

echo
echo "System Pods"

kubectl get pods -n kube-system -o wide

echo
echo "All Pods"

kubectl get pods -A

echo
echo "Services"

kubectl get svc -A

echo
echo "Cluster Info"

kubectl cluster-info

################################################################################
# Success
################################################################################

echo
echo -e "${GREEN}"
echo "======================================================"
echo " Calico Installed Successfully"
echo "======================================================"
echo -e "${NC}"
