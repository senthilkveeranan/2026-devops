#!/bin/bash
################################################################################
# Script Name : 07-verify.sh
# Description : Kubernetes Cluster Health Verification
# OS          : Rocky Linux 9.8
# Kubernetes  : v1.29.15
################################################################################

set -euo pipefail

################################################################################
# Variables
################################################################################

GREEN="\033[1;32m"
BLUE="\033[1;34m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

export KUBECONFIG=/etc/kubernetes/admin.conf

################################################################################
# Root Check
################################################################################

if [[ $EUID -ne 0 ]]; then
    echo "Run this script as root."
    exit 1
fi

################################################################################
# Verify kubectl
################################################################################

kubectl cluster-info >/dev/null 2>&1 || {
    echo "Kubernetes API Server is not reachable."
    exit 1
}

################################################################################
# Banner
################################################################################

echo
echo -e "${GREEN}"
echo "======================================================"
echo " Kubernetes Cluster Verification"
echo "======================================================"
echo -e "${NC}"

################################################################################
# Cluster Info
################################################################################

echo
echo -e "${BLUE}Cluster Information${NC}"

kubectl cluster-info

################################################################################
# Kubernetes Version
################################################################################

echo
echo -e "${BLUE}Kubernetes Version${NC}"

kubectl version

################################################################################
# Nodes
################################################################################

echo
echo -e "${BLUE}Node Status${NC}"

kubectl get nodes -o wide

################################################################################
# Node Readiness Check
################################################################################

NOTREADY=$(kubectl get nodes --no-headers | grep -v Ready | wc -l)

if [[ "$NOTREADY" -gt 0 ]]; then

echo
echo -e "${RED}"

echo "Some Nodes are Not Ready."

kubectl get nodes

exit 1

fi

################################################################################
# kube-system Pods
################################################################################

echo
echo -e "${BLUE}System Pods${NC}"

kubectl get pods -n kube-system -o wide

################################################################################
# Check Failed Pods
################################################################################

FAILED=$(kubectl get pods -A --no-headers | \
grep -E "CrashLoopBackOff|Error|ImagePullBackOff|Pending|ContainerCreating" | wc -l)

if [[ "$FAILED" -gt 0 ]]; then

echo

echo -e "${RED}"

echo "Some Pods are not Healthy"

kubectl get pods -A

exit 1

fi

################################################################################
# Control Plane Pods
################################################################################

echo
echo -e "${BLUE}Control Plane${NC}"

kubectl get pods -n kube-system | \
grep -E "apiserver|scheduler|controller|etcd"
################################################################################
# Calico Verification
################################################################################

echo
echo -e "${BLUE}Calico Components${NC}"

kubectl get pods -n kube-system | grep calico

################################################################################
# CoreDNS Verification
################################################################################

echo
echo -e "${BLUE}CoreDNS${NC}"

kubectl get pods -n kube-system | grep coredns

################################################################################
# kube-proxy Verification
################################################################################

echo
echo -e "${BLUE}kube-proxy${NC}"

kubectl get daemonset -n kube-system kube-proxy

################################################################################
# Services
################################################################################

echo
echo -e "${BLUE}Cluster Services${NC}"

kubectl get svc -A

################################################################################
# DaemonSets
################################################################################

echo
echo -e "${BLUE}DaemonSets${NC}"

kubectl get daemonset -A

################################################################################
# Deployments
################################################################################

echo
echo -e "${BLUE}Deployments${NC}"

kubectl get deployment -A

################################################################################
# DNS Test
################################################################################

echo
echo -e "${BLUE}Creating BusyBox Test Pod${NC}"

kubectl delete pod dns-test --ignore-not-found=true

kubectl run dns-test \
--image=busybox:1.36 \
--restart=Never \
-- sleep 3600

echo

echo "Waiting for BusyBox Pod..."

kubectl wait \
--for=condition=Ready \
pod/dns-test \
--timeout=180s

################################################################################
# DNS Resolution Test
################################################################################

echo
echo -e "${BLUE}DNS Resolution Test${NC}"

kubectl exec dns-test -- nslookup kubernetes.default.svc.cluster.local

################################################################################
# Internet Connectivity
################################################################################

echo
echo -e "${BLUE}Internet Connectivity${NC}"

kubectl exec dns-test -- ping -c 4 8.8.8.8 || true

################################################################################
# Test Deployment
################################################################################

echo
echo -e "${BLUE}Creating Test Deployment${NC}"

kubectl delete deployment nginx-test --ignore-not-found=true

kubectl create deployment nginx-test --image=nginx

kubectl expose deployment nginx-test \
--type=NodePort \
--port=80

################################################################################
# Wait for Deployment
################################################################################

kubectl rollout status deployment/nginx-test --timeout=180s

################################################################################
# Verify Test Deployment
################################################################################

echo
echo -e "${BLUE}Test Deployment${NC}"

kubectl get deployment nginx-test

kubectl get pods -o wide

kubectl get svc nginx-test

################################################################################
# Cluster Events
################################################################################

echo
echo -e "${BLUE}Recent Cluster Events${NC}"

kubectl get events -A \
--sort-by=.lastTimestamp | tail -20

################################################################################
# Generate Report
################################################################################

REPORT=/root/k8s-health-report.txt

cat > ${REPORT} <<EOF
==================================================
 Kubernetes Health Report
==================================================

Date:
$(date)

Nodes:
$(kubectl get nodes)

Pods:
$(kubectl get pods -A)

Services:
$(kubectl get svc -A)

DaemonSets:
$(kubectl get daemonset -A)

Deployments:
$(kubectl get deployment -A)

==================================================
EOF

################################################################################
# Cleanup Test Resources
################################################################################

kubectl delete pod dns-test --ignore-not-found=true

kubectl delete svc nginx-test --ignore-not-found=true

kubectl delete deployment nginx-test --ignore-not-found=true

################################################################################
# Success Banner
################################################################################

echo
echo -e "${GREEN}"
echo "======================================================"
echo " Kubernetes Cluster Verification Successful"
echo "======================================================"
echo
echo "Health Report : ${REPORT}"
echo
echo "Recommended Verification Commands:"
echo
echo "kubectl get nodes -o wide"
echo "kubectl get pods -A -o wide"
echo "kubectl get svc -A"
echo "kubectl top nodes"
echo "kubectl top pods -A"
echo
echo "======================================================"
echo -e "${NC}"
