#!/bin/bash

sudo apt update -y
sudo apt install -y docker.io  docker-compose
sudo systemctl enable --now docker

# Add user to docker group
sudo usermod -aG docker $USER