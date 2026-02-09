#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-02-09
# @Description: Management script for Langfuse
###

set -e
cd "$(dirname "$0")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

show_help() {
    echo -e "${BLUE}Langfuse Management Script${NC}"
    echo ""
    echo "Usage: ./manage.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start         - Start Langfuse services"
    echo "  stop          - Stop Langfuse services"
    echo "  restart       - Restart Langfuse services"
    echo "  status        - Show service status"
    echo "  logs          - View all logs"
    echo "  logs-web      - View web service logs"
    echo "  logs-worker   - View worker service logs"
    echo "  logs-click    - View ClickHouse logs"
    echo "  health        - Run health check"
    echo "  backup        - Backup database and config"
    echo "  restore       - Restore from backup"
    echo "  upgrade       - Pull latest images and restart"
    echo "  clean         - Stop and remove containers (keeps data)"
    echo "  purge         - Stop and remove everything (WARNING: deletes data!)"
    echo "  shell-web     - Enter web container shell"
    echo "  shell-click   - Enter ClickHouse container shell"
    echo ""
}

case "$1" in
    start)
        echo -e "${YELLOW}Starting Langfuse services...${NC}"
        docker compose up -d
        echo -e "${GREEN}✓ Services started${NC}"
        ;;
    
    stop)
        echo -e "${YELLOW}Stopping Langfuse services...${NC}"
        docker compose stop
        echo -e "${GREEN}✓ Services stopped${NC}"
        ;;
    
    restart)
        echo -e "${YELLOW}Restarting Langfuse services...${NC}"
        docker compose restart
        echo -e "${GREEN}✓ Services restarted${NC}"
        ;;
    
    status)
        docker compose ps
        ;;
    
    logs)
        docker compose logs -f
        ;;
    
    logs-web)
        docker compose logs -f langfuse-web
        ;;
    
    logs-worker)
        docker compose logs -f langfuse-worker
        ;;
    
    logs-click)
        docker compose logs -f clickhouse
        ;;
    
    health)
        ./health_check.sh
        ;;
    
    backup)
        ./backup.sh
        ;;
    
    restore)
        ./restore.sh
        ;;
    
    upgrade)
        echo -e "${YELLOW}Pulling latest images...${NC}"
        docker compose pull
        echo -e "${YELLOW}Restarting services...${NC}"
        docker compose up -d
        echo -e "${GREEN}✓ Upgrade complete${NC}"
        ;;
    
    clean)
        echo -e "${YELLOW}Stopping and removing containers...${NC}"
        docker compose down
        echo -e "${GREEN}✓ Containers removed (data preserved)${NC}"
        ;;
    
    purge)
        echo -e "${RED}WARNING: This will delete all data!${NC}"
        read -p "Are you sure? (yes/no): " CONFIRM
        if [ "$CONFIRM" = "yes" ]; then
            docker compose down -v
            echo -e "${GREEN}✓ Everything removed${NC}"
        else
            echo "Cancelled"
        fi
        ;;
    
    shell-web)
        docker compose exec langfuse-web sh
        ;;
    
    shell-click)
        docker compose exec clickhouse sh
        ;;
    
    *)
        show_help
        ;;
esac
