# 11 — Troubleshooting

## Overview

This document provides operational troubleshooting procedures for the local Kubernetes cluster.

The troubleshooting scope includes:

* Kubernetes control plane
* HAProxy
* etcd
* worker nodes
* containerd
* kubelet
* Calico
* CoreDNS
* OpenEBS
* Prometheus
* Grafana
* Fluentd
* Loki
* etcd backups
* DNS
* networking
* storage
* node failures

The general troubleshooting process is:

```text
Identify
   |
   v
Collect Status
   |
   v
Check Events
   |
   v
Check Logs
   |
   v
Identify Root Cause
   |
   v
Apply Minimal Change
   |
   v
Validate
   |
   v
Document
```

---

# 1. Initial Cluster Health Check

Start with:

```bash
kubectl get nodes -o wide
```

Then:

```bash
kubectl get pods -A
```

Check namespaces:

```bash
kubectl get namespaces
```

Check cluster information:

```bash
kubectl cluster-info
```

Check component resources:

```bash
kubectl get all -A
```

Check recent events:

```bash
kubectl get events -A --sort-by=.lastTimestamp
```

---

# 2. Quick Health Check Script

The project contains:

```text
scripts/health-check.sh
```

Example:

```bash
#!/usr/bin/env bash

set -euo pipefail

echo "======================================"
echo " Kubernetes Cluster Health Check"
echo "======================================"

echo
echo "== Cluster Information =="
kubectl cluster-info

echo
echo "== Nodes =="
kubectl get nodes -o wide

echo
echo "== Node Conditions =="
kubectl get nodes \
  -o custom-columns='NAME:.metadata.name,STATUS:.status.conditions[-1].type,TAINTS:.spec.taints'

echo
echo "== All Pods =="
kubectl get pods -A

echo
echo "== Storage Classes =="
kubectl get storageclass

echo
echo "== PVCs =="
kubectl get pvc -A

echo
echo "== PVs =="
kubectl get pv

echo
echo "== Recent Events =="
kubectl get events -A \
  --sort-by=.lastTimestamp | tail -50

echo
echo "======================================"
echo " Health check completed"
echo "======================================"
```

Make executable:

```bash
chmod +x scripts/health-check.sh
```

Run:

```bash
./scripts/health-check.sh
```

---

# 3. Kubernetes Node NotReady

Check:

```bash
kubectl get nodes
```

Example:

```text
NAME       STATUS     ROLES
master01   Ready      control-plane
master02   Ready      control-plane
master03   NotReady   control-plane
worker01   Ready      <none>
worker02   Ready      <none>
worker03   Ready      <none>
```

Inspect the affected node:

```bash
kubectl describe node master03
```

Look at:

```text
Conditions
Events
Taints
Addresses
Allocatable
Capacity
```

---

# 4. Check Kubelet

On the affected node:

```bash
sudo systemctl status kubelet
```

Check logs:

```bash
sudo journalctl -u kubelet -n 100 --no-pager
```

Follow logs:

```bash
sudo journalctl -u kubelet -f
```

Restart only after identifying the issue:

```bash
sudo systemctl restart kubelet
```

Verify:

```bash
sudo systemctl status kubelet
```

Then from an administrative machine:

```bash
kubectl get nodes
```

---

# 5. Check Containerd

Check:

```bash
sudo systemctl status containerd
```

Logs:

```bash
sudo journalctl -u containerd -n 100 --no-pager
```

Restart:

```bash
sudo systemctl restart containerd
```

Verify:

```bash
sudo systemctl status containerd
```

Check containers using `crictl`:

```bash
sudo crictl ps
```

Check all containers:

```bash
sudo crictl ps -a
```

---

# 6. Check CRI Configuration

Check:

```bash
sudo crictl info
```

The runtime should report containerd.

Check configuration:

```bash
cat /etc/crictl.yaml
```

Typical configuration:

```yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
```

Check the socket:

```bash
ls -l /run/containerd/containerd.sock
```

---

# 7. Pod Pending

Check:

```bash
kubectl get pods -A
```

For the affected pod:

```bash
kubectl describe pod <POD-NAME> -n <NAMESPACE>
```

Look at:

```text
Events
Conditions
Node
Volumes
Tolerations
Affinity
```

Common causes:

```text
Insufficient CPU
Insufficient memory
PVC Pending
Node selector mismatch
Taints
Affinity rules
Unavailable nodes
```

Check scheduler events:

```bash
kubectl get events -A \
  --sort-by=.lastTimestamp
```

---

# 8. Pod CrashLoopBackOff

Check:

```bash
kubectl get pod <POD-NAME> -n <NAMESPACE>
```

Describe:

```bash
kubectl describe pod <POD-NAME> -n <NAMESPACE>
```

Logs:

```bash
kubectl logs <POD-NAME> -n <NAMESPACE>
```

Previous container logs:

```bash
kubectl logs \
  <POD-NAME> \
  -n <NAMESPACE> \
  --previous
```

Check restart count:

```bash
kubectl get pod \
  <POD-NAME> \
  -n <NAMESPACE> \
  -o wide
```

Common causes:

```text
Application error
Configuration error
Missing Secret
Missing ConfigMap
Failed health probe
OOMKilled
Permission problem
Dependency unavailable
```

---

# 9. OOMKilled

Check:

```bash
kubectl describe pod <POD-NAME> -n <NAMESPACE>
```

Look for:

```text
Reason: OOMKilled
```

Check node memory:

```bash
kubectl top nodes
```

Check pod memory:

```bash
kubectl top pods -A
```

Check node:

```bash
free -h
```

Possible remediation:

* Reduce application memory usage.
* Increase container memory limits.
* Increase node capacity.
* Identify memory leaks.
* Reduce unnecessary workloads.

Do not simply increase limits without understanding the workload.

---

# 10. DiskPressure

Check:

```bash
kubectl get nodes
```

Then:

```bash
kubectl describe node <NODE-NAME>
```

Look for:

```text
DiskPressure=True
```

On the node:

```bash
df -h
```

Check inode usage:

```bash
df -i
```

Check Docker/containerd storage:

```bash
sudo du -sh /var/lib/containerd
```

Check Kubernetes logs:

```bash
sudo du -sh /var/log/*
```

Clean unused container images carefully.

For containerd:

```bash
sudo crictl images
```

Unused images should be removed only after confirming that they are not required.

---

# 11. HAProxy API Server Failure

The Kubernetes API endpoint is:

```text
k8s-api:6443
```

Check DNS:

```bash
getent hosts k8s-api
```

Check connectivity:

```bash
nc -vz k8s-api 6443
```

On the HAProxy machine:

```bash
sudo systemctl status haproxy
```

Check logs:

```bash
sudo journalctl -u haproxy -n 100 --no-pager
```

Validate configuration:

```bash
sudo haproxy -c \
  -f /etc/haproxy/haproxy.cfg
```

---

# 12. HAProxy Backend Has No Available Server

A common HAProxy message is:

```text
backend kubernetes-masters has no server available
```

Check each control-plane endpoint.

From the HAProxy node:

```bash
nc -vz <MASTER01-IP> 6443
nc -vz <MASTER02-IP> 6443
nc -vz <MASTER03-IP> 6443
```

All healthy API servers should accept connections.

Check API server on each master:

```bash
sudo crictl ps | grep kube-apiserver
```

Check API server logs:

```bash
sudo crictl logs <API-SERVER-CONTAINER-ID>
```

---

# 13. Kubernetes API Server Connection Refused

Test:

```bash
kubectl cluster-info
```

Check:

```bash
nc -vz k8s-api 6443
```

Check HAProxy:

```bash
sudo systemctl status haproxy
```

Check backend connectivity:

```bash
nc -vz <MASTER-IP> 6443
```

On the master:

```bash
sudo ss -lntp | grep 6443
```

The API server should be listening on port:

```text
6443
```

---

# 14. API Server Certificate Errors

Example:

```text
x509: certificate signed by unknown authority
```

Check the kubeconfig:

```bash
kubectl config view
```

Check certificate files:

```bash
sudo ls -l /etc/kubernetes/pki/
```

Check API server certificate:

```bash
sudo openssl x509 \
  -in /etc/kubernetes/pki/apiserver.crt \
  -noout \
  -subject \
  -issuer \
  -dates
```

Check certificate expiration:

```bash
sudo kubeadm certs check-expiration
```

Do not manually replace Kubernetes certificates without understanding the kubeadm certificate lifecycle.

---

# 15. etcd Health Check

On a control-plane node:

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  endpoint health
```

Check all members:

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://<MASTER01-IP>:2379,https://<MASTER02-IP>:2379,https://<MASTER03-IP>:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  endpoint status \
  --write-out=table
```

---

# 16. etcd Member List

Run:

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  member list \
  --write-out=table
```

Check:

```text
Member ID
Status
Name
Peer URLs
Client URLs
```

---

# 17. etcd Leader

Check:

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://<MASTER01-IP>:2379,https://<MASTER02-IP>:2379,https://<MASTER03-IP>:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  endpoint status \
  --write-out=table
```

Look for:

```text
IS LEADER
```

There should normally be one leader.

The leader may change after a member failure or election.

---

# 18. etcd Logs

Find the etcd container:

```bash
sudo crictl ps | grep etcd
```

Get logs:

```bash
sudo crictl logs <ETCD-CONTAINER-ID>
```

Look for:

```text
election
leader
raft
timeout
connection
disk
corruption
```

---

# 19. etcd Port Connectivity

Client port:

```text
2379
```

Peer port:

```text
2380
```

Check:

```bash
nc -vz <MASTER-IP> 2379
```

Check peer connectivity:

```bash
nc -vz <MASTER-IP> 2380
```

All etcd members must be able to communicate appropriately with one another.

---

# 20. Calico Troubleshooting

Check Calico pods:

```bash
kubectl get pods \
  -n kube-system \
  -l k8s-app=calico-node \
  -o wide
```

Check status:

```bash
kubectl get pods -n kube-system
```

Describe:

```bash
kubectl describe pod \
  -n kube-system \
  <CALICO-POD>
```

Logs:

```bash
kubectl logs \
  -n kube-system \
  <CALICO-POD>
```

---

# 21. Calico Node Status

If the Calico CLI is available:

```bash
calicoctl node status
```

If it is not installed, inspect the Calico DaemonSet:

```bash
kubectl get daemonset \
  -n kube-system \
  calico-node
```

Check:

```bash
kubectl describe daemonset \
  -n kube-system \
  calico-node
```

---

# 22. Pod-to-Pod Connectivity

Create a test pod:

```bash
kubectl run network-test \
  --image=busybox:1.36 \
  --restart=Never \
  -- sleep 3600
```

Check:

```bash
kubectl get pod network-test -o wide
```

Enter:

```bash
kubectl exec -it network-test -- sh
```

Test connectivity to another pod:

```bash
ping <POD-IP>
```

Delete:

```bash
kubectl delete pod network-test
```

---

# 23. Service Connectivity

Create a test deployment:

```bash
kubectl create deployment nginx-test \
  --image=nginx
```

Expose:

```bash
kubectl expose deployment nginx-test \
  --port=80 \
  --target-port=80
```

Check:

```bash
kubectl get svc nginx-test
```

Test from a temporary pod:

```bash
kubectl run curl-test \
  --image=curlimages/curl \
  --restart=Never \
  --rm \
  -it \
  -- \
  curl http://nginx-test
```

Delete the deployment when testing is complete:

```bash
kubectl delete deployment nginx-test
kubectl delete service nginx-test
```

---

# 24. CoreDNS Troubleshooting

Check:

```bash
kubectl get pods -n kube-system \
  -l k8s-app=kube-dns
```

Check service:

```bash
kubectl get svc -n kube-system kube-dns
```

Check logs:

```bash
kubectl logs \
  -n kube-system \
  -l k8s-app=kube-dns
```

Check DNS from a test pod:

```bash
kubectl run dns-test \
  --image=busybox:1.36 \
  --restart=Never \
  --rm \
  -it \
  -- \
  nslookup kubernetes.default
```

Expected result should resolve the Kubernetes service.

---

# 25. OpenEBS Troubleshooting

Check OpenEBS:

```bash
kubectl get pods -n openebs
```

Check StorageClasses:

```bash
kubectl get storageclass
```

Check PVCs:

```bash
kubectl get pvc -A
```

Check PVs:

```bash
kubectl get pv
```

If a PVC is pending:

```bash
kubectl describe pvc <PVC-NAME> -n <NAMESPACE>
```

Then inspect:

```bash
kubectl get events \
  -n <NAMESPACE> \
  --sort-by=.lastTimestamp
```

---

# 26. PVC Pending

The general flow is:

```text
PVC Pending
    |
    +--> StorageClass exists?
    |
    +--> Provisioner running?
    |
    +--> Capacity available?
    |
    +--> Access mode supported?
    |
    +--> Node topology valid?
    |
    +--> Volume provisioning successful?
```

Check StorageClass:

```bash
kubectl get storageclass <STORAGECLASS>
```

Check OpenEBS:

```bash
kubectl get pods -n openebs
```

---

# 27. PVC Bound but Pod Cannot Mount

Check:

```bash
kubectl describe pod <POD-NAME> -n <NAMESPACE>
```

Look at events.

Check PVC:

```bash
kubectl describe pvc <PVC-NAME> -n <NAMESPACE>
```

Check PV:

```bash
kubectl describe pv <PV-NAME>
```

Pay particular attention to:

```text
Node Affinity
Access Modes
Mount Errors
Volume Attachment
Storage Backend
```

---

# 28. Monitoring Troubleshooting

Check:

```bash
kubectl get pods -n monitoring
```

Check Prometheus:

```bash
kubectl get prometheus -n monitoring
```

Check Grafana:

```bash
kubectl get pods \
  -n monitoring \
  -l app.kubernetes.io/name=grafana
```

Check Alertmanager:

```bash
kubectl get alertmanager -n monitoring
```

---

# 29. Prometheus Not Collecting Metrics

Check Prometheus targets through the UI.

Alternatively inspect:

```bash
kubectl get servicemonitors -n monitoring
```

Check Prometheus logs:

```bash
kubectl logs \
  -n monitoring \
  <PROMETHEUS-POD>
```

Check ServiceMonitor:

```bash
kubectl describe servicemonitor \
  <SERVICEMONITOR-NAME> \
  -n monitoring
```

Check service endpoints:

```bash
kubectl get endpoints -A
```

---

# 30. Grafana Troubleshooting

Check:

```bash
kubectl get pods -n monitoring
```

Logs:

```bash
kubectl logs \
  -n monitoring \
  <GRAFANA-POD>
```

Check service:

```bash
kubectl get svc -n monitoring
```

Port-forward:

```bash
kubectl port-forward \
  -n monitoring \
  svc/kube-prometheus-stack-grafana \
  3000:80
```

---

# 31. Fluentd Troubleshooting

Check:

```bash
kubectl get daemonset -n logging
```

Check pods:

```bash
kubectl get pods -n logging -o wide
```

Logs:

```bash
kubectl logs \
  -n logging \
  <FLUENTD-POD>
```

Common issues:

```text
Loki unavailable
Output plugin missing
Configuration syntax error
Permission denied
Host log path unavailable
Resource exhaustion
```

---

# 32. Loki Troubleshooting

Check:

```bash
kubectl get pods -n logging
```

Check PVC:

```bash
kubectl get pvc -n logging
```

Check logs:

```bash
kubectl logs \
  -n logging \
  <LOKI-POD>
```

Health check:

```bash
kubectl port-forward \
  -n logging \
  svc/loki \
  3100:3100
```

Then:

```bash
curl http://localhost:3100/ready
```

Expected:

```text
ready
```

---

# 33. Logs Not Visible in Grafana

Trace the pipeline:

```text
Application
    |
    v
Container Runtime
    |
    v
/var/log/containers
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

Check each layer.

First:

```bash
kubectl logs <POD-NAME> -n <NAMESPACE>
```

Then inspect Fluentd.

Then query Loki.

Then verify the Grafana Loki data source.

---

# 34. etcd Backup Troubleshooting

Check CronJob:

```bash
kubectl get cronjob -n backup
```

Check Jobs:

```bash
kubectl get jobs -n backup
```

Check Pods:

```bash
kubectl get pods -n backup
```

Check logs:

```bash
kubectl logs \
  -n backup \
  <BACKUP-POD>
```

Check PVC:

```bash
kubectl get pvc -n backup
```

Check PV:

```bash
kubectl get pv
```

---

# 35. Backup Job Fails

Inspect the Job:

```bash
kubectl describe job \
  <JOB-NAME> \
  -n backup
```

Inspect pod:

```bash
kubectl describe pod \
  <BACKUP-POD> \
  -n backup
```

Possible causes:

```text
etcd unavailable
Certificate unavailable
PVC unavailable
Wrong endpoint
Snapshot failure
Insufficient storage
Image unavailable
Permission failure
```

---

# 36. Backup PVC Cannot Mount

Check:

```bash
kubectl describe pod \
  <BACKUP-POD> \
  -n backup
```

Then:

```bash
kubectl get pvc -n backup
```

And:

```bash
kubectl describe pvc \
  etcd-backup-pvc \
  -n backup
```

Check PV:

```bash
kubectl get pv
```

For local OpenEBS storage, inspect node affinity.

---

# 37. Worker Node Failure

If a worker fails:

```bash
kubectl get nodes -o wide
```

Identify:

```text
NotReady
```

Check the physical/virtual machine.

On the node:

```bash
sudo systemctl status kubelet
sudo systemctl status containerd
```

Check:

```bash
df -h
free -h
ip addr
ip route
```

Check network connectivity to the API server:

```bash
nc -vz k8s-api 6443
```

---

# 38. Control Plane Node Failure

With three control-plane nodes, first determine which services remain healthy:

```bash
kubectl get nodes
```

Check etcd:

```bash
ETCDCTL_API=3 etcdctl endpoint status
```

Check API server endpoints:

```bash
nc -vz <MASTER01-IP> 6443
nc -vz <MASTER02-IP> 6443
nc -vz <MASTER03-IP> 6443
```

Check HAProxy:

```bash
sudo systemctl status haproxy
```

The immediate objective is to determine whether:

```text
HAProxy
   |
   +--> API server availability
   |
   +--> etcd quorum
   |
   +--> kubelet
   |
   +--> containerd
```

remain healthy.

---

# 39. etcd Quorum Consideration

For a three-member etcd cluster:

```text
Members = 3
Quorum = 2
```

Therefore, the cluster requires two functioning members to maintain quorum.

Conceptually:

```text
3 members
   |
   +-- 3 healthy → quorum
   |
   +-- 2 healthy → quorum
   |
   +-- 1 healthy → no quorum
```

Do not intentionally stop multiple etcd members simultaneously without a recovery plan.

---

# 40. Do Not Delete etcd Data Directory

Avoid commands such as:

```bash
rm -rf /var/lib/etcd/*
```

unless performing a documented, controlled recovery procedure.

The etcd data directory contains critical Kubernetes cluster state.

If etcd is unhealthy, first collect:

```text
endpoint health
endpoint status
member list
etcd logs
disk status
network connectivity
```

---

# 41. Network Troubleshooting

Check interfaces:

```bash
ip addr
```

Check routes:

```bash
ip route
```

Check DNS:

```bash
resolvectl status
```

Check connectivity:

```bash
ping <IP>
```

Check TCP connectivity:

```bash
nc -vz <IP> <PORT>
```

Check listening ports:

```bash
sudo ss -lntup
```

---

# 42. Important Kubernetes Ports

Control-plane API:

```text
6443
```

etcd client:

```text
2379
```

etcd peer:

```text
2380
```

kubelet:

```text
10250
```

Calico networking may require additional ports depending on the selected networking mode.

Always verify the exact Calico configuration before restricting firewall rules.

---

# 43. DNS Troubleshooting

Check:

```bash
kubectl get svc -n kube-system kube-dns
```

Check CoreDNS:

```bash
kubectl get pods -n kube-system \
  -l k8s-app=kube-dns
```

Run:

```bash
kubectl run dns-test \
  --image=busybox:1.36 \
  --restart=Never \
  --rm \
  -it \
  -- \
  nslookup kubernetes.default.svc.cluster.local
```

If DNS fails, investigate:

```text
CoreDNS
Service
Network plugin
kube-proxy
Pod networking
Upstream DNS
```

---

# 44. Restarting Components

Avoid restarting multiple control-plane components simultaneously.

For systemd services:

```bash
sudo systemctl restart kubelet
```

```bash
sudo systemctl restart containerd
```

For Kubernetes workloads:

```bash
kubectl rollout restart deployment/<NAME> \
  -n <NAMESPACE>
```

For DaemonSets:

```bash
kubectl rollout restart daemonset/<NAME> \
  -n <NAMESPACE>
```

Always check the impact before restarting a critical component.

---

# 45. Safe Troubleshooting Order

For a Kubernetes outage, use this sequence:

```text
1. Node health
       |
2. Network connectivity
       |
3. containerd
       |
4. kubelet
       |
5. etcd
       |
6. kube-apiserver
       |
7. HAProxy
       |
8. CNI
       |
9. CoreDNS
       |
10. Application workloads
       |
11. Storage
       |
12. Monitoring/logging
```

This helps prevent troubleshooting an application when the underlying control plane is unavailable.

---

# 46. Useful Commands

## Nodes

```bash
kubectl get nodes -o wide
```

## Pods

```bash
kubectl get pods -A -o wide
```

## Services

```bash
kubectl get svc -A
```

## Endpoints

```bash
kubectl get endpoints -A
```

## PVCs

```bash
kubectl get pvc -A
```

## PVs

```bash
kubectl get pv
```

## StorageClasses

```bash
kubectl get storageclass
```

## Events

```bash
kubectl get events -A \
  --sort-by=.lastTimestamp
```

## Resource usage

```bash
kubectl top nodes
```

```bash
kubectl top pods -A
```

---

# 47. Collecting a Troubleshooting Bundle

When investigating a complex problem, collect:

```bash
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get svc -A
kubectl get endpoints -A
kubectl get pvc -A
kubectl get pv
kubectl get storageclass
kubectl get events -A --sort-by=.lastTimestamp
```

On the affected node:

```bash
systemctl status kubelet
systemctl status containerd
df -h
free -h
ip addr
ip route
```

For control-plane problems:

```bash
sudo crictl ps
sudo crictl ps -a
```

For etcd:

```bash
ETCDCTL_API=3 etcdctl endpoint health
ETCDCTL_API=3 etcdctl endpoint status --write-out=table
ETCDCTL_API=3 etcdctl member list --write-out=table
```

---

# 48. Troubleshooting Checklist

## Cluster

```text
[ ] API server reachable
[ ] All expected nodes present
[ ] Control-plane nodes Ready
[ ] Worker nodes Ready
[ ] CoreDNS Running
[ ] Calico Running
```

## HAProxy

```text
[ ] HAProxy service Running
[ ] Configuration valid
[ ] Port 6443 listening
[ ] Control-plane backends reachable
```

## etcd

```text
[ ] Three members configured
[ ] Quorum available
[ ] Endpoint health successful
[ ] Leader available
[ ] No critical disk errors
[ ] Peer connectivity working
```

## Storage

```text
[ ] OpenEBS pods healthy
[ ] StorageClasses available
[ ] PVCs Bound
[ ] PVs Available/Bound
[ ] No mount errors
```

## Monitoring

```text
[ ] Prometheus Running
[ ] Grafana Running
[ ] Alertmanager Running
[ ] Targets available
```

## Logging

```text
[ ] Fluentd Running
[ ] Loki Running
[ ] Loki PVC Bound
[ ] Logs reaching Loki
[ ] Grafana Loki data source working
```

## Backup

```text
[ ] Backup CronJob exists
[ ] Backup PVC Bound
[ ] etcd health check succeeds
[ ] Snapshot created
[ ] Snapshot verified
[ ] Backup file persisted
[ ] Retention working
```

---

# 49. Final Operational Principle

When troubleshooting this cluster, avoid making multiple changes simultaneously.

Use:

```text
Observe
  ↓
Measure
  ↓
Identify
  ↓
Change one thing
  ↓
Validate
  ↓
Document
```

This makes it easier to identify the actual root cause and prevents secondary failures from being introduced during recovery.

---

# 50. Result

The project now has a centralized troubleshooting guide covering:

```text
                    Kubernetes Cluster
                           |
        +------------------+------------------+
        |                  |                  |
     Control Plane       Workers           Storage
        |                  |                  |
      HAProxy            Kubelet           OpenEBS
      etcd               containerd          |
      API Server         Calico              |
        |                  |                  |
        +------------------+------------------+
                           |
                     Observability
                           |
              +------------+------------+
              |                         |
          Prometheus                  Loki
              |                         |
              +------------+------------+
                           |
                         Grafana
```

The core deployment documentation is now complete through:

```text
01  Prerequisites
02  Containerd
03  Kubernetes Installation
04  HA Control Plane
05  Calico
06  Worker Nodes
07  OpenEBS
08  Monitoring
09  Logging
10  etcd Backup
11  Troubleshooting
```

These documents form the operational documentation layer of the project.
