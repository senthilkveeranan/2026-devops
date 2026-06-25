#!/bin/bash
################################################################################
# Script Name : 05-worker-join.sh
# Description : Join Worker Node to Kubernetes Cluster
# OS          : Rocky Linux 9.8
# Kubernetes  : v1.29.15
# Runtime     : Containerd 1.7.x
################################################################################

set -euo pipefail

################################################################################
# Variables
################################################################################

MASTER_IP="192.168.56.101"
MASTER_PORT="6443"

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
# Worker Node Check
################################################################################

HOST=$(hostname)

if [[ "$HOST" == "kmaster" ]]; then
    echo
    echo "This script should NOT run on Master."
    exit 1
fi

################################################################################
# Verify containerd
################################################################################

echo
echo -e "${BLUE}"
echo "==============================================="
echo "Checking Container Runtime"
echo "==============================================="
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
# Verify Network Connectivity
################################################################################

echo

echo "Checking API Server Connectivity..."

ping -c 3 ${MASTER_IP}

################################################################################
# Verify API Port
################################################################################

echo

nc -zv ${MASTER_IP} ${MASTER_PORT}

################################################################################
# Join Command File
################################################################################

JOIN_FILE="./scripts/join-command.sh"

if [ ! -f "${JOIN_FILE}" ]; then

echo

echo -e "${RED}"

echo "join-command.sh not found."

echo

echo "Copy join-command.sh from Master."

echo -e "${NC}"

exit 1

fi

################################################################################
# Display Join Command
################################################################################

echo

echo "Worker Join Command"

cat ${JOIN_FILE}

################################################################################
# Existing Cluster Check
################################################################################

if [ -f /etc/kubernetes/kubelet.conf ]; then

echo

echo "Worker already joined."

read -p "Reset Worker and Join Again? (yes/no): " OPTION

if [[ "$OPTION" == "yes" ]]; then

kubeadm reset -f

rm -rf /etc/cni/net.d
rm -rf /var/lib/cni
rm -rf /etc/kubernetes

systemctl restart containerd

systemctl restart kubelet

sleep 10

else

exit 0

fi

fi
################################################################################
# Join Worker Node
################################################################################

echo
echo -e "${BLUE}"
echo "=================================================="
echo "Joining Worker Node to Kubernetes Cluster"
echo "=================================================="
echo -e "${NC}"

bash ${JOIN_FILE}

################################################################################
# Verify Join Status
################################################################################

if [ $? -ne 0 ]; then

echo

echo -e "${RED}"

echo "Worker Join Failed."

echo "Check kubelet logs."

echo -e "${NC}"

journalctl -u kubelet -n 50 --no-pager

exit 1

fi

################################################################################
# Restart kubelet
################################################################################

systemctl daemon-reload

systemctl restart kubelet

################################################################################
# Wait for kubelet
################################################################################

echo
echo "Waiting for kubelet..."

sleep 20

################################################################################
# Verify kubelet Service
################################################################################

systemctl is-active --quiet kubelet

if [ $? -ne 0 ]; then

echo

echo "kubelet Service Failed"

journalctl -u kubelet -n 100 --no-pager

exit 1

fi

################################################################################
# Verify CRI Runtime
################################################################################

echo
echo "Container Runtime"

crictl info | grep runtimeName

################################################################################
# Verify Container Runtime Socket
################################################################################

echo

ls -l /run/containerd/containerd.sock

################################################################################
# Wait for Node Registration
################################################################################

echo
echo "Waiting for Worker Registration..."

COUNT=0

while true
do

COUNT=$((COUNT+1))

STATUS=$(journalctl -u kubelet --no-pager -n 20 | \
grep "Successfully registered node" | wc -l)

if [ "$STATUS" -ge 1 ]; then
    break
fi

echo "Attempt : ${COUNT}"

sleep 10

if [ "$COUNT" -ge 30 ]; then

echo

echo "Node Registration Timeout"

journalctl -u kubelet -n 100 --no-pager

exit 1

fi

done

################################################################################
# Display kubelet Status
################################################################################

echo

systemctl status kubelet --no-pager

################################################################################
# Save Worker Information
################################################################################

cat >/root/worker-info.txt <<EOF

=========================================
 Kubernetes Worker Information
=========================================

Hostname

$(hostname)

IP Address

$(hostname -I)

Container Runtime

$(crictl info | grep runtimeName)

Kubelet

$(systemctl is-active kubelet)

Date

$(date)

=========================================

EOF

################################################################################
# Success Banner
################################################################################

echo
echo -e "${GREEN}"
echo "======================================================"
echo " Worker Node Successfully Joined Kubernetes Cluster"
echo "======================================================"
echo
echo "Verify from Master Node:"
echo
echo "kubectl get nodes"
echo
echo "kubectl get pods -A"
echo
echo "======================================================"
echo -e "${NC}"
