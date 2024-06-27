# Fluentum Dependencies Installation using Docker Compose

If you don't have a Kubernetes cluster, you can use Docker Compose to install Fluentum dependencies. This repository contains a Docker Compose file to install Fluentum dependencies using Docker Compose.

> [!IMPORTANT]
> This installation is for development demo and testing purposes only using a single machine. It is not recommended for production use.

## Prerequisites

1. [Docker](https://docs.docker.com/get-docker/)
1. [Docker Compose](https://docs.docker.com/compose/install/)

## Installation

```bash
cd docker-compose
docker-compose up -d
```
## Grafana configuration

Before you can deploy Fluentum, you need get datasource and set webhook in Grafana. Login to Grafana to:

1. Create Prometheus datasource pointing to the Prometheus created above, and copy the id to Fluentum app.yaml
    - Left menu -> Connections -> Data sources -> Add data source -> Prometheus
    - Set Prometheus server URL to http://prometheus:9090 (We use internal connection from Grafana deployment to Prometheus service)
    - Open Prometheus data source detail to get data source id. You can find it in the URL. For example, if the URL is `https://grafana.example.local/datasources/edit/eac72e5a-64d0-4629-b2d4-xxxxx`, then the data source id is `eac72e5a-64d0-4629-b2d4-xxxxx`.
    - Take note of the data source id. We will need it later in Fluentum app.yaml
1. Set theme to light
    - Left menu -> Administration -> Default preferences -> Interface theme -> Light
1. Add webhook contact point
    - Left menu -> Alerting -> Contact points -> Add contact point
    - Details
        - Name: fluentum-webhook
        - Integration: webhook
        - URL: <Fluentum API URL>/webhook/grafana/alert
        - Webhook settings
            - HTTP Method: POST
            - Basic auth username
            - Basic auth password
            - Whatever username and password you want to use for Grafana to authenticate to Fluentum, you need to set it in Fluentum app.yaml in `webhook.username` and `webhook.password` respectively.
    - Since fluentum backend is not deployed yet, this will fail. Save for now and we will check later.
1. Update notification policies
    - Edit default notification policy to send notification to fluentum-webhook 

## Accessing Components

1. Prometheus: [http://localhost:9090](http://localhost:9090)
1. Grafana: [http://localhost:3000](http://localhost:3000)
1. Elasticsearch: [http://localhost:9200](http://localhost:9200)
1. Kibana: [http://localhost:5601](http://localhost:5601)

Optionally, you can update /etc/hosts file to use custom domains for components.

```bash
127.0.0.1 prometheus.example.local
127.0.0.1 grafana.example.local
127.0.0.1 elasticsearch.example.local
127.0.0.1 kibana.example.local
127.0.0.1 app.example.local
127.0.0.1 api.example.local
```

## Uninstallation

```bash
cd docker-compose
docker-compose down
```
