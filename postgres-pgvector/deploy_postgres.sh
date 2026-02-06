#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-02-06
# @Description: One-click deploy script for PostgreSQL (pgvector)
###

set -e
cd "$(dirname "$0")"

# 1. Ensure .env exists from env.example
if [ ! -f .env ]; then
  echo "Creating .env from env.example..."
  cp env.example .env
  echo "⚠️  Please edit .env to set POSTGRES_PASSWORD and other values if needed."
fi

# 2. Add execute permission to setup script
chmod +x create_pg_volume.sh

# 3. Run volume setup script
./create_pg_volume.sh

# 4. Start PostgreSQL
sudo docker-compose up -d

echo ""
echo "✓ PostgreSQL (pgvector) deployed. Port: 5432"
