#!/bin/bash

set -e

MASTER_IP="192.168.56.101"
POD_CIDR="192.168.0.0/16"

echo "Initializing Kubernetes Control Plane..."
echo "Master IP : ${MASTER_IP}"
echo "Pod CIDR  : ${POD_CIDR}"

kubeadm init \
  --apiserver-advertise-address=${MASTER_IP} \
  --control-plane-endpoint=${MASTER_IP}:6443 \
  --pod-network-cidr=${POD_CIDR}

mkdir -p $HOME/.kube

cp /etc/kubernetes/admin.conf $HOME/.kube/config

chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf

echo "Installing Calico..."

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml

echo ""
echo "==========================================="
echo " Kubernetes Cluster Initialized Successfully"
echo "==========================================="
echo ""

echo "Worker Join Command:"
echo ""

kubeadm token create --print-join-command
