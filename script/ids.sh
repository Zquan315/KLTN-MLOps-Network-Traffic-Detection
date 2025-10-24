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
echo "Installing and Starting IDS Ingress Predict Agent"
echo "=============================================="

# ============================================================
# Step 1. Update system and install dependencies
# ============================================================
echo "[1/5] Updating system and installing base packages..."
sudo apt update -y
sudo apt install -y python3 python3-pip python3-dev build-essential libpcap-dev git

# ============================================================
# Step 2. Install Python libraries (with all requirements)
# ============================================================
echo "[2/5] Installing Python dependencies..."
python3 -m pip install --upgrade pip
pip install flask flask-socketio requests pandas boto3 eventlet gunicorn

echo "[✓] Python dependencies installed successfully."

# ============================================================
# Step 3. Clone or update repository
# ============================================================
REPO_URL="https://github.com/bqmxnh/ids-ingress-predict.git"
TARGET_DIR="$HOME/ids-ingress-predict"

echo "[3/5] Cloning repository from $REPO_URL..."
if [ -d "$TARGET_DIR" ]; then
    echo "[!] Repository already exists. Pulling latest changes..."
    cd "$TARGET_DIR"
    git pull
else
    git clone "$REPO_URL" "$TARGET_DIR"
    cd "$TARGET_DIR"
fi

# ============================================================
# Step 4. Start Flask-SocketIO server with Eventlet
# ============================================================
LOG_DIR="/var/log"
LOG_FILE="$LOG_DIR/ids-agent.log"
sudo mkdir -p "$LOG_DIR"
sudo touch "$LOG_FILE"
sudo chmod 666 "$LOG_FILE"

echo "[4/5] Starting IDS Ingress Predict Server..."
echo "[i] Logs will be written to $LOG_FILE"
echo "[i] Service running on port 5001"

# Run background with nohup
nohup python3 application.py > "$LOG_FILE" 2>&1 &

# ============================================================
# Step 5. Verification & summary
# ============================================================
sleep 3
if pgrep -f "application.py" >/dev/null; then
    echo "[✓] IDS Ingress Predict Agent is running successfully!"
    echo "[→] Check logs: tail -f $LOG_FILE"
else
    echo "[✗] Failed to start IDS agent. Check $LOG_FILE for details."
    exit 1
fi

echo "=============================================="
echo "Setup complete. IDS Ingress Predict is running on port 5001"
echo "=============================================="
