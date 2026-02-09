# Langfuse Quick Reference

## One-Command Deployment

```bash
./deploy_langfuse.sh
```

## Daily Operations

```bash
./manage.sh status      # Check services
./manage.sh logs        # View logs
./manage.sh restart     # Restart
./manage.sh health      # Health check
```

## Backup & Restore

```bash
./backup.sh             # Backup now
./restore.sh            # Restore from backup
```

## URLs

- **Langfuse**: http://localhost:3000
- **ClickHouse**: http://localhost:8123
- **MinIO Console**: http://localhost:9001

## Default Credentials (MinIO)

- Username: `minioadmin`
- Password: `minioadmin`

## Important Files

- `.env` - Configuration (auto-generated, don't commit)
- `.secrets` - Backup of secrets (auto-generated, don't commit)
- `backups/` - Database backups

## Troubleshooting One-Liners

```bash
# Fix: Database connection failed
grep DATABASE_URL .env  # Check connection string

# Fix: MinIO access denied
docker exec milvus-minio mc ls local/langfuse  # Verify bucket

# Fix: ClickHouse unhealthy
curl http://localhost:8123/ping  # Test health

# Fix: Service won't start
docker compose logs langfuse-web  # Check logs
```

## Emergency Commands

```bash
# Stop everything
docker compose down

# Complete cleanup (DELETES DATA!)
docker compose down -v
docker exec postgres psql -U postgres -c "DROP DATABASE langfuse;"
```

## File Structure

```
langfuse/
├── deploy_langfuse.sh       # Main deployment script
├── manage.sh                # Management commands
├── health_check.sh          # Health monitoring
├── backup.sh                # Backup script
├── restore.sh               # Restore script
├── docker-compose.yml       # Modified compose file
├── .env                     # Configuration (generated)
├── .secrets                 # Secrets backup (generated)
├── backups/                 # Backup directory (created)
├── README.md                # This file
└── README-DETAILED.md       # Comprehensive guide
```

## Support

For detailed troubleshooting, see [README-DETAILED.md](./README-DETAILED.md)
