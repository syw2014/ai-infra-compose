# Milvus deployment presets

This directory is organized by deployment mode first, not by file type.

## Layout
- `docker-compose/standalone-minio/` - Docker Compose deployment with standalone Milvus, external etcd container, and bundled MinIO.
- `standalone/embedded-etcd-local/` - Single-node deployment with `docker run`, embedded etcd, and local storage instead of MinIO.

## Which one to choose
- Choose `docker-compose/standalone-minio/` when you want a conventional Compose stack and S3-compatible object storage.
- Choose `standalone/embedded-etcd-local/` when you want the simplest single-node deployment and do not want MinIO.
