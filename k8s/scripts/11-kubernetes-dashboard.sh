#!/bin/bash
################################################################################
# Script Name : 12-kubernetes-dashboard.sh
# Description : Install Kubernetes Dashboard
# Kubernetes  : v1.29.15
# Rocky Linux : 9.8
################################################################################

set -euo pipefail

################################################################################
# Variables
################################################################################

DASHBOARD_VERSION="v7.10.5"

################################################################################
# Colors
################################################################################

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
# Verify Cluster
################################################################################

echo
echo -e "${BLUE}"
echo "================================================="
echo " Kubernetes Dashboard Installation"
echo "================================================="
echo -e "${NC}"

kubectl get nodes

################################################################################
# Install Dashboard
################################################################################

echo
echo "Installing Kubernetes Dashboard..."

kubectl apply -f \
https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml

################################################################################
# Wait for Dashboard
################################################################################

echo
echo "Waiting for Dashboard Deployment..."

kubectl rollout status deployment/kubernetes-dashboard \
-n kubernetes-dashboard \
--timeout=300s

################################################################################
# Verify Pods
################################################################################

echo

kubectl get pods -n kubernetes-dashboard

################################################################################
# Create Dashboard Admin User
################################################################################

cat <<EOF >/tmp/dashboard-admin.yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-admin
  namespace: kubernetes-dashboard

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-admin

roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin

subjects:

- kind: ServiceAccount
  name: dashboard-admin
  namespace: kubernetes-dashboard

EOF

kubectl apply -f /tmp/dashboard-admin.yaml

################################################################################
# Wait
################################################################################

sleep 15
################################################################################
# Generate Login Token
################################################################################

echo
echo "Generating Dashboard Login Token..."

TOKEN=$(kubectl -n kubernetes-dashboard create token dashboard-admin)

echo
echo "=========================================================="
echo "Dashboard Token"
echo "=========================================================="

echo "${TOKEN}"

echo "=========================================================="

################################################################################
# Change Service to NodePort (Lab Environment)
################################################################################

echo
echo "Changing Dashboard Service to NodePort..."

kubectl patch svc kubernetes-dashboard \
-n kubernetes-dashboard \
-p '{"spec":{"type":"NodePort"}}'

################################################################################
# Wait
################################################################################

sleep 10

################################################################################
# Get NodePort
################################################################################

NODEPORT=$(kubectl get svc kubernetes-dashboard \
-n kubernetes-dashboard \
-o jsonpath='{.spec.ports[0].nodePort}')

################################################################################
# Display URL
################################################################################

MASTER_IP=$(hostname -I | awk '{print $1}')

echo
echo "Dashboard URL"

echo

echo "https://${MASTER_IP}:${NODEPORT}"

################################################################################
# Verify Deployment
################################################################################

echo

kubectl get deployment \
-n kubernetes-dashboard

################################################################################
# Verify Pods
################################################################################

echo

kubectl get pods \
-n kubernetes-dashboard \
-o wide

################################################################################
# Verify Service
################################################################################

echo

kubectl get svc \
-n kubernetes-dashboard

################################################################################
# Verify Namespace
################################################################################

echo

kubectl get ns kubernetes-dashboard

################################################################################
# Save Dashboard Information
################################################################################

cat >/root/dashboard-info.txt <<EOF

=====================================================
Kubernetes Dashboard Installation
=====================================================

Installation Date

$(date)

Dashboard URL

https://${MASTER_IP}:${NODEPORT}

Dashboard Token

${TOKEN}

Dashboard Pods

$(kubectl get pods -n kubernetes-dashboard)

Dashboard Service

$(kubectl get svc -n kubernetes-dashboard)

=====================================================

EOF

################################################################################
# Success Banner
################################################################################

echo
echo -e "${GREEN}"
echo "====================================================="
echo " Kubernetes Dashboard Installed Successfully"
echo "====================================================="
echo

echo "Dashboard URL"

echo "https://${MASTER_IP}:${NODEPORT}"

echo

echo "Login Token"

echo

echo "${TOKEN}"

echo

echo "Information File"

echo "/root/dashboard-info.txt"

echo

echo "====================================================="
echo -e "${NC}"
