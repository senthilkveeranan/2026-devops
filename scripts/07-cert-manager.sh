#!/bin/bash
#===========================================================
# Script Name : 07-cert-manager.sh
# Description : Install Cert-Manager on k3s Kubernetes
# Author      : DevOps Lab
#===========================================================

set -euo pipefail

LOG_FILE="/var/log/devopslab-cert-manager.log"

log() {
    echo "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

[[ $EUID -eq 0 ]] || error_exit "Run this script as root."

export PATH=$PATH:/usr/local/bin

NAMESPACE="cert-manager"
RELEASE="cert-manager"
CHART="jetstack/cert-manager"

log "=============================================="
log "Starting Cert-Manager Installation"
log "=============================================="

#----------------------------------------------------------
# Prerequisite Checks
#----------------------------------------------------------
command -v kubectl >/dev/null 2>&1 || error_exit "kubectl not found"
command -v helm >/dev/null 2>&1 || error_exit "helm not found"

kubectl get nodes >/dev/null 2>&1 || error_exit "Kubernetes cluster is not accessible"

#----------------------------------------------------------
# Add Helm Repository
#----------------------------------------------------------
log "Adding Jetstack Helm Repository..."

helm repo add jetstack https://charts.jetstack.io >/dev/null 2>&1 || true
helm repo update

#----------------------------------------------------------
# Create Namespace
#----------------------------------------------------------
if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    log "Namespace already exists."
else
    kubectl create namespace "$NAMESPACE"
fi

#----------------------------------------------------------
# Install Cert-Manager
#----------------------------------------------------------
if helm status "$RELEASE" -n "$NAMESPACE" >/dev/null 2>&1; then
    log "Cert-Manager already installed."
else
    log "Installing Cert-Manager..."

    helm install "$RELEASE" "$CHART" \
        --namespace "$NAMESPACE" \
        --set installCRDs=true \
        --wait \
        --timeout 10m
fi

#----------------------------------------------------------
# Wait for Deployments
#----------------------------------------------------------
log "Waiting for Deployments..."

kubectl rollout status deployment/cert-manager \
    -n "$NAMESPACE" --timeout=300s

kubectl rollout status deployment/cert-manager-webhook \
    -n "$NAMESPACE" --timeout=300s

kubectl rollout status deployment/cert-manager-cainjector \
    -n "$NAMESPACE" --timeout=300s

#----------------------------------------------------------
# Verify Installation
#----------------------------------------------------------
log "Verifying Installation..."

kubectl get pods -n "$NAMESPACE"

kubectl get deployments -n "$NAMESPACE"

kubectl get crds | grep cert-manager

#----------------------------------------------------------
# Create SelfSigned ClusterIssuer
#----------------------------------------------------------
log "Creating SelfSigned ClusterIssuer..."

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-clusterissuer
spec:
  selfSigned: {}
EOF

sleep 5

kubectl get clusterissuer

#----------------------------------------------------------
# Summary
#----------------------------------------------------------
echo
echo "=============================================="
echo " Cert-Manager Installation Completed"
echo "=============================================="

kubectl get pods -n cert-manager

echo
kubectl get clusterissuer

echo
echo "Log File : $LOG_FILE"
echo "=============================================="
