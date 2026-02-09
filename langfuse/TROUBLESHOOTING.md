# Langfuse 部署问题排查清单

根据你提供的 ClickHouse 日志，容器已正常启动。请按以下步骤检查其他服务。

## 快速诊断命令

```bash
# 方法1: 运行诊断脚本（推荐）
cd langfuse
chmod +x diagnose.sh
./diagnose.sh
```

```bash
# 方法2: 手动检查
cd langfuse

# 1. 查看所有容器状态
docker compose ps

# 2. 查看 Web 服务日志
docker logs langfuse-web --tail 50

# 3. 查看 Worker 服务日志
docker logs langfuse-worker --tail 50

# 4. 测试服务访问
curl -I http://localhost:19532  # Langfuse Web
curl http://localhost:8123/ping  # ClickHouse
```

## 常见问题排查

### 问题1: Langfuse Web 无法启动

**症状**: `docker logs langfuse-web` 显示错误

**可能原因**:

1. **数据库连接失败**
   ```bash
   # 检查数据库是否存在
   docker exec postgres psql -U postgres -l | grep langfuse
   
   # 如果不存在，创建数据库
   docker exec postgres psql -U postgres -c "CREATE DATABASE langfuse;"
   ```

2. **环境变量配置错误**
   ```bash
   # 检查 .env 文件
   cat .env | grep -E "DATABASE_URL|REDIS|MINIO"
   
   # 确保格式正确
   # DATABASE_URL=postgresql://user:password@host.docker.internal:5432/langfuse
   # REDIS_CONNECTION_STRING=redis://:password@host.docker.internal:19531
   ```

3. **Redis 连接失败**
   ```bash
   # 测试 Redis 连接
   docker exec langfuse-web sh -c "nc -zv host.docker.internal 19531"
   
   # 如果失败，检查 Redis 是否运行
   docker ps | grep redis
   ```

4. **MinIO 连接失败**
   ```bash
   # 检查 MinIO bucket 是否存在
   MINIO_CONTAINER=$(docker ps --format "{{.Names}}" | grep minio | head -1)
   docker exec $MINIO_CONTAINER mc ls local/ | grep langfuse
   
   # 如果不存在，创建 bucket
   docker exec $MINIO_CONTAINER mc alias set local http://localhost:9000 minioadmin minioadmin
   docker exec $MINIO_CONTAINER mc mb local/langfuse
   ```

### 问题2: ClickHouse 已启动但 Web 无响应

**症状**: ClickHouse 日志正常，但 Langfuse Web 无法访问

**检查步骤**:

```bash
# 1. 确认 Web 容器是否运行
docker ps | grep langfuse-web

# 2. 如果未运行，查看退出原因
docker compose ps -a

# 3. 查看完整日志
docker logs langfuse-web

# 4. 检查端口映射
docker port langfuse-web
# 应该显示: 3000/tcp -> 0.0.0.0:19532
```

### 问题3: host.docker.internal 无法解析

**症状**: 日志中出现 "getaddrinfo ENOTFOUND host.docker.internal"

**解决方案**:

```bash
# 检查 docker-compose.yml 是否包含 extra_hosts
docker compose config | grep -A 2 extra_hosts

# 应该显示:
# extra_hosts:
#   - host.docker.internal:host-gateway

# 如果没有，检查 docker-compose.yml 文件
cat docker-compose.yml | grep -A 2 extra_hosts
```

### 问题4: 数据库迁移失败

**症状**: 日志中出现 "migration failed" 或数据库相关错误

**解决方案**:

```bash
# 1. 检查数据库连接
docker exec langfuse-web sh -c "nc -zv host.docker.internal 5432"

# 2. 手动测试数据库连接
docker exec postgres psql -U postgres -d langfuse -c "SELECT 1;"

# 3. 重启 Web 服务触发迁移
docker compose restart langfuse-web
docker logs -f langfuse-web
```

## 完整健康检查脚本

```bash
#!/bin/bash
# 保存为 quick_check.sh

echo "=== Langfuse 健康检查 ==="
echo ""

echo "1. 容器状态:"
docker ps --filter "name=langfuse" --format "table {{.Names}}\t{{.Status}}"
echo ""

echo "2. ClickHouse:"
curl -s http://localhost:8123/ping && echo " ✓" || echo " ✗"
echo ""

echo "3. Langfuse Web:"
curl -sI http://localhost:19532 | head -1
echo ""

echo "4. 外部服务:"
nc -zv localhost 5432 2>&1 | grep -q succeeded && echo "PostgreSQL: ✓" || echo "PostgreSQL: ✗"
nc -zv localhost 19531 2>&1 | grep -q succeeded && echo "Redis: ✓" || echo "Redis: ✗"
nc -zv localhost 9000 2>&1 | grep -q succeeded && echo "MinIO: ✓" || echo "MinIO: ✗"
echo ""

echo "5. 最近错误:"
docker logs langfuse-web --tail 20 2>&1 | grep -i error | tail -5
```

## 日志关键字搜索

查找特定错误:

```bash
# 数据库相关错误
docker logs langfuse-web 2>&1 | grep -i "database\|postgres\|connection"

# Redis 相关错误
docker logs langfuse-web 2>&1 | grep -i "redis"

# MinIO 相关错误
docker logs langfuse-web 2>&1 | grep -i "minio\|s3\|bucket"

# 认证相关错误
docker logs langfuse-web 2>&1 | grep -i "auth\|secret\|salt"

# 所有错误
docker logs langfuse-web 2>&1 | grep -i "error\|fail\|exception"
```

## 重启策略

如果服务异常:

```bash
# 1. 温和重启（保留容器）
docker compose restart

# 2. 完全重启（重建容器）
docker compose down
docker compose up -d

# 3. 强制重建（如果配置变更）
docker compose down
docker compose pull
docker compose up -d --force-recreate

# 4. 查看启动日志
docker compose logs -f
```

## 配置验证

确保 .env 文件配置正确:

```bash
# 必须配置的变量
grep -E "^(POSTGRES_|REDIS_|MINIO_|WEB_HOST_PORT|NEXTAUTH_|SALT|ENCRYPTION_KEY|CLICKHOUSE_PASSWORD)" .env

# 检查是否还有未替换的占位符
grep -E "your_|AUTO_GENERATED|changeme" .env
```

## 下一步

1. **运行诊断脚本**: `./diagnose.sh`
2. **查看完整日志**: 特别是 `docker logs langfuse-web`
3. **检查环境变量**: 确保所有密码和密钥已正确配置
4. **验证外部服务**: PostgreSQL、Redis、MinIO 都可访问
5. **检查数据库**: langfuse 数据库已创建
6. **检查 bucket**: MinIO 的 langfuse bucket 已创建

如果问题仍然存在，提供以下信息以便进一步诊断:
- `docker compose ps` 的输出
- `docker logs langfuse-web --tail 100` 的输出
- `.env` 文件的内容（隐藏敏感信息）
