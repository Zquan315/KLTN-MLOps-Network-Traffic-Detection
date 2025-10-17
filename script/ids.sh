#!/bin/bash 
# cài đặt node_exporter
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xvf node_exporter-1.8.2.linux-amd64.tar.gz
sudo cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/
sudo useradd -rs /bin/false node_exporter
sudo chown -R node_exporter:node_exporter /usr/local/bin/node_exporter

sudo tee /etc/systemd/system/node_exporter.service > /dev/null << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9100
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
sudo systemctl start node_exporter


############
# Deploy IDS: code call API
############

#!/bin/bash
set -euo pipefail

echo "=============================================="
echo "Installing and Starting IDS Agent"
echo "=============================================="

# Step 1. Update system and install dependencies
echo "[+] Updating system and installing base packages..."
sudo apt update -y
sudo apt install -y python3 python3-pip python3-dev build-essential libpcap-dev git

# Step 2. Install Python libraries
echo "[+] Installing Python dependencies..."
python3 -m pip install --upgrade pip
pip install nfstream requests

# Step 3. Clone or update repository
REPO_URL="https://github.com/bqmxnh/ids-agent.git"
TARGET_DIR="$HOME/ids-agent"

echo "[+] Cloning repository from $REPO_URL..."
if [ -d "$TARGET_DIR" ]; then
    echo "[!] Repository already exists, pulling latest changes..."
    cd "$TARGET_DIR"
    git pull
else
    git clone "$REPO_URL" "$TARGET_DIR"
    cd "$TARGET_DIR"
fi

# Step 4. Run the main application
echo "[+] Starting IDS Agent..."
sudo python3 application.py

echo "Setup complete. IDS Agent started successfully."
