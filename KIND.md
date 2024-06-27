# Fluentum Dependencies Installation on Kind Cluster

> [!NOTE]
> Following instructions are tested on Windows 10 with WSL2 and Ubuntu 22.04. You may need to adjust the instructions based on your operating system.

> [!IMPORTANT]
> You will need a machine with Docker installed to create a Kind cluster and minimum 8GB of RAM. This means If you use WSL on Windows, you will need a machine with at least 16 GB and allocate 8GB to WSL. If you want to run both Kafka plane and Fluentum control plane on the same machine, you will need a machine with minium 32GB of RAM and allocate 16GB to WSL.

> [!IMPORTANT]
> In this guide, you will not using cert-manager and external-dns. This means connection to Fluentum is not using TLS and you need to update your `/etc/hosts` file to access Fluentum components. The purpose of this guide is to provide a quick way to install Fluentum dependencies on Kind cluster for development and demo purposes.

## Prerequisites

1. [Docker](https://docs.docker.com/get-docker/). For Windows, you can use [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/).
1. [Kind](https://kind.sigs.k8s.io/). You can install Kind by following the instructions [here](https://kind.sigs.k8s.io/docs/user/quick-start/#installing-from-release-binaries).
1. [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/). You can install kubectl by following the instructions [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

## Create Kind Cluster

Since we want to be able to access the the dependencies from the host machine, we need to create a Kind cluster with a custom configuration. We will use the following configuration:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
```

This will create a Kind cluster that allow local host to make requests to the Ingress controller over ports 80/443. 

> [!IMPORTANT]
> In above configuration, we are using host ports 8080 and 8443. We are using these ports because 80 and 443 is recommended to be use by Kafka plane Kind cluster. This is important if you want to run both Kafka plane and Fluentum control plane on the same machine.

Create a Kind cluster with the above configuration:

```bash
kind create cluster --config kind/cluster/kind-config.yaml --name fluentum
```

> [!IMPORTANT]
> If you are using kind on Windows PowerShell and you want to access cluster from WSL, you will need to copy the kubeconfig file to WSL. You can do this by running the following command in WSL:

```bash
cp /mnt/c/Users/<username>/.kube/config ~/.kube/config
```

## Install Dependencies

### Update `/etc/hosts`


> [!IMPORTANT]
> In this guide, you will use domain example.local. You can choose to use any domain you want. Make sure to update the domain in the following steps.

Edit Windows hosts file (`C:\Windows\System32\drivers\etc\hosts`) and add the following entries:

```bash
127.0.0.1 prometheus.example.local
127.0.0.1 grafana.example.local
127.0.0.1 elasticsearch.example.local
127.0.0.1 kibana.example.local
127.0.0.1 app.example.local
127.0.0.1 api.example.local
```

### Ingress Controller

Install NGINX Ingress Controller for Kind by running the following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

See [Setting Up An Ingress Controller](https://kind.sigs.k8s.io/docs/user/ingress) for more information.

### Namespace

Create namespace for Fluentum dependencies installation:

```bash
kubectl create namespace fluentum
```

### Credentials

Starting from this point, you will need to create credentials for Fluentum dependencies. This repository provide example scripts to create credentials for Fluentum dependencies. You can choose to use the example scripts or create credentials manually.

> [!CAUTION]
> Make sure to edit [`credential.sh`](./script/credential.sh) to update the passwords and domain before running the scripts.

> [!NOTE]
> This repository used kustomize to install some of Fluentum dependencies.

### PostgreSQL

Install Kubegres PostgreSQL Operator using following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/reactive-tech/kubegres/v1.17/kubegres.yaml
```

Check if Kubegres PostgreSQL Operator is installed successfully:

```bash
kubectl get pods -n kubegres-system
```

> [!CAUTION]
> Make sure to update PostgreSQL credential in [`credential.sh`](./script/credential.sh) before installing PostgreSQL.

Create PostgreSQL credential

```bash
script/credential-postgres.sh
```

Install PostgreSQL

```bash
kubectl apply -k postgres
```

Check if PostgreSQL is installed successfully:

```bash
kubectl get pods -n fluentum
```

#### Creating databases

Fluentum requires two databases: `fluentum` and `grafana`. You can create the databases using following command:

```bash
kubectl exec -it -n fluentum fluentum-postgres-0 -- psql -U postgres -c "CREATE DATABASE fluentum;"
kubectl exec -it -n fluentum fluentum-postgres-0 -- psql -U postgres -c "CREATE DATABASE grafana;"
```

You will be prompted to enter password. Use the password that you created in the previous step.

### Prometheus Operator

Install Prometheus Operator using following command from [Prometheus Operator docs](https://prometheus-operator.dev/docs/user-guides/getting-started/#installing-the-operator):

> [!NOTE]
> Following command will install Prometheus Operator in `default` namespace. You can choose to install Prometheus Operator in a separate namespace if you want. If you choose to install Prometheus Operator in a separate namespace, you will need to update the bundle.yaml file accordingly.

```bash
LATEST=$(curl -s https://api.github.com/repos/prometheus-operator/prometheus-operator/releases/latest | jq -cr .tag_name)
curl -sL https://github.com/prometheus-operator/prometheus-operator/releases/download/${LATEST}/bundle.yaml | kubectl create -f -
```

### Prometheus

> [!NOTE]
> By default, Prometheus don't have authentication. In this repository, we use Basic Auth in NGINX Ingress Controller to provide authentication for Prometheus. 

> [!CAUTION]
> Make sure to update Prometheus credential in [`credential.sh`](./script/credential.sh) before installing Prometheus.

> [!IMPORTANT]
> Make sure to update Prometheus domain name in [`prometheus/prometheus-ingress.yaml`](./prometheus/prometheus-ingress.yaml) before installing Prometheus.

Create Prometheus credential

```bash
script/credential-prometheus.sh
```

Install Prometheus (this will also create Ingress resource for Prometheus):

```bash
kubectl apply -k kind/prometheus
```

Check if Prometheus is installed successfully:

```bash
kubectl get pods -n fluentum
```

Once Prometheus is installed, you can access Prometheus dashboard using its ingress URL. You will be prompted to enter username and password. Use the username and password that you created in the previous step.

```bash
open https://prometheus.example.local
```

### Grafana

> [!CAUTION]
> Make sure to update Grafana credential in [`credential.sh`](./script/credential.sh) before installing Grafana.

> [!IMPORTANT]
> Make sure to update Grafana domain name in [`grafana/grafana-ingress.yaml`](./grafana/grafana-ingress.yaml) before installing Grafana.

> [!IMPORTANT]
> Make sure to update Grafana root URL and Postgres credential in [`grafana/grafana-ini.yaml`](./grafana/grafana-ini.yaml) before installing Grafana.

Root URL and database section in [`grafana/grafana-ini.yaml`](./grafana/grafana-ini.yaml) should look like this:

```yaml
    root_url = https://grafana.example.local

    type = postgres
    host = fluentum-postgres:5432   # Use postgres service name only, since Grafana is deployed in the same namespace as PostgreSQL
    name = grafana
    user = postgres
    password = changeme

    ssl_mode = disable
```

> [!IMPORTANT]
> Make sure to update `GF_SECURITY_X_FRAME_OPTIONS` in [`grafana/grafana.yaml`](./grafana/grafana.yaml) with Fluentum UI domain before installing Grafana so that Grafana can be embedded in Fluentum UI.

Create Grafana credential

```bash
script/credential-grafana.sh
```

Install Grafana (this will also create Ingress resource for Grafana):

```bash
kubectl apply -k kind/grafana
```

Check if Grafana is installed successfully:

```bash
kubectl get pods -n fluentum
```

Once Grafana is installed, you can access Grafana dashboard using its ingress URL. You will be prompted to enter username and password. Use the username and password that you created in the previous step.

```bash
open https://grafana.example.local
```

#### Grafana configuration

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

## ECK Operator

Follow the instruction in [Elasticsearch Operator documentation](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-eck.html) to install ECK Operator.

```bash
kubectl create -f https://download.elastic.co/downloads/eck/2.11.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.11.0/operator.yaml
```

Check if ECK Operator is installed successfully:

```bash
kubectl get pods -n elastic-system
```

### Elasticsearch

> [!CAUTION]
> Make sure to update Elasticsearch credential in [`credential.sh`](./script/credential.sh) before installing Elasticsearch.

> [!IMPORTANT]
> Make sure to update Elasticsearch domain name in [`elasticsearch/elasticsearch-ingress.yaml`](./elasticsearch/elasticsearch-ingress.yaml) before installing Elasticsearch.

Create Elasticsearch credential

```bash
script/credential-elastic.sh
```

Install Elasticsearch (this will also create Ingress resource for Elasticsearch):

```bash
kubectl apply -k kind/elasticsearch
```

Check if Elasticsearch is installed successfully:

```bash
kubectl get pods -n fluentum
```

Once Elasticsearch is installed, you can access Elasticsearch using its ingress URL. You will be prompted to enter username and password. Use the username and password that you created in the previous step.

```bash
open https://elasticsearch.example.local
```

### Kibana

> [!CAUTION]
> Make sure to update Elastic anonymoys credential in [`credential.sh`](./script/credential.sh) before installing Kibana.

> [!IMPORTANT]
> Make sure to update Kibana domain name in [`kibana/kibana-ingress.yaml`](./kibana/kibana-ingress.yaml) before installing Kibana.

Create anonymous dashboard user in Elasticsearch and Index Lifecycle Policy.

```bash
script/credential-elastic-anonymous.sh
```

Install Kibana (this will also create Ingress resource for Kibana):

```bash
kubectl apply -k kind/kibana
```

Check if Kibana is installed successfully:
  
```bash
kubectl get pods -n fluentum
```

Once Kibana is installed, you can access Kibana dashboard using its ingress URL. You will be prompted to enter username and password. Use the username and password that you created in the previous step.

```bash
open https://kibana.example.local
```

For Administrator, you can login using Elasticsearch credential that you created in the previous step.

#### Audit log index pattern

Audit log index pattern is required to be created in Kibana before Fluentum can be installed. This is used to store audit log from Fluentum.

To generate audit_log_index_pattern_id:

```bash
script/kibana-audit-log-id.sh
```

Upon successful request, generated UUID will be printed on the console, copy that UUID to Fluentum app.yaml 

## Access Fluentum Dependencies from Another Kind Cluster

If you are running another Kind cluster to install Kafka plane, components in Kafka plane need to be able to access Fluentum dependencies specifically Prometheus to push metrics and Elasticsearch to push logs. To do this, you need to update Kafka cluster CoreDNS configuration to resolve Fluentum dependencies domain to the Fluentum Kind cluster.

First, get the IP address of the Fluentum Kind cluster:
```bash
docker inspect fluentum-control-plane
```

And get the IPAddress from the output. Then, update the CoreDNS configuration in the Kafka Kind cluster to resolve Fluentum dependencies domain to the Fluentum Kind cluster IP address.

```bash
k edit configmap -n kube-system coredns --context kind-fluentum
```

Add following lines to the `Corefile`:

```yaml
apiVersion: v1
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
        ## ------------ Add following lines amd use the IP address of the Fluentum Kind cluster ------------
        hosts {
          <IP> prometheus.example.local
          <IP> elasticsearch.example.local
          fallthrough
       }
    }
kind: ConfigMap
metadata:
  creationTimestamp: "2022-03-15T07:45:45Z"
  name: coredns
  namespace: kube-system
  resourceVersion: "123"
  uid: 1b1b1b1b-1b1b-1b1b-1b1b-1b1b1b1b1b1b
```

## Fluentum

Now that all the dependencies are installed, you can install Fluentum. Prepare the following information from the dependencies installation:

```yaml
database_url: postgres://postgres:changeme@fluentum-postgres:5432/fluentum?sslmode=disable
...
elasticsearch:
  address: https://elasticsearch.example.local
  username: elastic
  password: changeme
frontend:
  base_url: https://app.example.local
backend:
  base_url: https://api.example.local
prometheus:
  address: https://prometheus.example.local
  username: admin
  password: changeme
kibana:
  address: https://kibana.example.local
  username: elastic
  password: changeme
  audit_log_index_pattern_id: bd49adaf-5dac-4ed9-875c-xxxxx
grafana:
  address: https://grafana.example.local
  username: admin 
  password: changeme
  datasource_uid: eac72e5a-64d0-4629-b2d4-xxxxx
webhook:
  username: fluentum
  password: fluentum123
```

To install Fluentum, follow the instruction in [Fluentum installation guide](https://docs.fluentum.aegislabs.work/docs/installation/control-plane)
