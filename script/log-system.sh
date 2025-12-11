#!/bin/bash

set - e

sudo apt update -y
sudo apt install -y docker.io docker-compose ruby-full wget curl build-essential
sudo systemctl enable --now docker

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


# Add user to docker group
sudo usermod -aG docker ubuntu
sudo systemctl restart docker

cd /home/ubuntu
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install -O install
chmod +x ./install
sudo ./install auto || sudo ./install install

if [ -f /etc/systemd/system/codedeploy-agent.service ]; then
  echo "CodeDeploy service file found."
else
  sudo chmod 755 /opt/codedeploy-agent/bin/codedeploy-agent
  sudo tee /etc/systemd/system/codedeploy-agent.service > /dev/null <<EOF
[Unit]
Description=AWS CodeDeploy Agent
Wants=network-online.target
After=network.target

[Service]
ExecStart=/opt/codedeploy-agent/bin/codedeploy-agent start
User=nobody
Group=nogroup
RestartSec=10
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
fi

sudo systemctl daemon-reload
sudo systemctl enable --now codedeploy-agent
sudo systemctl start codedeploy-agent
sudo systemctl status codedeploy-agent