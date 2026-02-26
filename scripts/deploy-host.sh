#!/bin/bash
set -e

HOST=$1
HOST_DIR="infrastructure/hosts/$HOST"

echo "Deploying docker services for $HOST..."

docker stop adguard 2>/dev/null || true

if [[ -f "$HOST_DIR/adguard/AdGuardHome.yaml" ]]; then
  echo "Syncing AdGuard config..."
  sudo mkdir -p /opt/adguard/conf
  sudo cp "$HOST_DIR/adguard/AdGuardHome.yaml" /opt/adguard/conf/AdGuardHome.yaml
fi

docker compose -f "$HOST_DIR/docker-compose.yml" down 2>/dev/null || true
docker rm -f adguard 2>/dev/null || true

docker compose -f "$HOST_DIR/docker-compose.yml" pull
docker compose -f "$HOST_DIR/docker-compose.yml" up -d --remove-orphans

echo "Deploy done"