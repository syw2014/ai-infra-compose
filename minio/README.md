# MinIO preset

Place your MinIO `docker-compose.yml` here. Recommendations:
- Set `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` (or `MINIO_ACCESS_KEY`/`MINIO_SECRET_KEY`).
- Expose API (`9000`) and console (`9001`) ports as needed; keep them private unless secured.
- Mount data volumes or host paths for buckets (e.g., `/data`).
- Enable TLS and `MINIO_BROWSER_REDIRECT_URL` when fronted by a reverse proxy.
