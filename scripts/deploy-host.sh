#!/bin/bash
set -e

HOST=$1
HOST_DIR="infrastructure/hosts/$HOST"
HOST_YAML="$HOST_DIR/host.yaml"

if [[ -z "$HOST" ]]; then
  echo "Usage: ./deploy-host.sh <host>"
  exit 1
fi

if [[ ! -f "$HOST_YAML" ]]; then
  echo "Error: $HOST_YAML not found"
  exit 1
fi

# ── Tool installer ───────────────────────────────────────────────────────────
install_tool() {
  local tool=$1 version=$2
  local tmp_dir
  tmp_dir=$(mktemp -d)

  case "$tool" in
    kubeseal)
      echo "Installing kubeseal v${version}..."
      curl -sL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${version}/kubeseal-${version}-linux-arm64.tar.gz" \
        -o "$tmp_dir/kubeseal.tar.gz"
      tar xzf "$tmp_dir/kubeseal.tar.gz" -C "$tmp_dir" kubeseal
      sudo install -m 755 "$tmp_dir/kubeseal" /usr/local/bin/kubeseal
      ;;
    kubectl)
      echo "Installing kubectl v${version}..."
      curl -sL "https://dl.k8s.io/release/v${version}/bin/linux/arm64/kubectl" \
        -o "$tmp_dir/kubectl"
      sudo install -m 755 "$tmp_dir/kubectl" /usr/local/bin/kubectl
      ;;
    *)
      echo "Unknown tool: $tool (skipping)"
      ;;
  esac

  rm -rf "$tmp_dir"
}

echo "Deploying $HOST..."

# ── Install / update packages from host.yaml ─────────────────────────────────
PACKAGES=$(sed -n '/^packages:/,/^[^ ]/p' "$HOST_YAML" | grep '^\s*-' | sed 's/^\s*-\s*//' | tr '\n' ' ')
if [[ -n "$PACKAGES" ]]; then
  echo "Installing/updating packages: $PACKAGES"
  sudo apt-get update -qq
  sudo apt-get install -y $PACKAGES
fi

# ── Enable & start services from host.yaml ───────────────────────────────────
SERVICES=$(sed -n '/^services:/,/^[^ ]/p' "$HOST_YAML" | grep '^\s*-' | sed 's/^\s*-\s*//' | tr '\n' ' ')
for svc in $SERVICES; do
  echo "Enabling and starting service: $svc"
  sudo systemctl enable "$svc"
  sudo systemctl start "$svc"
done

# ── Install tools from host.yaml ─────────────────────────────────────────────
if grep -q '^tools:' "$HOST_YAML"; then
  grep -A 100 '^tools:' "$HOST_YAML" | tail -n +2 | grep '^\s' | while IFS=: read -r tool version; do
    tool=$(echo "$tool" | xargs)
    version=$(echo "$version" | xargs | tr -d '"')
    if [[ -n "$tool" && -n "$version" ]]; then
      install_tool "$tool" "$version"
    fi
  done
fi

# ── Sync dhcpcd.conf (optional) ──────────────────────────────────────────────
if [[ -f "$HOST_DIR/dhcpcd.conf" ]]; then
  echo "Syncing dhcpcd.conf..."
  sudo cp "$HOST_DIR/dhcpcd.conf" /etc/dhcpcd.conf
fi

# ── DNS ──────────────────────────────────────────────────────────────────────
printf 'nameserver 192.168.1.2\n' | sudo tee /etc/resolv.conf > /dev/null

# ── Sync AdGuard config (optional) ───────────────────────────────────────────
if [[ -f "$HOST_DIR/adguard/AdGuardHome.yaml" ]]; then
  echo "Syncing AdGuard config..."
  sudo mkdir -p /opt/adguard/conf
  sudo cp "$HOST_DIR/adguard/AdGuardHome.yaml" /opt/adguard/conf/AdGuardHome.yaml
fi

# ── Docker Compose (optional) ────────────────────────────────────────────────
if [[ -f "$HOST_DIR/docker-compose.yml" ]]; then
  echo "Deploying docker services..."
  docker compose -f "$HOST_DIR/docker-compose.yml" pull
  docker compose -f "$HOST_DIR/docker-compose.yml" up -d --force-recreate --remove-orphans
fi

echo "Deploy done"