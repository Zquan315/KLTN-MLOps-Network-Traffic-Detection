#!/bin/bash
set -x
exec > >(tee -a /var/log/userdata-debug.log) 2>&1

echo "=== Installing Node Exporter + IDS Agent ==="

# Node Exporter
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xzf node_exporter-1.8.2.linux-amd64.tar.gz
cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/
useradd -rs /bin/false node_exporter || true

cat <<EOF >/etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network-online.target
[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9100
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now node_exporter

# Python env
apt update -y
apt install -y python3 python3-pip python3-dev python3-numpy python3-pandas build-essential libpcap-dev git

python3 -m pip install -U pip setuptools wheel || true
python3 -m pip install flask flask-socketio requests boto3 eventlet gunicorn -q --no-input || true

# Clone repo
cd /home/ubuntu
git clone https://github.com/bqmxnh/ids-ingress-predict.git || true
cd ids-ingress-predict
nohup python3 application.py > /var/log/ids-agent.log 2>&1 &
