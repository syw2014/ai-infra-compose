# PostgreSQL + pgvector preset

Place your `docker-compose.yml` here for Postgres with the `pgvector` extension. Tips:
- Set `POSTGRES_USER`, `POSTGRES_PASSWORD`, and a default database via env or `.env`.
- Mount a data volume for durability (`/var/lib/postgresql/data`).
- Ensure the image includes `pgvector` (official `postgres` with `CREATE EXTENSION pgvector` or a prebuilt variant).
- Expose the port only when needed; consider `-c wal_level=logical` if logical replication is required.
