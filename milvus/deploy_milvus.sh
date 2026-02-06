#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-02-06
# @Description: One-click deploy script for Milvus standalone
###

set -e
cd "$(dirname "$0")"

# 1. Ensure .env exists from env.example (compose uses MINIO_ROOT_USER / MINIO_ROOT_PASSWORD)
if [ ! -f .env ]; then
  echo "Creating .env from env.example..."
  sed -e 's/^MINIO_ACCESS_KEY=/MINIO_ROOT_USER=/' -e 's/^MINIO_SECRET_KEY=/MINIO_ROOT_PASSWORD=/' env.example > .env
  echo "⚠️  Please edit .env to set MINIO_ROOT_USER / MINIO_ROOT_PASSWORD if needed."
fi

# 2. Add execute permission to setup script
chmod +x create_milvus_volumes.sh

# 3. Run volume setup script
./create_milvus_volumes.sh

# 4. Start Milvus standalone
sudo docker-compose -f milvus-standalone-docker-compose.yml up -d

echo ""
echo "✓ Milvus standalone deployed. Ports: 19530 (gRPC), 9091 (metrics), 9000/9001 (MinIO)."
