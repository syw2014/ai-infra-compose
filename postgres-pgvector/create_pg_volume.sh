#!/usr/bin/env bash
###
 # @Author: Jerry Shi
 # @Email: jerryshi0110@gmail.com
 # @Date: 2026-02-05 22:29:44
 # @LastEditors: Jerry Shi
 # @LastEditTime: 2026-02-05 22:29:59
 # @Description: file content
### 
set -e

# 进入 docker-compose.yml 所在目录再执行
BASE_DIR="$(pwd)"
VOLUME_DIR="$BASE_DIR/volumes/postgres"

echo "▶ Creating postgres volume directory..."
echo "  Path: $VOLUME_DIR"

# 1. 创建目录
mkdir -p "$VOLUME_DIR"

# 2. 设置安全权限（Postgres 推荐）
chmod 700 "$VOLUME_DIR"

# 3. 显示结果
echo "✔ Done."
ls -ld "$VOLUME_DIR"

echo
echo "⚠️  注意："
echo " - 不要手动 chown（pgvector 镜像会在首次启动时处理）"
echo " - 确保该目录不会被 git 提交（已加入 .gitignore）"
