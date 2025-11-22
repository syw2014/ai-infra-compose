# Redis preset

Put your `docker-compose.yml` here for Redis. Suggested defaults:
- Set a password (e.g., `REDIS_PASSWORD` with `--requirepass` or `redis.conf`).
- Add a data volume for persistence (`/data`).
- For HA, include sentinel/replica services in the same compose project.
