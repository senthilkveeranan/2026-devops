#!/bin/bash

set -e

kubeadm init \
--pod-network-cidr=192.168.0.0/16 \
--apiserver-advertise-address=$(hostname -I | awk '{print $1}')

mkdir -p $HOME/.kube

cp /etc/kubernetes/admin.conf $HOME/.kube/config

chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf

echo "Install Calico"

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml

echo ""
echo "Cluster initialized."
echo ""
echo "Run below command on workers"
echo ""
kubeadm token create --print-join-command
