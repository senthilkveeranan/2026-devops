#!/bin/bash
################################################################################
# Script Name : 14-longhorn-storage.sh
# Description : Install Longhorn Distributed Storage
# Kubernetes  : v1.29.15
# Longhorn    : v1.9.x
# Helm        : v3.x
# OS          : Rocky Linux 9.8
################################################################################

set -euo pipefail

################################################################################
# Variables
################################################################################

LONGHORN_VERSION="1.9.0"
LONGHORN_NAMESPACE="longhorn-system"

################################################################################
# Colors
################################################################################

GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NC="\033[0m"

################################################################################
# Kubernetes Config
################################################################################

export KUBECONFIG=/etc/kubernetes/admin.conf

################################################################################
# Root Check
################################################################################

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}"
    echo "Run this script as root."
    echo -e "${NC}"
    exit 1
fi

################################################################################
# Banner
################################################################################

clear

echo -e "${GREEN}"
echo "============================================================="
echo "        Longhorn Distributed Storage Installation"
echo "============================================================="
echo -e "${NC}"

################################################################################
# Verify Kubernetes Cluster
################################################################################

kubectl cluster-info >/dev/null

kubectl get nodes

################################################################################
# Verify Helm
################################################################################

if ! command -v helm >/dev/null 2>&1
then
    echo
    echo "Helm is not installed."
    exit 1
fi

################################################################################
# Verify iSCSI
################################################################################

echo
echo -e "${BLUE}"
echo "Installing Required Packages"
echo -e "${NC}"

dnf install -y \
iscsi-initiator-utils \
nfs-utils

################################################################################
# Enable Services
################################################################################

systemctl enable iscsid

systemctl restart iscsid

################################################################################
# Verify Service
################################################################################

systemctl status iscsid --no-pager

################################################################################
# Verify Open-iSCSI
################################################################################

iscsiadm --version

################################################################################
# Create Namespace
################################################################################

kubectl create namespace ${LONGHORN_NAMESPACE} \
--dry-run=client -o yaml | kubectl apply -f -

################################################################################
# Add Repository
################################################################################

helm repo add longhorn https://charts.longhorn.io

helm repo update

################################################################################
# Verify Repository
################################################################################

helm repo list

################################################################################
# Download Default Values
################################################################################

helm show values longhorn/longhorn \
> /root/longhorn-values.yaml

################################################################################
# Install Longhorn
################################################################################

echo
echo -e "${GREEN}"
echo "Installing Longhorn..."
echo -e "${NC}"

helm install longhorn \
longhorn/longhorn \
--namespace ${LONGHORN_NAMESPACE} \
--version ${LONGHORN_VERSION} \
-f /root/longhorn-values.yaml
################################################################################
# Wait for Longhorn Pods
################################################################################

echo
echo -e "${BLUE}"
echo "============================================================="
echo "Waiting for Longhorn Pods"
echo "============================================================="
echo -e "${NC}"

COUNT=0

while true
do

COUNT=$((COUNT+1))

READY=$(kubectl get pods -n ${LONGHORN_NAMESPACE} \
--no-headers | grep Running | wc -l)

TOTAL=$(kubectl get pods -n ${LONGHORN_NAMESPACE} \
--no-headers | wc -l)

echo

echo "Running Pods : ${READY}/${TOTAL}"

if [[ "$READY" -eq "$TOTAL" ]] && [[ "$TOTAL" -gt 0 ]]
then
    break
fi

sleep 15

if [[ "$COUNT" -ge 40 ]]
then

echo

echo "Longhorn Installation Timeout"

kubectl get pods -n ${LONGHORN_NAMESPACE}

exit 1

fi

done

################################################################################
# Verify Namespace
################################################################################

echo

kubectl get ns ${LONGHORN_NAMESPACE}

################################################################################
# Verify Pods
################################################################################

echo

kubectl get pods \
-n ${LONGHORN_NAMESPACE} \
-o wide

################################################################################
# Verify Deployments
################################################################################

echo

kubectl get deployment \
-n ${LONGHORN_NAMESPACE}

################################################################################
# Verify DaemonSets
################################################################################

echo

kubectl get daemonset \
-n ${LONGHORN_NAMESPACE}

################################################################################
# Verify CSI Driver
################################################################################

echo

kubectl get csidriver

################################################################################
# Verify Storage Classes
################################################################################

echo

kubectl get storageclass

################################################################################
# Check Default StorageClass
################################################################################

DEFAULT_SC=$(kubectl get storageclass \
-o jsonpath='{range .items[*]}{.metadata.name}{" "}{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}{"\n"}{end}' \
| grep true | awk '{print $1}')

echo

echo "Current Default StorageClass : ${DEFAULT_SC}"

################################################################################
# Set Longhorn as Default StorageClass
################################################################################

kubectl patch storageclass longhorn \
-p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

################################################################################
# Remove Default from Other StorageClasses
################################################################################

for sc in $(kubectl get storageclass -o name | cut -d/ -f2)
do

if [[ "$sc" != "longhorn" ]]
then

kubectl patch storageclass ${sc} \
-p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' \
|| true

fi

done

################################################################################
# Verify StorageClass
################################################################################

echo

kubectl get storageclass
################################################################################
# Create Test PVC
################################################################################

echo
echo -e "${BLUE}"
echo "============================================================="
echo "Creating Persistent Volume Claim"
echo "============================================================="
echo -e "${NC}"

cat <<EOF >/tmp/longhorn-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: longhorn-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 5Gi
EOF

kubectl apply -f /tmp/longhorn-pvc.yaml

################################################################################
# Wait PVC
################################################################################

kubectl wait \
--for=jsonpath='{.status.phase}'=Bound \
pvc/longhorn-pvc \
--timeout=180s

################################################################################
# Verify PVC
################################################################################

kubectl get pvc

################################################################################
# Verify PV
################################################################################

kubectl get pv

################################################################################
# Create Test Deployment
################################################################################

cat <<EOF >/tmp/nginx-longhorn.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-longhorn
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-longhorn
  template:
    metadata:
      labels:
        app: nginx-longhorn
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - mountPath: /usr/share/nginx/html
          name: webdata
      volumes:
      - name: webdata
        persistentVolumeClaim:
          claimName: longhorn-pvc
EOF

kubectl apply -f /tmp/nginx-longhorn.yaml

################################################################################
# Wait Deployment
################################################################################

kubectl rollout status deployment/nginx-longhorn \
--timeout=180s

################################################################################
# Verify Deployment
################################################################################

kubectl get deployment nginx-longhorn

kubectl get pods -o wide

################################################################################
# Verify Mounted Volume
################################################################################

POD=$(kubectl get pod \
-l app=nginx-longhorn \
-o jsonpath='{.items[0].metadata.name}')

kubectl exec ${POD} -- df -h

################################################################################
# Create Sample Data
################################################################################

kubectl exec ${POD} -- \
sh -c 'echo "Longhorn Storage Working" > /usr/share/nginx/html/index.html'

################################################################################
# Verify Data
################################################################################

kubectl exec ${POD} -- \
cat /usr/share/nginx/html/index.html

################################################################################
# Verify Longhorn Volumes
################################################################################

kubectl get volumes.longhorn.io \
-n ${LONGHORN_NAMESPACE}

################################################################################
# Display Longhorn UI Service
################################################################################

kubectl get svc \
-n ${LONGHORN_NAMESPACE}

################################################################################
# Generate Installation Report
################################################################################

cat >/root/longhorn-installation-report.txt <<EOF

===========================================================
Longhorn Installation Report
===========================================================

Installation Date

$(date)

Storage Classes

$(kubectl get storageclass)

Persistent Volumes

$(kubectl get pv)

Persistent Volume Claims

$(kubectl get pvc)

Longhorn Pods

$(kubectl get pods -n ${LONGHORN_NAMESPACE})

Volumes

$(kubectl get volumes.longhorn.io -n ${LONGHORN_NAMESPACE})

===========================================================

EOF

################################################################################
# Success Banner
################################################################################

echo
echo -e "${GREEN}"
echo "============================================================="
echo " Longhorn Installed Successfully"
echo "============================================================="
echo
echo "StorageClass"
echo
kubectl get storageclass
echo
echo "Persistent Volumes"
echo
kubectl get pv
echo
echo "Persistent Volume Claims"
echo
kubectl get pvc
echo
echo "Longhorn Pods"
echo
kubectl get pods -n ${LONGHORN_NAMESPACE}
echo
echo "Report"
echo "/root/longhorn-installation-report.txt"
echo
echo "============================================================="
echo -e "${NC}"
