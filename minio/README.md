# MinIO

Single-node MinIO preset following the same layout as other Compose-based components in this repository.

## Files
- `docker-compose.yml` - MinIO service definition.
- `env.example` - Default environment template. Copy to `.env` before deployment.
- `setup_minio.sh` - Creates local data directories.
- `deploy_minio.sh` - One-click deployment entrypoint.

## Quick Start
1. Enter the preset directory:
   ```bash
   cd minio
   ```
2. Copy the environment template and set a strong password:
   ```bash
   cp env.example .env
   ```
3. Deploy MinIO:
   ```bash
   chmod +x deploy_minio.sh setup_minio.sh
   ./deploy_minio.sh
   ```

## Access
- S3 API: `http://localhost:9000`
- Web console: `http://localhost:9001`

## Notes
- The deployment script uses the shared Compose wrapper and automatically picks `docker compose` or `docker-compose`.
- Persistent data is stored in `./volumes/data`.
- Keep secrets in `.env` and do not commit local credentials.
- For production, change default credentials, restrict exposed ports, and place MinIO behind TLS or a trusted network boundary.
