#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-02-09
# @Description: Health check script for Langfuse
###

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}  Langfuse Health Check${NC}"
echo -e "${BLUE}==================================${NC}"
echo ""

check_service() {
    local name=$1
    local url=$2
    
    if curl -sf "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $name: Healthy${NC}"
        return 0
    else
        echo -e "${RED}✗ $name: Unhealthy${NC}"
        return 1
    fi
}

check_tcp() {
    local name=$1
    local host=$2
    local port=$3
    
    if timeout 2 bash -c "echo > /dev/tcp/$host/$port" 2>/dev/null; then
        echo -e "${GREEN}✓ $name: Reachable${NC}"
        return 0
    else
        echo -e "${RED}✗ $name: Unreachable${NC}"
        return 1
    fi
}

echo -e "${YELLOW}Checking Langfuse services...${NC}"
check_service "Langfuse Web" "http://localhost:3000"
check_service "ClickHouse HTTP" "http://localhost:8123/ping"

echo ""
echo -e "${YELLOW}Checking dependencies...${NC}"
check_tcp "PostgreSQL" "localhost" "5432"
check_tcp "Redis" "localhost" "19531"
check_tcp "MinIO" "localhost" "9000"

echo ""
echo -e "${YELLOW}Container status:${NC}"
docker compose ps

echo ""
echo -e "${BLUE}To view logs:${NC}"
echo "  docker compose logs -f langfuse-web"
echo "  docker compose logs -f langfuse-worker"
echo "  docker compose logs -f clickhouse"
