#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-02-09
# @Description: One-click deploy script for Langfuse
###

set -e
cd "$(dirname "$0")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Langfuse Auto Deploy Script${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Step 1: Check dependencies (PostgreSQL, Redis, MinIO)
echo -e "${YELLOW}Step 1: Checking dependencies...${NC}"

check_service() {
    local service=$1
    local pattern=$2
    if docker ps | grep -q "$pattern"; then
        echo -e "${GREEN}✓ $service is running${NC}"
        return 0
    else
        echo -e "${RED}✗ $service is NOT running${NC}"
        return 1
    fi
}

DEPS_OK=true
check_service "PostgreSQL" "postgres" || DEPS_OK=false
check_service "Redis" "redis" || DEPS_OK=false
check_service "MinIO" "minio" || DEPS_OK=false

if [ "$DEPS_OK" = false ]; then
    echo ""
    echo -e "${RED}Error: Required services are not running.${NC}"
    echo -e "${YELLOW}Please deploy PostgreSQL, Redis, and MinIO first.${NC}"
    echo ""
    echo "Quick start commands:"
    echo "  cd ../postgres-pgvector && ./deploy_postgres.sh"
    echo "  cd ../redis && ./deploy_redis.sh"
    echo "  cd ../milvus && ./deploy_milvus.sh  # includes MinIO"
    exit 1
fi

echo ""

# Step 2: Download official files if not exists
echo -e "${YELLOW}Step 2: Downloading official configuration files...${NC}"

if [ ! -f "docker-compose.yml" ]; then
    echo "Downloading docker-compose.yml..."
    if ! wget -q https://raw.githubusercontent.com/langfuse/langfuse/main/docker-compose.yml; then
        echo -e "${RED}Failed to download docker-compose.yml${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ docker-compose.yml downloaded${NC}"
else
    echo -e "${GREEN}✓ docker-compose.yml already exists${NC}"
fi

if [ ! -f ".env.dev.example" ]; then
    echo "Downloading .env.dev.example..."
    if ! wget -q https://raw.githubusercontent.com/langfuse/langfuse/main/.env.dev.example; then
        echo -e "${RED}Failed to download .env.dev.example${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ .env.dev.example downloaded${NC}"
else
    echo -e "${GREEN}✓ .env.dev.example already exists${NC}"
fi

echo ""

# Step 3: Modify docker-compose.yml
echo -e "${YELLOW}Step 3: Modifying docker-compose.yml...${NC}"

if [ ! -f "docker-compose.yml.original" ]; then
    cp docker-compose.yml docker-compose.yml.original
    echo -e "${GREEN}✓ Original file backed up${NC}"
fi

# Create modified docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: "3.5"

services:
  # ===== ClickHouse (新部署) =====
  clickhouse:
    image: docker.io/clickhouse/clickhouse-server
    user: "101:101"
    container_name: ${CLICKHOUSE_CONTAINER_NAME:-langfuse-clickhouse}
    environment:
      CLICKHOUSE_DB: default
      CLICKHOUSE_USER: ${CLICKHOUSE_USER:-clickhouse}
      CLICKHOUSE_PASSWORD: ${CLICKHOUSE_PASSWORD:-clickhouse}
    volumes:
      - langfuse_clickhouse_data:/var/lib/clickhouse
      - langfuse_clickhouse_logs:/var/log/clickhouse-server
    ports:
      - ${HOST_IP:-127.0.0.1}:${CLICKHOUSE_HTTP_PORT:-8123}:8123
      - ${HOST_IP:-127.0.0.1}:${CLICKHOUSE_NATIVE_PORT:-9900}:9000
    healthcheck:
      test: wget --no-verbose --tries=1 --spider http://localhost:8123/ping || exit 1
      interval: 5s
      timeout: 5s
      retries: 10
      start_period: 1s
    restart: unless-stopped

  # ===== Langfuse Web =====
  langfuse-web:
    image: docker.io/langfuse/langfuse:latest
    container_name: ${WEB_CONTAINER_NAME:-langfuse-web}
    extra_hosts:
      - "host.docker.internal:host-gateway"
    depends_on:
      clickhouse:
        condition: service_healthy
    ports:
      - ${WEB_HOST_PORT:-3000}:3000
    env_file:
      - .env
    restart: unless-stopped

  # ===== Langfuse Worker =====
  langfuse-worker:
    image: docker.io/langfuse/langfuse:latest
    container_name: ${WORKER_CONTAINER_NAME:-langfuse-worker}
    command: worker
    extra_hosts:
      - "host.docker.internal:host-gateway"
    depends_on:
      clickhouse:
        condition: service_healthy
    env_file:
      - .env
    restart: unless-stopped

volumes:
  langfuse_clickhouse_data:
    driver: local
  langfuse_clickhouse_logs:
    driver: local
EOF

echo -e "${GREEN}✓ docker-compose.yml modified${NC}"
echo ""

# Step 4: Generate secrets and create .env
echo -e "${YELLOW}Step 4: Generating secrets and creating .env file...${NC}"

if [ -f ".env" ]; then
    BACKUP_NAME=".env.backup.$(date +%Y%m%d_%H%M%S)"
    mv .env "$BACKUP_NAME"
    echo -e "${YELLOW}⚠️  Existing .env backed up to $BACKUP_NAME${NC}"
fi

# Generate secrets
NEXTAUTH_SECRET=$(openssl rand -hex 32)
SALT=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
CLICKHOUSE_PASSWORD=$(openssl rand -base64 32 | tr -d '=+/')

echo -e "${GREEN}✓ Secrets generated${NC}"
echo ""

# Prompt for PostgreSQL password
echo -e "${BLUE}Please provide configuration:${NC}"
read -p "Enter PostgreSQL password (default: postgres): " POSTGRES_PASSWORD
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}

read -p "Enter Redis password (leave empty if no password): " REDIS_PASSWORD

read -p "Enter MinIO Access Key (default: minioadmin): " MINIO_ACCESS_KEY
MINIO_ACCESS_KEY=${MINIO_ACCESS_KEY:-minioadmin}

read -p "Enter MinIO Secret Key (default: minioadmin): " MINIO_SECRET_KEY
MINIO_SECRET_KEY=${MINIO_SECRET_KEY:-minioadmin}

# Build Redis connection string
if [ -z "$REDIS_PASSWORD" ]; then
    REDIS_CONNECTION_STRING="redis://host.docker.internal:19531"
else
    REDIS_CONNECTION_STRING="redis://:${REDIS_PASSWORD}@host.docker.internal:19531"
fi

# Create .env file
cat > .env << EOF
# ============================================
# 端口配置
# ============================================
WEB_HOST_PORT=3000
CLICKHOUSE_HTTP_PORT=8123
CLICKHOUSE_NATIVE_PORT=9900

# ============================================
# 容器名称
# ============================================
CLICKHOUSE_CONTAINER_NAME=langfuse-clickhouse
WEB_CONTAINER_NAME=langfuse-web
WORKER_CONTAINER_NAME=langfuse-worker

# ============================================
# PostgreSQL 配置 (使用现有服务)
# ============================================
DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@host.docker.internal:5432/langfuse
DIRECT_URL=postgresql://postgres:${POSTGRES_PASSWORD}@host.docker.internal:5432/langfuse

# ============================================
# Redis 配置 (使用现有服务)
# ============================================
REDIS_CONNECTION_STRING=${REDIS_CONNECTION_STRING}

# ============================================
# ClickHouse 配置 (新部署的容器)
# ============================================
CLICKHOUSE_USER=clickhouse
CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}
CLICKHOUSE_URL=http://clickhouse:8123
CLICKHOUSE_MIGRATION_URL=clickhouse://clickhouse:9000

# ============================================
# MinIO/S3 配置 (使用现有服务)
# ============================================
# Batch Export
LANGFUSE_S3_BATCH_EXPORT_ENABLED=true
LANGFUSE_S3_BATCH_EXPORT_BUCKET=langfuse
LANGFUSE_S3_BATCH_EXPORT_PREFIX=exports/
LANGFUSE_S3_BATCH_EXPORT_ENDPOINT=http://host.docker.internal:9000
LANGFUSE_S3_BATCH_EXPORT_FORCE_PATH_STYLE=true
LANGFUSE_S3_BATCH_EXPORT_ACCESS_KEY_ID=${MINIO_ACCESS_KEY}
LANGFUSE_S3_BATCH_EXPORT_SECRET_ACCESS_KEY=${MINIO_SECRET_KEY}
LANGFUSE_S3_BATCH_EXPORT_REGION=auto

# Media Upload
LANGFUSE_S3_MEDIA_UPLOAD_ENABLED=true
LANGFUSE_S3_MEDIA_UPLOAD_BUCKET=langfuse
LANGFUSE_S3_MEDIA_UPLOAD_PREFIX=media/
LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT=http://host.docker.internal:9000
LANGFUSE_S3_MEDIA_UPLOAD_FORCE_PATH_STYLE=true
LANGFUSE_S3_MEDIA_UPLOAD_ACCESS_KEY_ID=${MINIO_ACCESS_KEY}
LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY=${MINIO_SECRET_KEY}
LANGFUSE_S3_MEDIA_UPLOAD_REGION=auto

# Event Upload
LANGFUSE_S3_EVENT_UPLOAD_ENABLED=true
LANGFUSE_S3_EVENT_UPLOAD_BUCKET=langfuse
LANGFUSE_S3_EVENT_UPLOAD_PREFIX=events/
LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT=http://host.docker.internal:9000
LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE=true
LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID=${MINIO_ACCESS_KEY}
LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY=${MINIO_SECRET_KEY}
LANGFUSE_S3_EVENT_UPLOAD_REGION=auto

# ============================================
# 核心安全配置 (自动生成)
# ============================================
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
SALT=${SALT}
ENCRYPTION_KEY=${ENCRYPTION_KEY}

# ============================================
# 其他配置
# ============================================
NODE_ENV=production
TELEMETRY_ENABLED=true
LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES=false
EOF

echo -e "${GREEN}✓ .env file created${NC}"
echo ""

# Save secrets to .secrets file for backup
cat > .secrets << EOF
# Langfuse 安全密钥 - 生成时间: $(date)
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
SALT=${SALT}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}
EOF
chmod 600 .secrets

echo -e "${GREEN}✓ Secrets saved to .secrets (chmod 600)${NC}"
echo ""

# Step 5: Prepare database and storage
echo -e "${YELLOW}Step 5: Preparing database and storage...${NC}"

# Create PostgreSQL database
echo "Creating langfuse database in PostgreSQL..."
if docker exec postgres psql -U postgres -c "CREATE DATABASE langfuse;" 2>/dev/null; then
    echo -e "${GREEN}✓ Database 'langfuse' created${NC}"
else
    echo -e "${YELLOW}⚠️  Database 'langfuse' may already exist (this is OK)${NC}"
fi

# Check if MinIO bucket exists, create if not
echo "Checking MinIO bucket 'langfuse'..."

# Try to find MinIO container
MINIO_CONTAINER=$(docker ps --filter "ancestor=minio/minio" --format "{{.Names}}" | head -n 1)

if [ -z "$MINIO_CONTAINER" ]; then
    echo -e "${YELLOW}⚠️  MinIO container not found with 'minio/minio' image${NC}"
    echo -e "${YELLOW}   Please create bucket 'langfuse' manually at http://localhost:9001${NC}"
else
    echo "Found MinIO container: $MINIO_CONTAINER"
    
    # Configure mc alias and create bucket
    if docker exec "$MINIO_CONTAINER" mc alias set local http://localhost:9000 "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" 2>/dev/null; then
        if docker exec "$MINIO_CONTAINER" mc mb local/langfuse 2>/dev/null; then
            echo -e "${GREEN}✓ Bucket 'langfuse' created${NC}"
        else
            echo -e "${YELLOW}⚠️  Bucket 'langfuse' may already exist (this is OK)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Failed to configure mc or create bucket${NC}"
        echo -e "${YELLOW}   Please create bucket 'langfuse' manually at http://localhost:9001${NC}"
    fi
fi

echo ""

# Step 6: Pull images and start services
echo -e "${YELLOW}Step 6: Pulling images and starting services...${NC}"

docker compose pull
echo ""

docker compose up -d

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  Langfuse Deployed Successfully!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${BLUE}Service URLs:${NC}"
echo "  Langfuse Web:  http://localhost:3000"
echo "  ClickHouse:    http://localhost:8123"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Wait a moment for services to initialize"
echo "  2. Check service status:  docker compose ps"
echo "  3. View logs:             docker compose logs -f"
echo "  4. Open browser:          http://localhost:3000"
echo ""
echo -e "${BLUE}Health Check:${NC}"
echo "  ClickHouse:   curl http://localhost:8123/ping"
echo "  Langfuse Web: curl -I http://localhost:3000"
echo ""
echo -e "${BLUE}Management Commands:${NC}"
echo "  View logs:       docker compose logs -f langfuse-web"
echo "  Restart:         docker compose restart"
echo "  Stop:            docker compose down"
echo "  Full cleanup:    docker compose down -v"
echo ""
echo -e "${YELLOW}Important Files:${NC}"
echo "  Configuration:   .env"
echo "  Secrets backup:  .secrets"
echo "  Original compose: docker-compose.yml.original"
echo ""
