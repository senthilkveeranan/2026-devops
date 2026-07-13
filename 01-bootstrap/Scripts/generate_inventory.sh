#!/bin/bash

cat > inventory.ini <<EOF

[ansible]
192.168.56.10

[docker]
192.168.56.20

[web]
192.168.56.30
192.168.56.40

[utility]
192.168.56.50

[all:vars]
ansible_user=vagrant

EOF

echo "Inventory Created"
