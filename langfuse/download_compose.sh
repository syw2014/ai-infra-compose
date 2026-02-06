#!/bin/bash
#!/bin/bash
set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  步骤1: 下载 Langfuse 官方文件${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 工作目录
WORKDIR=./
mkdir -p $WORKDIR
cd $WORKDIR

echo -e "${GREEN}📁 工作目录: $WORKDIR${NC}"
echo ""

# 检查并备份已存在的文件
if [ -f "docker-compose.yml" ]; then
    BACKUP_NAME="docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}⚠️  docker-compose.yml 已存在，备份为 ${BACKUP_NAME}${NC}"
    mv docker-compose.yml "$BACKUP_NAME"
fi

if [ -f ".env.dev.example" ]; then
    BACKUP_NAME=".env.dev.example.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}⚠️  .env.dev.example 已存在，备份为 ${BACKUP_NAME}${NC}"
    mv .env.dev.example "$BACKUP_NAME"
fi

# 下载 docker-compose.yml
echo -e "${YELLOW}下载 docker-compose.yml...${NC}"
if wget -q https://raw.githubusercontent.com/langfuse/langfuse/main/docker-compose.yml; then
    echo -e "${GREEN}✅ docker-compose.yml 下载成功${NC}"
else
    echo -e "${RED}❌ docker-compose.yml 下载失败${NC}"
    exit 1
fi

# 下载 .env.dev.example
echo -e "${YELLOW}下载 .env.dev.example...${NC}"
if wget -q https://raw.githubusercontent.com/langfuse/langfuse/main/.env.dev.example; then
    echo -e "${GREEN}✅ .env.dev.example 下载成功${NC}"
else
    echo -e "${RED}❌ .env.dev.example 下载失败${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  下载完成！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${BLUE}已下载文件:${NC}"
ls -lh docker-compose.yml .env.dev.example
echo ""
echo -e "${BLUE}下一步: 运行 2-modify.sh 修改配置文件${NC}"
