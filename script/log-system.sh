#!/bin/bash

set -e

sudo apt update -y
sudo apt install -y docker.io  docker-compose ruby-full wget curl
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
  echo "Service file missing, creating manually..."
  sudo bash -c 'cat > /etc/systemd/system/codedeploy-agent.service <<EOF
[Unit]
Description=AWS CodeDeploy Agent
After=network.target

[Service]
ExecStart=/usr/bin/codedeploy-agent start
Restart=always
User=nobody
Group=nobody

[Install]
WantedBy=multi-user.target
EOF'
fi

sudo systemctl enable --now codedeploy-agent
sudo systemctl start codedeploy-agent
sudo systemctl status codedeploy-agent