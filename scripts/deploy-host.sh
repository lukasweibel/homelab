#!/bin/bash
set -e

HOST=$1
HOST_DIR="infrastructure/hosts/$HOST"

echo "Deploying docker services for $HOST..."

# ── Ensure the Pi itself uses external DNS (not AdGuard) ──────────────────────
if [[ -f "$HOST_DIR/dhcpcd.conf" ]]; then
  echo "Syncing dhcpcd.conf..."
  sudo cp "$HOST_DIR/dhcpcd.conf" /etc/dhcpcd.conf
  sudo systemctl restart dhcpcd
fi

# Force resolv.conf to external DNS so pulls never depend on AdGuard
echo "Setting resolv.conf to external DNS..."
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' | sudo tee /etc/resolv.conf > /dev/null

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