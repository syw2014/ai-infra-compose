#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-04-09
# @Description: One-click deploy script for MinIO
###

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$SCRIPT_DIR"
source "${ROOT_DIR}/scripts/compose_cmd.sh"

if [ ! -f .env ]; then
  echo "Creating .env from env.example..."
  cp env.example .env
  echo "⚠️  Please edit .env to set MINIO_ROOT_PASSWORD and ports if needed."
fi

chmod +x create_minio_volume.sh
./create_minio_volume.sh

COMPOSE_USE_SUDO="${COMPOSE_USE_SUDO:-1}"
compose up -d

echo ""
echo "✓ MinIO deployed."
echo "  S3 API:      http://localhost:${MINIO_API_PORT:-9000}"
echo "  Web console: http://localhost:${MINIO_CONSOLE_PORT:-9001}"
echo "  Data:        ${DOCKER_VOLUME_DIRECTORY:-.}/volumes/minio"
