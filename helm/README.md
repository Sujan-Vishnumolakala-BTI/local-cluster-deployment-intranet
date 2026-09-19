# Helm

This directory contains Helm configuration used by the Local Kubernetes Cluster Deployment project.

Third-party Helm charts are installed from their official Helm repositories. The repository stores only the project-specific configuration and values.

## Components

| Component             | Purpose                                                     |
| --------------------- | ----------------------------------------------------------- |
| OpenEBS               | Persistent storage                                          |
| kube-prometheus-stack | Prometheus, Grafana, Alertmanager and Kubernetes monitoring |
| Loki                  | Log aggregation                                             |

## Helm Prerequisites

Verify Helm:

```bash
helm version
```

Verify Kubernetes access:

```bash
kubectl cluster-info
```

Verify nodes:

```bash
kubectl get nodes
```

---

# OpenEBS

Add the OpenEBS repository:

```bash
helm repo add openebs https://openebs.github.io/openebs
```

Update repositories:

```bash
helm repo update
```

Create the namespace:

```bash
kubectl create namespace openebs
```

Install OpenEBS:

```bash
helm upgrade --install openebs \
    openebs/openebs \
    --namespace openebs \
    --create-namespace \
    -f helm/openebs/values.yaml
```

Check the installation:

```bash
kubectl get pods -n openebs
```

Check StorageClasses:

```bash
kubectl get storageclass
```

Check the Helm release:

```bash
helm list -n openebs
```

---

# Monitoring

The monitoring stack uses the `kube-prometheus-stack` chart.

Add the Prometheus community repository:

```bash
helm repo add prometheus-community \
    https://prometheus-community.github.io/helm-charts
```

Update repositories:

```bash
helm repo update
```

Create the namespace:

```bash
kubectl create namespace monitoring
```

Install:

```bash
helm upgrade --install monitoring \
    prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    -f helm/monitoring/values.yaml
```

Check:

```bash
kubectl get pods -n monitoring
```

Check services:

```bash
kubectl get svc -n monitoring
```

Check the release:

```bash
helm list -n monitoring
```

---

# Logging

The logging stack uses Loki.

Add the Grafana Helm repository:

```bash
helm repo add grafana https://grafana.github.io/helm-charts
```

Update repositories:

```bash
helm repo update
```

Create the namespace:

```bash
kubectl create namespace logging
```

Install Loki:

```bash
helm upgrade --install loki \
    grafana/loki \
    --namespace logging \
    --create-namespace \
    -f helm/logging/loki-values.yaml
```

Check:

```bash
kubectl get pods -n logging
```

Check services:

```bash
kubectl get svc -n logging
```

---

# Helm Verification

List all Helm releases:

```bash
helm list -A
```

Example:

```text
NAME         NAMESPACE     STATUS
openebs      openebs       deployed
monitoring   monitoring    deployed
loki         logging       deployed
```

Check chart values:

```bash
helm get values openebs -n openebs
```

```bash
helm get values monitoring -n monitoring
```

```bash
helm get values loki -n logging
```

Inspect rendered Kubernetes resources:

```bash
helm template monitoring \
    prometheus-community/kube-prometheus-stack \
    -n monitoring \
    -f helm/monitoring/values.yaml
```

---

# Helm Upgrade

Before upgrading a release:

```bash
helm repo update
```

Then:

```bash
helm upgrade monitoring \
    prometheus-community/kube-prometheus-stack \
    -n monitoring \
    -f helm/monitoring/values.yaml
```

For Loki:

```bash
helm upgrade loki \
    grafana/loki \
    -n logging \
    -f helm/logging/loki-values.yaml
```

For OpenEBS:

```bash
helm upgrade openebs \
    openebs/openebs \
    -n openebs \
    -f helm/openebs/values.yaml
```

---

# Helm Rollback

Check release history:

```bash
helm history monitoring -n monitoring
```

Rollback to a previous revision:

```bash
helm rollback monitoring <REVISION> -n monitoring
```

Verify:

```bash
helm status monitoring -n monitoring
```

---

# Important Storage Configuration

The project uses OpenEBS for persistent storage.

The StorageClass referenced by monitoring, logging, and backup configurations must exist before deploying workloads.

Check:

```bash
kubectl get storageclass
```

If your StorageClass is not named:

```text
openebs-hostpath
```

update the corresponding values files.

For example:

```yaml
storageClassName: <YOUR-STORAGE-CLASS>
```

Do not assume that all OpenEBS installations provide the same StorageClass names.

---

# Uninstall

Remove monitoring:

```bash
helm uninstall monitoring -n monitoring
```

Remove Loki:

```bash
helm uninstall loki -n logging
```

Remove OpenEBS:

```bash
helm uninstall openebs -n openebs
```

PersistentVolumes and PersistentVolumeClaims should be reviewed separately before deleting storage-related resources.

## Verification Checklist

```text
[ ] Helm installed
[ ] Helm repositories configured
[ ] OpenEBS installed
[ ] StorageClasses available
[ ] Monitoring stack installed
[ ] Prometheus running
[ ] Grafana running
[ ] Alertmanager running
[ ] Loki installed
[ ] Loki running
[ ] Persistent storage configured
[ ] Helm releases verified
```
