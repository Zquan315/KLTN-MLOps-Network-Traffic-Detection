#!/bin/bash 

# === Setup CodeDeploy ===
mkdir /home/ubuntu/student-management-app 
sudo chown -R ubuntu:ubuntu /home/ubuntu/student-management-app 
sudo chmod -R 777 /home/ubuntu/student-management-app

sudo apt update -y 
sudo apt install -y ruby wget python3 python3-pip git -y

cd /home/ubuntu 
wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install 
chmod +x ./install 
sudo ./install auto 

# === Setup IDS ===
cd /opt
sudo git clone https://github.com/bqmxnh/IDS.git
cd IDS

# Cài các thư viện Python cần thiết
sudo pip3 install nfstream pandas numpy joblib scikit-learn flask flask-socketio

# Chạy app ở background để không block script
nohup sudo python3 application.py > /var/log/ids.log 2>&1 &
