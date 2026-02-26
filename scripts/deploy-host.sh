#!/bin/bash
set -e

HOST_DIR="infrastructure/hosts/$1"

echo "Deploying docker services for $1..."
docker compose -f "$HOST_DIR/docker-compose.yml" pull
docker compose -f "$HOST_DIR/docker-compose.yml" up -d

echo "Deploy done"