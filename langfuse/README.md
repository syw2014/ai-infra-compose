# Langfuse Deployment

One-click deployment script for Langfuse using existing PostgreSQL, Redis, and MinIO infrastructure.

## Quick Start

### Prerequisites

Ensure these services are running:
- ✅ **PostgreSQL** (port 5432) - `pgvector/pgvector:pg17`
- ✅ **Redis** (port 19531) - `redis:7-alpine`
- ✅ **MinIO** (ports 9000-9001) - `minio/minio`

Deploy them first if needed:
```bash
cd ../postgres-pgvector && ./deploy_postgres.sh
cd ../redis && ./deploy_redis.sh
cd ../milvus && ./deploy_milvus.sh  # includes MinIO
```

### Deploy Langfuse

```bash
chmod +x deploy_langfuse.sh
./deploy_langfuse.sh
```

The script will:
1. Check if PostgreSQL, Redis, MinIO are running
2. Download official Langfuse configuration files
3. Modify docker-compose.yml (remove bundled DB services, add host.docker.internal support)
4. Generate secure secrets (NEXTAUTH_SECRET, SALT, ENCRYPTION_KEY, etc.)
5. Prompt for configuration (PostgreSQL password, MinIO credentials, etc.)
6. Create .env file with all settings
7. Initialize PostgreSQL database and MinIO bucket
8. Start Langfuse services

**Access Langfuse**: http://localhost:3000

## Management Commands

Use the management script for common operations:

```bash
./manage.sh start       # Start services
./manage.sh stop        # Stop services
./manage.sh restart     # Restart services
./manage.sh status      # Show status
./manage.sh logs        # View all logs
./manage.sh logs-web    # View web logs only
./manage.sh health      # Run health check
./manage.sh backup      # Backup database
./manage.sh restore     # Restore from backup
./manage.sh upgrade     # Pull latest images
```

Or use Docker Compose directly:
```bash
docker compose ps               # Status
docker compose logs -f          # All logs
docker compose logs -f langfuse-web   # Web logs
docker compose restart          # Restart all
docker compose down             # Stop and remove
```

## Service Architecture

| Component | Port | Description |
|-----------|------|-------------|
| Langfuse Web | 3000 | Web UI and API |
| ClickHouse HTTP | 8123 | Analytics database |
| ClickHouse Native | 9900 | Internal protocol |
| PostgreSQL* | 5432 | Main database (external) |
| Redis* | 19531 | Cache & queue (external) |
| MinIO* | 9000 | Object storage (external) |

\* Using existing external services

## Configuration Files

- `docker-compose.yml` - Modified compose file (original backed up as `.original`)
- `.env` - Main configuration (auto-generated, **DO NOT commit**)
- `.secrets` - Backup of generated secrets (chmod 600, **DO NOT commit**)
- `docker-compose.yml.original` - Original official compose file

## Scripts

| Script | Purpose |
|--------|---------|
| `deploy_langfuse.sh` | One-click deployment |
| `manage.sh` | Service management |
| `health_check.sh` | Health monitoring |
| `backup.sh` | Database and config backup |
| `restore.sh` | Restore from backup |

## Troubleshooting

### Check Service Health

```bash
./health_check.sh
```

### View Logs

```bash
docker compose logs -f langfuse-web
docker compose logs -f langfuse-worker
docker compose logs -f clickhouse
```

### Common Issues

**Database connection failed?**
```bash
# Verify PostgreSQL is running
docker ps | grep postgres

# Test connection from Langfuse container
docker compose exec langfuse-web sh -c "nc -zv host.docker.internal 5432"

# Check DATABASE_URL in .env
grep DATABASE_URL .env
```

**MinIO connection failed?**
```bash
# Verify MinIO is running
docker ps | grep minio

# Check bucket exists
docker exec milvus-minio mc ls local/langfuse

# Create bucket manually at http://localhost:9001
```

**ClickHouse unhealthy?**
```bash
# Check logs
docker compose logs clickhouse

# Test health endpoint
curl http://localhost:8123/ping
```

## Backup & Restore

**Automatic Backup** (scheduled daily at 2 AM):
```bash
# Add to crontab
(crontab -l 2>/dev/null; echo "0 2 * * * $(pwd)/backup.sh") | crotab -
```

**Manual Backup**:
```bash
./backup.sh
# Creates: backups/langfuse_db_YYYYMMDD_HHMMSS.sql.gz
#          backups/langfuse_config_YYYYMMDD_HHMMSS.tar.gz
```

**Restore**:
```bash
./restore.sh
# Prompts for backup file, drops database, restores, restarts services
```

## Upgrade

```bash
./manage.sh upgrade
# Or manually:
# docker compose pull
# docker compose up -d
```

## Security Notes

- `.env` and `.secrets` contain sensitive data - **never commit to version control**
- All secrets are auto-generated with strong randomness (32 bytes)
- Backups include database dumps and config - protect backup directory
- For production: use reverse proxy (Nginx/Caddy) with HTTPS

## Port Configuration

If default ports conflict, edit `.env` before deployment:

```bash
WEB_HOST_PORT=3000              # Langfuse web UI
CLICKHOUSE_HTTP_PORT=8123       # ClickHouse HTTP API
CLICKHOUSE_NATIVE_PORT=9900     # ClickHouse native (changed from 9000 to avoid MinIO conflict)
```

## Complete Cleanup

**Warning: Deletes all data!**

```bash
docker compose down -v                              # Remove containers and volumes
docker exec postgres psql -U postgres -c "DROP DATABASE langfuse;"  # Drop database
docker exec milvus-minio mc rm -r --force local/langfuse            # Delete bucket
rm -rf .env .secrets backups/                       # Remove config and backups
```

## Documentation

- [Detailed Deployment Guide](./README-DETAILED.md) - Comprehensive manual with troubleshooting
- [Official Langfuse Docs](https://langfuse.com/docs)
- [Langfuse GitHub](https://github.com/langfuse/langfuse)

## Support

For issues:
1. Run `./health_check.sh` to diagnose
2. Check logs: `docker compose logs`
3. See [README-DETAILED.md](./README-DETAILED.md) for comprehensive troubleshooting
