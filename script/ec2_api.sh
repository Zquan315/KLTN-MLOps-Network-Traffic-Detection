#!/bin/bash
set -euo pipefail

# ----------------------------------------------------------
# Node Exporter
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

echo "[+] Updating system and installing prerequisites..."
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common git gnupg lsb-release

echo "[+] Adding Docker official repository..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

echo "[+] Adding user 'ubuntu' to docker group..."
sudo usermod -aG docker ubuntu

# ⚠️ Thông báo người dùng cần đăng nhập lại để áp dụng group mới
echo "[!] Please log out and log back in for Docker group changes to take effect."
echo "Or run: newgrp docker"

# Clone repository
cd /home/ubuntu
if [ -d "arf-ids-mlops" ]; then
  echo "[*] Repo exists, pulling latest changes..."
  cd arf-ids-mlops
  git pull origin main || true
else
  git clone https://github.com/bqmxnh/arf-ids-mlops.git
  cd arf-ids-mlops
fi

sudo chown -R ubuntu:ubuntu /home/ubuntu/arf-ids-mlops

echo "[+] Building and running Docker Compose stack..."
docker compose build
docker compose up -d

echo "[+] Cleaning up..."
docker image prune -f

docker ps | tee /home/ubuntu/deploy_log.txt
echo "[✅] Deployment complete! Logs saved to /home/ubuntu/deploy_log.txt"
