# AI Infra Compose

Curated Docker Compose presets for common AI application infrastructure (Redis, PostgreSQL + pgvector, Milvus, Elasticsearch, MinIO, and more). Use these as drop-in templates across MLOps or app stacks.

## Directory layout
- `redis/` — caching/queue backends.
- `postgres-pgvector/` — relational storage with vector similarity.
- `milvus/` — vector database service, organized by deployment mode.
- `elasticsearch/` — search and log indexing.
- `minio/` — S3-compatible object storage.

## Usage
1) Pick a component directory and, when multiple presets exist, choose the deployment-mode subdirectory first.
2) Read that preset's `README.md` and use its entrypoint.
3) For Compose-based presets, adjust ports, passwords, and volumes, keep secrets in a local `.env`, then run `docker compose up -d`.
4) For script-based presets, run the provided helper such as `./deploy.sh` or `./standalone.sh start`.
5) Combine multiple services by sharing a project name (`-p ai-infra`) and a common network if needed.

## Conventions
- Prefer explicit volumes for data durability (e.g., bind to `./data/<component>`).  
- Expose only required ports; lock down defaults in production.  
- Keep service-specific notes inside each component directory.
- For Milvus, use explicit preset paths such as `milvus/docker-compose/standalone-minio/` or `milvus/standalone/embedded-etcd-local/`.

Contributions: add new presets or harden existing ones with sensible defaults.
