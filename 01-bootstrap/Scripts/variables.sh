#!/bin/bash
#===============================================================================
# Ultimate DevOps Lab
# File    : variables.sh
# Purpose : Global Variables
# OS      : Rocky Linux 9.x
# Author  : Senthil Kumar
#===============================================================================

#------------------------------------------
# Lab Information
#------------------------------------------
export LAB_NAME="Ultimate DevOps Lab"
export LAB_VERSION="1.0"
export LAB_DOMAIN="lab.local"

#------------------------------------------
# Timezone
#------------------------------------------
export TIMEZONE="Asia/Kolkata"

#------------------------------------------
# Default User
#------------------------------------------
export DEVOPS_USER="devops"
export DEVOPS_GROUP="devops"

#------------------------------------------
# SSH
#------------------------------------------
export SSH_PORT="22"

#------------------------------------------
# Network
#------------------------------------------
export NETWORK_PREFIX="192.168.56"

#------------------------------------------
# Hostnames
#------------------------------------------
export ANSIBLE_HOST="ansible"
export DOCKER_HOST="docker"
export WEB1_HOST="web1"
export WEB2_HOST="web2"
export UTILITY_HOST="utility"

#------------------------------------------
# IP Addresses
#------------------------------------------
export ANSIBLE_IP="${NETWORK_PREFIX}.10"
export DOCKER_IP="${NETWORK_PREFIX}.20"
export WEB1_IP="${NETWORK_PREFIX}.30"
export WEB2_IP="${NETWORK_PREFIX}.40"
export UTILITY_IP="${NETWORK_PREFIX}.50"

#------------------------------------------
# Common Packages
#------------------------------------------
COMMON_PACKAGES=(
git
curl
wget
vim
nano
tree
jq
tar
zip
unzip
rsync
bind-utils
net-tools
bash-completion
python3
python3-pip
openssh-clients
chrony
firewalld
policycoreutils-python-utils
)

#------------------------------------------
# Services
#------------------------------------------
SERVICES=(
sshd
chronyd
firewalld
)

#------------------------------------------
# Directories
#------------------------------------------
export LOG_DIR="/var/log/devops-lab"
export SCRIPT_DIR="/opt/devops-lab"
export BACKUP_DIR="/backup"

#------------------------------------------
# Inventory
#------------------------------------------
export INVENTORY_FILE="/vagrant/inventory/inventory.ini"

#------------------------------------------
# Colors
#------------------------------------------
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
WHITE="\033[1;37m"
NC="\033[0m"

#------------------------------------------
# Log File
#------------------------------------------
export LOG_FILE="${LOG_DIR}/bootstrap.log"

#------------------------------------------
# Kubernetes
#------------------------------------------
export KUBERNETES_VERSION="v1.33"
export HELM_VERSION="v3"

#------------------------------------------
# Docker
#------------------------------------------
export DOCKER_VERSION="latest"

#------------------------------------------
# Script Information
#------------------------------------------
SCRIPT_NAME=$(basename "$0")
DATE=$(date '+%F')
TIME=$(date '+%T')
