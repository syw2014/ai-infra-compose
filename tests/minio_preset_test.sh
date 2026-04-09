#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MINIO_DIR="${ROOT_DIR}/minio"

assert_file_exists() {
    local path=$1

    if [ ! -f "$path" ]; then
        echo "FAIL: expected file to exist: $path"
        exit 1
    fi
}

assert_contains() {
    local path=$1
    local pattern=$2

    if ! grep -Fq "$pattern" "$path"; then
        echo "FAIL: expected '$path' to contain: $pattern"
        exit 1
    fi
}

assert_executable_hint() {
    local path=$1
    assert_contains "$path" "#!/bin/bash"
}

assert_file_exists "${MINIO_DIR}/docker-compose.yml"
assert_file_exists "${MINIO_DIR}/deploy_minio.sh"
assert_file_exists "${MINIO_DIR}/create_minio_volume.sh"
assert_file_exists "${MINIO_DIR}/env.example"

assert_contains "${MINIO_DIR}/docker-compose.yml" "minio/minio:RELEASE.2025-07-23T15-54-02Z"
assert_contains "${MINIO_DIR}/docker-compose.yml" '${MINIO_API_PORT:-9000}:9000'
assert_contains "${MINIO_DIR}/docker-compose.yml" '${MINIO_CONSOLE_PORT:-9001}:9001'
assert_contains "${MINIO_DIR}/docker-compose.yml" '${DOCKER_VOLUME_DIRECTORY:-.}/volumes/minio:/data'
assert_contains "${MINIO_DIR}/docker-compose.yml" ".env"

assert_executable_hint "${MINIO_DIR}/deploy_minio.sh"
assert_contains "${MINIO_DIR}/deploy_minio.sh" 'source "${ROOT_DIR}/scripts/compose_cmd.sh"'
assert_contains "${MINIO_DIR}/deploy_minio.sh" "./create_minio_volume.sh"
assert_contains "${MINIO_DIR}/deploy_minio.sh" "compose up -d"

assert_executable_hint "${MINIO_DIR}/create_minio_volume.sh"
assert_contains "${MINIO_DIR}/create_minio_volume.sh" 'DOCKER_VOLUME_BASE_DIR="${DOCKER_VOLUME_DIRECTORY:-.}"'
assert_contains "${MINIO_DIR}/create_minio_volume.sh" 'mkdir -p "${DOCKER_VOLUME_BASE_DIR}/volumes/minio"'

assert_contains "${MINIO_DIR}/env.example" "MINIO_ROOT_USER=minioadmin"
assert_contains "${MINIO_DIR}/env.example" "MINIO_ROOT_PASSWORD="

assert_contains "${MINIO_DIR}/README.md" "./deploy_minio.sh"
assert_contains "${MINIO_DIR}/README.md" "DOCKER_VOLUME_DIRECTORY"
assert_contains "${MINIO_DIR}/README.md" "docker compose"
assert_contains "${MINIO_DIR}/README.md" ".env"

echo "minio_preset_test.sh: all cases passed"
