# Langfuse 快速部署指南

适用于同服务器已部署外部组件（PostgreSQL、Redis、MinIO）的场景。

## 一行命令部署

```bash
./setup.sh
```

首次运行会创建 `.env` 模板，你需要编辑它配置以下信息：

1. **PostgreSQL 配置**
   ```bash
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=你的密码
   POSTGRES_DB=langfuse
   ```

2. **Redis 配置**
   ```bash
   REDIS_PASSWORD=你的Redis密码
   ```

3. **MinIO 配置**
   ```bash
   MINIO_ACCESS_KEY=你的访问密钥
   MINIO_SECRET_KEY=你的密钥
   ```

4. **生成安全密钥**
   ```bash
   openssl rand -hex 32  # NEXTAUTH_SECRET
   openssl rand -hex 32  # SALT
   openssl rand -hex 32  # ENCRYPTION_KEY
   openssl rand -base64 32 | tr -d '=+/'  # CLICKHOUSE_PASSWORD
   ```

配置完成后，再次运行 `./setup.sh` 即可自动部署。

## 手动部署

如果你喜欢手动控制：

```bash
# 1. 创建配置文件
cp env.example .env
vim .env  # 编辑配置

# 2. 创建数据库
docker exec -it postgres psql -U postgres -c "CREATE DATABASE langfuse;"

# 3. 创建 MinIO bucket
# 访问 http://localhost:9001 或使用 mc 命令

# 4. 启动服务
docker compose up -d
```

## 验证部署

```bash
# 查看状态
docker compose ps

# 查看日志
docker compose logs -f

# 测试服务
curl http://localhost:19532           # Langfuse Web
curl http://localhost:8123/ping      # ClickHouse
```

## 服务地址

- **Langfuse**: http://localhost:19532
- **ClickHouse**: http://localhost:8123
- **MinIO Console**: http://localhost:9001

## 外部组件端口

| 服务 | 端口 | 说明 |
|------|------|------|
| PostgreSQL | 5432 | 主数据库 |
| Redis | 19531 | 缓存队列 |
| MinIO API | 9000 | 对象存储 |
| MinIO Console | 9001 | 管理界面 |

## 详细文档

- [CONFIG.md](./CONFIG.md) - 完整配置说明
- [env.example](./env.example) - 环境变量模板
- [docker-compose.yml](./docker-compose.yml) - 服务编排配置
