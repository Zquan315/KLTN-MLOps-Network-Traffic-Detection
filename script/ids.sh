#!/bin/bash
set -euo pipefail
set -x  # In từng lệnh ra log cloud-init để debug dễ hơn

DEBUG_LOG="/var/log/userdata-debug.log"
echo "==============================================" | tee -a "$DEBUG_LOG"
echo "Installing Node Exporter + IDS Agent" | tee -a "$DEBUG_LOG"
echo "==============================================" | tee -a "$DEBUG_LOG"

# ----------------------------------------------------------
# Node Exporter
# ----------------------------------------------------------
echo "[+] Installing Node Exporter..." | tee -a "$DEBUG_LOG"
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xzf node_exporter-1.8.2.linux-amd64.tar.gz
sudo cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/
sudo useradd -rs /bin/false node_exporter || true

sudo tee /etc/systemd/system/node_exporter.service > /dev/null << EOF
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

sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
echo "[✓] Node Exporter installed & running on :9100" | tee -a "$DEBUG_LOG"

# ----------------------------------------------------------
# IDS Flask Agent
# ----------------------------------------------------------
echo "[+] Installing dependencies..." | tee -a "$DEBUG_LOG"
sudo apt update -y
sudo apt install -y python3 python3-pip python3-dev build-essential libpcap-dev git

# Check pip version compatibility
python3 -m pip install --upgrade pip || true

if pip --help | grep -q break-system-packages; then
  pip install flask flask-socketio requests pandas boto3 eventlet gunicorn --break-system-packages
else
  pip install flask flask-socketio requests pandas boto3 eventlet gunicorn
fi

# ----------------------------------------------------------
# Clone & start IDS Agent
# ----------------------------------------------------------
echo "[+] Cloning repository..." | tee -a "$DEBUG_LOG"
REPO_URL="https://github.com/bqmxnh/ids-ingress-predict.git"
TARGET_DIR="$HOME/ids-ingress-predict"

if [ -d "$TARGET_DIR" ]; then
  cd "$TARGET_DIR" && git pull
else
  git clone "$REPO_URL" "$TARGET_DIR"
  cd "$TARGET_DIR"
fi

LOG_FILE="/var/log/ids-agent.log"
sudo touch "$LOG_FILE" && sudo chmod 666 "$LOG_FILE"

echo "[+] Starting IDS Agent..." | tee -a "$DEBUG_LOG"
nohup python3 application.py > "$LOG_FILE" 2>&1 &

sleep 3
if pgrep -f "application.py" >/dev/null; then
  echo "[✓] IDS Agent running on port 5001" | tee -a "$DEBUG_LOG"
else
  echo "[✗] Failed to start IDS Agent. Check $LOG_FILE" | tee -a "$DEBUG_LOG"
fi

echo "[✓] Installation finished successfully!" | tee -a "$DEBUG_LOG"
