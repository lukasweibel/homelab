#!/bin/bash
set -e

HOST=$1
HOST_DIR="infrastructure/hosts/$HOST"

echo "Deploying docker services for $HOST..."

# ── Ensure the Pi itself uses external DNS (not AdGuard) ──────────────────────
if [[ -f "$HOST_DIR/dhcpcd.conf" ]]; then
  echo "Syncing dhcpcd.conf..."
  sudo cp "$HOST_DIR/dhcpcd.conf" /etc/dhcpcd.conf
fi

# Replace resolv.conf with external DNS so host + Docker never depend on AdGuard
sudo rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' | sudo tee /etc/resolv.conf > /dev/null
echo "resolv.conf set to external DNS"

# Restart Docker so it picks up the new resolv.conf
sudo systemctl restart docker
echo "Docker restarted"

# Pull images with reliable DNS
docker compose -f "$HOST_DIR/docker-compose.yml" pull

if [[ -f "$HOST_DIR/adguard/AdGuardHome.yaml" ]]; then
  echo "Syncing AdGuard config..."
  sudo mkdir -p /opt/adguard/conf
  sudo cp "$HOST_DIR/adguard/AdGuardHome.yaml" /opt/adguard/conf/AdGuardHome.yaml
fi

# Restart with new config (image already cached)
docker compose -f "$HOST_DIR/docker-compose.yml" down 2>/dev/null || true
docker rm -f adguard 2>/dev/null || true
docker compose -f "$HOST_DIR/docker-compose.yml" up -d --remove-orphans

echo "Deploy done"