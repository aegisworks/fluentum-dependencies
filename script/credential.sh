#!/bin/bash

## Prometheus
export PROMETHEUS_USERNAME="admin"
export PROMETHEUS_PASSWORD="changeme"

## Grafana
export GRAFANA_USERNAME="admin"
export GRAFANA_PASSWORD="changeme"
export GRAFANA_URL="https://grafana.example.com" 

# Elasticsearch
# Note that username must be elastic
export ELASTIC_USERNAME="elastic"
export ELASTIC_PASSWORD="changeme"
export ELASTIC_URL="https://elasticsearch.example.com"

# Kibana
export KIBANA_URL="https://kibana.example.com"

# Elasticsearch anonymous user
export ANONYMOUS_USERNAME="dviewer"
export ANONYMOUS_PASSWORD="changeme"
export ANONYMOUS_FULL_NAME="Dashboard Viewer"
export ANONYMOUS_EMAIL="dviewer@example.com"

# PostgreSQL
export POSTGRES_SUPERUSER_PASSWORD="changeme"
export POSTGRES_REPLICATION_PASSWORD="changeme"
