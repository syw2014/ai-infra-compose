# Langfuse 部署配置说明

本目录包含 Langfuse 的 Docker Compose 部署配置，使用同服务器上已部署的外部组件（PostgreSQL、Redis、MinIO）。

## 快速开始

### 1. 配置环境变量

复制环境变量模板并编辑：

```bash
cp env.example .env
vim .env  # 或使用你喜欢的编辑器
```

### 2. 必须修改的配置项

编辑 `.env` 文件，修改以下配置：

```bash
# PostgreSQL 配置
POSTGRES_USER=postgres              # PostgreSQL 用户名
POSTGRES_PASSWORD=your_password     # PostgreSQL 密码
POSTGRES_DB=langfuse               # 数据库名称

# Redis 配置
REDIS_PASSWORD=your_redis_password  # Redis 密码

# MinIO 配置
MINIO_ACCESS_KEY=your_access_key   # MinIO 访问密钥
MINIO_SECRET_KEY=your_secret_key   # MinIO 密钥
```

### 3. 生成安全密钥

在 `.env` 文件中替换以下占位符：

```bash
# 生成密钥
openssl rand -hex 32  # 用于 NEXTAUTH_SECRET
openssl rand -hex 32  # 用于 SALT
openssl rand -hex 32  # 用于 ENCRYPTION_KEY
openssl rand -base64 32 | tr -d '=+/'  # 用于 CLICKHOUSE_PASSWORD
```

将生成的值填入 `.env` 文件：

```bash
NEXTAUTH_SECRET=<生成的值1>
SALT=<生成的值2>
ENCRYPTION_KEY=<生成的值3>
CLICKHOUSE_PASSWORD=<生成的值4>
```

### 4. 准备数据库和存储

#### 创建 PostgreSQL 数据库

```bash
# 连接到 PostgreSQL（根据你的配置调整）
docker exec -it postgres psql -U postgres

# 创建数据库
CREATE DATABASE langfuse;
\q
```

#### 创建 MinIO Bucket

访问 MinIO 控制台：http://localhost:9001

1. 使用你的 MinIO 凭证登录
2. 创建一个名为 `langfuse` 的 bucket

或使用命令行：

```bash
# 配置 mc（MinIO Client）
docker exec -it <minio-container-name> mc alias set local http://localhost:9000 <your_access_key> <your_secret_key>

# 创建 bucket
docker exec -it <minio-container-name> mc mb local/langfuse
```

### 5. 启动服务

```bash
docker compose up -d
```

### 6. 查看状态

```bash
docker compose ps
docker compose logs -f
```

## 服务访问

- **Langfuse Web UI**: http://localhost:19532
- **ClickHouse HTTP API**: http://localhost:8123
- **MinIO Console**: http://localhost:9001

## 外部组件端口

本配置使用以下外部服务（需要在同一服务器上已部署）：

| 服务 | 端口 | 说明 |
|------|------|------|
| PostgreSQL | 5432 | 主数据库 |
| Redis | 19531 | 缓存和队列 |
| MinIO API | 9000 | 对象存储 API |
| MinIO Console | 9001 | 对象存储控制台 |

## 管理命令

```bash
# 启动
docker compose up -d

# 停止
docker compose down

# 重启
docker compose restart

# 查看日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f langfuse-web
docker compose logs -f langfuse-worker
docker compose logs -f clickhouse

# 查看状态
docker compose ps
```

## 故障排查

### 检查服务连接

```bash
# 检查 PostgreSQL 连接
docker compose exec langfuse-web sh -c "nc -zv host.docker.internal 5432"

# 检查 Redis 连接
docker compose exec langfuse-web sh -c "nc -zv host.docker.internal 19531"

# 检查 MinIO 连接
docker compose exec langfuse-web sh -c "nc -zv host.docker.internal 9000"

# 检查 ClickHouse 健康状态
curl http://localhost:8123/ping
```

### 查看详细日志

```bash
# Web 服务日志
docker compose logs langfuse-web | tail -100

# Worker 服务日志
docker compose logs langfuse-worker | tail -100

# ClickHouse 日志
docker compose logs clickhouse | tail -100
```

## 环境变量说明

### PostgreSQL 配置

```bash
POSTGRES_HOST=host.docker.internal  # PostgreSQL 主机地址
POSTGRES_PORT=5432                  # PostgreSQL 端口
POSTGRES_USER=postgres              # PostgreSQL 用户名
POSTGRES_PASSWORD=xxx               # PostgreSQL 密码
POSTGRES_DB=langfuse               # 数据库名称
```

### Redis 配置

```bash
REDIS_HOST=host.docker.internal    # Redis 主机地址
REDIS_PORT=19531                   # Redis 端口
REDIS_PASSWORD=xxx                 # Redis 密码
```

### MinIO 配置

```bash
MINIO_ENDPOINT=http://host.docker.internal:9000  # MinIO API 端点
MINIO_ACCESS_KEY=xxx                             # MinIO 访问密钥
MINIO_SECRET_KEY=xxx                             # MinIO 密钥
MINIO_BUCKET=langfuse                           # MinIO bucket 名称
```

## 安全建议

1. **不要提交 `.env` 文件到版本控制**
   - `.env` 文件已在 `.gitignore` 中
   - 包含敏感信息（密码、密钥）

2. **定期轮换密钥**
   - 建议每 90 天更新一次密钥
   - 更新后重启服务

3. **备份配置**
   ```bash
   cp .env .env.backup.$(date +%Y%m%d)
   chmod 600 .env.backup.*
   ```

4. **使用强密码**
   - 所有密码至少 16 位
   - 包含大小写字母、数字和特殊字符

## 文件说明

- `docker-compose.yml` - Docker Compose 配置文件
- `.env` - 环境变量配置（不提交到 Git）
- `env.example` - 环境变量模板
- `.gitignore` - Git 忽略规则

## 参考文档

- [Langfuse 官方文档](https://langfuse.com/docs)
- [Langfuse GitHub](https://github.com/langfuse/langfuse)
- [Docker Compose 文档](https://docs.docker.com/compose/)
