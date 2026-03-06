# AI Infra Compose

面向常见 AI 应用基础设施的 Docker Compose 预设（Redis、PostgreSQL + pgvector、Milvus、Elasticsearch、MinIO 等），可直接作为模板用于 MLOps 或应用栈。

## 目录结构
- `redis/` — 缓存、队列后端。
- `postgres-pgvector/` — 关系型存储与向量相似度。
- `milvus/` — 向量数据库服务，按部署模式组织。
- `elasticsearch/` — 搜索与日志索引。
- `minio/` — 兼容 S3 的对象存储。
- `xinference/` — CPU 推理服务，用于 Embedding 和 Rerank 模型。

## 使用方法
1) 选择组件目录；如果该组件提供多种部署模式，先进入对应的预设子目录。
2) 先阅读该预设目录下的 `README.md`，按其中定义的入口执行。
3) 对于 Compose 方案，调整端口、密码和卷，将密钥保存在本地 `.env`，然后执行 `docker compose up -d`。
4) 对于脚本方案，执行提供的辅助脚本，例如 `./deploy.sh` 或 `./standalone.sh start`。
5) 组合多个服务时，共用项目名（`-p ai-infra`）和网络。

## 约定
- 使用显式卷保证数据持久性（如绑定到 `./data/<component>`）。  
- 仅暴露必要端口；生产环境收紧默认配置。  
- 每个组件目录内保留该服务的特定说明。
- 对于 Milvus，优先使用明确表达模式的路径，例如 `milvus/docker-compose/standalone-minio/` 或 `milvus/standalone/embedded-etcd-local/`。

欢迎贡献：新增预设或在合理默认上强化配置。
