#!/bin/bash
set -euo pipefail

# ----------------------------------------------------------
# CloudWatch Agent for ASG Scaling Metrics
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
# HONEYPOT APPLICATION (IMPROVED)
# ============================================
cat > /home/ubuntu/honeypot_app.py <<'PYTHON'
#!/usr/bin/env python3

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse, JSONResponse
from datetime import datetime, timezone, timedelta
from pathlib import Path
import json
import csv
import logging
from typing import Dict, Any

# ==================== LOGGING CONFIG ====================
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging. StreamHandler(),
        logging.FileHandler('/home/ubuntu/logs/honeypot.log')
    ]
)
logger = logging.getLogger(__name__)

# ==================== FASTAPI APP ====================
app = FastAPI(
    title="ARF IDS Honeypot System",
    description="Decoy system for attack traffic analysis",
    version="1.0.0"
)

# ==================== CONFIG ====================
LOGS_DIR = Path("/home/ubuntu/logs/attacks")
LOGS_DIR.mkdir(exist_ok=True, parents=True)

STATS_FILE = Path("/home/ubuntu/logs/honeypot_stats.json")

# ==================== STATS TRACKING ====================
attack_stats = {
    "total_received": 0,
    "by_protocol": {},
    "by_src_ip": {},
    "by_dst_port": {},
    "by_date": {},
    "high_confidence_attacks": 0,  # IDS confidence > 0.9
    "start_time": datetime.now(timezone.utc).isoformat(),
    "last_attack_time": None
}

def write_log_background(log_entry: dict, date_str: str):
    try:
        csv_file = LOGS_DIR / f"attacks_{date_str}.csv"
        is_new_file = not csv_file.exists()
        
        with open(csv_file, 'a', newline='', encoding='utf-8') as f:
            fieldnames = [
                "honeypot_receive_time", "flow_id", "src_ip", "src_port",
                "dst_ip", "dst_port", "protocol", "ids_label", "ids_confidence",
                "detection_time", "redirection_method", "total_packets",
                "total_bytes", "flow_duration_ms", "tcp_syn", "tcp_fin", "tcp_rst"
            ]
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            if is_new_file:
                writer.writeheader()
            writer.writerow(log_entry)
            
        logger.info(f"[LOGGED] Flow {log_entry['flow_id']} saved to CSV")
    except Exception as e:
        logger.error(f"[LOG ERROR] {e}")

def load_stats():
    """Load stats from file if exists"""
    global attack_stats
    if STATS_FILE.exists():
        try:
            with open(STATS_FILE, 'r') as f:
                attack_stats = json.load(f)
            logger.info(f"[STATS] Loaded:   {attack_stats['total_received']} total attacks")
        except Exception as e:
            logger.warning(f"[STATS] Failed to load:  {e}, using defaults")

def save_stats():
    """Save stats to file"""
    try:
        with open(STATS_FILE, 'w') as f:
            json.dump(attack_stats, f, indent=2)
    except Exception as e:
        logger.error(f"[STATS] Save failed: {e}")

# Load stats on startup
load_stats()

# ==================== HELPER FUNCTIONS ====================
def extract_flow_metadata(flow: Dict[str, Any]) -> Dict[str, Any]:
    """
    Extract metadata from flow data
    Supports both old format (direct features) and new format (enriched metadata)
    """
    # Check if new format (with redirection_metadata)
    if "redirection_metadata" in flow or "ids_label" in flow:
        # New enriched format from updated IDS
        return {
            "flow_id":  flow.get("flow_id", flow.get("Flow ID", "unknown")),
            "src_ip": flow.get("src_ip", flow.get("Source IP", "")),
            "src_port":  flow.get("src_port", flow.get("Source Port", "")),
            "dst_ip":  flow.get("dst_ip", flow.get("Destination IP", "")),
            "dst_port": flow.get("dst_port", flow.get("Destination Port", "")),
            "protocol":  flow.get("protocol", flow. get("Protocol", "")),
            "ids_label": flow.get("ids_label", "ATTACK"),
            "ids_confidence": flow.get("ids_confidence", 0.0),
            "detection_time": flow.get("detection_timestamp", flow.get("timestamp_utc", "")),
            "redirection_method": flow.get("redirection_method", "UNKNOWN"),
            "session_metadata": flow.get("session_metadata", {})
        }
    else: 
        # Old format (backward compatibility)
        return {
            "flow_id": flow.get("Flow ID", "unknown"),
            "src_ip": flow.get("Source IP", ""),
            "src_port": flow.get("Source Port", ""),
            "dst_ip": flow.get("Destination IP", ""),
            "dst_port": flow.get("Destination Port", ""),
            "protocol": flow.get("Protocol", ""),
            "ids_label": "ATTACK",
            "ids_confidence": 0.0,
            "detection_time": "",
            "redirection_method":  "LEGACY_FORMAT",
            "session_metadata":  {}
        }

# ==================== MAIN ENDPOINTS ====================
@app.get("/")
async def root():
    """Root endpoint - honeypot identification"""
    return {
        "status": "active",
        "service": "ARF IDS Honeypot",
        "Author": "QuanTC & MinhBQ",
        "message": "This is a decoy system for attack traffic analysis",
        "reference": "Beltran Lopez et al. (2024) - arXiv:2402.09191v2",
    }

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "honeypot",
        "uptime_since":  attack_stats["start_time"],
        "total_attacks_logged": attack_stats["total_received"]
    }

@app.post("/receive_attack")
async def receive_attack(flow: dict, background_tasks: BackgroundTasks):
    """
    Nhận traffic và trả lời NGAY LẬP TỨC. Việc ghi log đẩy xuống background.
    """
    try:  
        metadata = extract_flow_metadata(flow)
        
        dt_vn = datetime.now(timezone(timedelta(hours=7)))
        date_str = dt_vn.strftime('%Y%m%d')
        timestamp = dt_vn.strftime('%Y-%m-%d %H:%M:%S')
        
        session_meta = metadata.get("session_metadata", {})
        
        log_entry = {
            "honeypot_receive_time": timestamp,
            "flow_id": metadata["flow_id"],
            "src_ip": metadata["src_ip"],
            "src_port": metadata["src_port"],
            "dst_ip": metadata["dst_ip"],
            "dst_port":  metadata["dst_port"],
            "protocol": metadata["protocol"],
            "ids_label": metadata["ids_label"],
            "ids_confidence": round(metadata["ids_confidence"], 4),
            "detection_time":  metadata["detection_time"],
            "redirection_method": metadata["redirection_method"],
            "total_packets": session_meta.get("total_packets", 0),
            "total_bytes": session_meta.get("total_bytes", 0),
            "flow_duration_ms": session_meta.get("flow_duration_ms", 0),
            "tcp_syn":  session_meta.get("tcp_flags", {}).get("SYN", 0),
            "tcp_fin": session_meta.get("tcp_flags", {}).get("FIN", 0),
            "tcp_rst": session_meta. get("tcp_flags", {}).get("RST", 0)
        }
        
        # Cập nhật số liệu RAM ngay
        attack_stats["total_received"] += 1

        background_tasks.add_task(write_log_background, log_entry, date_str)
        
        return {
            "status": "received", 
            "flow_id": metadata["flow_id"]
        }
        
    except Exception as e: 
        logger.error(f"[ERROR] {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/logs/{date}")
async def download_logs(date: str):
    # Validate date format
    try:
        datetime.strptime(date, "%Y%m%d")
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="Invalid date format. Use YYYYMMDD (e.g., 20250113)"
        )
    
    csv_file = LOGS_DIR / f"attacks_{date}.csv"
    
    if not csv_file.exists():
        # Get available dates
        available = [f.stem.replace("attacks_", "") for f in LOGS_DIR.glob("attacks_*.csv")]
        raise HTTPException(
            status_code=404,
            detail=f"Log file for {date} not found. Available dates: {available}"
        )
    
    return FileResponse(
        path=csv_file,
        filename=f"attacks_{date}.csv",
        media_type="text/csv",
        headers={
            "Content-Disposition":  f"attachment; filename=attacks_{date}.csv",
            "Cache-Control": "no-cache"
        }
    )


@app.get("/stats")
async def get_today_stats():
    """Get statistics for today only"""
    today = datetime.now(timezone(timedelta(hours=7))).strftime("%Y%m%d")
    csv_file = LOGS_DIR / f"attacks_{today}.csv"
    
    if not csv_file.exists():
        return {
            "date": today,
            "attack_count": 0,
            "file_exists": False
        }
    
    # Count attacks
    with open(csv_file, "r") as f:
        count = sum(1 for _ in f) - 1
    
    # Get file size
    file_size = csv_file.stat().st_size
    
    return {
        "date": today,
        "attack_count":  count,
        "file_exists": True,
        "file_size_bytes": file_size,
        "file_size_mb": round(file_size / 1024 / 1024, 2),
        "download_url": f"/logs/{today}"
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