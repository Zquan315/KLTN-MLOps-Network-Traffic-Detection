#!/bin/bash

set - e

sudo apt update -y
sudo apt install -y docker.io docker-compose ruby-full wget curl build-essential
sudo systemctl enable --now docker

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