# Milvus preset

Drop your Milvus `docker-compose.yml` here. Common guidance:
- Decide on standalone vs distributed; standalone typically bundles etcd and MinIO.
- Persist data and metadata volumes (e.g., `/var/lib/milvus` and `/etcd`).
- Allocate enough resources (RAM/CPU) for index building; set `MILVUS_CACHE_SIZE` appropriately.
- If exposing externally, secure ports and credentials; consider a reverse proxy for TLS.
