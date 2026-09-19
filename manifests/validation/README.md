```bash
kubectl apply --dry-run=client \
  -f manifests/namespace/

kubectl apply --dry-run=client \
  -f manifests/storage/

kubectl apply --dry-run=client \
  -f manifests/logging/

kubectl apply --dry-run=client \
  -f manifests/backup/

helm template kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f manifests/monitoring/values.yaml \
  > /tmp/monitoring-rendered.yaml

ls -lh /tmp/monitoring-rendered.yaml
```