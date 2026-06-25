#!/bin/bash
################################################################################
# Script Name : 04-master-init.sh
# Description : Initialize Kubernetes Control Plane
# OS          : Rocky Linux 9.8
# Kubernetes  : v1.29.15
# Runtime     : containerd 1.7.x
################################################################################

set -euo pipefail

################################################################################
# Variables
################################################################################

POD_CIDR="192.168.0.0/16"
API_SERVER="192.168.56.101"
K8S_VERSION="v1.29.15"

GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NC="\033[0m"

################################################################################
# Root Check
################################################################################

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Please run this script as root${NC}"
    exit 1
fi

################################################################################
# Verify Containerd
################################################################################

echo -e "${BLUE}"
echo "=================================================="
echo "Checking Container Runtime..."
echo "=================================================="
echo -e "${NC}"

systemctl is-active --quiet containerd || {
    echo "Containerd is not running."
    exit 1
}

################################################################################
# Verify kubelet
################################################################################

systemctl enable kubelet

systemctl restart kubelet

################################################################################
# Swap Check
################################################################################

if swapon --show | grep -q swap; then
    echo "Swap is enabled."
    echo "Disable swap before continuing."
    exit 1
fi

################################################################################
# kubeadm reset if previous cluster exists (optional)
################################################################################

if [ -f /etc/kubernetes/admin.conf ]; then

echo
echo "Existing Cluster Detected"

read -p "Reset Existing Cluster? (yes/no): " OPTION

if [[ "$OPTION" == "yes" ]]; then

kubeadm reset -f

rm -rf /etc/cni/net.d
rm -rf /var/lib/cni
rm -rf /var/lib/etcd
rm -rf /etc/kubernetes
rm -rf $HOME/.kube

systemctl restart containerd
systemctl restart kubelet

sleep 15

fi

fi

################################################################################
# Pull Images
################################################################################

echo

echo -e "${BLUE}Pulling Kubernetes Images...${NC}"

kubeadm config images pull

################################################################################
# Display Images
################################################################################

echo

crictl images

################################################################################
# Initialize Cluster
################################################################################

echo
echo -e "${GREEN}"
echo "=================================================="
echo "Initializing Kubernetes Cluster"
echo "=================================================="
echo -e "${NC}"

kubeadm init \
--apiserver-advertise-address=${API_SERVER} \
--pod-network-cidr=${POD_CIDR} \
--kubernetes-version=${K8S_VERSION} \
--upload-certs | tee /root/kubeadm-init.log
################################################################################
# Verify kubeadm init
################################################################################

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo -e "${RED}"
    echo "kubeadm init Failed."
    echo "Check /root/kubeadm-init.log"
    echo -e "${NC}"
    exit 1
fi

################################################################################
# Configure kubectl
################################################################################

echo
echo -e "${BLUE}"
echo "=================================================="
echo "Configuring kubectl"
echo "=================================================="
echo -e "${NC}"

mkdir -p $HOME/.kube

cp -f /etc/kubernetes/admin.conf $HOME/.kube/config

chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=$HOME/.kube/config

################################################################################
# Bash Completion
################################################################################

echo "source <(kubectl completion bash)" >> ~/.bashrc

echo "alias k=kubectl" >> ~/.bashrc

echo "complete -o default -F __start_kubectl k" >> ~/.bashrc

source ~/.bashrc

################################################################################
# Generate Worker Join Command
################################################################################

echo
echo -e "${BLUE}"
echo "=================================================="
echo "Generating Worker Join Command"
echo "=================================================="
echo -e "${NC}"

kubeadm token create --print-join-command > /root/join-command.sh

chmod +x /root/join-command.sh

cp /root/join-command.sh ./scripts/join-command.sh 2>/dev/null || true

################################################################################
# Display Join Command
################################################################################

echo
echo "Worker Join Command"

cat /root/join-command.sh

################################################################################
# Wait for API Server
################################################################################

echo
echo -e "${BLUE}"
echo "Waiting for API Server..."
echo -e "${NC}"

COUNT=0

until kubectl get nodes >/dev/null 2>&1
do

COUNT=$((COUNT+1))

echo "Waiting... ${COUNT}"

sleep 5

if [ $COUNT -ge 60 ]; then

echo

echo "API Server did not become Ready."

exit 1

fi

done

################################################################################
# API Server Verification
################################################################################

echo

kubectl cluster-info

echo

kubectl version

################################################################################
# Verify Control Plane Pods
################################################################################

echo

kubectl get pods -n kube-system

################################################################################
# Verify Node
################################################################################

echo

kubectl get nodes -o wide

################################################################################
# Save Admin Config Backup
################################################################################

mkdir -p /root/kubeconfig-backup

cp /etc/kubernetes/admin.conf \
/root/kubeconfig-backup/admin.conf

################################################################################
# Save kubeadm Config
################################################################################

kubectl -n kube-system get cm kubeadm-config -o yaml \
> /root/kubeconfig-backup/kubeadm-config.yaml || true

################################################################################
# Wait for Control Plane Pods
################################################################################

echo
echo -e "${BLUE}"
echo "=================================================="
echo "Waiting for Control Plane Pods"
echo "=================================================="
echo -e "${NC}"

RETRY=0

while true
do

READY=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | \
grep -E "etcd|kube-apiserver|kube-controller-manager|kube-scheduler" | \
grep Running | wc -l)

if [ "$READY" -eq 4 ]; then
    break
fi

RETRY=$((RETRY+1))

echo "Waiting for Control Plane Pods... Attempt ${RETRY}"

sleep 10

if [ "$RETRY" -ge 30 ]; then
    echo
    echo -e "${RED}Control Plane Pods are not Ready.${NC}"
    kubectl get pods -n kube-system
    exit 1
fi

done

################################################################################
# Verify Control Plane
################################################################################

echo
echo -e "${GREEN}"
echo "Control Plane Components"
echo -e "${NC}"

kubectl get pods -n kube-system -o wide

################################################################################
# Verify Nodes
################################################################################

echo
echo -e "${GREEN}"
echo "Node Status"
echo -e "${NC}"

kubectl get nodes -o wide

################################################################################
# Verify Component Status
################################################################################

echo
echo -e "${GREEN}"
echo "Cluster Information"
echo -e "${NC}"

kubectl cluster-info

################################################################################
# Verify kube-system Pods
################################################################################

echo
kubectl get pods -n kube-system

################################################################################
# Verify Images
################################################################################

echo
echo "Container Images"

crictl images

################################################################################
# Verify Container Runtime
################################################################################

echo
echo "Container Runtime"

crictl info | grep runtimeName

################################################################################
# Verify kubelet
################################################################################

echo
systemctl status kubelet --no-pager

################################################################################
# Create Cluster Information
################################################################################

cat >/root/cluster-info.txt <<EOF
==================================================
 Kubernetes Cluster Information
==================================================

Hostname:
$(hostname)

IP Address:
$(hostname -I)

Kubernetes Version:
$(kubectl version --short 2>/dev/null)

Cluster Info:
$(kubectl cluster-info 2>/dev/null)

Nodes:
$(kubectl get nodes)

Pods:
$(kubectl get pods -A)

==================================================
EOF

################################################################################
# Success Message
################################################################################

echo
echo -e "${GREEN}"
echo "=========================================================="
echo " Kubernetes Master Installation Completed Successfully"
echo "=========================================================="
echo
echo "Next Steps:"
echo
echo "1. Install Calico"
echo
echo "   ./scripts/06-calico.sh"
echo
echo "2. Join Worker Nodes"
echo
echo "   ./scripts/05-worker-join.sh"
echo
echo "3. Verify Cluster"
echo
echo "   ./scripts/07-verify.sh"
echo
echo "Worker Join Command:"
echo
cat /root/join-command.sh
echo
echo "=========================================================="
echo -e "${NC}"
