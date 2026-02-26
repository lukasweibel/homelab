#!/bin/bash
set -e

HOST=$1
HOST_DIR="infrastructure/hosts/$HOST"

echo "Deploying docker services for $HOST..."

if [[ -f "$HOST_DIR/dhcpcd.conf" ]]; then
  sudo cp "$HOST_DIR/dhcpcd.conf" /etc/dhcpcd.conf
  sudo systemctl restart dhcpcd
fi

docker compose -f "$HOST_DIR/docker-compose.yml" down 2>/dev/null || true
docker rm -f adguard 2>/dev/null || true

if [[ -f "$HOST_DIR/adguard/AdGuardHome.yaml" ]]; then
  echo "Syncing AdGuard config..."
  sudo mkdir -p /opt/adguard/conf
  sudo cp "$HOST_DIR/adguard/AdGuardHome.yaml" /opt/adguard/conf/AdGuardHome.yaml
fi

# Now bring up
docker compose -f "$HOST_DIR/docker-compose.yml" pull
docker compose -f "$HOST_DIR/docker-compose.yml" up -d --remove-orphans

echo "Deploy done"