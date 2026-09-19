# Namespace Manifests

This directory contains the namespaces used by the project.

## Namespaces

| Namespace    | Purpose                              |
| ------------ | ------------------------------------ |
| `monitoring` | Prometheus, Grafana and Alertmanager |
| `logging`    | Loki and Fluentd                     |
| `backup`     | Automated etcd backups               |

## Apply

```bash
kubectl apply -f namespaces.yaml
```

## Verify

```bash
kubectl get namespace monitoring logging backup
```
