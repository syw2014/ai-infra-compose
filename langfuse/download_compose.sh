# 1. 下载 docker-compose.yml
###
 # @Author: Jerry Shi
 # @Email: jerryshi0110@gmail.com
 # @Date: 2026-02-06 10:24:16
 # @LastEditors: Jerry Shi
 # @LastEditTime: 2026-02-06 10:24:19
 # @Description: file content
### 
wget https://raw.githubusercontent.com/langfuse/langfuse/main/docker-compose.yml

# 2. 下载 .env.dev.example (作为环境变量模板)
wget https://raw.githubusercontent.com/langfuse/langfuse/main/.env.dev.example

# 3. 复制并重命名为 .env
cp .env.dev.example .env