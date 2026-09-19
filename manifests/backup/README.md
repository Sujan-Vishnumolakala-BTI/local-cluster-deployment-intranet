```bash
kubectl apply -f manifests/backup/etcd-backup-pvc.yaml
```

```bash
kubectl get pvc -n backup
```

```bash
kubectl apply -f manifests/backup/etcd-backup-cronjob.yaml
```

```bash
kubectl get cronjob -n backup
```
