```bash
helm upgrade --install loki \
  grafana/loki \
  --namespace logging \
  --create-namespace \
  -f manifests/logging/loki-values.yaml
```

```bash
kubectl get pods -n logging
```

```bash
kubectl apply -f manifests/logging/fluentd-daemonset.yaml
```

```bash
kubectl get daemonset -n logging
```

```bash
kubectl get pods -n logging -o wide
```
