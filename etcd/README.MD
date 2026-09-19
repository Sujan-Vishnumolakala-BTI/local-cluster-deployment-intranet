The etcd-backup-cronjob.yaml from Part 12 needs two changes for the scripts above:

Provide the three etcd endpoints.
Force the backup pod onto a control-plane node because /etc/kubernetes/pki/etcd is a control-plane host path.

Update the container environment with:

```yaml
env:
  - name: BACKUP_DIR
    value: /backup

  - name: ETCD_ENDPOINTS
    value: "https://<MASTER01-IP>:2379,https://<MASTER02-IP>:2379,https://<MASTER03-IP>:2379"

  - name: ETCD_CACERT
    value: /etc/kubernetes/pki/etcd/ca.crt

  - name: ETCD_CERT
    value: /etc/kubernetes/pki/etcd/server.crt

  - name: ETCD_KEY
    value: /etc/kubernetes/pki/etcd/server.key

  - name: RETENTION_DAYS
    value: "7"
```

Add the following under the CronJob pod's `spec`:

```yaml
nodeSelector:
  node-role.kubernetes.io/control-plane: ""

tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
```

Why this scheduling rule matters

Your etcd certificates are located on the control-plane machines:

```text
/etc/kubernetes/pki/etcd/
├── ca.crt
├── server.crt
└── server.key
```

Workers normally do not have these files.

Therefore:

```text
CronJob
   │
   ▼
Backup Pod
   │
   ├── must run on Control Plane
   │
   ├── mounts /etc/kubernetes/pki/etcd
   │
   └── connects to
        │
        ├── Master 1 etcd :2379
        ├── Master 2 etcd :2379
        └── Master 3 etcd :2379
                 │
                 ▼
          Detect current leader
                 │
                 ▼
          Snapshot from leader
                 │
                 ▼
          OpenEBS PVC /backup
```

Make the scripts executable

```bash
chmod +x etcd/backup.sh
chmod +x etcd/restore.sh
chmod +x etcd/health-check.sh
```

Quick local health-check example

On a control-plane node:

```bash
export ETCD_ENDPOINTS="https://<MASTER01-IP>:2379,https://<MASTER02-IP>:2379,https://<MASTER03-IP>:2379"

./etcd/health-check.sh
```