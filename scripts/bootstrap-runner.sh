#!/bin/bash
set -e

# ── Config ────────────────────────────────────────────────────────────────────
RUNNER_VERSION="2.322.0"
RUNNER_DIR="$HOME/actions-runner"
REPO_URL="https://github.com/lukasweibel/homelab"

# ── Args ──────────────────────────────────────────────────────────────────────
TOKEN=$1
HOST_LABEL=$2

if [[ -z "$TOKEN" || -z "$HOST_LABEL" ]]; then
  echo "Usage: ./bootstrap-runner.sh <REGISTRATION_TOKEN> <HOST_LABEL>"
  echo "  e.g: ./bootstrap-runner.sh AABBCC123 rpi-01"
  exit 1
fi

# ── Download ──────────────────────────────────────────────────────────────────
mkdir -p "$RUNNER_DIR"

curl -o "$RUNNER_DIR/actions-runner.tar.gz" -L \
  "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz"

tar xzf "$RUNNER_DIR/actions-runner.tar.gz" -C "$RUNNER_DIR"
rm "$RUNNER_DIR/actions-runner.tar.gz"

# ── Configure ─────────────────────────────────────────────────────────────────
"$RUNNER_DIR/config.sh" \
  --url "$REPO_URL" \
  --token "$TOKEN" \
  --name "$HOST_LABEL" \
  --labels "self-hosted,$HOST_LABEL" \
  --work "_work" \
  --unattended

# ── Install & start as systemd service ───────────────────────────────────────
sudo "$RUNNER_DIR/svc.sh" install
sudo "$RUNNER_DIR/svc.sh" start

echo ""
echo "Runner '$HOST_LABEL' registered and running as a service"
echo "Labels: self-hosted, $HOST_LABEL"