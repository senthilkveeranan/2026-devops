#!/bin/bash
###############################################################################
# Script Name : 05-ansible-core.sh
# Description : Install and Configure Ansible Core
# OS          : Rocky Linux 9
# Author      : Senthil DevOps Lab
###############################################################################

set -euo pipefail

LOGFILE="/var/log/05-ansible-core.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "========================================================="
echo " Installing Ansible Core"
echo "========================================================="

# Root Check
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this script as root."
    exit 1
fi

echo "[INFO] Updating DNF Cache..."
dnf makecache -y

echo "[INFO] Installing Required Packages..."
dnf install -y \
    ansible-core \
    python3 \
    python3-pip \
    git \
    sshpass \
    jq \
    curl \
    wget \
    unzip \
    zip \
    tar \
    rsync

echo "[INFO] Installing Python Packages..."
python3 -m pip install --upgrade pip

python3 -m pip install \
    jmespath \
    netaddr \
    passlib \
    pyyaml \
    kubernetes \
    openshift

echo "[INFO] Installing Ansible Galaxy Collections..."

collections=(
    ansible.posix
    community.general
    community.docker
    kubernetes.core
    amazon.aws
    community.crypto
)

for collection in "${collections[@]}"; do
    ansible-galaxy collection install "$collection" --force
done

echo "[INFO] Creating Directory Structure..."

mkdir -p /root/ansible/{inventory,playbooks,roles,collections,files,templates,logs}
mkdir -p /root/ansible/inventory/group_vars
mkdir -p /root/ansible/inventory/host_vars

echo "[INFO] Creating ansible.cfg..."

cat >/root/ansible/ansible.cfg <<EOF
[defaults]
inventory=/root/ansible/inventory/hosts.ini
roles_path=/root/ansible/roles
collections_paths=/root/.ansible/collections
host_key_checking=False
retry_files_enabled=False
forks=20
interpreter_python=auto_silent
stdout_callback=yaml
timeout=30

[privilege_escalation]
become=True
become_method=sudo
become_ask_pass=False
EOF

echo "[INFO] Creating Default Inventory..."

cat >/root/ansible/inventory/hosts.ini <<EOF
[devops]
devops-lab ansible_host=192.168.56.200

[managed]
ansible-01 ansible_host=192.168.56.201
ansible-02 ansible_host=192.168.56.202

[all:vars]
ansible_user=root
ansible_password=root
ansible_connection=ssh
EOF

echo "[INFO] Exporting ANSIBLE_CONFIG..."

grep -q ANSIBLE_CONFIG /root/.bashrc || \
echo 'export ANSIBLE_CONFIG=/root/ansible/ansible.cfg' >> /root/.bashrc

export ANSIBLE_CONFIG=/root/ansible/ansible.cfg

echo
echo "========================================================="
echo " Installed Versions"
echo "========================================================="

echo
ansible --version

echo
python3 --version

echo
pip3 --version

echo
git --version

echo
sshpass -V || true

echo
echo "Installed Collections"
ansible-galaxy collection list

echo
echo "========================================================="
echo " Ansible Core Installation Completed Successfully"
echo "========================================================="
