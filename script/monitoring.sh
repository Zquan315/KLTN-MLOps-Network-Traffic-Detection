#!/bin/bash

# ----------------------------------------------------------
#  CloudWatch Agent for ASG Scaling Metrics
# ----------------------------------------------------------
echo "[+] Installing CloudWatch Agent..."
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/cw-agent.deb
sudo dpkg -i -E /tmp/cw-agent.deb
rm /tmp/cw-agent.deb

sudo cat > /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json <<'CWCONFIG'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "mem": {
        "measurement": [
          {"name": "mem_used_percent", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          {"name": "used_percent", "rename": "disk_used_percent", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"],
        "ignore_file_system_types": ["sysfs", "devtmpfs", "tmpfs"]
      }
    },
    "append_dimensions": {
      "AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
      "InstanceId": "$${aws:InstanceId}"
    },
    "aggregation_dimensions": [["AutoScalingGroupName"]]
  }
}
CWCONFIG

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json

sudo systemctl enable amazon-cloudwatch-agent
echo "[✓] CloudWatch Agent installed for Memory & Disk metrics"
# ----------------------------------------------------------

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
sudo mkdir -p /opt/monitoring/rules
sudo mkdir -p /opt/monitoring/alertmanager

sudo cat > /opt/monitoring/prometheus.yml <<'YAML'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

# Load alerting rules
rule_files:
  - '/etc/prometheus/rules/*.yml'

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

  - job_name: 'honeypot-system'  
    metrics_path: /metrics
    scheme: http
    static_configs: 
      - targets: ["${HONEYPOT_URL}"] 
        labels:
          app: "honeypot_system"
YAML

# Create alert rules inline
sudo cat > /opt/monitoring/rules/node_exporter_rules.yml <<'RULES'
groups:
  - name: node_exporter_alerts
    interval: 30s
    rules:
      - alert: HighCpuUsage
        expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected on {{ $labels.instance }}"
          description: "CPU usage is above 80% (current: {{ $value | humanize }}%) for more than 5 minutes"

      - alert: CriticalCpuUsage
        expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 95
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Critical CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 95% (current: {{ $value | humanize }}%)"

      # Memory Alerts
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 80% (current: {{ $value | humanize }}%)"

      - alert: CriticalMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 95
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Critical memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 95% (current: {{ $value | humanize }}%)"

      # Disk Alerts
      - alert: HighDiskUsage
        expr: (node_filesystem_size_bytes{fstype=~"ext4|xfs"} - node_filesystem_free_bytes{fstype=~"ext4|xfs"}) / node_filesystem_size_bytes{fstype=~"ext4|xfs"} * 100 > 80
        for: 5m
        labels:
          severity: warning
          component: node
        annotations:
          summary: "High disk usage on {{ $labels.instance }}"
          description: "Disk {{ $labels.mountpoint }} is above 80% (current: {{ $value | humanize }}%)"

      - alert: CriticalDiskUsage
        expr: (node_filesystem_size_bytes{fstype=~"ext4|xfs"} - node_filesystem_free_bytes{fstype=~"ext4|xfs"}) / node_filesystem_size_bytes{fstype=~"ext4|xfs"} * 100 > 90
        for: 2m
        labels:
          severity: critical
          component: node
        annotations:
          summary: "Critical disk usage on {{ $labels.instance }}"
          description: "Disk {{ $labels.mountpoint }} is above 90% (current: {{ $value | humanize }}%)"
RULES

sudo cat > /opt/monitoring/rules/api_model_rules.yml <<'RULES'
groups:
  - name: api_model_alerts
    interval: 30s
    rules:
      # API Performance
      - alert: HighAPILatency
        expr: histogram_quantile(0.95, sum by (le, job, instance) (rate(prediction_latency_ms_bucket[5m]))) > 1000
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High API latency on {{ $labels.instance }}"
          description: "API p95 latency is above 1000ms (current: {{ $value | humanize }}ms)"

      - alert: CriticalAPILatency
        expr: histogram_quantile(0.95, sum by (le, job, instance) (rate(prediction_latency_ms_bucket[5m]))) > 2000
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Critical API latency on {{ $labels.instance }}"
          description: "API p95 latency is above 2000ms (current: {{ $value | humanize }}ms)"

      - alert: HighPredictionRequestRate
        expr: sum by (job, instance) (rate(prediction_requests_total[5m])) > 100
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High prediction request rate on {{ $labels.instance }}"
          description: "Prediction requests above 100 req/s for 10+ minutes"

      # Model & Process
      - alert: NoModelLearning
        expr: rate(model_learn_total[10m]) == 0
        for: 30m
        labels:
          severity: warning
        annotations:
          summary: "Model is not learning on {{ $labels.instance }}"
          description: "No model updates detected for more than 30 minutes"

      - alert: HighProcessMemory
        expr: process_resident_memory_bytes{job="api-system"} / 1024 / 1024 > 2048
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High process memory usage on {{ $labels.instance }}"
          description: "Process memory usage is above 2GB (current: {{ $value | humanize }}MB)"

      - alert: APIServiceDown
        expr: up{job="api-system"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "API service is down on {{ $labels.instance }}"
          description: "API service has been down for more than 2 minutes"

      - alert: HighAttackDetectionRate
        expr: rate(prediction_requests_total{job="api-system"}[5m]) > 100
        for: 5m
        labels:
          severity: warning
          component: ids
        annotations:
          summary: "High attack detection rate on {{ $labels.instance }}"
          description: "More than 100 predictions/s for 5 minutes. Possible attack in progress"
RULES

sudo cat > /opt/monitoring/alertmanager/alertmanager.yml <<'ALERTMGR'
global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'tocongquan315@gmail.com'
  smtp_auth_username: 'tocongquan315@gmail.com'
  smtp_auth_password: 'erubesawmtvzubkq'
  smtp_require_tls: true

route:
  receiver: email_receiver 

receivers:
  - name: 'email_receiver'
    email_configs:
      - to: 'tocongquan315@gmail.com'
        headers:
          Subject: '🚨 [Monitoring system alert] {{ .GroupLabels.alertname }}'
        send_resolved: true
ALERTMGR

sudo mkdir -p /opt/monitoring/grafana_data
sudo mkdir -p /opt/monitoring/prometheus_data
sudo mkdir -p /opt/monitoring/alertmanager_data
sudo chmod 777 -R /opt/monitoring/grafana_data /opt/monitoring/prometheus_data /opt/monitoring/alertmanager_data

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
      - --web.external-url=https://monitoring.qmuit.id.vn/prometheus
      - --web.route-prefix=/prometheus
    volumes:
      - /opt/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - /opt/monitoring/rules:/etc/prometheus/rules:ro
      - /opt/monitoring/prometheus_data:/prometheus
    ports:
      - "9090:9090"
    restart: unless-stopped
    depends_on:
      - alertmanager

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    command:
      - --config.file=/etc/alertmanager/alertmanager.yml
      - --storage.path=/alertmanager
      - --web.external-url=https://monitoring.qmuit.id.vn/alertmanager
      - --web.route-prefix=/alertmanager
    volumes:
      - /opt/monitoring/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
      - /opt/monitoring/alertmanager_data:/alertmanager
    ports:
      - "9093:9093"
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    user: "472:472"
    environment:
      - GF_SERVER_ROOT_URL=https://monitoring.qmuit.id.vn
      - GF_SERVER_SERVE_FROM_SUB_PATH=false
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_SECURITY_ADMIN_PASSWORD_CHANGE_REQUIRED=false
      - GF_AUTH_LDAP_ENABLED=false
      - GF_PATHS_DATA=/var/lib/grafana
      - GF_PATHS_LOGS=/var/log/grafana
      - GF_PATHS_PLUGINS=/var/lib/grafana/plugins
      - GF_PATHS_PROVISIONING=/etc/grafana/provisioning
    ports:
      - "3000:3000"
    volumes:
      - /opt/monitoring/grafana_data:/var/lib/grafana
    restart: unless-stopped
volumes:
  prometheus_data:
  alertmanager_data:
YAML

echo "[+] Starting Docker Compose services..."
cd /opt/monitoring/
sudo -E docker-compose up -d

