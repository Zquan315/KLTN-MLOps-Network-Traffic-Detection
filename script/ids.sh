#!/bin/bash
set -euo pipefail
set -x
exec > >(tee -a /var/log/userdata-debug.log) 2>&1

echo "==============================================" 
echo "Installing CloudWatch Agent + Node Exporter + IDS Agent"
echo "=============================================="

# ----------------------------------------------------------
# 0. CloudWatch Agent for ASG Scaling Metrics
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
# 1. Node Exporter
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
# 2. Python environment
# ----------------------------------------------------------
echo "[+] Installing Python dependencies..."
apt update -y
apt install -y python3 python3-pip python3-dev python3-numpy python3-pandas \
               build-essential libpcap-dev git unzip curl pkg-config libssl-dev net-tools htop lsof

python3 -m pip install -U pip setuptools wheel || true
python3 -m pip install flask flask-socketio flask-cors werkzeug==3.0.3 \
                        requests httpx boto3 eventlet gunicorn gevent gevent-websocket \
                        simplejson jinja2 --ignore-installed blinker -q --no-input || true

sudo timedatectl set-timezone "Asia/Ho_Chi_Minh"
# ----------------------------------------------------------
# 3. Clone & run IDS Agent
# ----------------------------------------------------------
echo "[+] Cloning IDS Agent..."
cd /home/ubuntu


if [ ! -d "ids-ingress-predict" ]; then
  git clone https://github.com/bqmxnh/ids-ingress-predict.git
else
  cd ids-ingress-predict && git pull && cd ..
fi

cd /home/ubuntu/ids-ingress-predict

mkdir -p /home/ubuntu/logs
chown ubuntu:ubuntu /home/ubuntu/logs
cd /home/ubuntu/ids-ingress-predict
chown -R ubuntu:ubuntu /home/ubuntu/ids-ingress-predict

echo "[+] Starting IDS Agent..."

export EMAIL_LAMBDA_URL="${EMAIL_LAMBDA_URL}"
# ==========================================================
sudo -E -u ubuntu bash -c "
  export EMAIL_LAMBDA_URL='$EMAIL_LAMBDA_URL'
  nohup gunicorn application:app \
  -k gthread \
  --workers 1 \
  --threads 10 \
  --bind 0.0.0.0:5001 \
  --timeout 300 \
  --keep-alive 5 \
  --access-logfile /home/ubuntu/logs/access.log \
  --error-logfile /home/ubuntu/logs/error.log \
  --log-level info \
  > /home/ubuntu/logs/gunicorn.log 2>&1 &
"
sleep 3

if pgrep -f "application:app" >/dev/null; then
  echo "[✓] IDS Agent running on port 5001"
else
  echo "[✗] Failed to start IDS Agent"
fi

echo "[✓] Installation finished successfully!"