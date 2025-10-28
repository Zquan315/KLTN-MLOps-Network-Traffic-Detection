#!/bin/bash

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
