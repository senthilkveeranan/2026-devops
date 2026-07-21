#!/usr/bin/env bash
###############################################################################
# Ultimate DevOps Lab
# Module      : 02-docker.sh
# Description : Install Docker CE
# Platform    : Rocky Linux 9.x
###############################################################################

set -Eeuo pipefail

############################################
# Logging
############################################

log() {
    echo "[INFO] $1"
}

error() {
    echo "[ERROR] $1"
    exit 1
}

############################################
# Root Check
############################################

[[ $EUID -eq 0 ]] || error "Run this script as root."

############################################
# PATH
############################################

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

############################################
# DNF Health Check
############################################

command -v dnf >/dev/null || error "dnf not found."

log "Checking DNF..."

dnf --version >/dev/null || error "DNF is not working."

############################################
# Clean Cache
############################################

dnf clean all
rm -rf /var/cache/dnf

############################################
# Remove Old Docker
############################################

log "Removing old Docker packages..."

dnf remove -y \
docker \
docker-client \
docker-client-latest \
docker-common \
docker-latest \
docker-latest-logrotate \
docker-logrotate \
docker-engine || true

############################################
# Install Plugin
############################################

log "Installing dnf-plugins-core..."

if ! rpm -q dnf-plugins-core >/dev/null 2>&1; then
    dnf install -y dnf-plugins-core
else
    log "dnf-plugins-core already installed."
fi

############################################
# Docker Repository
############################################

if [[ ! -f /etc/yum.repos.d/docker-ce.repo ]]; then

    log "Adding Docker Repository..."

    dnf config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo

fi

############################################
# Install Docker
############################################

log "Installing Docker..."

dnf install -y \
docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin

############################################
# Enable Docker
############################################

systemctl enable --now docker

############################################
# Add User
############################################

id vagrant &>/dev/null && usermod -aG docker vagrant || true

############################################
# Verify
############################################

docker --version

docker compose version

systemctl is-active docker

docker run --rm hello-world

############################################
# Completed
############################################

echo
echo "========================================="
echo " Docker Installation Completed"
echo "========================================="