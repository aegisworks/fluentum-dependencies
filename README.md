# Fluentum Dependencies

This repository contains guide and example scripts for installing Fluentum control plane dependencies in a Kubernetes cluster. 

> [!NOTE]
> This repository is not intended to be the only way to install Fluentum control plane dependencies, but rather an option for those who want to use Kubernetes. You are free to install Fluentum dependencies in VM or use managed services.

## Dependencies

Fluentum requires the following dependencies:

1. TLS certificate for Ingress Controller that covers all the domains Fluentum will use. This repository contains deployment of [cert-manager](https://cert-manager.io/docs/) to provision TLS certificates from [Let's Encrypt](https://letsencrypt.org/).
1. DNS records for the domains Fluentum will use. This repository contains deployment of [external-dns](https://github.com/kubernetes-sigs/external-dns) to manage DNS records.
1. Ingress Controller. This repository contains deployment of [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/). Ingress  Controller is used to route traffic to the Fluentum components.
1. PostgreSQL. This repository contains deployment of [PostgreSQL Operator](https://www.kubegres.io/) to manage PostgreSQL instance. PostgreSQL is used to store Fluentum data and Grafana data.
1. Prometheus. This repository contains deployment of [Prometheus Operator](https://prometheus-operator.dev/) to manage Prometheus instance. Prometheus is used to collect metrics from Fluentum components.
1. Grafana. This repository contains deployment of Grafana using standard Kubernetes yaml. Grafana is used to visualize metrics collected by Prometheus.
1. Elasticsearch. This repository contains deployment of [Elasticsearch Operator](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-quickstart.html) to manage Elasticsearch instance. Elasticsearch is used to store Fluentum logs.
1. Kibana. This repository contains deployment [Elasticsearch Operator](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-quickstart.html) to manage Kibana instance. Kibana is used to visualize logs stored in Elasticsearch.

## DNS records

Following DNS records are required and defined in the Ingress resources in this repository:

1. Prometheus domain (e.g. `prometheus.example.com`)
1. Grafana domain (e.g. `grafana.example.com`)
1. Elasticsearch domain (e.g. `elasticsearch.example.com`)
1. Kibana domain (e.g. `kibana.example.com`)

Please make sure to update the domains in the Ingress resources before deploying them. Above domains are required to be externally accessible because used by UI and components in Kafka plane.

You can also use path based routing instead of subdomain based routing. For example, you can use `example.com/prometheus` instead of `prometheus.example.com`. If you choose to use path based routing, you will need to update the Ingress resources accordingly.

> [!NOTE]
> Note that PostgreSQL does not require DNS records as it is not exposed to the internet.

## Dependency Credentials

Fluentum requires the following credentials:

1. PostgreSQL credentials as connection string
1. Prometheus credentials
1. Grafana credentials
1. Elasticsearch credentials
1. Kibana credentials

Please make sure that you take note of the credentials you use. You will need them when installing Fluentum.

> [!CAUTION]
> Credentials used in this repository are for demonstration purposes only. You must change them before deploying Fluentum dependencies.

## Installation

See  [installation guide](INSTALL.md) for instructions on how to install dependencies.

## Uninstallation

See  [uninstallation guide](UNINSTALL.md) for instructions on how to uninstall dependencies.
