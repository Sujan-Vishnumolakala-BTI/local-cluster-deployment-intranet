# Replace openebs-hostpath with the StorageClass selected for your cluster.

```bash 
helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f manifests/monitoring/values.yaml
```

```bash
kubectl get pods -n monitoring
```
