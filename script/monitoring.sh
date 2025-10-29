#!/bin/bash

# ----------------------------------------------------------
#  Node Exporter
# ----------------------------------------------------------
echo "[+] Installing Node Exporter..."
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
echo "[✓] Node Exporter running on port :9100"
# ----------------------------------------------------------


sudo apt update -y
sudo apt install -y docker.io  docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

sudo mkdir -p /opt/monitoring
sudo cat > /opt/monitoring/prometheus.yml <<'YAML'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

# Alertmanager configuration
# alerting:
#   alertmanagers:
#     - static_configs:
#         - targets:
#             - localhost:9093

scrape_configs:
  - job_name: 'ids-node'  
    metrics_path: /metrics
    scheme: http
    static_configs: 
      - targets: ["${ALB_DNS_IDS}"] 
        labels:
          app: "ids_node"

  - job_name: 'ec2-api'  
    metrics_path: /metrics
    scheme: http
    static_configs: 
      - targets: ["${EC2_API_IP}:9100"] 
        labels:
          app: "ec2_api"

  - job_name: 'log-system'  
    metrics_path: /metrics
    scheme: http
    static_configs: 
      - targets: ["${ALB_DNS_LOG}"] 
        labels:
          app: "log_system"

  - job_name: 'monitoring-system'  
    metrics_path: /metrics
    scheme: http
    static_configs: 
      - targets: ["${ALB_DNS_MONITOR}"] 
        labels:
          app: "monitoring_system"
YAML

sudo cat > /opt/monitoring/docker-compose.yml <<'YAML'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --web.external-url=http://monitoring.qm.uit/
      - --web.route-prefix=/prometheus
    volumes:
      - /opt/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    ports:
      - "9090:9090"
    restart: unless-stopped
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    environment:
      - GF_SERVER_ROOT_URL=http://monitoring.qm.uit/
    ports:
      - "3000:3000"
    restart: unless-stopped
YAML

cd /opt/monitoring/
sudo docker-compose up -d
