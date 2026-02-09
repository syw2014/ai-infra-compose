# Langfuse 部署指南 - 复用现有基础组件

本指南说明如何基于官方 Langfuse 配置，修改为使用现有的 PostgreSQL、Redis 和 MinIO 服务。

## 📋 目录

- [前置条件](#前置条件)
- [部署步骤](#部署步骤)
  - [1. 下载官方配置文件](#1-下载官方配置文件)
  - [2. 修改 docker-compose.yml](#2-修改-docker-composeyml)
  - [3. 创建并配置 .env 文件](#3-创建并配置-env-文件)
  - [4. 生成安全密钥](#4-生成安全密钥)
  - [5. 准备数据库和存储](#5-准备数据库和存储)
  - [6. 启动服务](#6-启动服务)
- [配置说明](#配置说明)
- [常见问题](#常见问题)
- [管理命令](#管理命令)

---

## 前置条件

确保以下服务已运行：
- ✅ **PostgreSQL** (端口: 5432) - pgvector/pgvector:pg17
- ✅ **Redis** (端口: 19531) - redis:7-alpine
- ✅ **MinIO** (端口: 9000-9001) - minio/minio

确认服务状态：
```bash
docker ps | grep -E "postgres|redis|minio"
```

确认 Docker 版本（需要支持 host.docker.internal）：
```bash
docker version
# Linux 需要 Docker 20.10+ 版本
```

---

## 部署步骤

### 1. 下载官方配置文件

```bash
# 创建工作目录
mkdir -p ~/dev/docker-deploy/ai-infra-compose/langfuse
cd ~/dev/docker-deploy/ai-infra-compose/langfuse

# 下载官方文件
wget https://raw.githubusercontent.com/langfuse/langfuse/main/docker-compose.yml
wget https://raw.githubusercontent.com/langfuse/langfuse/main/.env.dev.example

# 备份原始文件（推荐）
cp docker-compose.yml docker-compose.yml.original
cp .env.dev.example .env.dev.example.original
```

---

### 2. 修改 docker-compose.yml

#### 2.1 删除不需要的服务

打开 `docker-compose.yml`，**删除**以下服务定义（因为使用现有服务）：

- ❌ `postgres` 服务（整个服务块）
- ❌ `redis` 服务（整个服务块）
- ❌ `minio` 服务（整个服务块）

**只保留**以下服务：
- ✅ `clickhouse`
- ✅ `langfuse-web`
- ✅ `langfuse-worker`

#### 2.2 修改 ClickHouse 端口（避免与 MinIO 冲突）

找到 `clickhouse` 服务的 `ports` 部分，将 9000 端口改为 9900：

**原始配置：**
```yaml
ports:
  - ${HOST_IP:-127.0.0.1}:${CLICKHOUSE_HTTP_PORT:-8123}:8123
  - ${HOST_IP:-127.0.0.1}:${CLICKHOUSE_NATIVE_PORT:-9000}:9000
```

**修改为：**
```yaml
ports:
  - ${HOST_IP:-127.0.0.1}:${CLICKHOUSE_HTTP_PORT:-8123}:8123
  - ${HOST_IP:-127.0.0.1}:${CLICKHOUSE_NATIVE_PORT:-9900}:9000  # 改为 9900
```

#### 2.3 添加 host.docker.internal 支持

在 `langfuse-web` 和 `langfuse-worker` 服务中添加 `extra_hosts` 配置。

**在 langfuse-web 服务中添加：**
```yaml
langfuse-web:
  image: docker.io/langfuse/langfuse:latest
  container_name: ${WEB_CONTAINER_NAME:-langfuse-web}
  # ⬇️ 添加以下两行
  extra_hosts:
    - "host.docker.internal:host-gateway"
  # ⬆️ 添加结束
  depends_on:
    clickhouse:
      condition: service_healthy
  ports:
    - ${WEB_HOST_PORT:-3000}:3000
  # ... 其他配置保持不变
```

**在 langfuse-worker 服务中添加相同配置：**
```yaml
langfuse-worker:
  image: docker.io/langfuse/langfuse:latest
  container_name: ${WORKER_CONTAINER_NAME:-langfuse-worker}
  command: worker
  # ⬇️ 添加以下两行
  extra_hosts:
    - "host.docker.internal:host-gateway"
  # ⬆️ 添加结束
  depends_on:
    clickhouse:
      condition: service_healthy
  # ... 其他配置保持不变
```

#### 2.4 完整的 docker-compose.yml 参考

修改后的完整文件如下：

```yaml
version: "3.5"

services:
  # ===== ClickHouse (新部署) =====
  clickhouse:
    image: docker.io/clickhouse/clickhouse-server:24.1-alpine
    user: "101:101"
    container_name: ${CLICKHOUSE_CONTAINER_NAME:-langfuse-clickhouse}
    environment:
      CLICKHOUSE_DB: default
      CLICKHOUSE_USER: ${CLICKHOUSE_USER:-clickhouse}
      CLICKHOUSE_PASSWORD: ${CLICKHOUSE_PASSWORD:-clickhouse}
    volumes:
      - langfuse_clickhouse_data:/var/lib/clickhouse
      - langfuse_clickhouse_logs:/var/log/clickhouse-server
    ports:
      - ${HOST_IP:-127.0.0.1}:${CLICKHOUSE_HTTP_PORT:-8123}:8123
      - ${HOST_IP:-127.0.0.1}:${CLICKHOUSE_NATIVE_PORT:-9900}:9000
    healthcheck:
      test: wget --no-verbose --tries=1 --spider http://localhost:19533/ping || exit 1
      interval: 5s
      timeout: 5s
      retries: 10
      start_period: 1s
    restart: unless-stopped

  # ===== Langfuse Web =====
  langfuse-web:
    image: docker.io/langfuse/langfuse:latest
    container_name: ${WEB_CONTAINER_NAME:-langfuse-web}
    extra_hosts:
      - "host.docker.internal:host-gateway"
    depends_on:
      clickhouse:
        condition: service_healthy
    ports:
      - ${WEB_HOST_PORT:-3000}:3000
    env_file:
      - .env
    restart: unless-stopped

  # ===== Langfuse Worker =====
  langfuse-worker:
    image: docker.io/langfuse/langfuse:latest
    container_name: ${WORKER_CONTAINER_NAME:-langfuse-worker}
    command: worker
    extra_hosts:
      - "host.docker.internal:host-gateway"
    depends_on:
      clickhouse:
        condition: service_healthy
    env_file:
      - .env
    restart: unless-stopped

volumes:
  langfuse_clickhouse_data:
    driver: local
  langfuse_clickhouse_logs:
    driver: local
```

---

### 3. 创建并配置 .env 文件

#### 3.1 创建 .env 文件

```bash
cp .env.dev.example .env
```

#### 3.2 编辑 .env 文件

打开 `.env` 文件，添加或修改以下配置：

```bash
# ============================================
# 端口配置
# ============================================
WEB_HOST_PORT=3000
CLICKHOUSE_HTTP_PORT=19533
CLICKHOUSE_NATIVE_PORT=9900

# ============================================
# 容器名称（可选）
# ============================================
CLICKHOUSE_CONTAINER_NAME=langfuse-clickhouse
WEB_CONTAINER_NAME=langfuse-web
WORKER_CONTAINER_NAME=langfuse-worker

# ============================================
# PostgreSQL 配置 (使用现有服务)
# ============================================
# ⚠️ 修改为你的实际 PostgreSQL 密码
DATABASE_URL=postgresql://postgres:YOUR_POSTGRES_PASSWORD@host.docker.internal:5432/langfuse
DIRECT_URL=postgresql://postgres:YOUR_POSTGRES_PASSWORD@host.docker.internal:5432/langfuse

# ============================================
# Redis 配置 (使用现有服务)
# ============================================
# 如果 Redis 没有密码
REDIS_CONNECTION_STRING=redis://host.docker.internal:19531

# 如果 Redis 有密码，使用以下格式
# REDIS_CONNECTION_STRING=redis://:YOUR_REDIS_PASSWORD@host.docker.internal:19531

# ============================================
# ClickHouse 配置 (新部署的容器)
# ============================================
CLICKHOUSE_USER=clickhouse
CLICKHOUSE_PASSWORD=WILL_BE_GENERATED_IN_STEP_4
CLICKHOUSE_URL=http://clickhouse:8123
CLICKHOUSE_MIGRATION_URL=clickhouse://clickhouse:9000

# ============================================
# MinIO/S3 配置 (使用现有服务)
# ============================================
# Batch Export
LANGFUSE_S3_BATCH_EXPORT_ENABLED=true
LANGFUSE_S3_BATCH_EXPORT_BUCKET=langfuse
LANGFUSE_S3_BATCH_EXPORT_PREFIX=exports/
LANGFUSE_S3_BATCH_EXPORT_ENDPOINT=http://host.docker.internal:9000
LANGFUSE_S3_BATCH_EXPORT_FORCE_PATH_STYLE=true
LANGFUSE_S3_BATCH_EXPORT_ACCESS_KEY_ID=minioadmin
LANGFUSE_S3_BATCH_EXPORT_SECRET_ACCESS_KEY=minioadmin
LANGFUSE_S3_BATCH_EXPORT_REGION=auto

# Media Upload
LANGFUSE_S3_MEDIA_UPLOAD_ENABLED=true
LANGFUSE_S3_MEDIA_UPLOAD_BUCKET=langfuse
LANGFUSE_S3_MEDIA_UPLOAD_PREFIX=media/
LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT=http://host.docker.internal:9000
LANGFUSE_S3_MEDIA_UPLOAD_FORCE_PATH_STYLE=true
LANGFUSE_S3_MEDIA_UPLOAD_ACCESS_KEY_ID=minioadmin
LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY=minioadmin
LANGFUSE_S3_MEDIA_UPLOAD_REGION=auto

# Event Upload
LANGFUSE_S3_EVENT_UPLOAD_ENABLED=true
LANGFUSE_S3_EVENT_UPLOAD_BUCKET=langfuse
LANGFUSE_S3_EVENT_UPLOAD_PREFIX=events/
LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT=http://host.docker.internal:9000
LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE=true
LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID=minioadmin
LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY=minioadmin
LANGFUSE_S3_EVENT_UPLOAD_REGION=auto

# ============================================
# 核心安全配置 (⚠️ 必须在步骤4中生成!)
# ============================================
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=WILL_BE_GENERATED_IN_STEP_4
SALT=WILL_BE_GENERATED_IN_STEP_4
ENCRYPTION_KEY=WILL_BE_GENERATED_IN_STEP_4

# ============================================
# 其他配置
# ============================================
NODE_ENV=production
TELEMETRY_ENABLED=true
LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES=false

# ============================================
# 可选: 初始化配置
# ============================================
# 如需在首次启动时自动创建组织、项目和用户，请取消注释并配置
# LANGFUSE_INIT_ORG_NAME=My Organization
# LANGFUSE_INIT_PROJECT_NAME=My Project
# LANGFUSE_INIT_USER_EMAIL=admin@example.com
# LANGFUSE_INIT_USER_NAME=Admin
# LANGFUSE_INIT_USER_PASSWORD=changeme123
```

#### 3.3 必须修改的配置项

在 `.env` 文件中，以下配置**必须**根据实际情况修改：

| 配置项 | 说明 | 示例 |
|--------|------|------|
| `DATABASE_URL` 中的密码 | PostgreSQL 实际密码 | `postgresql://postgres:mypassword@...` |
| `REDIS_CONNECTION_STRING` | Redis 连接串（如有密码） | `redis://:redispass@...` |
| MinIO Access Key | 实际的 MinIO 访问密钥 | `LANGFUSE_S3_*_ACCESS_KEY_ID` |
| MinIO Secret Key | 实际的 MinIO 密钥 | `LANGFUSE_S3_*_SECRET_ACCESS_KEY` |

---

### 4. 生成安全密钥

运行以下命令生成强随机密钥：

```bash
# 生成 NEXTAUTH_SECRET
echo "NEXTAUTH_SECRET=$(openssl rand -hex 32)"

# 生成 SALT
echo "SALT=$(openssl rand -hex 32)"

# 生成 ENCRYPTION_KEY
echo "ENCRYPTION_KEY=$(openssl rand -hex 32)"

# 生成 CLICKHOUSE_PASSWORD
echo "CLICKHOUSE_PASSWORD=$(openssl rand -base64 32 | tr -d '=+/')"
```

**示例输出：**
```
NEXTAUTH_SECRET=a1b2c3d4e5f6...
SALT=f6e5d4c3b2a1...
ENCRYPTION_KEY=9876543210ab...
CLICKHOUSE_PASSWORD=xY9kL2mN8pQ...
```

**将生成的值复制到 `.env` 文件**，替换对应的占位符：

```bash
# 在 .env 文件中替换
NEXTAUTH_SECRET=a1b2c3d4e5f6...
SALT=f6e5d4c3b2a1...
ENCRYPTION_KEY=9876543210ab...
CLICKHOUSE_PASSWORD=xY9kL2mN8pQ...
```

**建议：将密钥保存到单独的文件（可选）**
```bash
cat > .secrets << EOF
# Langfuse 安全密钥 - 生成时间: $(date)
NEXTAUTH_SECRET=$(openssl rand -hex 32)
SALT=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
CLICKHOUSE_PASSWORD=$(openssl rand -base64 32 | tr -d '=+/')
EOF

chmod 600 .secrets
```

---

### 5. 准备数据库和存储

#### 5.1 创建 PostgreSQL 数据库

```bash
# 创建 langfuse 数据库
docker exec -it postgres psql -U postgres -c "CREATE DATABASE langfuse;"

# 验证数据库是否创建成功
docker exec -it postgres psql -U postgres -l | grep langfuse
```

**如果遇到权限问题：**
```bash
# 带密码执行
docker exec -it postgres bash
psql -U postgres
# 输入密码后
CREATE DATABASE langfuse;
\q
exit
```

#### 5.2 创建 MinIO Bucket

**方法1: 使用 MinIO 控制台（推荐）**

1. 打开浏览器访问: http://localhost:9001
2. 登录凭证:
   - 用户名: `minioadmin`
   - 密码: `minioadmin`
3. 点击 "Buckets" → "Create Bucket"
4. Bucket 名称: `langfuse`
5. 点击 "Create Bucket"

**方法2: 使用命令行**

```bash
# 配置 mc 别名
docker exec -it milvus-minio mc alias set local http://localhost:9000 minioadmin minioadmin

# 创建 bucket
docker exec -it milvus-minio mc mb local/langfuse

# 验证 bucket 是否创建成功
docker exec -it milvus-minio mc ls local/
```

---

### 6. 启动服务

#### 6.1 测试配置（可选但推荐）

验证 host.docker.internal 可用性：
```bash
docker run --rm --add-host=host.docker.internal:host-gateway alpine ping -c 2 host.docker.internal
```

#### 6.2 启动 Langfuse

```bash
# 拉取最新镜像
docker compose pull

# 启动服务
docker compose up -d

# 查看服务状态
docker compose ps
```

**预期输出：**
```
NAME                    IMAGE                                        STATUS
langfuse-clickhouse     clickhouse/clickhouse-server:24.1-alpine     Up (healthy)
langfuse-web            langfuse/langfuse:latest                     Up
langfuse-worker         langfuse/langfuse:latest                     Up
```

#### 6.3 查看日志

```bash
# 查看所有服务日志
docker compose logs -f

# 只查看 web 服务日志
docker compose logs -f langfuse-web

# 只查看 worker 服务日志
docker compose logs -f langfuse-worker

# 只查看 clickhouse 日志
docker compose logs -f clickhouse
```

#### 6.4 验证服务健康状态

```bash
# 检查 ClickHouse 健康状态
curl http://localhost:19533/ping

# 检查 Langfuse Web 服务
curl -I http://localhost:3000

# 检查容器健康状态
docker compose ps
```

#### 6.5 访问 Langfuse

打开浏览器访问: **http://localhost:3000**

首次访问会进入设置向导，创建管理员账户。

---

## 配置说明

### 架构对照表

| 组件 | 原始配置 | 修改后配置 | 说明 |
|------|---------|-----------|------|
| **PostgreSQL** | 容器内 `postgres:5432` | 宿主机 `host.docker.internal:5432` | 复用现有 PostgreSQL |
| **Redis** | 容器内 `redis:6379` | 宿主机 `host.docker.internal:19531` | 复用现有 Redis |
| **MinIO** | 容器内 `minio:9000` | 宿主机 `host.docker.internal:9000` | 复用现有 MinIO |
| **ClickHouse** | 新部署 `9000` | 新部署 `9900` | 避免端口冲突 |
| **Langfuse Web** | 新部署 `3000` | 新部署 `3000` | 主服务 |
| **Langfuse Worker** | 新部署（无端口） | 新部署（无端口） | 后台任务处理 |

### 端口映射

| 服务 | 容器端口 | 宿主机端口 | 用途 |
|------|---------|-----------|------|
| Langfuse Web | 3000 | 3000 | Web 界面 |
| ClickHouse HTTP | 8123 | 8123 | HTTP API |
| ClickHouse Native | 9000 | 9900 | 原生协议（避免冲突） |

### 环境变量说明

#### 数据库连接
```bash
# PostgreSQL 连接格式
DATABASE_URL=postgresql://[用户名]:[密码]@[主机]:[端口]/[数据库名]

# 示例
DATABASE_URL=postgresql://postgres:mypassword@host.docker.internal:5432/langfuse
```

#### Redis 连接
```bash
# 无密码格式
REDIS_CONNECTION_STRING=redis://[主机]:[端口]

# 有密码格式
REDIS_CONNECTION_STRING=redis://:[密码]@[主机]:[端口]

# 示例
REDIS_CONNECTION_STRING=redis://host.docker.internal:19531
REDIS_CONNECTION_STRING=redis://:myredispass@host.docker.internal:19531
```

#### MinIO/S3 配置
```bash
# Endpoint 格式
LANGFUSE_S3_*_ENDPOINT=http://[主机]:[端口]

# 示例
LANGFUSE_S3_BATCH_EXPORT_ENDPOINT=http://host.docker.internal:9000
```

### host.docker.internal 说明

`host.docker.internal` 是 Docker 提供的特殊 DNS 名称，用于从容器内访问宿主机服务。

- ✅ **Docker Desktop (Mac/Windows)**: 自动支持
- ✅ **Linux Docker 20.10+**: 需要配置 `extra_hosts`（已在 docker-compose.yml 中配置）

**测试是否可用：**
```bash
docker run --rm --add-host=host.docker.internal:host-gateway alpine ping -c 2 host.docker.internal
```

---

## 常见问题

### Q1: host.docker.internal 不可用怎么办？

**症状：**
```
Error: getaddrinfo ENOTFOUND host.docker.internal
```

**解决方案：**

1. **检查 Docker 版本**（Linux 需要 20.10+）
```bash
docker version
```

2. **确认 docker-compose.yml 中已添加 extra_hosts**
```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

3. **如果仍然失败，使用宿主机 IP**
```bash
# 获取宿主机 IP
ip addr show docker0 | grep -Po 'inet \K[\d.]+'

# 或
hostname -I | awk '{print $1}'

# 在 .env 中替换 host.docker.internal 为实际 IP
DATABASE_URL=postgresql://postgres:password@172.17.0.1:5432/langfuse
```

---

### Q2: 如何验证服务是否正常启动？

**检查步骤：**

```bash
# 1. 查看容器状态（所有容器应为 Up）
docker compose ps

# 2. 查看 web 服务日志
docker compose logs langfuse-web | tail -50

# 3. 测试健康检查
curl http://localhost:3000

# 4. 检查数据库连接
docker compose exec langfuse-web sh -c 'echo "SELECT 1" | nc -w 1 host.docker.internal 5432'

# 5. 检查 Redis 连接
docker compose exec langfuse-web sh -c 'echo "PING" | nc -w 1 host.docker.internal 19531'
```

**预期正常输出：**
- 容器状态: `Up` 或 `Up (healthy)`
- 日志中无连接错误
- curl 返回 HTTP 200 或 302

---

### Q3: 数据库连接失败？

**症状：**
```
Error: connect ECONNREFUSED
FATAL: password authentication failed
```

**排查步骤：**

1. **检查 PostgreSQL 是否运行**
```bash
docker ps | grep postgres
```

2. **检查数据库是否创建**
```bash
docker exec postgres psql -U postgres -l | grep langfuse
```

3. **验证连接信息**
```bash
# 从容器内测试连接
docker compose exec langfuse-web sh
# 在容器内执行
nc -zv host.docker.internal 5432
exit
```

4. **检查密码是否正确**
```bash
# 检查 .env 文件
grep DATABASE_URL .env

# 手动测试连接
docker run --rm --add-host=host.docker.internal:host-gateway postgres:17 \
  psql -h host.docker.internal -U postgres -d langfuse -c "SELECT 1"
```

---

### Q4: MinIO 连接失败？

**症状：**
```
Error: RequestTimeTooSkewed
Error: Access Denied
```

**排查步骤：**

1. **检查 MinIO 是否运行**
```bash
docker ps | grep minio
```

2. **检查 Bucket 是否创建**
```bash
# 访问控制台
open http://localhost:9001

# 或使用命令行
docker exec milvus-minio mc ls local/langfuse
```

3. **验证凭证**
```bash
# 检查 .env 中的凭证
grep LANGFUSE_S3 .env | grep -E "ACCESS_KEY|SECRET"

# 测试连接
curl -I http://localhost:9000
```

4. **检查时间同步（RequestTimeTooSkewed）**
```bash
# 检查容器时间
docker compose exec langfuse-web date
docker exec milvus-minio date

# 如果时间不同步，重启 MinIO 容器
docker restart milvus-minio
```

---

### Q5: ClickHouse 启动失败？

**症状：**
```
unhealthy: wget: error getting response
```

**排查步骤：**

1. **检查日志**
```bash
docker compose logs clickhouse
```

2. **检查端口冲突**
```bash
# 确认端口未被占用
netstat -tulpn | grep -E "8123|9900"
```

3. **手动测试健康检查**
```bash
docker compose exec clickhouse wget -q -O - http://localhost:19533/ping
```

4. **重启 ClickHouse**
```bash
docker compose restart clickhouse
docker compose logs -f clickhouse
```

---

### Q6: Web 界面无法访问？

**症状：**
```
This site can't be reached
ERR_CONNECTION_REFUSED
```

**排查步骤：**

1. **检查容器状态**
```bash
docker compose ps langfuse-web
```

2. **检查端口绑定**
```bash
netstat -tulpn | grep 3000
```

3. **查看 web 服务日志**
```bash
docker compose logs langfuse-web | tail -100
```

4. **检查防火墙**
```bash
# Ubuntu/Debian
sudo ufw status
sudo ufw allow 3000/tcp

# CentOS/RHEL
sudo firewall-cmd --list-ports
sudo firewall-cmd --add-port=3000/tcp --permanent
sudo firewall-cmd --reload
```

---

### Q7: 如何重置所有数据？

**警告：此操作会删除所有 Langfuse 数据！**

```bash
# 停止服务
docker compose down

# 删除数据卷
docker compose down -v

# 删除 PostgreSQL 数据库
docker exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS langfuse;"

# 删除 MinIO bucket
docker exec milvus-minio mc rm -r --force local/langfuse

# 重新开始部署
# 从步骤 5.1 开始重新执行
```

---

### Q8: 如何升级 Langfuse？

```bash
# 1. 停止服务
docker compose down

# 2. 备份数据（可选但推荐）
docker exec postgres pg_dump -U postgres langfuse > langfuse_backup_$(date +%Y%m%d).sql

# 3. 拉取最新镜像
docker compose pull

# 4. 启动服务
docker compose up -d

# 5. 查看日志
docker compose logs -f
```

---

## 管理命令

### 日常运维

```bash
# 查看所有服务状态
docker compose ps

# 查看实时日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f langfuse-web
docker compose logs -f langfuse-worker
docker compose logs -f clickhouse

# 重启所有服务
docker compose restart

# 重启特定服务
docker compose restart langfuse-web

# 停止服务
docker compose stop

# 启动服务
docker compose start

# 完全停止并删除容器
docker compose down

# 停止并删除数据卷（⚠️ 危险操作）
docker compose down -v
```

### 容器管理

```bash
# 进入容器 shell
docker compose exec langfuse-web sh
docker compose exec clickhouse sh

# 查看容器资源使用
docker stats

# 查看特定容器资源使用
docker stats langfuse-web langfuse-worker langfuse-clickhouse
```

### 数据库操作

```bash
# 连接 PostgreSQL
docker exec -it postgres psql -U postgres -d langfuse

# 连接 ClickHouse
docker compose exec clickhouse clickhouse-client

# 备份 PostgreSQL 数据库
docker exec postgres pg_dump -U postgres langfuse > backup_$(date +%Y%m%d).sql

# 恢复 PostgreSQL 数据库
docker exec -i postgres psql -U postgres langfuse < backup_20240101.sql
```

### 清理和维护

```bash
# 清理未使用的 Docker 资源
docker system prune

# 清理未使用的镜像
docker image prune

# 清理未使用的数据卷
docker volume prune

# 查看磁盘使用情况
docker system df
```

---

## 文件清单

部署完成后，目录结构如下：

```
langfuse/
├── docker-compose.yml              # 修改后的编排文件
├── docker-compose.yml.original     # 原始文件备份（可选）
├── .env                            # 生产配置文件 ⚠️ 不要提交到 Git
├── .env.dev.example                # 官方示例（参考）
├── .secrets                        # 密钥备份 ⚠️ 不要提交到 Git
└── README.md                       # 本文档
```

### .gitignore 配置（推荐）

如果使用 Git 版本控制，创建 `.gitignore` 文件：

```bash
cat > .gitignore << 'EOF'
# 敏感配置文件
.env
.secrets

# 备份文件
*.backup
*.sql
*.dump

# 日志
*.log
EOF
```

---

## 安全建议

### 密钥管理

1. ✅ **使用强随机密钥**
   ```bash
   # 所有密钥至少 32 字节
   openssl rand -hex 32
   ```

2. ✅ **定期轮换密钥**（每 90 天）
   - 生成新密钥
   - 更新 `.env` 文件
   - 重启服务

3. ✅ **备份密钥文件**
   ```bash
   cp .env .env.backup.$(date +%Y%m%d)
   chmod 600 .env.backup.*
   ```

4. ❌ **不要将 .env 提交到版本控制**
   ```bash
   # 添加到 .gitignore
   echo ".env" >> .gitignore
   echo ".secrets" >> .gitignore
   ```

### 网络安全

1. ✅ **限制端口访问**（生产环境）
   ```yaml
   # 仅本地访问
   ports:
     - "127.0.0.1:3000:3000"
   ```

2. ✅ **配置防火墙**
   ```bash
   # 仅允许必要端口
   sudo ufw allow 3000/tcp comment 'Langfuse Web'
   ```

3. ✅ **使用反向代理**（Nginx/Caddy）
   - 添加 HTTPS
   - 添加访问控制
   - 添加速率限制

### 数据安全

1. ✅ **定期备份数据库**
   ```bash
   # 创建备份脚本
   cat > backup.sh << 'EOF'
   #!/bin/bash
   BACKUP_DIR=~/langfuse-backups
   mkdir -p $BACKUP_DIR
   docker exec postgres pg_dump -U postgres langfuse | gzip > \
     $BACKUP_DIR/langfuse_$(date +%Y%m%d_%H%M%S).sql.gz
   # 保留最近 7 天的备份
   find $BACKUP_DIR -name "langfuse_*.sql.gz" -mtime +7 -delete
   EOF
   chmod +x backup.sh
   
   # 添加到 crontab（每天凌晨 2 点）
   (crontab -l 2>/dev/null; echo "0 2 * * * ~/dev/docker-deploy/ai-infra-compose/langfuse/backup.sh") | crontab -
   ```

2. ✅ **加密敏感数据**
   - PostgreSQL 启用 SSL
   - MinIO 启用加密

### 更新维护

1. ✅ **定期更新镜像**
   ```bash
   # 每月检查更新
   docker compose pull
   docker compose up -d
   ```

2. ✅ **监控日志**
   ```bash
   # 设置日志告警
   docker compose logs --since 1h | grep -i error
   ```

3. ✅ **监控资源使用**
   ```bash
   docker stats --no-stream
   ```

---

## 故障排查清单

### 服务无法启动

- [ ] 检查 Docker 服务是否运行: `systemctl status docker`
- [ ] 检查 docker-compose.yml 语法: `docker compose config`
- [ ] 检查端口是否被占用: `netstat -tulpn | grep -E "3000|8123|9900"`
- [ ] 检查磁盘空间: `df -h`
- [ ] 查看容器日志: `docker compose logs`

### 连接问题

- [ ] 检查现有服务状态: `docker ps | grep -E "postgres|redis|minio"`
- [ ] 测试 host.docker.internal: `docker run --rm --add-host=host.docker.internal:host-gateway alpine ping -c 2 host.docker.internal`
- [ ] 验证 PostgreSQL 连接: `docker run --rm --add-host=host.docker.internal:host-gateway postgres:17 pg_isready -h host.docker.internal -p 5432`
- [ ] 验证 Redis 连接: `docker run --rm --add-host=host.docker.internal:host-gateway redis:alpine redis-cli -h host.docker.internal -p 19531 ping`
- [ ] 验证 MinIO 连接: `curl -I http://localhost:9000`

### 配置问题

- [ ] 检查 .env 文件是否存在: `ls -la .env`
- [ ] 验证密钥已生成: `grep -E "NEXTAUTH_SECRET|SALT|ENCRYPTION_KEY" .env | grep -v "WILL_BE_GENERATED"`
- [ ] 检查数据库 URL 格式: `grep DATABASE_URL .env`
- [ ] 检查 MinIO 凭证: `grep LANGFUSE_S3 .env | grep -E "ACCESS_KEY|SECRET"`

### 数据问题

- [ ] 检查数据库是否创建: `docker exec postgres psql -U postgres -l | grep langfuse`
- [ ] 检查 MinIO bucket: `docker exec milvus-minio mc ls local/langfuse`
- [ ] 检查数据卷: `docker volume ls | grep langfuse`

---

## 性能优化

### 资源限制（可选）

在 `docker-compose.yml` 中为服务添加资源限制：

```yaml
services:
  langfuse-web:
    # ... 其他配置
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G

  clickhouse:
    # ... 其他配置
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 4G
        reservations:
          cpus: '2'
          memory: 2G
```

### ClickHouse 优化

创建 `clickhouse-config.xml` 配置文件（可选）：

```xml
<clickhouse>
    <max_concurrent_queries>100</max_concurrent_queries>
    <max_memory_usage>10000000000</max_memory_usage>
</clickhouse>
```

在 docker-compose.yml 中挂载：
```yaml
clickhouse:
  volumes:
    - ./clickhouse-config.xml:/etc/clickhouse-server/config.d/custom.xml
```

---

## 监控和告警

### 健康检查脚本

创建 `health-check.sh`:

```bash
#!/bin/bash

echo "=== Langfuse 健康检查 ==="
echo ""

# Web 服务
if curl -sf http://localhost:3000 > /dev/null; then
    echo "✅ Web 服务: 正常"
else
    echo "❌ Web 服务: 异常"
fi

# ClickHouse
if curl -sf http://localhost:19533/ping > /dev/null; then
    echo "✅ ClickHouse: 正常"
else
    echo "❌ ClickHouse: 异常"
fi

# PostgreSQL
if docker run --rm --add-host=host.docker.internal:host-gateway postgres:17 \
    pg_isready -h host.docker.internal -p 5432 -q; then
    echo "✅ PostgreSQL: 正常"
else
    echo "❌ PostgreSQL: 异常"
fi

# Redis
if docker run --rm --add-host=host.docker.internal:host-gateway redis:alpine \
    redis-cli -h host.docker.internal -p 19531 ping > /dev/null 2>&1; then
    echo "✅ Redis: 正常"
else
    echo "⚠️  Redis: 无法连接（可能需要密码）"
fi

echo ""
echo "=== 容器状态 ==="
docker compose ps
```

```bash
chmod +x health-check.sh
./health-check.sh
```

---

## 参考链接

- 📚 [Langfuse 官方文档](https://langfuse.com/docs)
- 🔧 [Langfuse GitHub 仓库](https://github.com/langfuse/langfuse)
- 🐳 [Docker Compose 文档](https://docs.docker.com/compose/)
- 🗄️ [ClickHouse 文档](https://clickhouse.com/docs)
- 📦 [MinIO 文档](https://min.io/docs/)

---

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0 | 2024-02-06 | 初始版本 |

---

## 许可证

本文档基于 MIT 许可证发布。

---

## 贡献

欢迎提交问题和改进建议！

---

**如有问题，请查看 [常见问题](#常见问题) 部分或查看服务日志进行排查。**
