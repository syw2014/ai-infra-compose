<!--
 * @Author: Jerry Shi
 * @Email: jerryshi0110@gmail.com
 * @Date: 2026-02-06 10:25:00
 * @LastEditors: Jerry Shi
 * @LastEditTime: 2026-02-06 10:25:04
 * @Description: file content
-->
# 1. 创建工作目录
mkdir langfuse-deploy
cd langfuse-deploy

# 2. 下载必要文件
wget https://raw.githubusercontent.com/langfuse/langfuse/main/docker-compose.yml
wget https://raw.githubusercontent.com/langfuse/langfuse/main/.env.dev.example

# 3. 创建并配置 .env 文件
cp .env.dev.example .env

# 4. 生成安全的密钥
echo "SALT=$(openssl rand -hex 16)" >> .env
echo "ENCRYPTION_KEY=$(openssl rand -hex 32)" >> .env
echo "NEXTAUTH_SECRET=$(openssl rand -hex 32)" >> .env

# 5. 编辑 .env 文件,修改必要的配置
nano .env  # 或使用其他编辑器

# 6. 启动服务
docker compose up -d

# 7. 查看日志
docker compose logs -f