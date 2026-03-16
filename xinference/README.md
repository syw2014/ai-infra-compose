# Xinference CPU

基于 [Xinference](https://github.com/xorbitsai/inference) 的 CPU 推理服务，专为部署 **Embedding** 和 **Rerank** 模型设计，无需 GPU。

## 适用场景

- BGE-M3、BGE-small-en-v1.5 等嵌入模型（Embedding）
- BGE-reranker-v2-m3、BGE-reranker-base 等重排模型（Rerank）
- 不依赖 GPU，适合纯 CPU 的服务器环境

## 目录结构

```
xinference/
├── docker-compose.yml            # Xinference 容器编排
├── env.example                   # 环境变量模板
├── create_xinference_volumes.sh  # 创建本地卷目录
├── download_model.sh             # 预下载模型到本地缓存
├── deploy_xinference.sh          # 一键部署脚本
└── volumes/
    ├── xinference/               # Xinference 配置与注册信息（自动创建）
    └── models/                   # HuggingFace / ModelScope 缓存（自动创建）
```

## 快速部署

```bash
chmod +x deploy_xinference.sh
./deploy_xinference.sh
```

脚本会自动完成：
1. 从 `env.example` 初始化 `.env`
2. 创建本地卷目录
3. 拉取镜像并启动服务
4. 等待健康检查通过

## 预下载模型

为避免容器启动后再在线下载模型，可以先将模型权重下载到挂载目录，Xinference 启动后会直接复用本地缓存。

```bash
# 使用 ModelScope 预下载
chmod +x download_model.sh
./download_model.sh --source modelscope --preset bge-m3
./download_model.sh --source modelscope --preset bge-reranker-v2-m3

# 使用 HuggingFace 预下载
./download_model.sh --source huggingface --preset bge-m3
./download_model.sh --source huggingface --preset bge-reranker-v2-m3
```

也支持传任意上游仓库 ID：

```bash
./download_model.sh --source huggingface --repo-id BAAI/bge-large-zh-v1.5
./download_model.sh --source modelscope --repo-id Xorbits/bge-large-zh-v1___5
```

注意：

- `XINFERENCE_MODEL_SRC` 必须与预下载使用的 `--source` 保持一致，否则 Xinference 会去另一套缓存目录查找模型。
- 脚本直接调用 Python SDK 下载模型：`huggingface_hub` 或 `modelscope`。
- 运行前请在宿主机安装对应依赖，例如 `python3 -m pip install -U huggingface_hub` 或 `python3 -m pip install -U modelscope`。
- 如需使用 HuggingFace 镜像站，可在 `.env` 中设置 `HF_ENDPOINT`。

## 服务信息

| 项目          | 地址                          |
|---------------|-------------------------------|
| API 根路径    | http://localhost:9997         |
| Web UI        | http://localhost:9997/ui      |
| OpenAI 兼容层 | http://localhost:9997/v1      |

## 环境变量说明

| 变量                    | 默认值           | 说明                                      |
|-------------------------|------------------|-------------------------------------------|
| `XINFERENCE_MODEL_SRC`  | `modelscope`     | 模型下载源，中国环境推荐 `modelscope`     |
| `XINFERENCE_HOME`       | `/root/.xinference` | 模型缓存目录（映射到 `./volumes/xinference`） |
| `HF_ENDPOINT`           | -                | HuggingFace 镜像站，`huggingface` 源时使用 |
| `TZ`                    | `Asia/Shanghai`  | 时区                                      |

## 启动模型

部署完成后，通过 CLI 或 Web UI 加载模型。

### Embedding 模型

```bash
# BGE-M3（多语言，推荐）
xinference launch --model-name bge-m3 --model-type embedding

# BGE-small-en-v1.5（轻量英文）
xinference launch --model-name bge-small-en-v1.5 --model-type embedding
```

### Rerank 模型

```bash
# BGE-reranker-v2-m3（多语言，推荐）
xinference launch --model-name bge-reranker-v2-m3 --model-type rerank

# BGE-reranker-base（轻量）
xinference launch --model-name bge-reranker-base --model-type rerank
```

### 通过 API 调用

```python
from xinference.client import Client

client = Client("http://localhost:9997")

# 调用 Embedding 模型
model = client.get_model("bge-m3")
embeddings = model.create_embedding("Hello, world!")

# 调用 Rerank 模型
reranker = client.get_model("bge-reranker-v2-m3")
result = reranker.rerank(
    documents=["doc1 content", "doc2 content"],
    query="your query"
)
```

### OpenAI 兼容接口

```bash
# Embedding
curl http://localhost:9997/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{"model": "bge-m3", "input": "Hello, world!"}'

# Rerank
curl http://localhost:9997/v1/rerank \
  -H "Content-Type: application/json" \
  -d '{
    "model": "bge-reranker-v2-m3",
    "query": "your query",
    "documents": ["doc1", "doc2"]
  }'
```

## 常用管理命令

```bash
# 查看日志
docker compose logs -f xinference

# 重启服务
docker compose restart xinference

# 停止服务
docker compose down

# 停止并清除数据卷（会删除已下载的模型缓存）
docker compose down -v
```

## 资源参考

| 模型                   | 类型      | 大小约    | 说明              |
|------------------------|-----------|-----------|-------------------|
| bge-m3                 | Embedding | ~2.3 GB   | 多语言，综合最优  |
| bge-small-en-v1.5      | Embedding | ~130 MB   | 轻量英文          |
| bge-reranker-v2-m3     | Rerank    | ~1.1 GB   | 多语言，综合最优  |
| bge-reranker-base      | Rerank    | ~280 MB   | 轻量中英文        |

> 模型首次启动时自动从 ModelScope / HuggingFace 下载，之后命中本地缓存。
>
> 如果已通过 `./download_model.sh` 预下载，容器启动后会直接复用缓存，通常不再需要在线下载。
