#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-02-09
# @Description: Quick setup script for Langfuse with external components
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
echo -e "${BLUE}  Langfuse Quick Setup${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env from template...${NC}"
    cp env.example .env
    echo -e "${GREEN}✓ .env file created${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Please edit .env file and configure:${NC}"
    echo "  1. POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB"
    echo "  2. REDIS_PASSWORD"
    echo "  3. MINIO_ACCESS_KEY, MINIO_SECRET_KEY"
    echo "  4. Generate security keys (see below)"
    echo ""
    echo -e "${BLUE}Generate security keys with:${NC}"
    echo "  openssl rand -hex 32  # For NEXTAUTH_SECRET"
    echo "  openssl rand -hex 32  # For SALT"
    echo "  openssl rand -hex 32  # For ENCRYPTION_KEY"
    echo "  openssl rand -base64 32 | tr -d '=+/'  # For CLICKHOUSE_PASSWORD"
    echo ""
    exit 0
fi

# Source .env to check configuration
source .env

# Check if required variables are configured
MISSING_CONFIG=false

check_var() {
    local var_name=$1
    local var_value=$2
    local default_value=$3
    
    if [ -z "$var_value" ] || [ "$var_value" = "$default_value" ]; then
        echo -e "${RED}✗ $var_name is not configured${NC}"
        MISSING_CONFIG=true
    else
        echo -e "${GREEN}✓ $var_name is configured${NC}"
    fi
}

echo -e "${YELLOW}Checking configuration...${NC}"
echo ""

# Check PostgreSQL config
check_var "POSTGRES_USER" "$POSTGRES_USER" ""
check_var "POSTGRES_PASSWORD" "$POSTGRES_PASSWORD" "your_postgres_password"
check_var "POSTGRES_DB" "$POSTGRES_DB" ""

# Check Redis config
check_var "REDIS_PASSWORD" "$REDIS_PASSWORD" "your_redis_password"

# Check MinIO config
check_var "MINIO_ACCESS_KEY" "$MINIO_ACCESS_KEY" "minioadmin"
check_var "MINIO_SECRET_KEY" "$MINIO_SECRET_KEY" "minioadmin"

# Check security keys
check_var "NEXTAUTH_SECRET" "$NEXTAUTH_SECRET" "AUTO_GENERATED_BY_DEPLOY_SCRIPT"
check_var "SALT" "$SALT" "AUTO_GENERATED_BY_DEPLOY_SCRIPT"
check_var "ENCRYPTION_KEY" "$ENCRYPTION_KEY" "AUTO_GENERATED_BY_DEPLOY_SCRIPT"
check_var "CLICKHOUSE_PASSWORD" "$CLICKHOUSE_PASSWORD" "AUTO_GENERATED_BY_DEPLOY_SCRIPT"

echo ""

if [ "$MISSING_CONFIG" = true ]; then
    echo -e "${RED}Configuration incomplete!${NC}"
    echo -e "${YELLOW}Please edit .env file and configure the missing values.${NC}"
    exit 1
fi

echo -e "${GREEN}All required configuration is set!${NC}"
echo ""

# Check external services
echo -e "${YELLOW}Checking external services...${NC}"
echo ""

check_service() {
    local service=$1
    local host=$2
    local port=$3
    
    if nc -zv $host $port 2>&1 | grep -q succeeded; then
        echo -e "${GREEN}✓ $service is reachable at $host:$port${NC}"
        return 0
    else
        echo -e "${RED}✗ $service is NOT reachable at $host:$port${NC}"
        return 1
    fi
}

SERVICES_OK=true

# Check PostgreSQL (convert host.docker.internal to localhost for host check)
check_service "PostgreSQL" "localhost" "$POSTGRES_PORT" || SERVICES_OK=false
check_service "Redis" "localhost" "$REDIS_PORT" || SERVICES_OK=false
check_service "MinIO" "localhost" "9000" || SERVICES_OK=false

echo ""

if [ "$SERVICES_OK" = false ]; then
    echo -e "${RED}Some services are not reachable!${NC}"
    echo -e "${YELLOW}Please ensure PostgreSQL, Redis, and MinIO are running on this server.${NC}"
    exit 1
fi

echo -e "${GREEN}All external services are reachable!${NC}"
echo ""

# Create PostgreSQL database
echo -e "${YELLOW}Preparing PostgreSQL database...${NC}"

if docker exec postgres psql -U "$POSTGRES_USER" -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$POSTGRES_DB"; then
    echo -e "${YELLOW}⚠️  Database '$POSTGRES_DB' already exists${NC}"
else
    if PGPASSWORD="$POSTGRES_PASSWORD" docker exec -i postgres psql -U "$POSTGRES_USER" -c "CREATE DATABASE $POSTGRES_DB;" 2>/dev/null; then
        echo -e "${GREEN}✓ Database '$POSTGRES_DB' created${NC}"
    else
        echo -e "${RED}✗ Failed to create database${NC}"
        echo -e "${YELLOW}You may need to create it manually:${NC}"
        echo "  docker exec -it postgres psql -U $POSTGRES_USER"
        echo "  CREATE DATABASE $POSTGRES_DB;"
    fi
fi

echo ""

# Create MinIO bucket
echo -e "${YELLOW}Preparing MinIO bucket...${NC}"

# Try to find MinIO container
MINIO_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i minio | head -n 1)

if [ -z "$MINIO_CONTAINER" ]; then
    echo -e "${YELLOW}⚠️  MinIO container not found${NC}"
    echo -e "${YELLOW}Please create bucket '$MINIO_BUCKET' manually at http://localhost:9001${NC}"
else
    echo "Found MinIO container: $MINIO_CONTAINER"
    
    # Configure mc alias and create bucket
    if docker exec "$MINIO_CONTAINER" mc alias set local http://localhost:9000 "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" 2>/dev/null; then
        if docker exec "$MINIO_CONTAINER" mc mb local/$MINIO_BUCKET 2>/dev/null; then
            echo -e "${GREEN}✓ Bucket '$MINIO_BUCKET' created${NC}"
        else
            echo -e "${YELLOW}⚠️  Bucket '$MINIO_BUCKET' may already exist${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Failed to configure MinIO${NC}"
        echo -e "${YELLOW}Please create bucket '$MINIO_BUCKET' manually at http://localhost:9001${NC}"
    fi
fi

echo ""

# Pull images
echo -e "${YELLOW}Pulling Docker images...${NC}"
docker compose pull

echo ""

# Start services
echo -e "${YELLOW}Starting Langfuse services...${NC}"
docker compose up -d

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  Langfuse Setup Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${BLUE}Service URLs:${NC}"
echo "  Langfuse Web:     http://localhost:$WEB_HOST_PORT"
echo "  ClickHouse API:   http://localhost:$CLICKHOUSE_HTTP_PORT"
echo "  MinIO Console:    http://localhost:9001"
echo ""
echo -e "${BLUE}Check status:${NC}"
echo "  docker compose ps"
echo "  docker compose logs -f"
echo ""
echo -e "${BLUE}Health check:${NC}"
echo "  curl http://localhost:$CLICKHOUSE_HTTP_PORT/ping"
echo "  curl -I http://localhost:$WEB_HOST_PORT"
echo ""
