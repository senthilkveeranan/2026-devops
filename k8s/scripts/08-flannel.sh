#!/bin/bash
################################################################################
# Script Name : 08-flannel.sh
# Description : Install Flannel CNI Plugin
# OS          : Rocky Linux 9.8
# Kubernetes  : v1.29.15
################################################################################

set -euo pipefail

################################################################################
# Variables
################################################################################

FLANNEL_URL="https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml"

GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NC="\033[0m"

export KUBECONFIG=/etc/kubernetes/admin.conf

################################################################################
# Root Check
################################################################################

if [[ $EUID -ne 0 ]]; then
    echo "Run as root."
    exit 1
fi

################################################################################
# Master Verification
################################################################################

HOST=$(hostname)

if [[ "$HOST" != "kmaster" ]]; then

echo

echo "Run this script only on Master."

exit 1

fi

################################################################################
# API Server Check
################################################################################

kubectl cluster-info >/dev/null

################################################################################
# Check Existing Calico
################################################################################

echo

echo -e "${BLUE}"
echo "Checking Existing CNI"
echo -e "${NC}"

CALICO=$(kubectl get pods -n kube-system 2>/dev/null | grep calico | wc -l)

if [[ "$CALICO" -gt 0 ]]; then

echo

echo -e "${YELLOW}"

echo "Calico is already installed."

echo

read -p "Remove Calico and Continue? (yes/no): " OPTION

if [[ "$OPTION" != "yes" ]]; then

exit 0

fi

echo

kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/calico.yaml

echo

echo "Waiting for Calico Cleanup..."

sleep 30

fi

################################################################################
# Download Flannel
################################################################################

echo

echo "Downloading Flannel..."

curl -L ${FLANNEL_URL} \
-o /root/kube-flannel.yml

################################################################################
# Verify Download
################################################################################

if [[ ! -f /root/kube-flannel.yml ]]; then

echo

echo "Download Failed."

exit 1

fi

################################################################################
# Install Flannel
################################################################################

echo

echo -e "${GREEN}"

echo "Installing Flannel..."

echo -e "${NC}"

kubectl apply -f /root/kube-flannel.yml

################################################################################
# Wait for Flannel
################################################################################

COUNT=0

while true
do

COUNT=$((COUNT+1))

READY=$(kubectl get pods -n kube-flannel --no-headers 2>/dev/null | \
grep Running | wc -l)

if [[ "$READY" -ge 1 ]]; then
    break
fi

echo "Waiting... Attempt ${COUNT}"

sleep 10

if [[ "$COUNT" -ge 30 ]]; then

echo

echo "Flannel Installation Failed."

kubectl get pods -A

exit 1

fi

done
################################################################################
# Verify Flannel DaemonSet
################################################################################

echo
echo -e "${BLUE}"
echo "=============================================="
echo "Flannel DaemonSet"
echo "=============================================="
echo -e "${NC}"

kubectl get daemonset -A

################################################################################
# Wait for CoreDNS
################################################################################

echo
echo "Waiting for CoreDNS..."

COUNT=0

while true
do

COUNT=$((COUNT+1))

READY=$(kubectl get pods -n kube-system \
--no-headers | grep coredns | grep Running | wc -l)

if [[ "$READY" -ge 2 ]]; then
    break
fi

echo "Attempt ${COUNT}"

sleep 10

if [[ "$COUNT" -ge 30 ]]; then

echo

echo "CoreDNS Failed"

kubectl get pods -A

exit 1

fi

done

################################################################################
# Verify Nodes
################################################################################

echo
echo -e "${GREEN}"
echo "=============================================="
echo "Node Status"
echo "=============================================="
echo -e "${NC}"

kubectl get nodes -o wide

################################################################################
# Verify kube-system Pods
################################################################################

echo

kubectl get pods -n kube-system -o wide

################################################################################
# Verify All Pods
################################################################################

echo

kubectl get pods -A

################################################################################
# Verify Services
################################################################################

echo

kubectl get svc -A

################################################################################
# Verify kube-proxy
################################################################################

echo

kubectl get daemonset kube-proxy -n kube-system

################################################################################
# Verify CNI Configuration
################################################################################

echo

echo "CNI Configuration"

ls -l /etc/cni/net.d/

################################################################################
# Verify Network Interfaces
################################################################################

echo

ip addr | grep flannel || true

################################################################################
# Verify Routing Table
################################################################################

echo

ip route

################################################################################
# DNS Test
################################################################################

kubectl delete pod dns-test --ignore-not-found=true

kubectl run dns-test \
--image=busybox:1.36 \
--restart=Never \
-- sleep 3600

kubectl wait \
--for=condition=Ready \
pod/dns-test \
--timeout=180s

kubectl exec dns-test -- nslookup kubernetes.default.svc.cluster.local

################################################################################
# Generate Report
################################################################################

cat >/root/flannel-info.txt <<EOF

======================================================
 Kubernetes Flannel Information
======================================================

Installation Date

$(date)

Nodes

$(kubectl get nodes)

Pods

$(kubectl get pods -A)

Services

$(kubectl get svc -A)

======================================================

EOF

################################################################################
# Cleanup
################################################################################

kubectl delete pod dns-test --ignore-not-found=true

################################################################################
# Success Banner
################################################################################

echo
echo -e "${GREEN}"
echo "======================================================"
echo " Flannel Installation Completed Successfully"
echo "======================================================"
echo

kubectl get nodes

echo

kubectl get pods -A

echo

echo "Next Step"

echo "./scripts/07-verify.sh"

echo

echo "======================================================"
echo -e "${NC}"
