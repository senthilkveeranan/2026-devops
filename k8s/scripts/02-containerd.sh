#!/bin/bash
################################################################################
# Script Name : 02-containerd.sh
# Purpose     : Install and Configure Containerd Runtime
# OS          : Rocky Linux 9.8
# Kubernetes  : v1.29.15
# Runtime     : containerd 1.7.x
################################################################################

set -euo pipefail

################################################################################
# Colors
################################################################################

GREEN="\033[1;32m"
BLUE="\033[1;34m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

################################################################################
# Banner
################################################################################

clear

echo -e "${GREEN}"
echo "======================================================="
echo "      Installing Containerd Runtime"
echo "======================================================="
echo -e "${NC}"

################################################################################
# Root Check
################################################################################

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

################################################################################
# Install Required Packages
################################################################################

echo -e "${BLUE}Installing prerequisite packages...${NC}"

dnf install -y \
yum-utils \
device-mapper-persistent-data \
lvm2 \
curl \
wget \
tar

################################################################################
# Add Docker Repository
################################################################################

echo -e "${BLUE}Adding Docker Repository...${NC}"

dnf config-manager \
--add-repo \
https://download.docker.com/linux/centos/docker-ce.repo

################################################################################
# Install Containerd
################################################################################

echo -e "${BLUE}Installing containerd...${NC}"

dnf install -y containerd.io

################################################################################
# Create Config Directory
################################################################################

mkdir -p /etc/containerd

################################################################################
# Generate Default Config
################################################################################

containerd config default >/etc/containerd/config.toml

################################################################################
# Configure Systemd Cgroup
################################################################################

echo -e "${BLUE}Configuring SystemdCgroup...${NC}"

sed -i \
's/SystemdCgroup = false/SystemdCgroup = true/' \
/etc/containerd/config.toml

################################################################################
# Configure Pause Image
################################################################################

echo -e "${BLUE}Configuring Pause Image...${NC}"

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

echo -e "${BLUE}Starting Containerd...${NC}"

systemctl daemon-reload
systemctl enable containerd
systemctl restart containerd

sleep 5

################################################################################
# Verify Containerd
################################################################################

systemctl is-active --quiet containerd

if [ $? -ne 0 ]; then
    echo -e "${RED}Containerd service failed.${NC}"
    exit 1
fi

################################################################################
# Install crictl
################################################################################

echo -e "${BLUE}Installing crictl...${NC}"

CRICTL_VERSION="v1.29.0"

curl -L --fail \
-o /tmp/crictl.tar.gz \
https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz

tar -C /usr/local/bin -xzf /tmp/crictl.tar.gz

chmod +x /usr/local/bin/crictl

rm -f /tmp/crictl.tar.gz

################################################################################
# Configure crictl
################################################################################

cat >/etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
