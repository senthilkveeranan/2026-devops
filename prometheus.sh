#!/bin/bash

echo "===== Prometheus Installation Started ====="

# Variables
VERSION="2.52.0"
USER="prometheus"

# Create user
useradd --no-create-home --shell /bin/false $USER

# Create directories
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus

# Download Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v${VERSION}/prometheus-${VERSION}.linux-amd64.tar.gz

# Extract
tar -xvf prometheus-${VERSION}.linux-amd64.tar.gz
cd prometheus-${VERSION}.linux-amd64

# Copy binaries
cp prometheus /usr/local/bin/
cp promtool /usr/local/bin/

# Set ownership
chown $USER:$USER /usr/local/bin/prometheus
chown $USER:$USER /usr/local/bin/promtool

# Copy config
cp prometheus.yml /etc/prometheus/

# Set permissions
chown -R $USER:$USER /etc/prometheus
chown -R $USER:$USER /var/lib/prometheus

# Create systemd service
cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
After=network.target

[Service]
User=$USER
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus

Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reexec
systemctl daemon-reload

# Start service
systemctl enable --now prometheus

echo "===== Prometheus Installed Successfully ====="
echo "Access URL: http://<server-ip>:9090"
