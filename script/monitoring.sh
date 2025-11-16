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
      - targets: ["${IDS_URL}"] 
        labels:
          app: "ids_node"

  - job_name: 'log-system'  
    metrics_path: /metrics
    scheme: http
    static_configs: 
      - targets: ["${LOG_URL}"] 
        labels:
          app: "log_system"

  - job_name: 'monitoring-system'  
    metrics_path: /metrics
    scheme: http
    static_configs: 
      - targets: ["${MONITOR_URL}"] 
        labels:
          app: "monitoring_system"

  - job_name: 'api-system'  
    metrics_path: /metrics
    scheme: http
    static_configs: 
      - targets: ["${API_URL}"] 
        labels:
          app: "api_system"
YAML
sudo mkdir -p /opt/monitoring/grafana_data
sudo mkdir -p /opt/monitoring/prometheus_data
sudo chmod 777 -R /opt/monitoring/grafana_data /opt/monitoring/prometheus_data

sudo cat > /opt/monitoring/docker-compose.yml <<'YAML'
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.path=/prometheus
      - --storage.tsdb.retention.time=15d
      - --web.external-url=http://monitoring.qmuit.id.vn/prometheus
      - --web.route-prefix=/prometheus
    volumes:
      - /opt/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    restart: unless-stopped
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    environment:
      - GF_SERVER_ROOT_URL=http://monitoring.qmuit.id.vn
      - GF_SERVER_SERVE_FROM_SUB_PATH=false
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_SECURITY_ADMIN_PASSWORD_CHANGE_REQUIRED=false
      - GF_AUTH_LDAP_ENABLED=false
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    restart: unless-stopped
volumes:
  prometheus_data:
  grafana_data:
YAML

cd /opt/monitoring/
sudo -E docker-compose up -d
