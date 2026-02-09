# ⚠️ 重要配置变更说明

## 配置已恢复为 Langfuse 官方标准

由于之前的自定义端口配置导致部署错误，现已**完全恢复**为 Langfuse 官方 docker-compose.yml 配置。

---

## 🔄 主要变更

### **1. ClickHouse 端口（已恢复官方配置）**

| 端口类型 | 之前（错误） | 现在（官方） |
|---------|-------------|-------------|
| HTTP API | 19533 | **8123** |
| Native Protocol | 9900 | **9000** |
| 绑定地址 | 可配置 | **127.0.0.1**（固定） |

### **2. Langfuse Web 端口**

| 服务 | 容器端口 | 宿主机端口 |
|------|---------|-----------|
| Langfuse Web | 3000 | **19532** |

### **3. 其他关键变更**

| 配置项 | 之前 | 现在（官方） |
|--------|------|-------------|
| ClickHouse restart | `unless-stopped` | `always` |
| Container names | 自定义名称 | Docker 自动生成 |
| Port 变量 | 使用环境变量 | 硬编码固定值 |

---

## 📋 当前端口分配

### **Langfuse 服务**

| 服务 | 端口 | 访问地址 | 绑定 |
|------|------|---------|------|
| **Langfuse Web** | 19532 | http://localhost:19532 | 0.0.0.0 |
| **ClickHouse HTTP** | 8123 | http://localhost:8123 | 127.0.0.1 |
| **ClickHouse Native** | 9000 | - | 127.0.0.1 |

### **外部组件**（同服务器部署）

| 服务 | 端口 |
|------|------|
| PostgreSQL | 5432 |
| Redis | 19531 |
| MinIO API | 9000 |
| MinIO Console | 9001 |

---

## ⚠️ 端口冲突处理

### **问题：ClickHouse Native (9000) 与 MinIO API (9000) 冲突**

**解决方案（3 选 1）**：

#### **方案 1：修改 MinIO 端口（推荐）**
```bash
# 停止 MinIO
docker stop milvus-minio

# 修改 MinIO docker-compose.yml，改为其他端口
ports:
  - "9002:9000"  # 将 API 端口改为 9002
  - "9001:9001"

# 重启 MinIO
docker compose up -d
```

#### **方案 2：ClickHouse 仅绑定内部使用**
ClickHouse Native 端口主要用于容器间通信，已绑定到 `127.0.0.1`，**不应从外部访问**。

如果 MinIO 在不同的容器网络中，两者不会冲突。

#### **方案 3：分离网络**
```bash
# 为 Langfuse 创建独立网络
docker network create langfuse-net

# 在 docker-compose.yml 中指定网络
networks:
  default:
    name: langfuse-net
    external: false
```

---

## 🔧 在服务器上的更新步骤

### **1. 停止现有服务**
```bash
cd /path/to/langfuse
docker compose down
```

### **2. 拉取最新配置**
```bash
git pull
```

### **3. 检查端口冲突**
```bash
# 检查 9000 端口是否被占用
lsof -i :9000
netstat -tulpn | grep 9000

# 如果 MinIO 占用，参考上面的解决方案
```

### **4. 重新启动**
```bash
docker compose up -d
```

### **5. 验证服务**
```bash
# 查看状态
docker compose ps

# 测试 ClickHouse
curl http://localhost:8123/ping
# 应该返回: Ok.

# 测试 Langfuse Web
curl -I http://localhost:19532
```

---

## 📌 重要说明

### **为什么恢复官方配置？**

1. ✅ **兼容性**: 官方配置经过充分测试
2. ✅ **稳定性**: 避免因自定义配置导致的部署错误
3. ✅ **安全性**: ClickHouse 端口绑定到 127.0.0.1，仅本地访问
4. ✅ **维护性**: 与官方文档和社区支持保持一致

### **不要修改什么？**

❌ **不要修改** `docker-compose.yml` 中的 ClickHouse 配置
❌ **不要修改** ClickHouse 的端口绑定（127.0.0.1）
❌ **不要修改** restart 策略（必须是 `always`）

### **可以修改什么？**

✅ 可以修改 `langfuse-web` 的端口 (19532 → 其他)
✅ 可以修改 `.env` 文件中的应用配置
✅ 可以调整 volumes 挂载路径

---

## 🆘 故障排查

### **错误：ClickHouse 健康检查失败**

```bash
# 查看 ClickHouse 日志
docker compose logs clickhouse

# 常见原因：
# 1. 端口 8123 或 9000 被占用
# 2. 数据卷权限问题
# 3. 内存不足
```

### **错误：address already in use**

```bash
# 找出占用端口的进程
lsof -i :8123  # ClickHouse HTTP
lsof -i :9000  # ClickHouse Native 或 MinIO

# 停止冲突的服务或修改其端口
```

### **错误：Langfuse Web 无法连接 ClickHouse**

检查 `.env` 文件：
```bash
# 应该包含:
CLICKHOUSE_URL=http://clickhouse:8123
CLICKHOUSE_MIGRATION_URL=clickhouse://clickhouse:9000

# 注意：容器间通信使用服务名 'clickhouse'，不是 localhost
```

---

## 📚 相关文档

- [官方 docker-compose.yml](https://github.com/langfuse/langfuse/blob/main/docker-compose.yml)
- [Langfuse 官方文档](https://langfuse.com/docs/deployment/self-host)
- [故障排查指南](./TROUBLESHOOTING.md)

---

**最后更新**: 2026-02-09
**版本**: 官方标准配置
