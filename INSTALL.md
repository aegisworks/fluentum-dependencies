#  Fluentum Dependencies Installation

## Namespace

Create namespace for Fluentum installation:

```bash
kubectl create namespace fluentum
```

Fluentum use ingress to route traffic to control plane components and it is mandatory to have TLS secrets and ingress resources in the same namespace. It is recommended to install Fluentum dependencies that use Ingress and Fluentum itself in a same namespace so that they can share secrets. Note that this is not a hard requirement and you can install Fluentum dependencies in a separate namespace if you want. If you choose to install Fluentum dependencies in a separate namespace, you will need to create necessary TLS secrets in that namespace.

Following is a table of namespaces for Fluentum dependencies:

| Dependency | Namespace |
| ---------- | --------- |
| cert-manager | cert-manager |
| external-dns | external-dns |
| NGINX Ingress Controller | nginx |
| PostgreSQL | fluentum |
| Prometheus | fluentum |
| Grafana | fluentum |
| Elasticsearch | fluentum |
| Kibana | fluentum |

## DNS provider credentials

> [!NOTE]
> Integration of DNS records is optional. You can choose to create DNS records and TLS certificate manually if you want.

Decide on DNS name and provider that you want to use and follow the instruction in your DNS provider documentation to create credentials for the DNS provider. You will need to provide the credentials to the external-dns deployment and cert-manager TLS certificate issuer.

For examples:
- If you want to use DigitalOcean as your DNS provider, you can follow the instruction in [DigitalOcean documentation](https://docs.digitalocean.com/reference/api/create-personal-access-token/) to create personal access token with `Read` and `Write` permissions.
- If you want to use Cloudflare as your DNS provider, you can follow the instruction in [Cloudflare documentation](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) to create API token with `Zone:Read` and `DNS:Edit` permissions.

Take note of the credentials you create. You will need them when installing external-dns and cert-manager TLS certificate issuer.

## Cert-manager

Install cert-manager using Helm:

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.3 \
  --set installCRDs=true
```

Check if cert-manager is installed successfully:

```bash
kubectl get pods -n cert-manager
```

## TLS certificate issuer

Cert-manager support multiple TLS certificate issuers. You can choose to use Let's Encrypt or other TLS certificate issuers. This repository contains example of using Let's Encrypt as TLS certificate cluster issuer using DNS-01 challenge.

List of supported DNS providers can be found in [cert-manager documentation](https://cert-manager.io/docs/configuration/acme/dns01/).

Before deploying cluster issuer, you need to create secrets for DNS provider credentials. Following is example of creating DigitalOcean credentials secret for cert-manager:
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: do-credentials
  namespace: cert-manager
type: Opaque
data:
  access-token: <your DigitalOcean API token with base64 encoding>
EOF
```

Following is example of cluster issuer for Let's Encrypt using DigitalOcean as DNS provider:

> [!IMPORTANT]
> Make sure to use credentials secret name and key that you created in the previous step and update email address with your email address.

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: do-dns-staging
  namespace: cert-manager
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: <your email>
    preferredChain: 'ISRG Root X1'
    privateKeySecretRef:
      name: letsencrypt-do-staging
    solvers:
    - dns01:
        digitalocean:
          tokenSecretRef:
            name: do-credentials
            key: access-token
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: do-dns-prod
  namespace: cert-manager
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: <your email>
    preferredChain: 'ISRG Root X1'
    privateKeySecretRef:
      name: letsencrypt-do-prod
    solvers:
    - dns01:
        digitalocean:
          tokenSecretRef:
            name: do-credentials
            key: access-token
EOF
```

## TLS certificate

Following is example of TLS certificate for Fluentum control plane:

> [!IMPORTANT]
> Make sure to update domain name `example.com` in the TLS certificate example deployment with your domain name.

> [!IMPORTANT]
> Make sure to update issuer name in the TLS certificate example deployment with your TLS certificate issuer name

> [!NOTE]
> Following example use wildcard certificate. You can also use certificate for specific domain name.

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: fluentum-tls
  namespace: fluentum
spec:
  secretName: fluentum-tls
  issuerRef:
    name: do-dns-prod
    kind: ClusterIssuer
    group: cert-manager.io
  commonName: "*.example.com"
  dnsNames:
    - "*.example.com"
EOF
```

## External-dns

External-dns support multiple DNS providers. You can choose to use Cloudflare or other DNS providers. 

List of supported DNS providers can be found in [external-dns documentation](https://kubernetes-sigs.github.io/external-dns/v0.14.0/). Please follow the instruction in the documentation to deploy external-dns that is configured to use your DNS provider.

Following is example of [external-dns deployment for DigitalOcean](external-dns/external-dns.yaml):

First, create namespace for external-dns amd create secret for DigitalOcean API token:

```bash
kubectl create ns external-dns

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: do-credentials
  namespace: external-dns
type: Opaque
data:
  access-token: <your DigitalOcean API token with base64 encoding>
EOF
```

Then deploy external-dns:

> [!IMPORTANT]
> Make sure to use credentials secret name and key that you created in the previous step.

> [!IMPORTANT]
> Make sure to update `<domain name>` in the external-dns example deployment with your domain name.

> [!WARNING]
> Following yaml use DigitalOcean as DNS provider. You can choose to use other DNS providers.

```bash
kubectl apply -f external-dns/external-dns.yaml -n external-dns
```

Check if external-dns is installed successfully:

```bash
kubectl get pods -n external-dns
```

## Ingress Controller

Install NGINX Ingress Controller using Helm:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace nginx \
  --create-namespace \
  --set controller.publishService.enabled=true \
  --set controller.extraArgs.enable-ssl-passthrough="true"
```

Check if NGINX Ingress Controller is installed successfully:

```bash
kubectl get pods -n nginx
```

This will create a LoadBalancer service in the `nginx` namespace to allow external access to the Ingress Controller. 

## Credentials

Starting from this point, you will need to create credentials for Fluentum dependencies. This repository provide example scripts to create credentials for Fluentum dependencies. You can choose to use the example scripts or create credentials manually.

> [!CAUTION]
> Make sure to edit [`credential.sh`](./script/credential.sh) to update the passwords and domain before running the scripts.

> [!NOTE]
> This repository used kustomize to install some of Fluentum dependencies.

## PostgreSQL

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

## Creating databases

Fluentum requires two databases: `fluentum` and `grafana`. You can create the databases using following command:

```bash
kubectl exec -it -n fluentum fluentum-postgres-0 -- psql -U postgres -c "CREATE DATABASE fluentum;"
kubectl exec -it -n fluentum fluentum-postgres-0 -- psql -U postgres -c "CREATE DATABASE grafana;"
```

You will be prompted to enter password. Use the password that you created in the previous step.

## Prometheus Operator

Install Prometheus Operator using following command from [Prometheus Operator docs](https://prometheus-operator.dev/docs/user-guides/getting-started/#installing-the-operator):

> [!NOTE]
> Following command will install Prometheus Operator in `default` namespace. You can choose to install Prometheus Operator in a separate namespace if you want. If you choose to install Prometheus Operator in a separate namespace, you will need to update the bundle.yaml file accordingly.

```bash
LATEST=$(curl -s https://api.github.com/repos/prometheus-operator/prometheus-operator/releases/latest | jq -cr .tag_name)
curl -sL https://github.com/prometheus-operator/prometheus-operator/releases/download/${LATEST}/bundle.yaml | kubectl create -f -
```

## Prometheus

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
kubectl apply -k prometheus
```

Check if Prometheus is installed successfully:

```bash
kubectl get pods -n fluentum
```

Once Prometheus is installed, you can access Prometheus dashboard using its ingress URL. You will be prompted to enter username and password. Use the username and password that you created in the previous step.

```bash
open https://prometheus.example.com
```

## Grafana

> [!CAUTION]
> Make sure to update Grafana credential in [`credential.sh`](./script/credential.sh) before installing Grafana.

> [!IMPORTANT]
> Make sure to update Grafana domain name in [`grafana/grafana-ingress.yaml`](./grafana/grafana-ingress.yaml) before installing Grafana.

> [!IMPORTANT]
> Make sure to update Grafana root URL and Postgres credential in [`grafana/grafana-ini.yaml`](./grafana/grafana-ini.yaml) before installing Grafana.

Root URL and database section in [`grafana/grafana-ini.yaml`](./grafana/grafana-ini.yaml) should look like this:

```yaml
    root_url = https://grafana.example.com

    type = postgres
    host = fluentum-postgres:5432   # Use postgres service name only, since Grafana is deployed in the same namespace as PostgreSQL
    name = grafana
    user = postgres
    password = changeme

    ssl_mode = disable
```

> [!IMPORTANT]
> Make sure to update `GF_SECURITY_X_FRAME_OPTIONS` in [`grafana/grafana.yaml`](./grafana/grafana.yaml) with Fluentum UI domain before installing Grafana.

Create Grafana credential

```bash
script/credential-grafana.sh
```

Install Grafana (this will also create Ingress resource for Grafana):

```bash
kubectl apply -k grafana
```

Check if Grafana is installed successfully:

```bash
kubectl get pods -n fluentum
```

Once Grafana is installed, you can access Grafana dashboard using its ingress URL. You will be prompted to enter username and password. Use the username and password that you created in the previous step.

```bash
open https://grafana.example.com
```

## Grafana configuration

Before you can deploy Fluentum, you need get datasource and set webhook in Grafana. Login to Grafana to:

1. Create Prometheus datasource pointing to the Prometheus created above, and copy the id to Fluentum app.yaml
    - Left menu -> Connections -> Data sources -> Add data source -> Prometheus
    - Set Prometheus server URL to http://prometheus:9090 (We use internal connection from Grafana deployment to Prometheus service)
    - Open Prometheus data source detail to get data source id. You can find it in the URL. For example, if the URL is `https://grafana.example.com/datasources/edit/eac72e5a-64d0-4629-b2d4-xxxxx`, then the data source id is `eac72e5a-64d0-4629-b2d4-xxxxx`.
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

## Elasticsearch

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
kubectl apply -k elasticsearch
```

Check if Elasticsearch is installed successfully:

```bash
kubectl get pods -n fluentum
```

Once Elasticsearch is installed, you can access Elasticsearch using its ingress URL. You will be prompted to enter username and password. Use the username and password that you created in the previous step.

```bash
open https://elasticsearch.example.com
```

## Kibana

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
kubectl apply -k kibana
```

Check if Kibana is installed successfully:
  
```bash
kubectl get pods -n fluentum
```

Once Kibana is installed, you can access Kibana dashboard using its ingress URL. You will be prompted to enter username and password. Use the username and password that you created in the previous step.

```bash
open https://kibana.example.com
```

For Administrator, you can login using Elasticsearch credential that you created in the previous step.

## Audit log index pattern

Audit log index pattern is required to be created in Kibana before Fluentum can be installed. This is used to store audit log from Fluentum.

To generate audit_log_index_pattern_id:

```bash
script/kibana-audit-log-id.sh
```

Upon successful request, generated UUID will be printed on the console, copy that UUID to Fluentum app.yaml 

## Fluentum

Now that all the dependencies are installed, you can install Fluentum. Prepare the following information from the dependencies installation:

```yaml
database_url: postgres://postgres:changeme@fluentum-postgres:5432/fluentum?sslmode=disable
...
elasticsearch:
  address: https://elasticsearch.example.com
  username: elastic
  password: changeme
frontend:
  base_url: https://app.example.com
backend:
  base_url: https://api.example.com
prometheus:
  address: https://prometheus.example.com
  username: admin
  password: changeme
kibana:
  address: https://kibana.example.com
  username: elastic
  password: changeme
  audit_log_index_pattern_id: bd49adaf-5dac-4ed9-875c-xxxxx
grafana:
  address: https://grafana.example.com
  username: admin 
  password: changeme
  datasource_uid: eac72e5a-64d0-4629-b2d4-xxxxx
webhook:
  username: fluentum
  password: fluentum123
```

To install Fluentum, follow the instruction in [Fluentum installation guide](https://docs.fluentum.aegislabs.work/docs/installation/control-plane)
