#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-02-06 10:41:47
# @LastEditors: Jerry Shi
# @LastEditTime: 2026-04-02
# @Description: One-click deploy script for Redis
###

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$SCRIPT_DIR"
source "${ROOT_DIR}/scripts/compose_cmd.sh"

chmod +x setup_redis.sh
./setup_redis.sh

COMPOSE_USE_SUDO="${COMPOSE_USE_SUDO:-1}"
compose up -d

echo ""
echo "✓ Redis deployed."
echo "  Port: 19531 (host) -> 6379 (container)"
echo "  Config: ./redis.conf"
echo "  Data:  ./volumes/redis"
