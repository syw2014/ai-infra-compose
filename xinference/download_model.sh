#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-03-16
# @Description: Pre-download Xinference models into local cache volumes via SDKs
###

set -euo pipefail
cd "$(dirname "$0")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SOURCE=""
MODEL_ID=""
REVISION=""
PYTHON_BIN="${PYTHON_BIN:-python3}"

print_usage() {
    cat <<'EOF'
Usage:
  ./download_model.sh [--source modelscope|huggingface] --model-id MODEL_ID [--revision REVISION]

Options:
  --source      Download source, defaults to XINFERENCE_MODEL_SRC in .env, or modelscope
  --model-id    Upstream model id, for example BAAI/bge-m3 or Xorbits/bge-m3
  --revision    Optional revision / branch / tag
  --python      Python executable, default: python3
  -h, --help    Show this help message

Examples:
  ./download_model.sh --source modelscope --model-id Xorbits/bge-m3
  ./download_model.sh --source huggingface --model-id BAAI/bge-reranker-v2-m3
  ./download_model.sh --source huggingface --model-id BAAI/bge-m3
EOF
}

if [ -f ".env" ]; then
    set -a
    # shellcheck disable=SC1091
    source ./.env
    set +a
fi

SOURCE="${XINFERENCE_MODEL_SRC:-modelscope}"

while [ $# -gt 0 ]; do
    case "$1" in
        --source)
            SOURCE="$2"
            shift 2
            ;;
        --revision)
            REVISION="$2"
            shift 2
            ;;
        --model-id)
            MODEL_ID="$2"
            shift 2
            ;;
        --python)
            PYTHON_BIN="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown argument: $1${NC}"
            echo ""
            print_usage
            exit 1
            ;;
    esac
done

case "$SOURCE" in
    modelscope|huggingface)
        ;;
    *)
        echo -e "${RED}Unsupported source: ${SOURCE}${NC}"
        echo -e "${YELLOW}Supported values: modelscope, huggingface${NC}"
        exit 1
        ;;
esac

if [ -z "$MODEL_ID" ]; then
    echo -e "${RED}Missing model id.${NC}"
    echo -e "${YELLOW}Pass --model-id.${NC}"
    exit 1
fi

if ! command -v "${PYTHON_BIN}" >/dev/null 2>&1; then
    echo -e "${RED}Python executable not found: ${PYTHON_BIN}${NC}"
    exit 1
fi

chmod +x ./create_xinference_volumes.sh
./create_xinference_volumes.sh > /dev/null

HF_CACHE_DIR="${PWD}/volumes/models/huggingface"
MODELSCOPE_CACHE_DIR="${PWD}/volumes/models/modelscope"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Xinference Model Pre-download${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Source:     ${SOURCE}"
echo "Model ID:   ${MODEL_ID}"
if [ -n "$REVISION" ]; then
    echo "Revision:   ${REVISION}"
fi
echo "Python:     ${PYTHON_BIN}"
echo ""

if [ "${SOURCE}" = "huggingface" ]; then
    if ! "${PYTHON_BIN}" -c "import huggingface_hub" >/dev/null 2>&1; then
        echo -e "${RED}Missing Python dependency: huggingface_hub${NC}"
        echo -e "${YELLOW}Install it with:${NC}"
        echo "  ${PYTHON_BIN} -m pip install -U huggingface_hub"
        exit 1
    fi
else
    if ! "${PYTHON_BIN}" -c "import modelscope" >/dev/null 2>&1; then
        echo -e "${RED}Missing Python dependency: modelscope${NC}"
        echo -e "${YELLOW}Install it with:${NC}"
        echo "  ${PYTHON_BIN} -m pip install -U modelscope"
        exit 1
    fi
fi

export HF_HOME="${HF_CACHE_DIR}"
export MODELSCOPE_CACHE="${MODELSCOPE_CACHE_DIR}"
export HF_HUB_DISABLE_SYMLINKS_WARNING=1
if [ -n "${HF_ENDPOINT:-}" ]; then
    export HF_ENDPOINT
fi

if [ "${SOURCE}" = "huggingface" ]; then
    "${PYTHON_BIN}" - <<PY
from huggingface_hub import snapshot_download

local_dir = snapshot_download(
    repo_id="${MODEL_ID}",
    revision="${REVISION}",
    cache_dir="${HF_CACHE_DIR}",
    local_dir=None,
    local_dir_use_symlinks=False,
    resume_download=True,
)
print(local_dir)
PY
else
    "${PYTHON_BIN}" - <<PY
from modelscope.hub.snapshot_download import snapshot_download

local_dir = snapshot_download(
    model_id="${MODEL_ID}",
    revision="${REVISION}" or None,
    cache_dir="${MODELSCOPE_CACHE_DIR}",
)
print(local_dir)
PY
fi

echo ""
echo -e "${GREEN}✓ Model download completed${NC}"
echo -e "${GREEN}  Cache path is now available under ./volumes/models/${SOURCE}${NC}"
echo -e "${YELLOW}  Start Xinference with the same XINFERENCE_MODEL_SRC=${SOURCE} to reuse this cache.${NC}"
