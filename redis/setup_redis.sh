#!/bin/bash
###
 # @Author: Jerry Shi
 # @Email: jerryshi0110@gmail.com
 # @Date: 2026-02-06 10:41:35
 # @LastEditors: Jerry Shi
 # @LastEditTime: 2026-02-06 10:41:38
 # @Description: file content
### 

# Redis 部署准备脚本

echo "开始准备 Redis 部署环境..."

# 1. 创建本地目录
echo "创建数据目录..."
mkdir -p ./volumes/redis

# 2. 设置权限
echo "设置目录权限..."
sudo chown -R 999:999 ./volumes/redis

echo "✓ 目录创建完成"
echo "✓ 权限设置完成"
echo ""
echo "现在可以运行: docker-compose up -d"