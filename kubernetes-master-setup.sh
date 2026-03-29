#!/bin/bash

set -e

echo "========== Disable SELinux =========="
setenforce 0 || true
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

echo "========== Disable Swap =========="
swapoff -a
sed -i '/swap/d' /etc/fstab

echo "========== Kernel Modules =========="
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

echo "========== Sysctl =========="
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sysctl --system

echo "========== Install containerd =========="
dnf install -y yum-utils
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y containerd.io

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl daemon-reexec
systemctl enable --now containerd

echo "========== Kubernetes Repo =========="
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF

echo "========== Install Kubernetes =========="
dnf install -y kubelet kubeadm kubectl
systemctl enable --now kubelet

echo "========== Firewall =========="
firewall-cmd --permanent --add-port=6443/tcp || true
firewall-cmd --permanent --add-port=30000-32767/tcp || true
firewall-cmd --permanent --add-port=10250/tcp || true
firewall-cmd --reload || true

echo "========== Initialize Cluster =========="
#kubeadm init --pod-network-cidr=192.168.0.0/16
kubeadm init --apiserver-advertise-address=192.168.56.14 --pod-network-cidr=10.244.0.0/16

echo "========== Configure kubectl =========="
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

echo "========== Install Calico =========="
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

echo "Waiting for nodes..."
sleep 30

kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

echo "========== Install Dashboard =========="
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

echo "Waiting for dashboard pods..."
sleep 20

echo "========== Create Admin User (FIXED YAML) =========="

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
name: admin-user
namespace: kubernetes-dashboard
-------------------------------

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
name: admin-user-binding
roleRef:
apiGroup: rbac.authorization.k8s.io
kind: ClusterRole
name: cluster-admin
subjects:

* kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
  EOF

echo "========== Expose Dashboard =========="
kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard
-p '{"spec": {"type": "NodePort"}}'

echo "========== Get Access Details =========="

kubectl -n kubernetes-dashboard get svc kubernetes-dashboard

echo "---------- TOKEN ----------"
kubectl -n kubernetes-dashboard create token admin-user

echo "---------- ACCESS ----------"
echo "https://<YOUR-IP>:<NODEPORT>"

echo "========== DONE =========="

