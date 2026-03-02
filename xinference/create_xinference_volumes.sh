#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-03-02
# @Description: Create local volume directories for Xinference
###

set -e
cd "$(dirname "$0")"

echo "Creating Xinference volume directories..."
mkdir -p ./volumes/xinference
mkdir -p ./volumes/models/huggingface
mkdir -p ./volumes/models/modelscope

echo "✓ Volume directories ready:"
echo "   ./volumes/xinference           — Xinference config & registry"
echo "   ./volumes/models/huggingface   — HuggingFace model cache"
echo "   ./volumes/models/modelscope    — ModelScope model cache"
echo ""
echo "Tip: Pre-downloaded model files can be placed directly into these"
echo "     directories before starting the container."
