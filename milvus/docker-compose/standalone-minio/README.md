# Milvus via Docker Compose

This preset runs three containers:
- `milvus-standalone`
- `etcd`
- `minio`

Use this when you want a standard Compose deployment and S3-compatible object storage.

## Files
- `docker-compose.yml` - compose stack definition
- `.env.example` - MinIO credentials and optional volume root
- `create_volumes.sh` - prepares `etcd`, `minio`, and `milvus` volume directories
- `deploy.sh` - copies `.env` if missing, creates volumes, and starts the stack

## Start
```bash
cd milvus/docker-compose/standalone-minio
cp .env.example .env
./deploy.sh
```

## Notes
- Data is persisted under `${DOCKER_VOLUME_DIRECTORY:-.}/volumes`.
- This mode depends on MinIO. If you want local storage with no MinIO, use `../../standalone/embedded-etcd-local/`.
