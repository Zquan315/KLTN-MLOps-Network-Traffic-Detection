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

sudo apt update -y
sudo apt install -y python3 python3-pip python3-venv
sudo pip3 install Flask

sudo mkdir -p /home/ubuntu/logs/
sudo chown ubuntu:ubuntu /home/ubuntu/logs/
cd /home/ubuntu
sudo -u ubuntu python3 -m venv venv 

# Install dependencies
cat > requirements.txt <<EOF
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-dateutil==2.8.2
EOF
sudo chown ubuntu:ubuntu requirements.txt
sudo -u ubuntu /home/ubuntu/venv/bin/pip install -r requirements.txt

# ============================================
# HONEYPOT APPLICATION
# ============================================
cat > /home/ubuntu/honeypot_app.py <<'PYTHON'
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from datetime import datetime, timezone, timedelta
import json
import csv
from pathlib import Path
import logging

# Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)

app = FastAPI(title="Honeypot System", version="1.0.0")

LOGS_DIR = Path("/home/ubuntu/logs")
LOGS_DIR.mkdir(exist_ok=True, parents=True)

@app.get("/")
async def root():
    return {
        "status": "active",
        "service": "ARF IDS Honeypot",
        "message": "This is a decoy system for attack traffic analysis",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.post("/receive_attack")
async def receive_attack(flow: dict):
    """Receive redirected attack traffic from IDS"""
    try:
        # Get today's log file
        dt_vn = datetime.now(timezone(timedelta(hours=7)))
        today = dt_vn.strftime("%Y%m%d")
        timestamp = dt_vn.strftime('%Y-%m-%d %H:%M:%S')  # UTC+7
        log_file = LOGS_DIR / f"attack_traffic_{today}.csv"
        
        # Extract flow data
        flow_id = flow.get("Flow ID") or flow.get("flow_id", "unknown")

        # Prepare row
        row = {
            "timestamp": timestamp,
            "flow_id": flow.get("Flow ID", ""),
            "src_ip": flow.get("Source IP", ""),
            "src_port": flow.get("Source Port", ""),
            "dst_ip": flow.get("Destination IP", ""),
            "dst_port": flow.get("Destination Port", ""),
            "protocol": flow.get("Protocol", ""),
            "label": "ATTACK",
            "content": f"{flow.get('Source IP')}:{flow.get('Source Port')} → {flow.get('Destination IP')}:{flow.get('Destination Port')} ({flow.get('Protocol', 'TCP')})",
            "features_json": json.dumps(flow)
        }
        
        # Write to CSV
        file_exists = log_file.exists()
        with open(log_file, "a", newline="", encoding="utf-8") as f:
            fieldnames = ["flow_id", "timestamp", "src_ip", "src_port", "dst_ip", 
                        "dst_port", "protocol", "label", "content", "features_json"]
            writer = csv.DictWriter(f, fieldnames=fieldnames)
                
            if not file_exists:
                writer.writeheader()
                
            writer.writerow(row)
            
        logging.info(f"[HONEYPOT] Logged attack flow: {flow_id}")
            
        return {
            "status": "logged",
            "flow_id": flow_id,
            "timestamp": timestamp,
            "log_file": str(log_file)
        }
    except Exception as e:
        logging.error(f"[HONEYPOT] Error logging attack flow: {e}")
        raise HTTPException(status_code=500, detail="Error logging attack flow")

@app.get("/stats")
async def get_stats():
    """Get honeypot statistics"""
    today = datetime.now().strftime("%Y%m%d")
    log_file = LOGS_DIR / f"attack_traffic_{today}.csv"
    
    if not log_file.exists():
        return {
            "date": today,
            "count": 0,
            "file": str(log_file),
            "size_bytes": 0
        }
    
    with open(log_file, "r") as f:
        count = sum(1 for _ in f) - 1  # Exclude header
    file_size = log_file.stat().st_size

    return {
        "count": count,
        "date": today,
        "file": str(log_file),
        "size_bytes": file_size,
        "size_mb": round(file_size / 1024 / 1024, 2)
    }

@app.get("/logs/{date}")
async def download_logs(date: str):
    """
    Download logs for a specific date
    Format: YYYYMMDD (e.g., 20251116)
    """
    # Validate date format
    try:
        datetime.strptime(date, "%Y%m%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYYMMDD")
    
    log_file = LOGS_DIR / f"attack_traffic_{date}.csv"
    
    if not log_file.exists():
        raise HTTPException(status_code=404, detail=f"Log file for {date} not found")
    
    return FileResponse(
        path=log_file,
        filename=f"attack_traffic_{date}.csv",
        media_type="text/csv"
    )

# ============================================
# LIST ALL LOG FILES
# ============================================
@app.get("/logs")
async def list_logs():
    """List all available log files"""
    log_files = sorted(LOGS_DIR.glob("attack_traffic_*.csv"))
    
    files_info = []
    for log_file in log_files:
        # Extract date from filename
        date_str = log_file.stem.replace("attack_traffic_", "")
        
        with open(log_file, "r") as f:
            count = sum(1 for _ in f) - 1  # Exclude header
        
        files_info.append({
            "date": date_str,
            "filename": log_file.name,
            "count": count,
            "size_bytes": log_file.stat().st_size,
            "download_url": f"/logs/{date_str}"
        })
    
    return {
        "total_files": len(files_info),
        "files": files_info
    }

PYTHON

sudo chown ubuntu:ubuntu /home/ubuntu/honeypot_app.py

# ============================================
# SYSTEMD SERVICE
# ============================================
sudo cat > /etc/systemd/system/honeypot.service <<EOF
[Unit]
Description=Honeypot System
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/home/ubuntu/venv/bin/uvicorn honeypot_app:app --host 0.0.0.0 --port 5500 --workers 2
Restart=always
RestartSec=5s
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now honeypot

echo "[✓] Honeypot system deployed on port 5500"