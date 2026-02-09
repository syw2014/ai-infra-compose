#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-02-09
# @Description: Test script to validate deployment setup
###

set -e
cd "$(dirname "$0")"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Langfuse Setup Validation${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

ERRORS=0

check_file() {
    local file=$1
    local desc=$2
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ $desc exists${NC}"
    else
        echo -e "${RED}✗ $desc missing${NC}"
        ((ERRORS++))
    fi
}

check_executable() {
    local file=$1
    local desc=$2
    
    if [ -x "$file" ]; then
        echo -e "${GREEN}✓ $desc is executable${NC}"
    else
        echo -e "${RED}✗ $desc not executable${NC}"
        ((ERRORS++))
    fi
}

echo -e "${YELLOW}Checking scripts...${NC}"
check_file "deploy_langfuse.sh" "Deployment script"
check_executable "deploy_langfuse.sh" "Deployment script"
check_file "manage.sh" "Management script"
check_executable "manage.sh" "Management script"
check_file "health_check.sh" "Health check script"
check_executable "health_check.sh" "Health check script"
check_file "backup.sh" "Backup script"
check_executable "backup.sh" "Backup script"
check_file "restore.sh" "Restore script"
check_executable "restore.sh" "Restore script"

echo ""
echo -e "${YELLOW}Checking documentation...${NC}"
check_file "README.md" "Main README"
check_file "README-DETAILED.md" "Detailed README"
check_file "QUICKSTART.md" "Quick reference"
check_file "env.example" "Environment template"

echo ""
echo -e "${YELLOW}Checking configuration...${NC}"
check_file ".gitignore" "Git ignore file"

echo ""
echo -e "${YELLOW}Checking dependencies...${NC}"

if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker is installed${NC}"
    docker --version
else
    echo -e "${RED}✗ Docker is not installed${NC}"
    ((ERRORS++))
fi

if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose is available${NC}"
else
    echo -e "${RED}✗ Docker Compose is not available${NC}"
    ((ERRORS++))
fi

if command -v wget &> /dev/null; then
    echo -e "${GREEN}✓ wget is installed${NC}"
else
    echo -e "${YELLOW}⚠ wget is not installed (needed for download)${NC}"
fi

if command -v openssl &> /dev/null; then
    echo -e "${GREEN}✓ openssl is installed${NC}"
else
    echo -e "${RED}✗ openssl is not installed (needed for key generation)${NC}"
    ((ERRORS++))
fi

echo ""
echo -e "${YELLOW}Checking for running dependencies...${NC}"

if docker ps 2>/dev/null | grep -q postgres; then
    echo -e "${GREEN}✓ PostgreSQL container is running${NC}"
else
    echo -e "${YELLOW}⚠ PostgreSQL container not found (required for deployment)${NC}"
fi

if docker ps 2>/dev/null | grep -q redis; then
    echo -e "${GREEN}✓ Redis container is running${NC}"
else
    echo -e "${YELLOW}⚠ Redis container not found (required for deployment)${NC}"
fi

if docker ps 2>/dev/null | grep -q minio; then
    echo -e "${GREEN}✓ MinIO container is running${NC}"
else
    echo -e "${YELLOW}⚠ MinIO container not found (required for deployment)${NC}"
fi

echo ""
echo -e "${BLUE}================================${NC}"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All validation checks passed!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Ensure PostgreSQL, Redis, and MinIO are running"
    echo "  2. Run: ./deploy_langfuse.sh"
    echo "  3. Access: http://localhost:3000"
    exit 0
else
    echo -e "${RED}✗ Found $ERRORS errors${NC}"
    echo ""
    echo -e "${YELLOW}Please fix the errors above before deploying.${NC}"
    exit 1
fi
