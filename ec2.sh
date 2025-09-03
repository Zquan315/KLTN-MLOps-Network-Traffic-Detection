#!/bin/bash 

# cài đặt các gói cần thiết
sudo apt update -y 
sudo apt install -y ruby wget python3 python3-pip git -y

# === Setup IDS ===
cd /opt
sudo git clone https://github.com/bqmxnh/IDS.git
cd IDS

# Cài các thư viện Python cần thiết
sudo pip3 install nfstream pandas numpy joblib scikit-learn flask flask-socketio

# Chạy app ở background để không block script
nohup sudo python3 application.py > /var/log/ids.log 2>&1 &
