<!--
 * @Author: Jerry Shi
 * @Email: jerryshi0110@gmail.com
 * @Date: 2025-11-22 10:28:35
 * @LastEditors: Jerry Shi
 * @LastEditTime: 2026-02-06 10:38:47
 * @Description: file content
-->
# 1. 创建本地目录
mkdir -p ./volumes/redis

# 2. 设置权限
sudo chown -R 999:999 ./volumes/redis

# 3. 启动服务
docker-compose up -d

# 4. 查看状态
docker-compose ps

# 5. 查看日志
docker-compose logs -f redis