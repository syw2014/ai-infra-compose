#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MILVUS_IMAGE="${MILVUS_IMAGE:-milvusdb/milvus:v2.6.4}"
CONTAINER_NAME="${CONTAINER_NAME:-milvus-standalone}"

ensure_embed_config() {
    if [ ! -f "${SCRIPT_DIR}/embedEtcd.yaml" ]; then
        cat << EOF > "${SCRIPT_DIR}/embedEtcd.yaml"
listen-client-urls: http://0.0.0.0:2379
advertise-client-urls: http://0.0.0.0:2379
quota-backend-bytes: 4294967296
auto-compaction-mode: revision
auto-compaction-retention: '1000'
EOF
    fi
}

ensure_user_config() {
    if [ ! -f "${SCRIPT_DIR}/user.yaml" ]; then
        if [ -f "${SCRIPT_DIR}/user.yaml.example" ]; then
            cp "${SCRIPT_DIR}/user.yaml.example" "${SCRIPT_DIR}/user.yaml"
        else
            cat << EOF > "${SCRIPT_DIR}/user.yaml"
# Extra config to override default milvus.yaml
EOF
        fi
    fi
}

run_embed() {
    ensure_embed_config
    ensure_user_config
    mkdir -p "${SCRIPT_DIR}/volumes/milvus"

    docker run -d \
        --name "${CONTAINER_NAME}" \
        --security-opt seccomp:unconfined \
        -e ETCD_USE_EMBED=true \
        -e ETCD_DATA_DIR=/var/lib/milvus/etcd \
        -e ETCD_CONFIG_PATH=/milvus/configs/embedEtcd.yaml \
        -e COMMON_STORAGETYPE=local \
        -e DEPLOY_MODE=STANDALONE \
        -v "${SCRIPT_DIR}/volumes/milvus:/var/lib/milvus" \
        -v "${SCRIPT_DIR}/embedEtcd.yaml:/milvus/configs/embedEtcd.yaml" \
        -v "${SCRIPT_DIR}/user.yaml:/milvus/configs/user.yaml" \
        -p 19530:19530 \
        -p 9091:9091 \
        -p 2379:2379 \
        --health-cmd="curl -f http://localhost:9091/healthz" \
        --health-interval=30s \
        --health-start-period=90s \
        --health-timeout=20s \
        --health-retries=3 \
        "${MILVUS_IMAGE}" \
        milvus run standalone > /dev/null
}

wait_for_milvus_running() {
    echo "Wait for Milvus starting..."
    while true
    do
        res=$(docker ps | grep "${CONTAINER_NAME}" | grep healthy | wc -l)
        if [ "$res" -eq 1 ]; then
            echo "Start successfully."
            echo "Edit user.yaml and restart the container if you need to change Milvus defaults."
            break
        fi
        sleep 1
    done
}

start() {
    res=$(docker ps | grep "${CONTAINER_NAME}" | grep healthy | wc -l)
    if [ "$res" -eq 1 ]; then
        echo "Milvus is running."
        exit 0
    fi

    res=$(docker ps -a | grep "${CONTAINER_NAME}" | wc -l)
    if [ "$res" -eq 1 ]; then
        docker start "${CONTAINER_NAME}" > /dev/null
    else
        run_embed
    fi

    wait_for_milvus_running
}

stop() {
    docker stop "${CONTAINER_NAME}" > /dev/null
    echo "Stop successfully."
}

delete_container() {
    res=$(docker ps | grep "${CONTAINER_NAME}" | wc -l)
    if [ "$res" -eq 1 ]; then
        echo "Please stop Milvus service before delete."
        exit 1
    fi
    docker rm "${CONTAINER_NAME}" > /dev/null
    echo "Delete Milvus container successfully."
}

delete() {
    read -p "Delete container and local data under ${SCRIPT_DIR}/volumes? [y/N] > " check
    if [ "$check" = "y" ] || [ "$check" = "Y" ]; then
        delete_container
        rm -rf "${SCRIPT_DIR}/volumes"
        rm -f "${SCRIPT_DIR}/embedEtcd.yaml"
        rm -f "${SCRIPT_DIR}/user.yaml"
        echo "Delete successfully."
    else
        echo "Exit delete."
    fi
}

case $1 in
    restart)
        stop
        start
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    delete)
        delete
        ;;
    *)
        echo "Usage: bash standalone.sh restart|start|stop|delete"
        ;;
esac
