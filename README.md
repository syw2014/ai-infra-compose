# AI Infra Compose

Curated Docker Compose presets for common AI application infrastructure (Redis, PostgreSQL + pgvector, Milvus, Elasticsearch, MinIO, and more). Use these as drop-in templates across MLOps or app stacks.

## Directory layout
- `redis/` — caching/queue backends.
- `postgres-pgvector/` — relational storage with vector similarity.
- `milvus/` — vector database service.
- `elasticsearch/` — search and log indexing.
- `minio/` — S3-compatible object storage.

## Usage
1) Pick a component directory and place your `docker-compose.yml` (or copy in the provided example when available).  
2) Adjust ports, passwords, and volumes; keep secrets in a local `.env`.  
3) Start it: `docker compose -f <component>/docker-compose.yml up -d`.  
4) Combine multiple services by sharing a project name (`-p ai-infra`) and a common network if needed.

## Conventions
- Prefer explicit volumes for data durability (e.g., bind to `./data/<component>`).  
- Expose only required ports; lock down defaults in production.  
- Keep service-specific notes inside each component directory.

Contributions: add new presets or harden existing ones with sensible defaults.
