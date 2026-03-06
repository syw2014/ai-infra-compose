#!/bin/bash
###
# @Description: One-click deploy script for Milvus standalone with Docker Compose and MinIO
###

set -e
cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo "Creating .env from .env.example..."
  cp .env.example .env
  echo "Please review .env before exposing this deployment outside the host."
fi

chmod +x create_volumes.sh
./create_volumes.sh

docker compose up -d

echo ""
echo "Milvus Compose deployment started."
echo "Ports: 19530 (gRPC), 9091 (metrics), 9000/9001 (MinIO)."
