#!/bin/bash
#
# 05-ingress-nginx.sh
# Install Ingress NGINX Controller
#

set -euo pipefail

LOGFILE="/var/log/devops/ingress-nginx.log"
mkdir -p /var/log/devops

exec > >(tee -a "$LOGFILE") 2>&1

echo "========================================="
echo " Installing Ingress NGINX"
echo "========================================="

export PATH="/usr/local/bin:$PATH"
hash -r

# Verify prerequisites
command -v kubectl >/dev/null || {
    echo "[ERROR] kubectl not found."
    exit 1
}

command -v helm >/dev/null || {
    echo "[ERROR] helm not found."
    exit 1
}

# Verify cluster
kubectl cluster-info >/dev/null

# Namespace
kubectl create namespace ingress-nginx \
    --dry-run=client -o yaml | kubectl apply -f -

# Repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo update

# Install / Upgrade
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --set controller.publishService.enabled=true \
    --wait \
    --timeout 10m

echo
echo "Waiting for Controller..."

kubectl rollout status deployment ingress-nginx-controller \
    -n ingress-nginx \
    --timeout=300s

echo
echo "========================================="
echo " Pods"
echo "========================================="

kubectl get pods -n ingress-nginx -o wide

echo
echo "========================================="
echo " Services"
echo "========================================="

kubectl get svc -n ingress-nginx

echo
echo "========================================="
echo " Deployments"
echo "========================================="

kubectl get deploy -n ingress-nginx

echo
echo "========================================="
echo " Installation Completed Successfully"
echo "========================================="
