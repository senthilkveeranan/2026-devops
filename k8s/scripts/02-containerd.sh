#!/bin/bash
################################################################################
# Script Name : 02-containerd.sh
# Purpose     : Install and Configure Containerd Runtime
# OS          : Rocky Linux 9.8
# Kubernetes  : v1.29.15
# Containerd  : 1.7.x
################################################################################

set -e

GREEN="\033[1;32m"
BLUE="\033[1;34m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${GREEN}"
echo "======================================================="
echo " Installing Container Runtime (containerd)"
echo "======================================================="
echo -e "${NC}"

################################################################################
# Root Check
################################################################################

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script as root.${NC}"
    exit 1
fi

################################################################################
# Install Docker CE Repository
################################################################################

echo -e "${BLUE}Adding Docker CE Repository...${NC}"

dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

################################################################################
# Install Containerd
################################################################################

echo -e "${BLUE}Installing Containerd...${NC}"

dnf install -y containerd.io

################################################################################
# Create Configuration Directory
################################################################################

mkdir -p /etc/containerd

################################################################################
# Generate Default Configuration
################################################################################

containerd config default > /etc/containerd/config.toml

################################################################################
# Configure Systemd Cgroup
################################################################################

echo -e "${BLUE}Configuring Systemd Cgroup...${NC}"

sed -i \
's/SystemdCgroup = false/SystemdCgroup = true/' \
/etc/containerd/config.toml

################################################################################
# Configure Pause Image
################################################################################

sed -i \
's#sandbox_image = .*#sandbox_image = "registry.k8s.io/pause:3.9"#' \
/etc/containerd/config.toml

################################################################################
# Enable CRI Plugin
################################################################################

sed -i \
's/disabled_plugins = \["cri"\]/disabled_plugins = \[\]/' \
/etc/containerd/config.toml || true

################################################################################
# Restart Containerd
################################################################################

systemctl daemon-reload

systemctl enable containerd

systemctl restart containerd

################################################################################
# Wait
################################################################################

sleep 5

################################################################################
# Configure crictl
################################################################################

cat <<EOF >/etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

################################################################################
# Verify Containerd
################################################################################

echo
echo "Containerd Version"
containerd --version

echo
echo "Containerd Status"
systemctl status containerd --no-pager

echo
echo "CRI Runtime"

crictl info

################################################################################
# Verify Socket
################################################################################

echo

ls -l /run/containerd/containerd.sock

################################################################################
# Test Runtime
################################################################################

echo

crictl version

################################################################################

echo -e "${GREEN}"
echo "======================================================="
echo " Containerd Installation Completed Successfully"
echo "======================================================="
echo -e "${NC}"
