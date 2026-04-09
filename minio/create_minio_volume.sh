#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-04-09
# @Description: Create MinIO local volume directories
###

set -e

DOCKER_VOLUME_BASE_DIR="${DOCKER_VOLUME_DIRECTORY:-.}"

echo "Creating MinIO volume directories under: ${DOCKER_VOLUME_BASE_DIR}/volumes"

mkdir -p "${DOCKER_VOLUME_BASE_DIR}/volumes"
mkdir -p "${DOCKER_VOLUME_BASE_DIR}/volumes/minio"

echo "MinIO volume directories created successfully."
echo "You can now run './deploy_minio.sh' from minio."
