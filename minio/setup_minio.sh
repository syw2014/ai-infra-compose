#!/bin/bash
###
# @Author: Jerry Shi
# @Email: jerryshi0110@gmail.com
# @Date: 2026-04-09
# @Description: Prepare local directories for MinIO deployment
###

set -e

echo "Preparing MinIO deployment environment..."

mkdir -p ./volumes/data

echo "✓ Created data directory: ./volumes/data"
