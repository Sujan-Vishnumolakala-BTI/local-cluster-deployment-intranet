# 10 — Automated etcd Backup

## Overview

The Kubernetes control plane uses **etcd** as its distributed key-value database.

The cluster contains:

```text
Control Plane 01 → etcd member
Control Plane 02 → etcd member
Control Plane 03 → etcd member
```

The backup architecture must ensure that:

* Only one backup is created for each scheduled run.
* The backup is taken from a healthy etcd member.
* The etcd cluster is checked before backup.
* Backup files are stored on persistent storage.
* OpenEBS provides the persistent volume.
* Old backups are removed according to the retention policy.
* Backup integrity can be verified.
* A restore procedure is available.
* The backup process does not unnecessarily interfere with normal Kubernetes operations.

---

# 1. etcd Architecture

The project uses a three-member stacked etcd architecture:

```text
                    Kubernetes Control Plane
                             |
          +------------------+------------------+
          |                  |                  |
          v                  v                  v
      Master 01          Master 02          Master 03
          |                  |                  |
        etcd               etcd               etcd
          |                  |                  |
          +------------------+------------------+
                     etcd cluster
```

The three etcd members maintain a replicated state.

The etcd cluster should normally have one elected leader and two followers.

The leader can change when:

* A node becomes unavailable.
* An etcd member restarts.
* Network connectivity changes.
* An election occurs.

Therefore, the backup process should not permanently assume that a specific control-plane node is always the leader.

---

# 2. Backup Architecture

The backup design is:

```text
                    Kubernetes Cluster
                           |
                     CronJob
                  Every 24 Hours
                           |
                           v
                 Backup Coordinator
                           |
                  Discover etcd Leader
                           |
                           v
                 Healthy etcd Member
                           |
                           v
                    etcd snapshot
                           |
                           v
                  OpenEBS-backed PVC
                           |
                           v
                  Persistent Backup
```

The important principle is:

```text
Do not hard-code Master 01 as the permanent backup source.
```

The backup process should determine the current etcd leader or otherwise select a healthy etcd member dynamically.

---

# 3. Backup Storage Architecture

The backup storage uses a Kubernetes PersistentVolumeClaim.

```text
CronJob
   |
   v
Backup Pod
   |
   v
PVC
   |
   v
PersistentVolume
   |
   v
OpenEBS StorageClass
   |
   v
OpenEBS
```

The PVC provides persistent storage independent of the lifecycle of an individual backup pod.

---

# 4. Create Backup Namespace

Create a dedicated namespace:

```bash
kubectl create namespace backup
```

Verify:

```bash
kubectl get namespace backup
```

Expected:

```text
NAME      STATUS
backup    Active
```

---

# 5. Select the OpenEBS StorageClass

Check available StorageClasses:

```bash
kubectl get storageclass
```

Example:

```text
NAME                 PROVISIONER
openebs-hostpath     openebs.io/local
```

The exact StorageClass depends on the OpenEBS storage engine configured in the cluster.

Use the selected StorageClass in the backup PVC.

For example:

```text
openebs-hostpath
```

Do not assume that this particular class provides cross-node replication.

A local OpenEBS volume may remain associated with the node where the volume was provisioned.

For higher availability, use an OpenEBS storage engine and configuration that explicitly provides replication.

---

# 6. Backup PVC

Create:

```text
manifests/backup/etcd-backup-pvc.yaml
```

Example:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: etcd-backup-pvc
  namespace: backup
spec:
  accessModes:
    - ReadWriteOnce

  storageClassName: <OPENEBS_STORAGE_CLASS>

  resources:
    requests:
      storage: 20Gi
```

Replace:

```text
<OPENEBS_STORAGE_CLASS>
```

with the StorageClass selected for the project.

Apply:

```bash
kubectl apply -f manifests/backup/etcd-backup-pvc.yaml
```

Verify:

```bash
kubectl get pvc -n backup
```

Expected:

```text
NAME              STATUS   VOLUME
etcd-backup-pvc   Bound    pvc-xxxxxxxx
```

---

# 7. Understand PVC Allocation

When the PVC is created:

```text
PVC
 |
 | storageClassName
 v
OpenEBS
 |
 | dynamic provisioning
 v
PV
 |
 v
Storage backend
```

The user does not manually create the PV when dynamic provisioning is enabled.

Kubernetes requests storage from the configured OpenEBS StorageClass.

OpenEBS provisions the corresponding persistent volume.

Check:

```bash
kubectl get pv
```

Detailed information:

```bash
kubectl describe pv <PV-NAME>
```

---

# 8. Important Storage Topology Consideration

The backup pod may be scheduled on a node that can access the selected volume.

For local storage, Kubernetes may enforce node affinity.

Check:

```bash
kubectl describe pv <PV-NAME>
```

Look for:

```text
Node Affinity
```

This is important because:

```text
Local Storage ≠ Automatically Replicated Storage
```

If the selected OpenEBS engine stores data only on one node, losing that node can make the backup volume unavailable.

Therefore, the backup storage design should be evaluated separately from the etcd backup mechanism.

---

# 9. etcd Backup Script

Create:

```text
etcd/backup.sh
```

Example:

```bash
#!/usr/bin/env bash

set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/backup}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_FILE="${BACKUP_DIR}/etcd-snapshot-${TIMESTAMP}.db"

ETCDCTL_API=3

ETCD_ENDPOINTS="${ETCD_ENDPOINTS:-https://127.0.0.1:2379}"
ETCD_CACERT="${ETCD_CACERT:-/etc/kubernetes/pki/etcd/ca.crt}"
ETCD_CERT="${ETCD_CERT:-/etc/kubernetes/pki/etcd/peer.crt}"
ETCD_KEY="${ETCD_KEY:-/etc/kubernetes/pki/etcd/peer.key}"

echo "Starting etcd backup..."
echo "Endpoint: ${ETCD_ENDPOINTS}"
echo "Backup file: ${BACKUP_FILE}"

mkdir -p "${BACKUP_DIR}"

echo "Checking etcd health..."

ETCDCTL_API=3 etcdctl \
  --endpoints="${ETCD_ENDPOINTS}" \
  --cacert="${ETCD_CACERT}" \
  --cert="${ETCD_CERT}" \
  --key="${ETCD_KEY}" \
  endpoint health

echo "Creating etcd snapshot..."

ETCDCTL_API=3 etcdctl \
  --endpoints="${ETCD_ENDPOINTS}" \
  --cacert="${ETCD_CACERT}" \
  --cert="${ETCD_CERT}" \
  --key="${ETCD_KEY}" \
  snapshot save "${BACKUP_FILE}"

echo "Verifying snapshot..."

ETCDCTL_API=3 etcdctl \
  snapshot status "${BACKUP_FILE}" \
  --write-out=table

echo "Backup completed successfully:"
echo "${BACKUP_FILE}"

find "${BACKUP_DIR}" \
  -type f \
  -name "etcd-snapshot-*.db" \
  -mtime +7 \
  -delete

echo "Old backups cleaned."
```

Make it executable:

```bash
chmod +x etcd/backup.sh
```

---

# 10. Backup File Naming

Backups use UTC timestamps:

```text
etcd-snapshot-20260919T050000Z.db
```

The timestamp provides:

* Unique filenames
* Chronological ordering
* Easy identification
* Easier retention management
* Easier restore selection

---

# 11. etcd Snapshot Verification

After creating a snapshot:

```bash
ETCDCTL_API=3 etcdctl \
  snapshot status \
  /backup/etcd-snapshot-<TIMESTAMP>.db \
  --write-out=table
```

The snapshot metadata should be available.

A successful snapshot creation alone should not be treated as the complete backup validation.

The backup process should also verify that:

* The file exists.
* The file is non-zero.
* `etcdctl snapshot status` can read it.

---

# 12. Backup Container Image

The CronJob requires an image containing:

* etcdctl
* the backup script
* required shell utilities

Create:

```text
docker/etcd-backup/Dockerfile
```

Example:

```dockerfile
FROM quay.io/coreos/etcd:v3.6.5

COPY etcd/backup.sh /usr/local/bin/backup.sh

RUN chmod +x /usr/local/bin/backup.sh

ENTRYPOINT ["/usr/local/bin/backup.sh"]
```

The etcd image version should be aligned with the etcd version used by the Kubernetes cluster.

Check the running etcd version:

```bash
kubectl -n kube-system exec \
  <ETCD-POD> \
  -- etcdctl version
```

---

# 13. Build the Backup Image

From the project root:

```bash
docker build \
  -t local-etcd-backup:latest \
  -f docker/etcd-backup/Dockerfile \
  .
```

Verify:

```bash
docker images | grep etcd
```

If the Kubernetes nodes cannot directly access the local Docker image, push the image to a registry accessible by the cluster.

For example:

```text
registry.example.com/local-etcd-backup:<TAG>
```

Then update the CronJob image.

---

# 14. Leader-Aware Backup

The etcd cluster has a dynamic leader.

Check the current leader:

```bash
ETCDCTL_API=3 etcdctl \
  --endpoints=https://<MASTER01-IP>:2379,https://<MASTER02-IP>:2379,https://<MASTER03-IP>:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  endpoint status \
  --write-out=table
```

The output contains information such as:

```text
ENDPOINT
STATUS
VERSION
DB SIZE
IS LEADER
RAFT TERM
RAFT INDEX
```

The `IS LEADER` column identifies the current leader.

The leader can change over time.

Therefore, the backup process should discover the current state instead of permanently configuring:

```text
MASTER01 = backup server
```

---

# 15. Important etcd Backup Principle

An etcd snapshot can be created from an etcd member.

The backup architecture should therefore focus on:

```text
Healthy etcd member
        +
Consistent snapshot
        +
Persistent storage
```

Leader awareness is useful for deterministic source selection, but the design should also tolerate leader changes.

If the selected member becomes unavailable, the backup job should fail safely or select another healthy member rather than producing an invalid backup.

---

# 16. CronJob

Create:

```text
manifests/backup/etcd-backup-cronjob.yaml
```

Example:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: etcd-backup
  namespace: backup
spec:
  schedule: "0 2 * * *"

  concurrencyPolicy: Forbid

  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3

  jobTemplate:
    spec:
      backoffLimit: 2

      template:
        metadata:
          labels:
            app: etcd-backup

        spec:
          restartPolicy: OnFailure

          containers:
            - name: etcd-backup
              image: local-etcd-backup:latest
              imagePullPolicy: IfNotPresent

              env:
                - name: BACKUP_DIR
                  value: /backup

              volumeMounts:
                - name: backup-storage
                  mountPath: /backup

                - name: etcd-certs
                  mountPath: /etc/kubernetes/pki/etcd
                  readOnly: true

          volumes:
            - name: backup-storage
              persistentVolumeClaim:
                claimName: etcd-backup-pvc

            - name: etcd-certs
              hostPath:
                path: /etc/kubernetes/pki/etcd
                type: Directory
```

---

# 17. Important CronJob Scheduling Consideration

The example schedule:

```text
0 2 * * *
```

means:

```text
Every day at 02:00
```

Kubernetes CronJob schedules use the timezone configured for the Kubernetes CronJob controller unless an explicit timezone is configured.

For a project that requires an exact timezone, configure and document the intended timezone explicitly rather than assuming the node's local timezone.

The important requirement is:

```text
One backup every 24 hours
```

---

# 18. Concurrency Control

The CronJob uses:

```yaml
concurrencyPolicy: Forbid
```

This prevents a new backup Job from starting if the previous backup Job is still running.

This avoids:

```text
Backup Job 01
       |
       +---- still running
       |
Backup Job 02
       |
       +---- starts simultaneously
```

Instead:

```text
Backup Job 01
       |
       | completes
       v
Next scheduled backup
```

---

# 19. Apply the Backup Configuration

Apply the PVC:

```bash
kubectl apply \
  -f manifests/backup/etcd-backup-pvc.yaml
```

Apply the CronJob:

```bash
kubectl apply \
  -f manifests/backup/etcd-backup-cronjob.yaml
```

Verify:

```bash
kubectl get cronjob -n backup
```

Expected:

```text
NAME          SCHEDULE    SUSPEND
etcd-backup   0 2 * * *   False
```

---

# 20. Test the CronJob Manually

Do not wait 24 hours for the first test.

Create a Job from the CronJob:

```bash
kubectl create job \
  --from=cronjob/etcd-backup \
  etcd-backup-manual \
  -n backup
```

Check:

```bash
kubectl get jobs -n backup
```

Check pods:

```bash
kubectl get pods -n backup
```

---

# 21. Check Backup Logs

Find the backup pod:

```bash
kubectl get pods -n backup
```

Then:

```bash
kubectl logs \
  -n backup \
  <BACKUP-POD>
```

Expected output should contain messages similar to:

```text
Starting etcd backup...
Checking etcd health...
Creating etcd snapshot...
Verifying snapshot...
Backup completed successfully
Old backups cleaned.
```

---

# 22. Verify Backup File

The backup PVC can be inspected using a temporary pod.

Create:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: backup-inspector
  namespace: backup
spec:
  restartPolicy: Never

  containers:
    - name: inspector
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          echo "Backup files:"
          ls -lh /backup
          sleep 3600

      volumeMounts:
        - name: backup-storage
          mountPath: /backup

  volumes:
    - name: backup-storage
      persistentVolumeClaim:
        claimName: etcd-backup-pvc
```

Apply:

```bash
kubectl apply -f backup-inspector.yaml
```

Check:

```bash
kubectl exec \
  -n backup \
  backup-inspector \
  -- ls -lh /backup
```

Expected:

```text
etcd-snapshot-20260919T020000Z.db
```

---

# 23. Delete the Inspection Pod

After verification:

```bash
kubectl delete pod \
  -n backup \
  backup-inspector
```

The backup file remains because it is stored on the PVC.

---

# 24. Backup Retention

The backup script removes files older than seven days:

```bash
find "${BACKUP_DIR}" \
  -type f \
  -name "etcd-snapshot-*.db" \
  -mtime +7 \
  -delete
```

Therefore, the storage contains approximately the most recent seven days of backups, subject to the actual backup frequency and filesystem timestamps.

Example:

```text
Day 01 → snapshot
Day 02 → snapshot
Day 03 → snapshot
...
Day 07 → snapshot
Day 08 → oldest eligible backup removed
```

Retention should be increased if the recovery requirements require a longer history.

---

# 25. Backup Integrity Check

A backup should be verified after creation.

Example:

```bash
ETCDCTL_API=3 etcdctl \
  snapshot status \
  /backup/etcd-snapshot-<TIMESTAMP>.db \
  --write-out=table
```

Check file size:

```bash
ls -lh /backup/
```

Check checksum:

```bash
sha256sum \
  /backup/etcd-snapshot-<TIMESTAMP>.db
```

A checksum can be stored alongside the backup:

```text
etcd-snapshot-20260919T020000Z.db
etcd-snapshot-20260919T020000Z.db.sha256
```

This provides an additional integrity check.

---

# 26. Restore Architecture

Restoration should not be performed casually on a running production control plane.

The general restore architecture is:

```text
Backup PVC
    |
    v
etcd snapshot
    |
    v
Snapshot verification
    |
    v
etcd restore
    |
    v
New etcd data directory
    |
    v
Control-plane recovery
```

A restore procedure should be tested separately.

---

# 27. Restore Script

Create:

```text
etcd/restore.sh
```

Example:

```bash
#!/usr/bin/env bash

set -euo pipefail

SNAPSHOT="${1:-}"

if [[ -z "${SNAPSHOT}" ]]; then
  echo "Usage:"
  echo "  $0 /path/to/etcd-snapshot.db"
  exit 1
fi

if [[ ! -f "${SNAPSHOT}" ]]; then
  echo "Snapshot does not exist:"
  echo "${SNAPSHOT}"
  exit 1
fi

ETCDCTL_API=3 etcdctl \
  snapshot status \
  "${SNAPSHOT}" \
  --write-out=table

echo
echo "Snapshot verification completed."
echo
echo "Restore must be performed according to the cluster recovery procedure."
echo "Do not overwrite a running etcd data directory without a controlled recovery plan."
```

Make executable:

```bash
chmod +x etcd/restore.sh
```

---

# 28. Why Restore Requires Special Handling

The etcd data directory is part of the Kubernetes control-plane state.

A careless restore can cause:

* API server inconsistency
* stale cluster state
* certificate/configuration mismatch
* loss of recently created resources
* control-plane disruption

Therefore, restoration should be performed only after:

1. Identifying the required snapshot.
2. Verifying the snapshot.
3. Planning the control-plane recovery.
4. Stopping or isolating the appropriate etcd member.
5. Restoring the snapshot to a controlled data directory.
6. Reconfiguring the etcd member if required.
7. Verifying etcd cluster health.
8. Verifying Kubernetes API server health.

---

# 29. etcd Backup Health Check

Create:

```text
etcd/health-check.sh
```

Example:

```bash
#!/usr/bin/env bash

set -euo pipefail

ETCD_ENDPOINTS="${ETCD_ENDPOINTS:-https://127.0.0.1:2379}"
ETCD_CACERT="${ETCD_CACERT:-/etc/kubernetes/pki/etcd/ca.crt}"
ETCD_CERT="${ETCD_CERT:-/etc/kubernetes/pki/etcd/peer.crt}"
ETCD_KEY="${ETCD_KEY:-/etc/kubernetes/pki/etcd/peer.key}"

echo "Checking etcd endpoint health..."

ETCDCTL_API=3 etcdctl \
  --endpoints="${ETCD_ENDPOINTS}" \
  --cacert="${ETCD_CACERT}" \
  --cert="${ETCD_CERT}" \
  --key="${ETCD_KEY}" \
  endpoint health

echo
echo "Checking etcd endpoint status..."

ETCDCTL_API=3 etcdctl \
  --endpoints="${ETCD_ENDPOINTS}" \
  --cacert="${ETCD_CACERT}" \
  --cert="${ETCD_CERT}" \
  --key="${ETCD_KEY}" \
  endpoint status \
  --write-out=table
```

Make executable:

```bash
chmod +x etcd/health-check.sh
```

---

# 30. Verify etcd Cluster Before Backup

Before backup, check:

```bash
ETCDCTL_API=3 etcdctl \
  --endpoints=https://<MASTER01-IP>:2379,https://<MASTER02-IP>:2379,https://<MASTER03-IP>:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  endpoint health \
  --cluster
```

A healthy cluster should report successful health checks for the available members.

Check member list:

```bash
ETCDCTL_API=3 etcdctl \
  --endpoints=https://<MASTER01-IP>:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  member list \
  --write-out=table
```

---

# 31. Leader Detection

Use:

```bash
ETCDCTL_API=3 etcdctl \
  --endpoints=https://<MASTER01-IP>:2379,https://<MASTER02-IP>:2379,https://<MASTER03-IP>:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  endpoint status \
  --write-out=table
```

The output contains:

```text
IS LEADER
```

Example conceptual output:

```text
ENDPOINT        VERSION    DB SIZE    IS LEADER
master01:2379   3.x        ...        false
master02:2379   3.x        ...        true
master03:2379   3.x        ...        false
```

The leader can later change:

```text
master02 → leader
master03 → leader
master01 → leader
```

The backup implementation must therefore avoid assuming that one particular node is permanently the leader.

---

# 32. Backup Failure Handling

The CronJob should fail if:

* etcd health check fails
* snapshot creation fails
* snapshot verification fails
* backup storage cannot be mounted
* backup directory is unavailable
* required certificates are missing

The backup should not report success when the snapshot was not successfully created and verified.

Check failed Jobs:

```bash
kubectl get jobs -n backup
```

Check Job details:

```bash
kubectl describe job <JOB-NAME> -n backup
```

Check pod logs:

```bash
kubectl logs \
  -n backup \
  <BACKUP-POD>
```

---

# 33. CronJob History

The CronJob configuration keeps:

```yaml
successfulJobsHistoryLimit: 3
failedJobsHistoryLimit: 3
```

This controls Kubernetes Job objects.

It does **not** delete the actual backup files from the PVC.

Backup file retention is handled separately by the backup script.

Therefore:

```text
Kubernetes Job Retention
        ≠
Backup File Retention
```

Both must be configured independently.

---

# 34. Security Considerations

The backup process requires access to etcd certificates.

These certificates are sensitive.

Do not:

* Commit private keys to Git.
* Put certificates directly in Git manifests.
* Print private key contents in logs.
* Store credentials in ConfigMaps.
* Expose etcd ports publicly.

The repository should contain references and deployment instructions, not copies of:

```text
/etc/kubernetes/pki/etcd/*.key
```

---

# 35. Backup Storage Security

The backup PVC contains Kubernetes cluster state.

Protect it from unauthorized access.

Recommended controls include:

```text
RBAC
Restricted namespace access
Storage access controls
Node access controls
Backup retention
Backup integrity verification
```

If backups are later copied to external storage, encrypt them according to the organization's security requirements.

---

# 36. Manual Backup

A manual backup can be triggered when required.

Create a Job from the CronJob:

```bash
kubectl create job \
  --from=cronjob/etcd-backup \
  etcd-backup-manual-$(date +%s) \
  -n backup
```

Check:

```bash
kubectl get jobs -n backup
```

---

# 37. Verify Complete Backup Pipeline

Run the following:

```bash
kubectl get cronjob -n backup
```

```bash
kubectl get pvc -n backup
```

```bash
kubectl get pv
```

```bash
kubectl get jobs -n backup
```

Then manually trigger:

```bash
kubectl create job \
  --from=cronjob/etcd-backup \
  etcd-backup-test \
  -n backup
```

Check:

```bash
kubectl get pods -n backup
```

Check logs:

```bash
kubectl logs \
  -n backup \
  <BACKUP-POD>
```

Verify the resulting snapshot exists on the PVC.

---

# 38. Complete Backup Flow

The final backup workflow is:

```text
                 CronJob
              Every 24 Hours
                    |
                    v
              Create Job
                    |
                    v
             Backup Pod
                    |
                    v
           Check etcd cluster
                    |
                    v
          Identify healthy member
                    |
                    v
           Create etcd snapshot
                    |
                    v
             Verify snapshot
                    |
                    v
              Write to PVC
                    |
                    v
                 OpenEBS
                    |
                    v
            Retain required files
                    |
                    v
             Backup Complete
```

---

# 39. Complete Project Architecture

After implementing the backup system, the project architecture becomes:

```text
                         Client
                           |
                           v
                       HAProxy
                           |
          +----------------+----------------+
          |                |                |
       Master 01        Master 02        Master 03
          |                |                |
        etcd             etcd             etcd
          |                |                |
          +----------------+----------------+
                           |
                    Kubernetes API
                           |
          +----------------+----------------+
          |                |                |
       Worker 01        Worker 02        Worker 03
          |                |                |
          +----------------+----------------+
                           |
          +----------------+----------------+
          |                                 |
       Monitoring                         Logging
          |                                 |
     Prometheus                           Fluentd
          |                                 |
       Grafana                              Loki
          |                                 |
          +----------------+----------------+
                           |
                        OpenEBS
                           |
                +----------+----------+
                |                     |
         Monitoring PVC          Backup PVC
                                      |
                                      v
                               etcd Snapshots
```

---

# 40. Validation Checklist

Before moving to the next stage:

```text
[ ] backup namespace exists
[ ] OpenEBS StorageClass selected
[ ] etcd backup PVC created
[ ] PVC is Bound
[ ] PV is available
[ ] backup image built
[ ] backup image available to Kubernetes nodes
[ ] etcd certificates available to backup process
[ ] etcd health check succeeds
[ ] etcd member status can be retrieved
[ ] current leader can be identified
[ ] backup CronJob exists
[ ] CronJob runs every 24 hours
[ ] concurrencyPolicy is Forbid
[ ] manual backup Job succeeds
[ ] etcd snapshot is created
[ ] snapshot status can be verified
[ ] backup file exists on PVC
[ ] backup retention is configured
[ ] failed backup Jobs can be investigated
[ ] restore procedure is documented
[ ] sensitive etcd keys are not committed to Git
```

---

# 41. Result

The cluster now has an automated etcd backup system.

The final design is:

```text
                 Kubernetes CronJob
                         |
                    Every 24h
                         |
                         v
                Leader-aware backup
                         |
                         v
                   etcd snapshot
                         |
                         v
                    Backup PVC
                         |
                         v
                      OpenEBS
                         |
                         v
                 Persistent Backup
```

The backup system provides the foundation for disaster recovery.

The next stage implements **cluster troubleshooting and operational recovery procedures**, covering Kubernetes nodes, containerd, kubelet, HAProxy, Calico, OpenEBS, Prometheus, Loki, etcd, DNS, networking, and common failure scenarios.
