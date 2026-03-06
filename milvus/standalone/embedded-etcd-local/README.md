# Milvus single-node without MinIO

This preset runs a single Milvus container with:
- embedded etcd
- local storage
- optional `user.yaml` overrides mounted into the container

Use this when you want the simplest single-node deployment and do not want a MinIO dependency.

## Files
- `standalone.sh` - lifecycle helper for `start`, `stop`, `restart`, and `delete`
- `user.yaml.example` - example overrides for Milvus 2.6.x

## Start
```bash
cd milvus/standalone/embedded-etcd-local
cp user.yaml.example user.yaml
./standalone.sh start
```

## Notes
- Data is stored under `./volumes/milvus`.
- This mode sets `COMMON_STORAGETYPE=local`.
- `embedEtcd.yaml` is generated automatically by the script when missing.
