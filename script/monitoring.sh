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
sudo apt install -y docker.io  docker-compose nfs-common
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

sudo mkdir -p /opt/monitoring
sudo mkdir -p /opt/monitoring/rules
sudo mkdir -p /opt/monitoring/alertmanager

# ----------------------------------------------------------
#  EFS Mount for Persistent Storage
# ----------------------------------------------------------
echo "[+] Mounting EFS for persistent monitoring data..."

# Get EFS DNS from Terraform remote state or metadata
EFS_DNS="${EFS_DNS_NAME}"

# Create mount point for EFS
sudo mkdir -p /mnt/efs

# Mount EFS to /mnt/efs
echo "[+] Mounting EFS filesystem: $EFS_DNS..."
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $EFS_DNS:/ /mnt/efs

# Create directories for each service on EFS
sudo mkdir -p /mnt/efs/prometheus
sudo mkdir -p /mnt/efs/grafana-data
sudo mkdir -p /mnt/efs/grafana-db
sudo mkdir -p /mnt/efs/alertmanager

# Set correct permissions
sudo chown -R 65534:65534 /mnt/efs/prometheus
sudo chown -R 472:472 /mnt/efs/grafana-data
sudo chown -R 999:999 /mnt/efs/grafana-db
sudo chown -R 65534:65534 /mnt/efs/alertmanager
sudo chmod 700 /mnt/efs/grafana-db

# Add to /etc/fstab for persistence across reboots
if ! grep -q "$EFS_DNS" /etc/fstab; then
  echo "$EFS_DNS:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" | sudo tee -a /etc/fstab
fi

sudo cat > /opt/monitoring/prometheus.yml <<YAML
global:
  scrape_interval: 15s
  evaluation_interval: 15s

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093
      path_prefix: /alertmanager

# Load alerting rules
rule_files:
  - '/etc/prometheus/rules/*.yml'

scrape_configs:
  - job_name: 'ids-system'  
    metrics_path: /metrics
    scheme: https
    static_configs: 
      - targets: ["${IDS_URL}"] 
        labels:
          app: "ids_node"

  - job_name: 'log-system'  
    metrics_path: /metrics
    scheme: https
    static_configs: 
      - targets: ["${LOG_URL}"] 
        labels:
          app: "log_system"

  - job_name: 'monitoring-system'  
    metrics_path: /metrics
    scheme: https
    static_configs: 
      - targets: ["${MONITOR_URL}"] 
        labels:
          app: "monitoring_system"

  - job_name: 'api-system'  
    metrics_path: /metrics
    scheme: https
    static_configs: 
      - targets: ["${API_URL}"] 
        labels:
          app: "api_system"

  - job_name: 'honeypot-system'  
    metrics_path: /metrics
    scheme: https
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

      - alert: HighPredictionRequestRate
        expr: sum by (instance) (rate(prediction_requests_total{job="api-system", instance="api.qmuit.id.vn"}[2m])) > 50
        for: 2m
        labels:
          severity: critical
          component: ids
        annotations:
          summary: "High prediction request rate on api.qmuit.id.vn"
          description: "More than 50 predictions/s for 2 minutes."
RULES

sudo cat > /opt/monitoring/alertmanager/alertmanager.yml <<'ALERTMGR'
global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'tocongquan315@gmail.com'
  smtp_auth_username: 'tocongquan315@gmail.com'
  smtp_auth_password: 'maswtwbwedkpmkzp'
  smtp_require_tls: true

route:
  receiver: email_receiver 

receivers:
  - name: 'email_receiver'
    email_configs:
      - to: 'tocongquan315@gmail.com'
        headers:
          Subject: '🚨 [{{ .Status | toUpper }}] {{ .CommonLabels.alertname }} - {{ .CommonLabels.instance }}'
        send_resolved: true
ALERTMGR

sudo cat > /opt/monitoring/docker-compose.yml <<'YAML'
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
      - /mnt/efs/prometheus:/prometheus
    ports:
      - "9090:9090"
    restart: always
    depends_on:
      - alertmanager

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    command:
      - --config.file=/etc/alertmanager/alertmanager.yml
      - --storage.path=/alertmanager
      - --web.external-url=https://monitoring.qmuit.id.vn/alertmanager
    volumes:
      - /opt/monitoring/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
      - /mnt/efs/alertmanager:/alertmanager
    ports:
      - "9093:9093"
    restart: always

  grafana-db:
    image: postgres:15-alpine
    container_name: grafana-db
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_USER=grafana
      - POSTGRES_PASSWORD=grafana_secure_password_123
      - POSTGRES_HOST_AUTH_METHOD=scram-sha-256
    volumes:
      - /mnt/efs/grafana-db:/var/lib/postgresql/data
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U grafana"]
      interval: 5s
      timeout: 5s
      retries: 5

  # SERVICE QUAN TRỌNG: Tự động tạo DB grafana nếu chưa có
  grafana-db-init:
    image: postgres:15-alpine
    container_name: grafana-db-init
    restart: "no"
    environment:
      - PGPASSWORD=grafana_secure_password_123
    depends_on:
      grafana-db:
        condition: service_healthy
    # Logic: Đợi DB chính lên -> Thử tạo DB grafana -> Nếu lỗi (do đã có) thì bỏ qua
    command: >
      sh -c "until pg_isready -h grafana-db -U grafana; do sleep 2; done;
             echo 'Check/Create database grafana...';
             psql -h grafana-db -U grafana -d postgres -c 'CREATE DATABASE grafana' || echo 'Database grafana already exists, skipping...'"

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    environment:
      - GF_SERVER_ROOT_URL=https://monitoring.qmuit.id.vn
      - GF_SERVER_SERVE_FROM_SUB_PATH=false
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_SECURITY_ADMIN_PASSWORD_CHANGE_REQUIRED=false
      - GF_AUTH_LDAP_ENABLED=false
      - GF_DATABASE_TYPE=postgres
      - GF_DATABASE_HOST=grafana-db:5432
      - GF_DATABASE_NAME=grafana
      - GF_DATABASE_USER=grafana
      - GF_DATABASE_PASSWORD=grafana_secure_password_123
      - GF_DATABASE_SSL_MODE=disable
    ports:
      - "3000:3000"
    volumes:
      - /mnt/efs/grafana-data:/var/lib/grafana
    restart: always
    depends_on:
      grafana-db:
        condition: service_healthy
      grafana-db-init:
        condition: service_completed_successfully
YAML

echo "[+] Starting Docker Compose seryvices..."
cd /opt/monitoring/
sudo -E docker-compose up -d

