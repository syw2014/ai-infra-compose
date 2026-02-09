#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-02-09
# @Description: Restore script for Langfuse
###

set -e
cd "$(dirname "$0")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKUP_DIR="./backups"

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}  Langfuse Restore${NC}"
echo -e "${BLUE}==================================${NC}"
echo ""

if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}Error: Backup directory not found${NC}"
    exit 1
fi

echo -e "${YELLOW}Available backups:${NC}"
ls -lh "$BACKUP_DIR"/*.sql.gz 2>/dev/null || echo "No database backups found"

echo ""
read -p "Enter backup file name (without path, e.g., langfuse_db_20260209_120000.sql.gz): " BACKUP_FILE

if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Backup file not found${NC}"
    exit 1
fi

echo ""
echo -e "${RED}WARNING: This will DROP and recreate the langfuse database!${NC}"
read -p "Are you sure? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

echo ""
echo -e "${YELLOW}Stopping Langfuse services...${NC}"
docker compose down

echo -e "${YELLOW}Dropping and recreating database...${NC}"
docker exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS langfuse;"
docker exec postgres psql -U postgres -c "CREATE DATABASE langfuse;"

echo -e "${YELLOW}Restoring database from backup...${NC}"
gunzip -c "$BACKUP_DIR/$BACKUP_FILE" | docker exec -i postgres psql -U postgres -d langfuse

echo -e "${GREEN}✓ Database restored${NC}"

echo ""
echo -e "${YELLOW}Starting Langfuse services...${NC}"
docker compose up -d

echo ""
echo -e "${GREEN}Restore completed!${NC}"
echo "Run ./health_check.sh to verify services"
