#!/bin/bash
set -euo pipefail

# Cài đặt Python và Flask
sudo apt-get update -y
sudo apt-get install -y python3-pip
sudo pip3 install Flask

# Tạo thư mục log
sudo mkdir -p /home/ubuntu/log/honeypot
sudo chown ubuntu:ubuntu /home/ubuntu/log/honeypot

# 1. Tạo file ứng dụng honeypot
sudo tee /home/ubuntu/honeypot_app.py > /dev/null <<EOF
import os
import csv
import json
from flask import Flask, request
import datetime
import logging
from threading import Lock

app = Flask(__name__)
LOG_DIR = '/home/ubuntu/log/honeypot'
lock = Lock()

# Cấu hình logging cơ bản
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Endpoint này sẽ nhận tất cả các request tấn công
@app.route('/', defaults={'path': ''}, methods=['GET', 'POST', 'PUT', 'DELETE'])
@app.route('/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
def honeypot_listener(path):
    try:
        # Lấy ngày hiện tại YYYY-MM-DD
        today = datetime.datetime.now().strftime('%Y-%m-%d')
        log_file_path = os.path.join(LOG_DIR, f'honeypot_attacks_{today}.csv')
        
        # Lấy dữ liệu JSON từ request (do ids-agent gửi qua)
        # csv_playback.py gửi JSON, nên chúng ta nhận JSON
        attack_data = request.get_json()

        if not attack_data:
            attack_data = {"error": "No JSON payload received", "source_ip": request.remote_addr}

        # Ghi vào file CSV
        # Sử dụng 'lock' để tránh lỗi khi ghi file đồng thời
        with lock:
            # Kiểm tra nếu file chưa tồn tại -> ghi header
            file_exists = os.path.isfile(log_file_path)
            
            with open(log_file_path, 'a', newline='') as f:
                # Lấy tất cả các keys từ JSON làm header
                # Chúng ta giả định attack_data là một dict phẳng
                if not isinstance(attack_data, dict):
                    attack_data = {'payload': json.dumps(attack_data)}

                fieldnames = attack_data.keys()
                writer = csv.DictWriter(f, fieldnames=fieldnames)

                if not file_exists:
                    writer.writeheader()
                
                writer.writerow(attack_data)

        logger.info(f"Logged attack to {log_file_path}")
        
        # Trả về 200 OK để ids-agent biết đã nhận
        return {"status": "logged"}, 200

    except Exception as e:
        logger.error(f"Error in honeypot: {e}")
        return {"status": "error"}, 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5500)
EOF

# 2. Tạo systemd service để chạy ứng dụng honeypot
sudo tee /etc/systemd/system/honeypot.service > /dev/null <<EOF
[Unit]
Description=Honeypot Logger Service
After=network.target

[Service]
User=ubuntu
ExecStart=/usr/bin/python3 /home/ubuntu/honeypot_app.py
Restart=on-failure
WorkingDirectory=/home/ubuntu
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 3. Khởi chạy dịch vụ
sudo systemctl daemon-reload
sudo systemctl enable --now honeypot
sudo systemctl start honeypot