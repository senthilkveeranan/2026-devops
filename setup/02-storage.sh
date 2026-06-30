#!/bin/bash

echo "===== Storage Verification ====="

lsblk

echo
echo "Available disks:"

for disk in /dev/sdb /dev/sdc /dev/sdd
do
    if [ -b "$disk" ]; then
        echo "$disk detected."
    else
        echo "$disk NOT found."
    fi
done
