#!/bin/bash

# Define the base directory for Docker volumes.
# This should match the DOCKER_VOLUME_DIRECTORY variable used in docker-compose.yml.
# If DOCKER_VOLUME_DIRECTORY is not set in your environment, it will default to the current directory.
# Example: export DOCKER_VOLUME_DIRECTORY=/opt/milvus-data
DOCKER_VOLUME_BASE_DIR="${DOCKER_VOLUME_DIRECTORY:-.}"

echo "Creating Milvus volume directories under: $DOCKER_VOLUME_BASE_DIR/volumes"

# Create the main volumes directory if it doesn't exist
mkdir -p "${DOCKER_VOLUME_BASE_DIR}/volumes"

# Create subdirectories for each service
mkdir -p "${DOCKER_VOLUME_BASE_DIR}/volumes/etcd"
mkdir -p "${DOCKER_VOLUME_BASE_DIR}/volumes/minio"
mkdir -p "${DOCKER_VOLUME_BASE_DIR}/volumes/milvus"

echo "Milvus volume directories created successfully."
echo "You can now run 'docker compose -f milvus-standalone-docker-compose.yml up -d' to start Milvus."