#!/bin/bash
set -e

IMAGE_NAME=$1
if [ -z "$IMAGE_NAME" ]; then
  echo "Usage: ./trivy_scan.sh <image_name>"
  exit 1
fi

echo "🔍 Scanning image: $IMAGE_NAME"
trivy image --severity HIGH,CRITICAL --ignore-unfixed $IMAGE_NAME || true

echo "🔍 Scanning local project for secrets..."
trivy fs --security-checks secret ./app || true

echo "✅ Trivy scan done."
