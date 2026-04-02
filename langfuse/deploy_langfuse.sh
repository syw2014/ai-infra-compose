#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-02-10
# @Description: Deploy Langfuse with external PostgreSQL, Redis, and MinIO
###

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$SCRIPT_DIR"
source "${ROOT_DIR}/scripts/compose_cmd.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Langfuse Deploy (External Services)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# External service configuration
PG_HOST="150.136.9.250"
PG_PORT="5432"
PG_USER="postgres"
PG_PASSWORD="F3w%9pZ!Q@7sXk2mA8"
PG_DATABASE="postgres"

REDIS_HOST="150.136.9.250"
REDIS_PORT="6379"
REDIS_PASSWORD="F3w%9pZ!Q@iXk2mA8"

MINIO_HOST="150.136.9.250"
MINIO_PORT="9000"
MINIO_ACCESS_KEY="admin"
MINIO_SECRET_KEY="F3w%9pZ!Q@7swXk2mA8"
MINIO_BUCKET="langfuse"

# Step 1: Check external services connectivity
echo -e "${YELLOW}Step 1: Testing external services connectivity...${NC}"

check_tcp_connection() {
    local host=$1
    local port=$2
    local service=$3
    
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/${host}/${port}" 2>/dev/null; then
        echo -e "${GREEN}✓ ${service} (${host}:${port}) is reachable${NC}"
        return 0
    else
        echo -e "${RED}✗ ${service} (${host}:${port}) is NOT reachable${NC}"
        return 1
    fi
}

SERVICES_OK=true
check_tcp_connection "$PG_HOST" "$PG_PORT" "PostgreSQL" || SERVICES_OK=false
check_tcp_connection "$REDIS_HOST" "$REDIS_PORT" "Redis" || SERVICES_OK=false
check_tcp_connection "$MINIO_HOST" "$MINIO_PORT" "MinIO" || SERVICES_OK=false

if [ "$SERVICES_OK" = false ]; then
    echo ""
    echo -e "${RED}Error: Cannot connect to one or more external services.${NC}"
    echo -e "${YELLOW}Please verify the services are running and accessible from this host.${NC}"
    exit 1
fi

echo ""

# Step 2: Generate secure secrets
echo -e "${YELLOW}Step 2: Generating secure secrets...${NC}"

# Check if .env exists and backup
if [ -f ".env" ]; then
    BACKUP_NAME=".env.backup.$(date +%Y%m%d_%H%M%S)"
    cp .env "$BACKUP_NAME"
    echo -e "${YELLOW}⚠️  Existing .env backed up to $BACKUP_NAME${NC}"
fi

# Generate secrets (using hex to avoid special characters that might cause issues)
NEXTAUTH_SECRET=$(openssl rand -hex 32)
SALT=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
CLICKHOUSE_PASSWORD=$(openssl rand -hex 16)

echo -e "${GREEN}✓ Secrets generated${NC}"
echo ""

# Step 3: Update .env file with actual credentials
echo -e "${YELLOW}Step 3: Updating .env file...${NC}"

# URL encode the password for DATABASE_URL
PG_PASSWORD_ENCODED=$(printf %s "$PG_PASSWORD" | jq -sRr @uri)
REDIS_PASSWORD_ENCODED=$(printf %s "$REDIS_PASSWORD" | jq -sRr @uri)

cat > .env << EOF
# ============================================================================
# Langfuse Environment Configuration - External Services
# Generated: $(date)
# ============================================================================

# ============================================
# PostgreSQL Configuration (External)
# ============================================
DATABASE_URL=postgresql://${PG_USER}:${PG_PASSWORD_ENCODED}@${PG_HOST}:${PG_PORT}/${PG_DATABASE}

# ============================================
# ClickHouse Configuration (Local Container)
# ============================================
CLICKHOUSE_MIGRATION_URL=clickhouse://clickhouse:9000
CLICKHOUSE_URL=http://clickhouse:8123
CLICKHOUSE_USER=clickhouse
CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}
CLICKHOUSE_CLUSTER_ENABLED=false

# ============================================
# Redis Configuration (External)
# ============================================
REDIS_HOST=${REDIS_HOST}
REDIS_PORT=${REDIS_PORT}
REDIS_AUTH=${REDIS_PASSWORD}
REDIS_TLS_ENABLED=false

# ============================================
# MinIO/S3 Configuration (External)
# ============================================
LANGFUSE_USE_AZURE_BLOB=false

# Event Upload Configuration
LANGFUSE_S3_EVENT_UPLOAD_BUCKET=${MINIO_BUCKET}
LANGFUSE_S3_EVENT_UPLOAD_REGION=auto
LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID=${MINIO_ACCESS_KEY}
LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY=${MINIO_SECRET_KEY}
LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT=http://${MINIO_HOST}:${MINIO_PORT}
LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE=true
LANGFUSE_S3_EVENT_UPLOAD_PREFIX=events/

# Media Upload Configuration
LANGFUSE_S3_MEDIA_UPLOAD_BUCKET=${MINIO_BUCKET}
LANGFUSE_S3_MEDIA_UPLOAD_REGION=auto
LANGFUSE_S3_MEDIA_UPLOAD_ACCESS_KEY_ID=${MINIO_ACCESS_KEY}
LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY=${MINIO_SECRET_KEY}
LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT=http://${MINIO_HOST}:${MINIO_PORT}
LANGFUSE_S3_MEDIA_UPLOAD_FORCE_PATH_STYLE=true
LANGFUSE_S3_MEDIA_UPLOAD_PREFIX=media/

# Batch Export Configuration
LANGFUSE_S3_BATCH_EXPORT_ENABLED=true
LANGFUSE_S3_BATCH_EXPORT_BUCKET=${MINIO_BUCKET}
LANGFUSE_S3_BATCH_EXPORT_PREFIX=exports/
LANGFUSE_S3_BATCH_EXPORT_REGION=auto
LANGFUSE_S3_BATCH_EXPORT_ENDPOINT=http://${MINIO_HOST}:${MINIO_PORT}
LANGFUSE_S3_BATCH_EXPORT_EXTERNAL_ENDPOINT=http://${MINIO_HOST}:${MINIO_PORT}
LANGFUSE_S3_BATCH_EXPORT_ACCESS_KEY_ID=${MINIO_ACCESS_KEY}
LANGFUSE_S3_BATCH_EXPORT_SECRET_ACCESS_KEY=${MINIO_SECRET_KEY}
LANGFUSE_S3_BATCH_EXPORT_FORCE_PATH_STYLE=true

# ============================================
# Security Configuration
# ============================================
NEXTAUTH_URL=http://localhost:19532
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
SALT=${SALT}
ENCRYPTION_KEY=${ENCRYPTION_KEY}

# ============================================
# Application Configuration
# ============================================
TELEMETRY_ENABLED=true
LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES=true
EOF

echo -e "${GREEN}✓ .env file updated${NC}"
echo ""

# Save secrets to .secrets file for backup
cat > .secrets << EOF
# Langfuse Security Secrets
# Generated: $(date)
# KEEP THIS FILE SECURE AND DO NOT COMMIT TO GIT

NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
SALT=${SALT}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}

# External Services
PG_HOST=${PG_HOST}
PG_PASSWORD=${PG_PASSWORD}
REDIS_HOST=${REDIS_HOST}
REDIS_PASSWORD=${REDIS_PASSWORD}
MINIO_HOST=${MINIO_HOST}
MINIO_ACCESS_KEY=${MINIO_ACCESS_KEY}
MINIO_SECRET_KEY=${MINIO_SECRET_KEY}
EOF
chmod 600 .secrets

echo -e "${GREEN}✓ Secrets saved to .secrets (chmod 600)${NC}"
echo ""

# Step 4: Initialize MinIO bucket
echo -e "${YELLOW}Step 4: Initializing MinIO bucket...${NC}"

# Try to create bucket using mc (MinIO Client)
if command -v mc &> /dev/null; then
    echo "Using MinIO client to create bucket..."
    
    # Configure mc alias
    if mc alias set langfuse-minio "http://${MINIO_HOST}:${MINIO_PORT}" "${MINIO_ACCESS_KEY}" "${MINIO_SECRET_KEY}" &>/dev/null; then
        # Try to create bucket
        if mc mb "langfuse-minio/${MINIO_BUCKET}" &>/dev/null; then
            echo -e "${GREEN}✓ Bucket '${MINIO_BUCKET}' created${NC}"
        else
            # Check if bucket already exists
            if mc ls "langfuse-minio/${MINIO_BUCKET}" &>/dev/null; then
                echo -e "${YELLOW}⚠️  Bucket '${MINIO_BUCKET}' already exists (OK)${NC}"
            else
                echo -e "${RED}✗ Failed to create bucket '${MINIO_BUCKET}'${NC}"
                echo -e "${YELLOW}   Please create it manually at http://${MINIO_HOST}:9001${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  Could not connect to MinIO${NC}"
        echo -e "${YELLOW}   Please create bucket '${MINIO_BUCKET}' manually at http://${MINIO_HOST}:9001${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  MinIO client (mc) not installed${NC}"
    echo -e "${YELLOW}   Please create bucket '${MINIO_BUCKET}' manually at http://${MINIO_HOST}:9001${NC}"
    echo -e "${BLUE}   Install mc: https://min.io/docs/minio/linux/reference/minio-mc.html${NC}"
fi

echo ""

# Step 5: Pull and start services
echo -e "${YELLOW}Step 5: Starting Langfuse services...${NC}"

compose pull
echo ""

compose up -d

echo ""

# Step 6: Wait and check service health
echo -e "${YELLOW}Step 6: Checking service health...${NC}"
echo "Waiting for services to start..."
sleep 10

# Check if containers are running
if compose ps | grep -q "Up"; then
    echo -e "${GREEN}✓ Containers are running${NC}"
else
    echo -e "${RED}✗ Some containers failed to start${NC}"
    echo "Run '$(printf '%s ' "${COMPOSE_CMD[@]}")logs' to see errors"
fi

# Check ClickHouse
if curl -s http://localhost:8123/ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ ClickHouse is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  ClickHouse is not responding yet (may need more time)${NC}"
fi

# Check Langfuse web
if curl -s -o /dev/null -w "%{http_code}" http://localhost:19532 | grep -q "200\|302\|301"; then
    echo -e "${GREEN}✓ Langfuse web is responding${NC}"
else
    echo -e "${YELLOW}⚠️  Langfuse web is not responding yet (may need more time)${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Langfuse Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Service Information:${NC}"
echo "  Langfuse Web:     http://localhost:19532"
echo "  ClickHouse HTTP:  http://localhost:8123"
echo ""
echo -e "${BLUE}External Services:${NC}"
echo "  PostgreSQL:  ${PG_HOST}:${PG_PORT}"
echo "  Redis:       ${REDIS_HOST}:${REDIS_PORT}"
echo "  MinIO:       ${MINIO_HOST}:${MINIO_PORT}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Wait 30-60 seconds for full initialization"
echo "  2. View logs:         $(printf '%s ' "${COMPOSE_CMD[@]}")logs -f"
echo "  3. Check status:      $(printf '%s ' "${COMPOSE_CMD[@]}")ps"
echo "  4. Open Langfuse:     http://localhost:19532"
echo ""
echo -e "${BLUE}Management Commands:${NC}"
echo "  View logs:        $(printf '%s ' "${COMPOSE_CMD[@]}")logs -f langfuse-web"
echo "  Restart:          $(printf '%s ' "${COMPOSE_CMD[@]}")restart"
echo "  Stop:             $(printf '%s ' "${COMPOSE_CMD[@]}")down"
echo "  Cleanup volumes:  $(printf '%s ' "${COMPOSE_CMD[@]}")down -v"
echo ""
echo -e "${YELLOW}Important Files:${NC}"
echo "  Configuration:    .env"
echo "  Secrets backup:   .secrets (chmod 600)"
echo ""
echo -e "${YELLOW}Security Note:${NC}"
echo "  Make sure to keep .env and .secrets files secure!"
echo "  Do NOT commit them to version control."
echo ""
