# Part 07 — OpenEBS Storage

This document describes the installation, configuration, and validation of OpenEBS as the persistent storage layer for the Kubernetes cluster.

OpenEBS will provide persistent volumes for workloads that require storage beyond the lifecycle of individual Pods.

## 1. Storage Architecture

The storage architecture is:

```text
                    Kubernetes Workload
                           |
                           v
                         PVC
                           |
                           v
                     StorageClass
                           |
                           v
                         OpenEBS
                           |
                           v
                  Persistent Storage
```

For the etcd backup implementation, the flow will later be:

```text
etcd CronJob
     |
     v
etcd Snapshot
     |
     v
OpenEBS-backed PVC
     |
     v
Persistent Backup Data
```

## 2. Why OpenEBS

OpenEBS provides Kubernetes-native persistent storage and integrates with Kubernetes StorageClasses, PersistentVolumes, and PersistentVolumeClaims.

It can provide storage using different engines and local or replicated storage depending on the selected configuration.

For this project, storage should be selected based on the backup and application requirements rather than assuming that every OpenEBS engine provides the same availability characteristics.

## 3. Check the Existing Cluster

Before installing OpenEBS:

```bash
kubectl get nodes -o wide
```

All expected nodes should be available.

Check existing StorageClasses:

```bash
kubectl get storageclass
```

Check existing PVs:

```bash
kubectl get pv
```

Check PVCs:

```bash
kubectl get pvc -A
```

## 4. Install Helm

Verify Helm:

```bash
helm version
```

If Helm is not installed, install it using the official Helm installation procedure.

Verify:

```bash
helm version
```

## 5. Add OpenEBS Repository

Add the OpenEBS Helm repository:

```bash
helm repo add openebs https://openebs.github.io/openebs
```

Update the repository:

```bash
helm repo update
```

Verify:

```bash
helm repo list
```

## 6. Install OpenEBS

Create the OpenEBS namespace:

```bash
kubectl create namespace openebs
```

Install OpenEBS:

```bash
helm install openebs openebs/openebs \
  --namespace openebs
```

Check the Helm release:

```bash
helm list -n openebs
```

## 7. Verify OpenEBS Pods

Check:

```bash
kubectl get pods -n openebs
```

Wait until the required OpenEBS components become `Running`.

For more information:

```bash
kubectl get pods -n openebs -o wide
```

Check all OpenEBS resources:

```bash
kubectl get all -n openebs
```

## 8. Verify OpenEBS StorageClasses

List StorageClasses:

```bash
kubectl get storageclass
```

Depending on the OpenEBS version and enabled engines, several StorageClasses may be available.

For example:

```text
openebs-hostpath
```

or StorageClasses associated with LocalPV or Mayastor.

Do not assume a particular StorageClass name until it has been verified on the installed cluster.

Get details:

```bash
kubectl describe storageclass <storage-class-name>
```

## 9. Storage Selection

For this project, the storage requirement should be evaluated separately for:

1. Application persistent data
2. Monitoring data
3. Logging data
4. etcd backup data

For example:

```text
Application
    |
    +---- PVC
    |
    v
OpenEBS StorageClass

etcd Backup
    |
    +---- PVC
    |
    v
OpenEBS StorageClass
```

A local-storage implementation does not automatically provide cross-node replication.

If backup availability across node failures is a requirement, select an OpenEBS engine and topology that explicitly provides the required replication behavior.

## 10. Create a Storage Namespace

Create a namespace for storage testing:

```bash
kubectl create namespace storage-test
```

Verify:

```bash
kubectl get namespace storage-test
```

## 11. Create a Test PVC

Create:

```text
manifests/storage/pvc.yaml
```

Example:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: openebs-test-pvc
  namespace: storage-test
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: openebs-hostpath
```

> Verify that `openebs-hostpath` exists in your cluster before applying this manifest. If your installed OpenEBS version provides a different StorageClass, replace the value accordingly.

Apply:

```bash
kubectl apply -f manifests/storage/pvc.yaml
```

Check:

```bash
kubectl get pvc -n storage-test
```

## 12. Understand PVC Binding

A PVC requests storage.

```text
PVC
 |
 | requests 5Gi
 v
StorageClass
 |
 v
OpenEBS Provisioner
 |
 v
PV
```

Check:

```bash
kubectl get pvc -n storage-test
```

Then:

```bash
kubectl get pv
```

A successful claim should eventually show:

```text
STATUS: Bound
```

## 13. Inspect the PersistentVolume

Run:

```bash
kubectl get pv
```

Get details:

```bash
kubectl describe pv <pv-name>
```

Important fields include:

* Capacity
* Access Modes
* Reclaim Policy
* StorageClass
* Claim
* Node affinity
* Provisioner

## 14. StorageClass Configuration

Create:

```text
manifests/storage/storage-class.yaml
```

For an existing OpenEBS provisioner, the StorageClass should be defined according to the selected OpenEBS engine.

Example structure:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-project
provisioner: <OPENEBS-PROVISIONER>
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
```

The actual `provisioner` value must match the OpenEBS engine installed in the cluster.

Check available provisioners:

```bash
kubectl get storageclass -o wide
```

Do not create a duplicate StorageClass if the required OpenEBS StorageClass already exists.

## 15. Why `WaitForFirstConsumer` Can Be Useful

For topology-aware storage, `WaitForFirstConsumer` can delay volume provisioning until Kubernetes knows where the consuming Pod will run.

The scheduling flow becomes:

```text
PVC
 |
 v
Pod scheduled
 |
 v
Node selected
 |
 v
Storage provisioned
```

This can be important for topology-aware or node-local storage.

The correct binding mode depends on the selected OpenEBS engine.

## 16. Create a Test Pod

Create:

```text
manifests/storage/test-pod.yaml
```

Example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: openebs-test
  namespace: storage-test
spec:
  containers:
    - name: test
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          while true; do
            date
            sleep 30
          done
      volumeMounts:
        - name: storage
          mountPath: /data
  volumes:
    - name: storage
      persistentVolumeClaim:
        claimName: openebs-test-pvc
```

Apply:

```bash
kubectl apply -f manifests/storage/test-pod.yaml
```

Check:

```bash
kubectl get pod -n storage-test -o wide
```

## 17. Verify the Mounted Volume

Check the mount:

```bash
kubectl exec -n storage-test openebs-test -- df -h /data
```

Write data:

```bash
kubectl exec -n storage-test openebs-test -- \
  sh -c 'echo "OpenEBS storage test" > /data/test.txt'
```

Read it:

```bash
kubectl exec -n storage-test openebs-test -- \
  cat /data/test.txt
```

Expected:

```text
OpenEBS storage test
```

## 18. Test Persistence

Delete the test Pod:

```bash
kubectl delete pod openebs-test -n storage-test
```

Recreate it:

```bash
kubectl apply -f manifests/storage/test-pod.yaml
```

Read the file:

```bash
kubectl exec -n storage-test openebs-test -- \
  cat /data/test.txt
```

The data should remain if the underlying storage and PVC are persistent.

## 19. Understand Where the Volume Is Mounted

The exact node where storage is physically located depends on the OpenEBS engine and StorageClass.

For node-local storage, a PV can have node affinity.

Inspect:

```bash
kubectl describe pv <pv-name>
```

Look for:

```text
Node Affinity
```

For replicated OpenEBS engines, the data may be distributed across multiple storage replicas according to the engine's topology and configuration.

Therefore:

```text
PVC
 |
 v
OpenEBS
 |
 +---- Local storage
 |
 +---- OR replicated storage
```

The physical storage behavior depends on the selected engine.

## 20. Check PVC and Pod Relationship

Run:

```bash
kubectl get pvc -n storage-test
```

```bash
kubectl get pv
```

```bash
kubectl get pod -n storage-test -o wide
```

This lets you correlate:

```text
Pod
 |
 +---- Node
       |
       +---- PVC
             |
             +---- PV
                   |
                   +---- StorageClass
                         |
                         +---- OpenEBS
```

## 21. Reclaim Policy

Check:

```bash
kubectl get storageclass
```

Typical reclaim policies include:

```text
Delete
Retain
```

For important backup data, `Retain` can be preferable when you want the underlying volume to remain available after a PVC is deleted.

However, the reclaim policy should be selected based on the project's data-retention requirements.

## 22. Backup Storage Recommendation

The etcd backup system will use persistent storage.

The intended architecture is:

```text
                    etcd Cluster
                         |
                         v
                  Backup CronJob
                         |
                         v
                  Snapshot File
                         |
                         v
                     Backup PVC
                         |
                         v
                      OpenEBS
```

For backups, consider:

* Persistent storage
* Retention policy
* Volume capacity
* Node failure behavior
* Replica count
* Backup rotation
* Restore testing

A backup stored only on the same infrastructure without an independent copy should not be treated as the only disaster-recovery copy.

## 23. OpenEBS Troubleshooting

### OpenEBS pods are not running

Check:

```bash
kubectl get pods -n openebs
```

Describe:

```bash
kubectl describe pod <pod-name> -n openebs
```

Check logs:

```bash
kubectl logs <pod-name> -n openebs
```

### PVC is Pending

Check:

```bash
kubectl get pvc -n storage-test
```

Describe:

```bash
kubectl describe pvc openebs-test-pvc -n storage-test
```

Check StorageClasses:

```bash
kubectl get storageclass
```

Check events:

```bash
kubectl get events -n storage-test --sort-by=.lastTimestamp
```

### PV is not created

Check:

```bash
kubectl get pv
```

Check the StorageClass:

```bash
kubectl describe storageclass <storage-class-name>
```

Check OpenEBS pods:

```bash
kubectl get pods -n openebs
```

### Pod cannot mount the volume

Check:

```bash
kubectl describe pod openebs-test -n storage-test
```

Look for events such as:

```text
FailedMount
FailedAttachVolume
FailedMountVolume
```

Check the PV:

```bash
kubectl describe pv <pv-name>
```

## 24. Storage Capacity

Check node filesystem capacity:

```bash
df -h
```

Check OpenEBS-related resources:

```bash
kubectl get pods -n openebs -o wide
```

For local storage, verify that the node hosting the storage has sufficient disk capacity.

For replicated storage, account for replication overhead.

For example, a logical 10 GiB volume replicated three times may require approximately 30 GiB of raw storage capacity before additional overhead.

## 25. Clean Up the Test

Delete the test Pod:

```bash
kubectl delete pod openebs-test -n storage-test
```

Delete the PVC:

```bash
kubectl delete pvc openebs-test-pvc -n storage-test
```

Check:

```bash
kubectl get pv
```

Delete the test namespace if no longer required:

```bash
kubectl delete namespace storage-test
```

## 26. Production Considerations

Before using OpenEBS for important data, define:

* Storage engine
* Replication requirements
* Node topology
* Disk topology
* Failure domains
* Capacity planning
* Backup policy
* Retention policy
* Recovery procedure

Do not assume that installing OpenEBS alone makes data highly available.

Storage availability depends on the selected OpenEBS engine and its configuration.

## 27. Validation Checklist

* [ ] OpenEBS namespace exists.
* [ ] OpenEBS components are running.
* [ ] StorageClasses are available.
* [ ] Selected StorageClass has the expected provisioner.
* [ ] PVC can be created.
* [ ] PVC reaches `Bound`.
* [ ] PV is created.
* [ ] Pod can mount the PVC.
* [ ] Data can be written.
* [ ] Data can be read.
* [ ] Data persists after Pod recreation.
* [ ] Storage topology is understood.
* [ ] Reclaim policy is appropriate.
* [ ] Backup storage requirements are documented.

## 28. Result

The cluster now has a persistent storage layer:

```text
                         Kubernetes
                              |
                              v
                            PVC
                              |
                              v
                       StorageClass
                              |
                              v
                           OpenEBS
                              |
              +---------------+---------------+
              |                               |
              v                               v
       Local Storage                    Replicated Storage
       (depending on                  (depending on selected
        selected engine)                    engine)
```

OpenEBS is now ready to provide persistent storage for the workloads in this project.

The next stage is monitoring with Prometheus and Grafana.

Continue with:

`docs/08-monitoring.md`
