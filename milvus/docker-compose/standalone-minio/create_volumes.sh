#!/bin/bash

set -e

DOCKER_VOLUME_BASE_DIR="${DOCKER_VOLUME_DIRECTORY:-.}"

echo "Creating Milvus volume directories under: $DOCKER_VOLUME_BASE_DIR/volumes"

mkdir -p "${DOCKER_VOLUME_BASE_DIR}/volumes"
mkdir -p "${DOCKER_VOLUME_BASE_DIR}/volumes/etcd"
mkdir -p "${DOCKER_VOLUME_BASE_DIR}/volumes/minio"
mkdir -p "${DOCKER_VOLUME_BASE_DIR}/volumes/milvus"

echo "Milvus volume directories created successfully."
echo "You can now run './deploy.sh' from milvus/docker-compose/standalone-minio."
