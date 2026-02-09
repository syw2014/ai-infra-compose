#!/bin/bash
###
# Langfuse 部署诊断脚本
# 在服务器上运行此脚本检查所有服务状态
###

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Langfuse 部署状态诊断${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 检查 Docker 容器状态
echo -e "${YELLOW}1. Docker 容器状态${NC}"
echo "----------------------------------------"
docker ps --filter "name=langfuse" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 2. 检查所有服务详细状态
echo -e "${YELLOW}2. Langfuse 服务详细状态${NC}"
echo "----------------------------------------"
cd /path/to/langfuse  # 替换为你的实际路径
docker compose ps
echo ""

# 3. 检查 ClickHouse
echo -e "${YELLOW}3. ClickHouse 健康检查${NC}"
echo "----------------------------------------"
if curl -sf http://localhost:19533/ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ ClickHouse HTTP 正常 (port 19533)${NC}"
    curl -s http://localhost:19533/ping
else
    echo -e "${RED}✗ ClickHouse HTTP 无响应${NC}"
fi
echo ""

# 4. 检查外部依赖服务
echo -e "${YELLOW}4. 外部依赖服务检查${NC}"
echo "----------------------------------------"

check_port() {
    local name=$1
    local port=$2
    if timeout 2 bash -c "echo > /dev/tcp/localhost/$port" 2>/dev/null; then
        echo -e "${GREEN}✓ $name (port $port) 可访问${NC}"
    else
        echo -e "${RED}✗ $name (port $port) 不可访问${NC}"
    fi
}

check_port "PostgreSQL" "5432"
check_port "Redis" "19531"
check_port "MinIO API" "9000"
check_port "MinIO Console" "9001"
echo ""

# 5. 检查 Langfuse Web
echo -e "${YELLOW}5. Langfuse Web 服务检查${NC}"
echo "----------------------------------------"
if curl -sf http://localhost:19532 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Langfuse Web 正常响应 (port 19532)${NC}"
    curl -I http://localhost:19532 2>&1 | head -1
else
    echo -e "${RED}✗ Langfuse Web 无响应${NC}"
    echo "检查 langfuse-web 容器日志："
    docker logs langfuse-web --tail 30
fi
echo ""

# 6. 检查环境变量配置
echo -e "${YELLOW}6. 环境变量配置检查${NC}"
echo "----------------------------------------"
if [ -f .env ]; then
    echo "DATABASE_URL: $(grep DATABASE_URL .env | cut -d'=' -f2 | sed 's/:[^:]*@/:***@/')"
    echo "REDIS_CONNECTION_STRING: $(grep REDIS_CONNECTION_STRING .env | cut -d'=' -f2 | sed 's/:[^:]*@/:***@/')"
    echo "MINIO_ENDPOINT: $(grep MINIO_ENDPOINT .env | grep -v '#' | head -1 | cut -d'=' -f2)"
    echo "WEB_HOST_PORT: $(grep WEB_HOST_PORT .env | grep -v '#' | head -1 | cut -d'=' -f2)"
else
    echo -e "${RED}✗ .env 文件不存在${NC}"
fi
echo ""

# 7. 测试容器内部连接
echo -e "${YELLOW}7. 容器内部连接测试${NC}"
echo "----------------------------------------"
if docker ps | grep -q langfuse-web; then
    echo "测试从 langfuse-web 容器连接外部服务："
    
    echo -n "PostgreSQL (5432): "
    if docker exec langfuse-web sh -c "timeout 2 nc -zv host.docker.internal 5432" 2>&1 | grep -q succeeded; then
        echo -e "${GREEN}✓ 成功${NC}"
    else
        echo -e "${RED}✗ 失败${NC}"
    fi
    
    echo -n "Redis (19531): "
    if docker exec langfuse-web sh -c "timeout 2 nc -zv host.docker.internal 19531" 2>&1 | grep -q succeeded; then
        echo -e "${GREEN}✓ 成功${NC}"
    else
        echo -e "${RED}✗ 失败${NC}"
    fi
    
    echo -n "MinIO (9000): "
    if docker exec langfuse-web sh -c "timeout 2 nc -zv host.docker.internal 9000" 2>&1 | grep -q succeeded; then
        echo -e "${GREEN}✓ 成功${NC}"
    else
        echo -e "${RED}✗ 失败${NC}"
    fi
else
    echo -e "${YELLOW}⚠ langfuse-web 容器未运行，跳过连接测试${NC}"
fi
echo ""

# 8. 检查数据库
echo -e "${YELLOW}8. PostgreSQL 数据库检查${NC}"
echo "----------------------------------------"
if docker ps | grep -q postgres; then
    echo "检查 langfuse 数据库是否存在："
    if docker exec postgres psql -U postgres -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw langfuse; then
        echo -e "${GREEN}✓ 数据库 'langfuse' 存在${NC}"
    else
        echo -e "${RED}✗ 数据库 'langfuse' 不存在${NC}"
        echo "创建命令: docker exec postgres psql -U postgres -c \"CREATE DATABASE langfuse;\""
    fi
else
    echo -e "${YELLOW}⚠ PostgreSQL 容器未运行${NC}"
fi
echo ""

# 9. 检查 MinIO bucket
echo -e "${YELLOW}9. MinIO Bucket 检查${NC}"
echo "----------------------------------------"
MINIO_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i minio | head -n 1)
if [ -n "$MINIO_CONTAINER" ]; then
    echo "MinIO 容器: $MINIO_CONTAINER"
    if docker exec "$MINIO_CONTAINER" mc ls local/langfuse 2>/dev/null | grep -q .; then
        echo -e "${GREEN}✓ Bucket 'langfuse' 存在${NC}"
    else
        echo -e "${YELLOW}⚠ Bucket 'langfuse' 可能不存在${NC}"
        echo "创建命令: docker exec $MINIO_CONTAINER mc mb local/langfuse"
    fi
else
    echo -e "${YELLOW}⚠ MinIO 容器未找到${NC}"
fi
echo ""

# 10. 最近日志
echo -e "${YELLOW}10. 服务最近日志（最后20行）${NC}"
echo "----------------------------------------"
echo ""
echo -e "${BLUE}=== Langfuse Web 日志 ===${NC}"
docker logs langfuse-web --tail 20 2>&1
echo ""
echo -e "${BLUE}=== Langfuse Worker 日志 ===${NC}"
docker logs langfuse-worker --tail 20 2>&1
echo ""
echo -e "${BLUE}=== ClickHouse 日志 ===${NC}"
docker logs langfuse-clickhouse --tail 10 2>&1
echo ""

# 总结
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  诊断完成${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "查看完整日志："
echo "  docker logs -f langfuse-web"
echo "  docker logs -f langfuse-worker"
echo "  docker logs -f langfuse-clickhouse"
echo ""
echo "重启服务："
echo "  cd /path/to/langfuse && docker compose restart"
echo ""
