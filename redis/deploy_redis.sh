# 1. 下载脚本到您的项目目录
###
 # @Author: Jerry Shi
 # @Email: jerryshi0110@gmail.com
 # @Date: 2026-02-06 10:41:47
 # @LastEditors: Jerry Shi
 # @LastEditTime: 2026-02-06 10:44:13
 # @Description: file content
### 
# 2. 添加执行权限(如果需要)
chmod +x setup_redis.sh

# 3. 运行脚本
./setup_redis.sh

# 4. 启动Redis
sudo docker-compose up -d

echo ""
echo "✓ Redis deployed."
echo "  Port: 19531 (host) -> 6379 (container)"
echo "  Config: ./redis.conf"
echo "  Data:  ./volumes/redis"