#!/bin/bash
set -euo pipefail

# =========================================================
# Cập nhật hệ thống và cài Docker + Docker Compose
# =========================================================
echo "[+] Updating system and installing Docker..."
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl software-properties-common git

# Thêm repo Docker chính thức
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker

# =========================================================
# Clone repo từ GitHub
# =========================================================
echo "[+] Cloning arf-ids-mlops repository..."
cd /home/ubuntu

if [ -d "arf-ids-mlops" ]; then
  echo "[*] Repository already exists, pulling latest changes..."
  cd arf-ids-mlops
  git pull origin main || true
else
  git clone https://github.com/bqmxnh/arf-ids-mlops.git
  cd arf-ids-mlops
fi

# Đảm bảo quyền thư mục đúng để Docker chạy không lỗi
chown -R ubuntu:ubuntu /home/ubuntu/arf-ids-mlops

# =========================================================
# Build & deploy stack MLOps
# =========================================================
echo "[+] Building and running Docker Compose stack..."
docker compose build
docker compose up -d

# =========================================================
# Clean up & info
# =========================================================
docker image prune -f
echo "[✅] Deployment complete! Services running:"
docker ps

# Ghi log để kiểm tra sau reboot
docker ps > /home/ubuntu/deploy_log.txt
