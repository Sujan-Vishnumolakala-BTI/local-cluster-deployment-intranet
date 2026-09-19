# Cluster Validation

This directory contains validation scripts for the Local Kubernetes Cluster Deployment project.

The validation scripts are designed to verify the major infrastructure and Kubernetes components after deployment.

## Validation Areas

```text
Kubernetes
    │
    ├── Control Plane
    ├── Worker Nodes
    ├── API Server
    └── Calico
          │
          ▼
       Storage
          │
          └── OpenEBS
                │
                ├── PVC
                └── PV
          │
          ▼
      Monitoring
          │
          ├── Prometheus
          ├── Grafana
          └── Alertmanager
          │
          ▼
       Logging
          │
          ├── Fluentd
          └── Loki
          │
          ▼
      ETCD Backup
          │
          ├── CronJob
          ├── PVC
          └── Snapshot
```

## Prerequisites

The following commands should be available:

```bash
kubectl
helm
```

For storage validation:

```bash
kubectl
```

For etcd backup validation:

```bash
kubectl
```

## Run All Validation

From the repository root:

```bash
./validation/validate-cluster.sh
```

Then:

```bash
./validation/validate-storage.sh
```

```bash
./validation/validate-monitoring.sh
```

```bash
./validation/validate-logging.sh
```

```bash
./validation/validate-backup.sh
```

## Recommended Validation Order

Run the checks in this order:

```text
1. Kubernetes cluster
       ↓
2. Storage
       ↓
3. Monitoring
       ↓
4. Logging
       ↓
5. etcd backup
```

Do not troubleshoot higher-level components until the Kubernetes API and nodes are healthy.

## Expected Result

A healthy deployment should have:

```text
Control-plane nodes    Ready
Worker nodes            Ready
Calico                  Running
CoreDNS                 Running
OpenEBS                  Running
PVCs                     Bound
Prometheus               Running
Grafana                  Running
Alertmanager             Running
Loki                     Running
Fluentd                  Running
etcd backup CronJob      Scheduled
etcd backup PVC          Bound
```

## Troubleshooting

If a validation script reports a failure, inspect the corresponding component.

### Nodes

```bash
kubectl get nodes -o wide
```

### Pods

```bash
kubectl get pods -A
```

### Events

```bash
kubectl get events -A --sort-by=.lastTimestamp
```

### Storage

```bash
kubectl get pv,pvc -A
```

### Helm

```bash
helm list -A
```

### Backup

```bash
kubectl get cronjob,job,pod,pvc -n backup
```
