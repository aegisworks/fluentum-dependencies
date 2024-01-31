#  Fluentum Dependencies Uninstallation

Run the following commands to uninstall Fluentum dependencies:

```bash
kubectl delete -k kibana
kubectl delete -k elasticsearch
kubectl delete -k elastic-operator

kubectl delete -k grafana

kubectl delete -k prometheus
kubectl delete ns prometheus-operator

kubectl delete ns kubegres-system
kubectl delete -k postgres

helm uninstall ingress-nginx -n nginx
kubectl delete namespace nginx

helm uninstall cert-manager -n cert-manager
kubectl delete namespace cert-manager

kubectl delete ns external-dns
```
