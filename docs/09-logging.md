# 09 — Centralized Logging

## Overview

This project uses **Fluentd + Loki + Grafana** for centralized Kubernetes logging.

The logging architecture collects container logs from all Kubernetes nodes, forwards them to Loki, and provides centralized log visualization through Grafana.

The monitoring and logging architecture is:

```text
                         Kubernetes Cluster
                                |
              +-----------------+-----------------+
              |                 |                 |
           Worker 01         Worker 02         Worker 03
              |                 |                 |
          Container Logs   Container Logs   Container Logs
              |                 |                 |
              +-----------------+-----------------+
                                |
                           Fluentd
                        DaemonSet
                                |
                                v
                              Loki
                                |
                                v
                             Grafana
```

Prometheus remains responsible for metrics, while Loki is responsible for logs.

---

# 1. Logging Components

The logging stack consists of:

| Component  | Purpose                                         |
| ---------- | ----------------------------------------------- |
| Fluentd    | Collects and forwards Kubernetes container logs |
| Loki       | Stores and indexes log metadata                 |
| Grafana    | Queries and visualizes logs                     |
| Kubernetes | Generates container and system logs             |
| OpenEBS    | Provides persistent storage for Loki            |

The responsibilities are separated:

```text
Prometheus → Metrics
Loki       → Logs
Grafana    → Visualization
Fluentd    → Log Collection
```

---

# 2. Kubernetes Logging Architecture

Container logs are normally available on each Kubernetes node.

A simplified flow is:

```text
Application Container
        |
        v
Container Runtime
        |
        v
Node Log Files
        |
        v
Fluentd
        |
        v
Loki
        |
        v
Grafana
```

Because Fluentd is deployed as a DaemonSet, each eligible node can run a Fluentd instance.

---

# 3. Create Logging Namespace

Create the namespace:

```bash
kubectl create namespace logging
```

Verify:

```bash
kubectl get namespace logging
```

Expected:

```text
NAME       STATUS
logging    Active
```

---

# 4. Install Loki

The project uses Helm for Loki deployment.

Add the Grafana Helm repository:

```bash
helm repo add grafana https://grafana.github.io/helm-charts
```

Update Helm repositories:

```bash
helm repo update
```

Search for Loki:

```bash
helm search repo grafana/loki
```

---

# 5. Loki Storage

Loki should use persistent storage so that log data does not disappear when the Loki pod is recreated.

The storage architecture is:

```text
Loki
 |
 v
PersistentVolumeClaim
 |
 v
OpenEBS StorageClass
 |
 v
PersistentVolume
 |
 v
OpenEBS
```

Check the available StorageClasses:

```bash
kubectl get storageclass
```

Use the OpenEBS StorageClass selected for this cluster.

Do not assume that all OpenEBS StorageClasses provide the same replication or failure behavior.

---

# 6. Loki Values File

Create:

```text
manifests/logging/loki-values.yaml
```

Example:

```yaml
deploymentMode: SingleBinary

loki:
  auth_enabled: false

  commonConfig:
    replication_factor: 1

  storage:
    type: filesystem

  limits_config:
    retention_period: 168h
    allow_structured_metadata: true
    volume_enabled: true

singleBinary:
  replicas: 1

  persistence:
    enabled: true
    storageClass: <OPENEBS_STORAGE_CLASS>
    accessModes:
      - ReadWriteOnce
    size: 20Gi

gateway:
  enabled: false

monitoring:
  selfMonitoring:
    enabled: false

  lokiCanary:
    enabled: false

test:
  enabled: false
```

Replace:

```text
<OPENEBS_STORAGE_CLASS>
```

with the StorageClass configured in the cluster.

For example, if the selected StorageClass is:

```text
openebs-hostpath
```

then use:

```yaml
storageClass: openebs-hostpath
```

The storage engine and replication behavior must be understood before using a StorageClass for production log retention.

---

# 7. Install Loki

Install Loki using the values file:

```bash
helm install loki \
  grafana/loki \
  --namespace logging \
  -f manifests/logging/loki-values.yaml
```

Verify:

```bash
helm list -n logging
```

Expected release:

```text
loki
```

---

# 8. Verify Loki

Check pods:

```bash
kubectl get pods -n logging
```

Check deployments:

```bash
kubectl get deployments -n logging
```

Check services:

```bash
kubectl get svc -n logging
```

Check PVC:

```bash
kubectl get pvc -n logging
```

Expected PVC state:

```text
STATUS
Bound
```

---

# 9. Verify Loki Logs

Get Loki pods:

```bash
kubectl get pods -n logging
```

View logs:

```bash
kubectl logs -n logging <LOKI-POD>
```

Follow logs:

```bash
kubectl logs -n logging <LOKI-POD> -f
```

Look for errors related to:

```text
storage
filesystem
permissions
ingester
compactor
configuration
```

---

# 10. Loki Service

Check the Loki service:

```bash
kubectl get svc -n logging
```

Typical Loki access inside the cluster is through:

```text
http://loki.logging.svc.cluster.local:3100
```

Verify the service:

```bash
kubectl describe svc loki -n logging
```

The exact service name can differ depending on the Helm chart configuration.

Use:

```bash
kubectl get svc -n logging
```

to determine the actual service name.

---

# 11. Loki Health Check

Port-forward Loki:

```bash
kubectl port-forward \
  -n logging \
  svc/loki \
  3100:3100
```

Test:

```bash
curl http://localhost:3100/ready
```

Expected:

```text
ready
```

Another useful endpoint is:

```bash
curl http://localhost:3100/metrics
```

---

# 12. Fluentd Architecture

Fluentd is deployed as a DaemonSet.

```text
             Kubernetes Nodes
                    |
       +------------+------------+
       |            |            |
    Fluentd      Fluentd      Fluentd
    Pod          Pod          Pod
       |            |            |
       +------------+------------+
                    |
                    v
                   Loki
```

Each Fluentd instance collects logs from its local node.

---

# 13. Fluentd Namespace

Fluentd can run in the same `logging` namespace:

```bash
kubectl get namespace logging
```

If it does not exist:

```bash
kubectl create namespace logging
```

---

# 14. Fluentd Service Account

Create:

```text
manifests/logging/fluentd-rbac.yaml
```

Example:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluentd
  namespace: logging
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fluentd
rules:
  - apiGroups: [""]
    resources:
      - pods
      - namespaces
    verbs:
      - get
      - list
      - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fluentd
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: fluentd
subjects:
  - kind: ServiceAccount
    name: fluentd
    namespace: logging
```

Apply:

```bash
kubectl apply -f manifests/logging/fluentd-rbac.yaml
```

Verify:

```bash
kubectl get serviceaccount -n logging
```

---

# 15. Fluentd Configuration

Create:

```text
manifests/logging/fluentd-configmap.yaml
```

Example:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: logging
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/fluentd-containers.log.pos
      tag kubernetes.*
      read_from_head true

      <parse>
        @type cri
      </parse>
    </source>

    <filter kubernetes.**>
      @type kubernetes_metadata
    </filter>

    <match kubernetes.**>
      @type loki
      url "http://loki.logging.svc.cluster.local:3100"

      <label>
        job kubernetes
        namespace_name $.kubernetes.namespace_name
        pod_name $.kubernetes.pod_name
        container_name $.kubernetes.container_name
      </label>

      line_format json
    </match>
```

The exact Fluentd Loki output plugin must be installed in the Fluentd image.

---

# 16. Fluentd Image

Fluentd requires the appropriate Loki output plugin.

Do not assume that the default Fluentd image contains every output plugin.

The project can use a custom Fluentd image.

Create:

```text
docker/fluentd/Dockerfile
```

Example:

```dockerfile
FROM fluent/fluentd:v1.18-debian-1

USER root

RUN gem install fluent-plugin-grafana-loki

USER fluent
```

Build:

```bash
docker build \
  -t local-fluentd:loki \
  docker/fluentd/
```

If the cluster uses containerd and the image is built on a separate machine, make the image available to every node or push it to a registry accessible by the cluster.

---

# 17. Fluentd DaemonSet

Create:

```text
manifests/logging/fluentd-daemonset.yaml
```

Example:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: logging
spec:
  selector:
    matchLabels:
      app: fluentd

  template:
    metadata:
      labels:
        app: fluentd

    spec:
      serviceAccountName: fluentd

      tolerations:
        - operator: Exists

      containers:
        - name: fluentd
          image: local-fluentd:loki
          imagePullPolicy: IfNotPresent

          resources:
            requests:
              cpu: 100m
              memory: 200Mi
            limits:
              cpu: 500m
              memory: 500Mi

          volumeMounts:
            - name: varlog
              mountPath: /var/log

            - name: fluentd-config
              mountPath: /fluentd/etc/fluent.conf
              subPath: fluent.conf

      volumes:
        - name: varlog
          hostPath:
            path: /var/log

        - name: fluentd-config
          configMap:
            name: fluentd-config
```

Apply:

```bash
kubectl apply -f manifests/logging/fluentd-daemonset.yaml
```

---

# 18. Verify Fluentd

Check the DaemonSet:

```bash
kubectl get daemonset -n logging
```

Check pods:

```bash
kubectl get pods -n logging -o wide
```

The number of Fluentd pods should correspond to the number of eligible Kubernetes nodes.

For example:

```text
fluentd-xxxxx
fluentd-yyyyy
fluentd-zzzzz
```

---

# 19. Check Fluentd Logs

Get Fluentd pods:

```bash
kubectl get pods -n logging
```

Check logs:

```bash
kubectl logs -n logging <FLUENTD-POD>
```

Look for successful connection/output messages.

Common errors include:

```text
connection refused
authentication failed
plugin not found
permission denied
configuration error
```

---

# 20. Test Log Collection

Create a test application:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: log-test
  namespace: default
spec:
  replicas: 1

  selector:
    matchLabels:
      app: log-test

  template:
    metadata:
      labels:
        app: log-test

    spec:
      containers:
        - name: log-test
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - |
              while true; do
                echo "Kubernetes centralized logging test"
                sleep 10
              done
```

Apply:

```bash
kubectl apply -f log-test.yaml
```

Check logs:

```bash
kubectl logs deployment/log-test
```

Expected:

```text
Kubernetes centralized logging test
```

---

# 21. Verify Logs in Fluentd

Find the node running the test pod:

```bash
kubectl get pod -o wide
```

Then inspect the Fluentd pod on the same node.

```bash
kubectl get pods -n logging -o wide
```

Check:

```bash
kubectl logs -n logging <FLUENTD-POD>
```

The Fluentd instance should process the container log.

---

# 22. Verify Logs in Loki

Query Loki through its HTTP API.

Port-forward:

```bash
kubectl port-forward \
  -n logging \
  svc/loki \
  3100:3100
```

Check labels:

```bash
curl http://localhost:3100/loki/api/v1/labels
```

If logs have been successfully ingested, Kubernetes-related labels should be available.

Query streams:

```bash
curl \
  "http://localhost:3100/loki/api/v1/query?query={namespace_name=\"default\"}"
```

The exact query depends on the labels configured by Fluentd.

---

# 23. Add Loki to Grafana

Grafana is already deployed by the monitoring stack.

Open Grafana:

```bash
kubectl port-forward \
  -n monitoring \
  svc/kube-prometheus-stack-grafana \
  3000:80
```

Open:

```text
http://localhost:3000
```

Navigate to:

```text
Connections
    ↓
Data Sources
    ↓
Add data source
    ↓
Loki
```

Set the Loki URL to the internal Kubernetes service:

```text
http://loki.logging.svc.cluster.local:3100
```

If the service name differs:

```bash
kubectl get svc -n logging
```

Use the actual Loki service name.

Click:

```text
Save & Test
```

---

# 24. Query Logs in Grafana

Open:

```text
Explore
```

Select:

```text
Loki
```

A basic LogQL query is:

```logql
{namespace_name="default"}
```

Filter by application:

```logql
{namespace_name="default", pod_name=~"log-test-.*"}
```

Filter by container:

```logql
{container_name="log-test"}
```

Search for an error:

```logql
{namespace_name="default"} |= "error"
```

Search for a specific message:

```logql
{namespace_name="default"} |= "Kubernetes centralized logging test"
```

---

# 25. LogQL Concepts

Loki uses **LogQL** for log queries.

Basic selector:

```logql
{namespace_name="default"}
```

Multiple labels:

```logql
{namespace_name="default", container_name="log-test"}
```

Substring filtering:

```logql
{namespace_name="default"} |= "error"
```

Exclude text:

```logql
{namespace_name="default"} != "healthcheck"
```

Regular expression:

```logql
{namespace_name="default"} |~ "error|failed|fatal"
```

LogQL can be used from Grafana Explore and dashboards.

---

# 26. Logging Architecture with Monitoring

The completed observability architecture is:

```text
                     Kubernetes Cluster
                            |
            +---------------+---------------+
            |                               |
          Metrics                           Logs
            |                               |
       Node Exporter                     Fluentd
            |                               |
     kube-state-metrics                     |
            |                               |
            v                               v
        Prometheus                         Loki
            |                               |
            +---------------+---------------+
                            |
                         Grafana
                            |
                +-----------+-----------+
                |                       |
            Dashboards                Logs
```

Prometheus and Loki remain separate data stores.

Grafana provides a common visualization interface.

---

# 27. Log Retention

Loki retention should be configured according to:

* Available storage
* Log volume
* Required historical period
* Application requirements
* OpenEBS capacity

The example configuration uses:

```text
7 days
```

Retention should be monitored continuously.

Check the Loki PVC:

```bash
kubectl get pvc -n logging
```

Check PV:

```bash
kubectl get pv
```

Check node filesystem:

```bash
df -h
```

---

# 28. Log Volume Considerations

High-volume applications can generate large amounts of logs.

Examples include:

```text
Application debug logs
HTTP access logs
API server logs
Container restart logs
Security logs
Database logs
Ingress logs
```

Avoid enabling verbose logging unnecessarily.

Use appropriate application log levels:

```text
ERROR
WARN
INFO
DEBUG
```

`DEBUG` logging can significantly increase storage consumption.

---

# 29. Fluentd Resource Management

Fluentd runs on Kubernetes nodes and consumes CPU and memory.

Check:

```bash
kubectl top pods -n logging
```

If Metrics Server is installed.

Alternatively use Prometheus metrics.

If Fluentd consumes excessive resources, review:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 200Mi
  limits:
    cpu: 500m
    memory: 500Mi
```

These are starting values and should be adjusted according to actual workload.

---

# 30. Fluentd Buffering

Log forwarding should account for temporary Loki unavailability.

A production Fluentd configuration should use buffering so that short-term Loki failures do not immediately result in log loss.

Example conceptual configuration:

```text
Container Logs
      |
      v
   Fluentd
      |
      v
   Buffer
      |
      v
     Loki
```

The buffer can be configured as file-based storage.

For example:

```text
/var/log/fluentd-buffer
```

The exact buffer configuration depends on the Fluentd output plugin being used.

---

# 31. Troubleshooting

## 31.1 Fluentd Pod Not Starting

Check:

```bash
kubectl get pods -n logging
```

Describe:

```bash
kubectl describe pod <FLUENTD-POD> -n logging
```

Check logs:

```bash
kubectl logs -n logging <FLUENTD-POD>
```

Common causes:

```text
Invalid Fluentd configuration
Missing plugin
Image unavailable
Permission problems
HostPath problems
Resource pressure
```

---

## 31.2 Fluentd Cannot Connect to Loki

Check Loki:

```bash
kubectl get pods -n logging
```

Check service:

```bash
kubectl get svc -n logging
```

Check endpoints:

```bash
kubectl get endpoints -n logging
```

From Fluentd:

```bash
kubectl exec -n logging <FLUENTD-POD> -- \
  wget -qO- http://loki.logging.svc.cluster.local:3100/ready
```

Expected:

```text
ready
```

If this fails, investigate:

* Loki pod status
* Service configuration
* DNS
* NetworkPolicy
* Port configuration
* Fluentd configuration

---

## 31.3 Loki PVC Pending

Check:

```bash
kubectl get pvc -n logging
```

Describe:

```bash
kubectl describe pvc <PVC-NAME> -n logging
```

Check:

```bash
kubectl get storageclass
```

Check OpenEBS:

```bash
kubectl get pods -n openebs
```

Check:

```bash
kubectl get pv
```

---

## 31.4 Logs Are Not Appearing in Grafana

Check the complete path:

```text
Container
   ↓
Node log file
   ↓
Fluentd
   ↓
Loki
   ↓
Grafana
```

First verify:

```bash
kubectl logs <APPLICATION-POD>
```

Then Fluentd:

```bash
kubectl logs -n logging <FLUENTD-POD>
```

Then Loki:

```bash
kubectl logs -n logging <LOKI-POD>
```

Then query Loki:

```bash
curl http://localhost:3100/loki/api/v1/labels
```

Finally verify the Grafana Loki data source.

---

# 32. Delete Test Application

After testing:

```bash
kubectl delete deployment log-test
```

If a test manifest was created:

```bash
kubectl delete -f log-test.yaml
```

---

# 33. Logging Validation

Run:

```bash
kubectl get pods -n logging
```

```bash
kubectl get svc -n logging
```

```bash
kubectl get pvc -n logging
```

```bash
kubectl get daemonset -n logging
```

Verify:

```text
[ ] logging namespace exists
[ ] Loki is installed
[ ] Loki pod is Running
[ ] Loki PVC is Bound
[ ] Fluentd DaemonSet exists
[ ] Fluentd runs on required nodes
[ ] Fluentd can connect to Loki
[ ] Container logs are collected
[ ] Loki contains log streams
[ ] Grafana has Loki data source
[ ] Grafana can query Loki
[ ] LogQL queries return results
[ ] Log retention is configured
[ ] OpenEBS storage is healthy
```

---

# 34. Result

After completing this stage, the project has centralized logging:

```text
                 Kubernetes Nodes
                        |
                  Container Logs
                        |
                        v
                     Fluentd
                        |
                        v
                       Loki
                        |
                        v
                     Grafana
                        |
                        v
                  Centralized Logs
```

The observability layer is now:

```text
                 Kubernetes Cluster
                         |
             +-----------+-----------+
             |                       |
          Metrics                   Logs
             |                       |
        Prometheus                 Fluentd
             |                       |
             |                       v
             |                      Loki
             |                       |
             +-----------+-----------+
                         |
                      Grafana
                         |
              +----------+----------+
              |                     |
           Metrics                 Logs
```

The next stage implements the **automated etcd backup system**, including leader-aware backup selection, Kubernetes CronJob execution, OpenEBS-backed persistent storage, backup verification, retention, and restore procedures.
