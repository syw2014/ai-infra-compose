#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-03-02
# @Description: One-click deploy script for Xinference CPU (embedding & rerank models)
###

set -e
cd "$(dirname "$0")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Xinference CPU Deploy${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Prepare .env
echo -e "${YELLOW}Step 1: Preparing environment configuration...${NC}"

if [ ! -f ".env" ]; then
    cp env.example .env
    echo -e "${GREEN}✓ .env created from env.example${NC}"
    echo -e "${YELLOW}  Review .env and adjust XINFERENCE_MODEL_SRC if needed.${NC}"
else
    echo -e "${YELLOW}⚠️  .env already exists, skipping copy.${NC}"
fi

echo ""

# Step 2: Create volume directories
echo -e "${YELLOW}Step 2: Creating volume directories...${NC}"

chmod +x create_xinference_volumes.sh
./create_xinference_volumes.sh

echo ""

# Step 3: Pull image and start service
echo -e "${YELLOW}Step 3: Pulling Xinference image...${NC}"

sudo docker compose pull

echo ""
echo -e "${YELLOW}Step 4: Starting Xinference service...${NC}"

sudo docker compose up -d

echo ""

# Step 5: Wait and health check
echo -e "${YELLOW}Step 5: Waiting for Xinference to become ready...${NC}"
echo "This may take up to 60 seconds on first launch..."

READY=false
for i in $(seq 1 12); do
    sleep 5
    if curl -sf http://localhost:9997/v1/models > /dev/null 2>&1; then
        READY=true
        break
    fi
    echo -e "  Waiting... (${i}/12)"
done

echo ""

if [ "$READY" = true ]; then
    echo -e "${GREEN}✓ Xinference is healthy and responding${NC}"
else
    echo -e "${YELLOW}⚠️  Xinference has not responded yet (may still be initializing)${NC}"
    echo -e "${YELLOW}   Run: docker compose logs -f xinference${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Xinference CPU Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Service Information:${NC}"
echo "  Xinference API:  http://localhost:9997"
echo "  Xinference UI:   http://localhost:9997/ui"
echo "  OpenAI-compat:   http://localhost:9997/v1"
echo ""
echo -e "${BLUE}Quick Model Launch Examples:${NC}"
echo "  # Launch BGE-M3 embedding model (ModelScope):"
echo "  xinference launch --model-name bge-m3 --model-type embedding"
echo ""
echo "  # Launch BGE-reranker-v2-m3 rerank model (ModelScope):"
echo "  xinference launch --model-name bge-reranker-v2-m3 --model-type rerank"
echo ""
echo "  # Or use the web UI to manage models:"
echo "  open http://localhost:9997/ui"
echo ""
echo -e "${BLUE}Management Commands:${NC}"
echo "  View logs:        docker compose logs -f xinference"
echo "  Restart:          docker compose restart xinference"
echo "  Stop:             docker compose down"
echo "  Cleanup volumes:  docker compose down -v"
echo ""
echo -e "${BLUE}Data Persistence:${NC}"
echo "  Xinference home:  ./volumes/xinference"
echo "  HF cache:         ./volumes/models/huggingface"
echo "  ModelScope cache: ./volumes/models/modelscope"
echo ""
echo -e "${YELLOW}Note:${NC}"
echo "  You can pre-download models before startup to avoid online pulls:"
echo "  ./download_model.sh --source modelscope --preset bge-m3"
echo "  ./download_model.sh --source modelscope --preset bge-reranker-v2-m3"
echo "  Then start Xinference with the same XINFERENCE_MODEL_SRC value."
echo "  Model size varies: BGE-M3 ~2.3 GB, BGE-reranker-v2-m3 ~1.1 GB."
echo "  Set XINFERENCE_MODEL_SRC=modelscope in .env for faster downloads in China."
echo ""
