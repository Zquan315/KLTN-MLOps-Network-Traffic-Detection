#!/bin/bash 
# cài đặt node_exporter
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xvf node_exporter-1.8.2.linux-amd64.tar.gz
sudo cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/
sudo useradd -rs /bin/false node_exporter
sudo chown -R node_exporter:node_exporter /usr/local/bin/node_exporter

sudo tee /etc/systemd/system/node_exporter.service > /dev/null << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9100
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
sudo systemctl start node_exporter
# cài đặt các gói cần thiết
sudo apt update -y 
sudo apt install -y ruby wget python3 python3-pip git -y

# === Setup IDS ===
cd /opt
sudo git clone https://github.com/bqmxnh/IDS.git
cd IDS

# Cài các thư viện Python cần thiết
sudo pip3 install nfstream pandas numpy joblib scikit-learn flask flask-socketio

# Chạy app ở background để không block script
nohup sudo python3 application.py > /var/log/ids.log 2>&1 &
