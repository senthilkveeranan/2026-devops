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
################################################################################
# Verify Calico DaemonSet
################################################################################

echo
echo -e "${GREEN}"
echo "=============================================="
echo "Calico DaemonSet"
echo "=============================================="
echo -e "${NC}"

kubectl get daemonset -n kube-system

################################################################################
# Verify Calico Deployment
################################################################################

echo

kubectl get deployment -n kube-system

################################################################################
# Wait for CoreDNS
################################################################################

echo
echo "Waiting for CoreDNS..."

COUNT=0

while true
do

COUNT=$((COUNT+1))

READY=$(kubectl get pods -n kube-system \
--no-headers | grep coredns | grep Running | wc -l)

if [ "$READY" -ge 2 ]; then
    break
fi

echo "Attempt : ${COUNT}"

sleep 10

if [ "$COUNT" -ge 30 ]; then

echo

echo "CoreDNS Failed"

kubectl get pods -n kube-system

exit 1

fi

done

################################################################################
# Verify Nodes
################################################################################

echo
echo -e "${GREEN}"
echo "=============================================="
echo "Node Status"
echo "=============================================="
echo -e "${NC}"

kubectl get nodes -o wide

################################################################################
# Verify kube-system Pods
################################################################################

echo

kubectl get pods -n kube-system -o wide

################################################################################
# Verify All Pods
################################################################################

echo

kubectl get pods -A

################################################################################
# Verify Services
################################################################################

echo

kubectl get svc -A

################################################################################
# Verify Cluster Information
################################################################################

echo

kubectl cluster-info

################################################################################
# Verify CNI Configuration
################################################################################

echo

echo "CNI Configuration"

ls -l /etc/cni/net.d/

################################################################################
# Verify Calico Interfaces
################################################################################

echo

ip addr | grep cali || true

################################################################################
# Verify Routes
################################################################################

echo

ip route

################################################################################
# Save Calico Information
################################################################################

cat >/root/calico-info.txt <<EOF

======================================================
 Kubernetes Calico Information
======================================================

Installation Date

$(date)

Nodes

$(kubectl get nodes)

Calico Pods

$(kubectl get pods -n kube-system | grep calico)

CoreDNS

$(kubectl get pods -n kube-system | grep coredns)

Services

$(kubectl get svc -A)

======================================================

EOF

################################################################################
# Success Banner
################################################################################

echo
echo -e "${GREEN}"
echo "======================================================"
echo " Calico Installation Completed Successfully"
echo "======================================================"
echo
echo "Cluster Status"
echo

kubectl get nodes

echo

kubectl get pods -A

echo

echo "Next Step"

echo "./scripts/07-verify.sh"

echo

echo "======================================================"
echo -e "${NC}"
