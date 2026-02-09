#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-02-09
# @Description: Backup script for Langfuse
###

set -e
cd "$(dirname "$0")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}  Langfuse Backup${NC}"
echo -e "${BLUE}==================================${NC}"
echo ""

echo -e "${YELLOW}Backing up PostgreSQL database...${NC}"
POSTGRES_PASSWORD=$(grep "DATABASE_URL" .env | sed 's/.*postgres:\([^@]*\)@.*/\1/')
docker exec postgres pg_dump -U postgres langfuse | gzip > "$BACKUP_DIR/langfuse_db_${TIMESTAMP}.sql.gz"
echo -e "${GREEN}✓ Database backed up to $BACKUP_DIR/langfuse_db_${TIMESTAMP}.sql.gz${NC}"

echo ""
echo -e "${YELLOW}Backing up configuration files...${NC}"
tar -czf "$BACKUP_DIR/langfuse_config_${TIMESTAMP}.tar.gz" .env .secrets docker-compose.yml 2>/dev/null || true
echo -e "${GREEN}✓ Config backed up to $BACKUP_DIR/langfuse_config_${TIMESTAMP}.tar.gz${NC}"

echo ""
echo -e "${YELLOW}Cleaning up old backups (keeping last 7 days)...${NC}"
find "$BACKUP_DIR" -name "langfuse_*.sql.gz" -mtime +7 -delete
find "$BACKUP_DIR" -name "langfuse_*.tar.gz" -mtime +7 -delete
echo -e "${GREEN}✓ Old backups cleaned up${NC}"

echo ""
echo -e "${GREEN}Backup completed!${NC}"
echo ""
ls -lh "$BACKUP_DIR"
