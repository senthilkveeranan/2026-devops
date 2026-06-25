#!/bin/bash
################################################################################
# Script Name : 03-kubernetes.sh
# Purpose     : Install Kubernetes Components
# OS          : Rocky Linux 9.8
# Kubernetes  : v1.29.15
# Runtime     : containerd 1.7.x
################################################################################

set -e

GREEN="\033[1;32m"
BLUE="\033[1;34m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${GREEN}"
echo "=========================================================="
echo " Installing Kubernetes v1.29.15"
echo "=========================================================="
echo -e "${NC}"

################################################################################
# Root Check
################################################################################

if [[ $EUID -ne 0 ]]; then
    echo "Run as root."
    exit 1
fi

################################################################################
# Remove Old Repository
################################################################################

rm -f /etc/yum.repos.d/kubernetes.repo

################################################################################
# Kubernetes Repository
################################################################################

cat <<EOF >/etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF

################################################################################
# Refresh Repository
################################################################################

dnf clean all
dnf makecache

################################################################################
# Disable Excludes
################################################################################

dnf config-manager --save --setopt=*.exclude=''

################################################################################
# Install Kubernetes Packages
################################################################################

echo
echo "Installing Kubernetes Packages..."
echo

dnf install -y \
kubelet-1.29.15 \
kubeadm-1.29.15 \
kubectl-1.29.15 \
cri-tools \
kubernetes-cni

################################################################################
# Prevent Automatic Upgrade
################################################################################

dnf versionlock add \
kubelet \
kubeadm \
kubectl

################################################################################
# Enable kubelet
################################################################################

systemctl daemon-reload

systemctl enable kubelet

################################################################################
# Verify Versions
################################################################################

echo
echo "=========================================="

kubeadm version

echo

kubectl version --client

echo

kubelet --version

################################################################################
# Pull Kubernetes Images
################################################################################

echo
echo "Pulling Kubernetes Images..."
echo

kubeadm config images pull

################################################################################
# Verify Images
################################################################################

echo
echo "Container Images"
echo

crictl images

################################################################################
# Verify Runtime
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
# Required Images
################################################################################

echo
echo "Expected Images"

echo
echo "pause:3.9"
echo "etcd:3.5.x"
echo "kube-apiserver:v1.29.15"
echo "kube-controller-manager:v1.29.15"
echo "kube-scheduler:v1.29.15"
echo "coredns"

################################################################################
# Firewall Ports
################################################################################

echo
echo "Opening Kubernetes Firewall Ports"

firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10257/tcp
firewall-cmd --permanent --add-port=10259/tcp
firewall-cmd --reload

################################################################################

echo
echo -e "${GREEN}"
echo "=========================================================="
echo " Kubernetes Installation Completed Successfully"
echo "=========================================================="
echo -e "${NC}"
