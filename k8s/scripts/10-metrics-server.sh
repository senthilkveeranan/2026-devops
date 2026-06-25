#!/bin/bash
################################################################################
# Script Name : 11-metrics-server.sh
# Description : Install Kubernetes Metrics Server
# Kubernetes  : v1.29.15
# Rocky Linux : 9.8
################################################################################

set -euo pipefail

################################################################################
# Variables
################################################################################

METRICS_VERSION="v0.7.2"

################################################################################
# Colors
################################################################################

GREEN="\033[1;32m"
BLUE="\033[1;34m"
RED="\033[1;31m"
NC="\033[0m"

export KUBECONFIG=/etc/kubernetes/admin.conf

################################################################################
# Root Check
################################################################################

if [[ $EUID -ne 0 ]]; then
    echo "Run as root"
    exit 1
fi

################################################################################
# Verify Kubernetes
################################################################################

echo
echo -e "${BLUE}"
echo "=============================================="
echo "Verifying Kubernetes Cluster"
echo "=============================================="
echo -e "${NC}"

kubectl get nodes

################################################################################
# Download Metrics Server
################################################################################

echo

echo "Downloading Metrics Server..."

curl -L \
https://github.com/kubernetes-sigs/metrics-server/releases/download/${METRICS_VERSION}/components.yaml \
-o /root/metrics-server.yaml

################################################################################
# Configure Metrics Server
################################################################################

echo

echo "Configuring Metrics Server..."

sed -i '/args:/a\
        - --kubelet-insecure-tls\
        - --kubelet-preferred-address-types=InternalIP,Hostname\
        - --metric-resolution=15s' \
/root/metrics-server.yaml

################################################################################
# Install Metrics Server
################################################################################

kubectl apply -f /root/metrics-server.yaml

################################################################################
# Wait for Deployment
################################################################################

echo

echo "Waiting for Metrics Server..."

kubectl rollout status deployment metrics-server \
-n kube-system \
--timeout=180s

################################################################################
# Verify Pods
################################################################################

echo

kubectl get pods -n kube-system | grep metrics
################################################################################
# Wait for Metrics API
################################################################################

echo
echo "Waiting for Metrics API..."

COUNT=0

while true
do
    COUNT=$((COUNT+1))

    kubectl top nodes >/dev/null 2>&1 && break

    echo "Attempt : ${COUNT}"

    sleep 10

    if [[ "$COUNT" -ge 30 ]]; then

        echo
        echo "Metrics API Failed"

        kubectl get pods -n kube-system | grep metrics

        exit 1

    fi

done

################################################################################
# Verify APIService
################################################################################

echo
echo "APIService"

kubectl get apiservice | grep metrics

################################################################################
# Verify Nodes Metrics
################################################################################

echo
echo "Node Metrics"

kubectl top nodes

################################################################################
# Verify Pod Metrics
################################################################################

echo
echo "Pod Metrics"

kubectl top pods -A

################################################################################
# Describe Metrics Server
################################################################################

echo
echo "Metrics Server"

kubectl describe deployment metrics-server \
-n kube-system

################################################################################
# Verify Logs
################################################################################

echo
echo "Metrics Server Logs"

kubectl logs \
deployment/metrics-server \
-n kube-system \
--tail=20

################################################################################
# Cluster Resource Usage
################################################################################

echo
echo "Resource Usage"

kubectl top nodes

echo

kubectl top pods -A

################################################################################
# Generate Report
################################################################################

cat >/root/metrics-server-report.txt <<EOF

====================================================
Metrics Server Installation Report
====================================================

Installation Date

$(date)

Deployment

$(kubectl get deployment metrics-server -n kube-system)

Pods

$(kubectl get pods -n kube-system | grep metrics)

APIService

$(kubectl get apiservice | grep metrics)

Node Usage

$(kubectl top nodes)

Pod Usage

$(kubectl top pods -A)

====================================================

EOF

################################################################################
# Success Banner
################################################################################

echo
echo -e "${GREEN}"
echo "====================================================="
echo " Metrics Server Installed Successfully"
echo "====================================================="
echo

kubectl top nodes

echo

kubectl top pods -A

echo

echo "Report"

echo "/root/metrics-server-report.txt"

echo

echo "====================================================="
echo -e "${NC}"
