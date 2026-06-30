#!/bin/bash
set -e

dnf -y update

dnf install -y \
vim \
wget \
curl \
net-tools \
bind-utils \
bash-completion \
lsof \
tree \
unzip \
tar

cat <<EOF >> /etc/hosts
192.168.56.11 vcs01
192.168.56.12 vcs02
EOF

systemctl enable sshd
systemctl start sshd
