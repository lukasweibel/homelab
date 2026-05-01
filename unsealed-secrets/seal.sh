#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CERT="$SCRIPT_DIR/sealed-secrets-public.pem"
OUTPUT_DIR="$SCRIPT_DIR/../clusters/home-cluster/secrets"

if [ ! -f "$CERT" ]; then
  echo "ERROR: $CERT not found"
  exit 1
fi

for secret in "$SCRIPT_DIR"/*.yaml; do
  filename="$(basename "$secret")"
  output="$OUTPUT_DIR/$filename"

  echo "Sealing $filename → $output"
  kubeseal --cert "$CERT" --format yaml < "$secret" > "$output"
done

echo "Done. Don't forget to update kustomization.yaml if you added new secrets."
