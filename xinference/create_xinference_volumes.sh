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

echo "✓ Volume directory ready: ./volumes/xinference"
