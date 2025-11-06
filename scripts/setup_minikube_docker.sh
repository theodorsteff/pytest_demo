#!/usr/bin/env bash
set -euo pipefail

# Helper to install Docker (if needed), configure Minikube to use the Docker driver,
# lower default memory to 2048MB, and start Minikube. Safe to re-run.

OUT_MEMORY=${1:-2048}

echo "=== setup_minikube_docker.sh ==="
echo "Desired minikube memory: ${OUT_MEMORY}MB"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not found — installing..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
else
  echo "Docker already installed: $(docker --version)"
fi

echo "Enabling docker service..."
sudo systemctl enable --now docker

echo "Adding $USER to docker group (may require logout/login)..."
sudo usermod -aG docker "$USER" || true

echo "Configuring minikube to use driver=docker and memory=${OUT_MEMORY}MB"
minikube config set driver docker || true
minikube config set memory ${OUT_MEMORY} || true

echo "Deleting any existing minikube cluster (if present) and starting new one..."
minikube delete || true

echo "Starting minikube inside newgrp so docker group applies to this session..."
if command -v newgrp >/dev/null 2>&1; then
  newgrp docker <<NG
set -e
echo "docker: $(docker --version)"
minikube start --driver=docker
minikube status
kubectl get nodes -o wide || true
NG
else
  echo "newgrp not available; please log out and log back in to apply docker group membership and then run:"
  echo "  minikube start --driver=docker"
fi

echo "=== setup_minikube_docker.sh finished ==="
