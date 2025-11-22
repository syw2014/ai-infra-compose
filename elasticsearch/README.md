# Elasticsearch preset

Put your Elasticsearch `docker-compose.yml` here. Consider:
- For single-node dev, set `discovery.type=single-node`; for clusters, configure seed hosts and unique node names.
- Tune heap via `ES_JAVA_OPTS=-Xms1g -Xmx1g` and mount a data volume (`/usr/share/elasticsearch/data`).
- Set strong credentials (`ELASTIC_PASSWORD`) and enable TLS if exposed.
- Add Kibana/Logstash in the same project if needed for observability.
