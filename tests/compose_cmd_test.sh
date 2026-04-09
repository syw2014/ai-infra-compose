#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HELPER_PATH="${ROOT_DIR}/scripts/compose_cmd.sh"

assert_eq() {
    local expected=$1
    local actual=$2
    local message=$3

    if [ "$expected" != "$actual" ]; then
        echo "FAIL: ${message}"
        echo "  expected: ${expected}"
        echo "  actual:   ${actual}"
        exit 1
    fi
}

make_stub_bin() {
    local bin_dir=$1
    mkdir -p "$bin_dir"

    cat > "${bin_dir}/docker" <<'EOF'
#!/bin/bash
if [ "${DOCKER_COMPOSE_AVAILABLE:-0}" = "1" ] && [ "${1:-}" = "compose" ] && [ "${2:-}" = "version" ]; then
  exit 0
fi
exit 1
EOF
    chmod +x "${bin_dir}/docker"

    cat > "${bin_dir}/docker-compose" <<'EOF'
#!/bin/bash
if [ "${DOCKER_COMPOSE_V1_AVAILABLE:-0}" = "1" ] && [ "${1:-}" = "version" ]; then
  exit 0
fi
exit 1
EOF
    chmod +x "${bin_dir}/docker-compose"

    cat > "${bin_dir}/sudo" <<'EOF'
#!/bin/bash
if [ "$#" -eq 0 ]; then
  exit 1
fi
exec "$@"
EOF
    chmod +x "${bin_dir}/sudo"
}

run_case() {
    local expected=$1
    local docker_available=$2
    local docker_compose_available=$3
    local use_sudo=$4
    local bin_dir

    bin_dir="$(mktemp -d)"
    make_stub_bin "$bin_dir"

    PATH="${bin_dir}:$PATH" \
    DOCKER_COMPOSE_AVAILABLE="$docker_available" \
    DOCKER_COMPOSE_V1_AVAILABLE="$docker_compose_available" \
    COMPOSE_USE_SUDO="$use_sudo" \
    bash -c "
      set -euo pipefail
      source \"$HELPER_PATH\"
      detect_compose_cmd
      printf '%s' \"\${COMPOSE_CMD[*]}\"
    " > "${bin_dir}/result.txt"

    assert_eq "$expected" "$(cat "${bin_dir}/result.txt")" "compose command should resolve correctly"
    rm -rf "$bin_dir"
}

run_lazy_detection_case() {
    local expected=$1
    local docker_available=$2
    local docker_compose_available=$3
    local use_sudo=$4
    local bin_dir

    bin_dir="$(mktemp -d)"
    make_stub_bin "$bin_dir"

    PATH="${bin_dir}:$PATH" \
    DOCKER_COMPOSE_AVAILABLE="$docker_available" \
    DOCKER_COMPOSE_V1_AVAILABLE="$docker_compose_available" \
    COMPOSE_USE_SUDO="$use_sudo" \
    bash -c "
      set -euo pipefail
      source \"$HELPER_PATH\"
      compose version >/dev/null 2>&1
      printf '%s' \"\${COMPOSE_CMD[*]}\"
    " > "${bin_dir}/result.txt"

    assert_eq "$expected" "$(cat "${bin_dir}/result.txt")" "compose should lazily detect command without bad substitution"
    rm -rf "$bin_dir"
}

run_case "docker compose" 1 1 0
run_case "docker-compose" 0 1 0
run_case "sudo docker compose" 1 0 1
run_case "sudo docker-compose" 0 1 1
run_lazy_detection_case "docker compose" 1 0 0

echo "compose_cmd_test.sh: all cases passed"
