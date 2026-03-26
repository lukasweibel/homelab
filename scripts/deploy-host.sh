#!/bin/bash
set -e

HOST=$1
HOST_DIR="infrastructure/hosts/$HOST"

echo "Deploying docker services for $HOST..."

# ── DNS: Pi uses AdGuard (192.168.1.2) ────────────────────────────────────────
# External port-53 DNS is blocked on this network.
# AdGuard uses DNS-over-TLS (port 853) to reach upstream, so it works.
if [[ -f "$HOST_DIR/dhcpcd.conf" ]]; then
  echo "Syncing dhcpcd.conf..."
  sudo cp "$HOST_DIR/dhcpcd.conf" /etc/dhcpcd.conf
fi
printf 'nameserver 192.168.1.2\n' | sudo tee /etc/resolv.conf > /dev/null

# ── Pull images WHILE AdGuard is still running (DNS available) ────────────────
docker compose -f "$HOST_DIR/docker-compose.yml" pull

# ── Sync AdGuard config ───────────────────────────────────────────────────────
if [[ -f "$HOST_DIR/adguard/AdGuardHome.yaml" ]]; then
  echo "Syncing AdGuard config..."
  sudo mkdir -p /opt/adguard/conf
  sudo cp "$HOST_DIR/adguard/AdGuardHome.yaml" /opt/adguard/conf/AdGuardHome.yaml
fi

# ── Quick restart: images are cached, DNS downtime is minimal ─────────────────
# force-recreate avoids a full down/up cycle — container is replaced in-place
docker compose -f "$HOST_DIR/docker-compose.yml" up -d --force-recreate --remove-orphans

echo "Deploy done"