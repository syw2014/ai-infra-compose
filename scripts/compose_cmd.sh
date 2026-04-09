#!/bin/bash

set -euo pipefail

detect_compose_cmd() {
    local prefix=()

    if [ "${COMPOSE_USE_SUDO:-0}" = "1" ]; then
        prefix=(sudo)
    fi

    if [ "${#prefix[@]}" -gt 0 ]; then
        if "${prefix[@]}" docker compose version >/dev/null 2>&1; then
            COMPOSE_CMD=("${prefix[@]}" docker compose)
            return 0
        fi

        if "${prefix[@]}" docker-compose version >/dev/null 2>&1; then
            COMPOSE_CMD=("${prefix[@]}" docker-compose)
            return 0
        fi
    else
        if docker compose version >/dev/null 2>&1; then
            COMPOSE_CMD=(docker compose)
            return 0
        fi

        if docker-compose version >/dev/null 2>&1; then
            COMPOSE_CMD=(docker-compose)
            return 0
        fi
    fi

    echo "Error: neither 'docker compose' nor 'docker-compose' is available." >&2
    exit 1
}

compose() {
    if ! declare -p COMPOSE_CMD >/dev/null 2>&1 || [ "${#COMPOSE_CMD[@]}" -eq 0 ]; then
        detect_compose_cmd
    fi

    "${COMPOSE_CMD[@]}" "$@"
}
