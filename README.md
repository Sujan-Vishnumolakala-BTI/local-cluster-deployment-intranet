# Local Kubernetes Cluster Deployment

A complete local Kubernetes cluster deployment project using `kubeadm`, `containerd`, `Calico`, `HAProxy`, `OpenEBS`, Prometheus, Grafana, Fluentd, Loki, and automated etcd backup.

## Architecture

The cluster consists of:

* 1 HAProxy load balancer
* 3 Kubernetes control-plane nodes
* 3 Kubernetes worker nodes
* 3 etcd members running with the control-plane nodes
* Calico CNI
* OpenEBS storage
* Prometheus and Grafana monitoring
* Fluentd and Loki logging
* Automated etcd backup using Kubernetes CronJob

<img width="1374" height="1145" alt="image" src="https://github.com/user-attachments/assets/93565b5b-6227-4022-86f6-45bfb4d1a4cb" />


```text
                         ┌──────────────────────┐
                         │      HAProxy LB       │
                         │       :6443           │
                         └──────────┬───────────┘
                                    │
                 ┌──────────────────┼──────────────────┐
                 │                  │                  │
                 ▼                  ▼                  ▼
          ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
          │  Master 01  │    │  Master 02  │    │  Master 03  │
          │ kube-apiserver│   │ kube-apiserver│   │ kube-apiserver│
          │    etcd     │    │    etcd     │    │    etcd     │
          └──────┬──────┘    └──────┬──────┘    └──────┬──────┘
                 │                  │                  │
                 └──────────────────┼──────────────────┘
                                    │
                           Kubernetes Cluster
                                    │
                 ┌──────────────────┼──────────────────┐
                 │                  │                  │
                 ▼                  ▼                  ▼
          ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
          │  Worker 01  │    │  Worker 02  │    │  Worker 03  │
          └─────────────┘    └─────────────┘    └─────────────┘

                  ┌─────────────────────────────┐
                  │       Cluster Services      │
                  │                             │
                  │  Calico                     │
                  │  OpenEBS                    │
                  │  Prometheus + Grafana       │
                  │  Fluentd + Loki             │
                  │  etcd Backup                │
                  └─────────────────────────────┘
```

## Components

| Component  | Purpose                          |
| ---------- | -------------------------------- |
| Kubernetes | Container orchestration          |
| kubeadm    | Kubernetes cluster bootstrapping |
| containerd | Container runtime                |
| HAProxy    | Kubernetes API load balancing    |
| Calico     | Container networking             |
| OpenEBS    | Persistent storage               |
| Prometheus | Metrics collection               |
| Grafana    | Metrics visualization            |
| Fluentd    | Log collection                   |
| Loki       | Log aggregation                  |
| etcd       | Kubernetes cluster state storage |
| CronJob    | Automated etcd backup            |

## Repository Structure

```text
local-cluster-deployment/
│
├── README.md
│
├── docs/
│   ├── 01-prerequisites.md
│   ├── 02-containerd.md
│   ├── 03-kubernetes-installation.md
│   ├── 04-ha-control-plane.md
│   ├── 05-calico.md
│   ├── 06-worker-nodes.md
│   ├── 07-openebs.md
│   ├── 08-monitoring.md
│   ├── 09-logging.md
│   ├── 10-etcd-backup.md
│   └── 11-troubleshooting.md
│
├── manifests/
│   ├── namespace/
│   ├── storage/
│   ├── monitoring/
│   ├── logging/
│   └── backup/
│
├── scripts/
│   ├── prerequisites.sh
│   ├── install.sh
│   ├── uninstall.sh
│   └── health-check.sh
│
├── etcd/
│   ├── backup.sh
│   ├── restore.sh
│   └── health-check.sh
│
├── haproxy/
│   ├── haproxy.cfg
│   └── README.md
│
├── helm/
│   └── ...
│
├── docker/
│   └── ...
│
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── terraform.tfvars.example
```

## Prerequisites

The following are required before deploying the cluster:

* Ubuntu Linux
* Minimum 3 control-plane nodes
* Minimum 3 worker nodes
* Network connectivity between all nodes
* SSH access between required machines
* Static or reserved IP addresses
* Internet connectivity
* Sudo privileges

Required software:

* containerd
* kubeadm
* kubelet
* kubectl
* Helm
* HAProxy

Detailed prerequisite configuration is available in:

`docs/01-prerequisites.md`

## Cluster Installation

The cluster is bootstrapped using `kubeadm`.

The installation process consists of:

1. Prepare all nodes.
2. Install and configure containerd.
3. Install kubeadm, kubelet and kubectl.
4. Configure the HAProxy API endpoint.
5. Initialize the first control-plane node.
6. Join the remaining control-plane nodes.
7. Join the worker nodes.
8. Install Calico.
9. Validate the cluster.

Detailed instructions:

`docs/02-containerd.md`

`docs/03-kubernetes-installation.md`

`docs/04-ha-control-plane.md`

`docs/05-calico.md`

`docs/06-worker-nodes.md`

## High Availability

Three control-plane nodes are used to provide a highly available Kubernetes control plane.

HAProxy provides a single Kubernetes API endpoint:

```text
HAProxy
   |
   +----> Master 01 :6443
   |
   +----> Master 02 :6443
   |
   +----> Master 03 :6443
```

The Kubernetes clients and worker nodes communicate with the API server through the HAProxy endpoint.

HAProxy configuration is available under:

```text
haproxy/
```

Detailed documentation:

`docs/04-ha-control-plane.md`

## Networking

Calico is used as the Kubernetes Container Network Interface.

Calico provides:

* Pod networking
* Network routing
* Network policies
* Node-to-node communication

Calico configuration and deployment instructions are covered in:

`docs/05-calico.md`

## Worker Nodes

Worker nodes run application workloads and Kubernetes components required for workload execution.

The worker-node deployment process includes:

* containerd configuration
* kubelet installation
* Kubernetes node configuration
* joining the cluster
* node validation

Documentation:

`docs/06-worker-nodes.md`

## OpenEBS Storage

OpenEBS provides persistent storage for workloads that require persistent volumes.

The storage configuration is maintained under:

```text
manifests/storage/
```

The storage implementation includes:

* StorageClass
* PersistentVolume
* PersistentVolumeClaim
* OpenEBS storage configuration

Documentation:

`docs/07-openebs.md`

## Monitoring

The monitoring stack consists of:

* Prometheus
* Grafana
* Node Exporter

Prometheus collects Kubernetes and node metrics.

Grafana provides dashboards for monitoring cluster resources and workloads.

Monitoring manifests are available under:

```text
manifests/monitoring/
```

Documentation:

`docs/08-monitoring.md`

## Logging

The logging stack consists of:

* Fluentd
* Loki
* Grafana

The logging flow is:

```text
Kubernetes Pods
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

Fluentd collects container logs and forwards them to Loki.

Loki stores and indexes the log metadata.

Grafana is used to query and visualize the logs.

Logging configuration is available under:

```text
manifests/logging/
```

Documentation:

`docs/09-logging.md`

## etcd Backup

The Kubernetes cluster uses a three-member etcd cluster.

An automated backup mechanism is implemented using a Kubernetes CronJob.

The backup workflow is:

```text
Kubernetes CronJob
        |
        v
Identify etcd leader
        |
        v
Connect to etcd
        |
        v
Create etcd snapshot
        |
        v
Store snapshot
        |
        v
OpenEBS-backed persistent storage
```

The backup system contains:

* Kubernetes ServiceAccount
* RBAC permissions
* Backup configuration
* PersistentVolumeClaim
* CronJob
* etcd snapshot operation
* Restore procedure
* Backup health checks

Backup manifests are located under:

```text
manifests/backup/
```

Backup scripts are located under:

```text
etcd/
```

Documentation:

`docs/10-etcd-backup.md`

## Backup Schedule

The etcd backup CronJob is configured to execute every 24 hours.

Example:

```text
Every 24 hours
      |
      v
Check etcd cluster
      |
      v
Identify healthy/leader endpoint
      |
      v
Create snapshot
      |
      v
Store backup on persistent storage
```

Backup retention and restoration procedures are documented separately.

## Health Checks

The project includes health-check scripts for validating the cluster.

Run:

```bash
./scripts/health-check.sh
```

The health check verifies:

* Kubernetes nodes
* Kubernetes API
* Control-plane components
* etcd
* Calico
* OpenEBS
* PersistentVolumes
* PersistentVolumeClaims
* Monitoring components
* Logging components

## Troubleshooting

Common troubleshooting procedures are documented in:

`docs/11-troubleshooting.md`

Topics include:

* Kubernetes API connection failures
* HAProxy backend failures
* Node `NotReady`
* Calico networking issues
* etcd health problems
* containerd problems
* OpenEBS storage issues
* PVC pending
* Prometheus failures
* Grafana issues
* Fluentd problems
* Loki problems
* etcd backup failures

## Documentation

| Document                        | Description                               |
| ------------------------------- | ----------------------------------------- |
| `01-prerequisites.md`           | System and network prerequisites          |
| `02-containerd.md`              | containerd installation and configuration |
| `03-kubernetes-installation.md` | Kubernetes installation                   |
| `04-ha-control-plane.md`        | HA control-plane configuration            |
| `05-calico.md`                  | Calico networking                         |
| `06-worker-nodes.md`            | Worker-node configuration                 |
| `07-openebs.md`                 | OpenEBS storage                           |
| `08-monitoring.md`              | Prometheus and Grafana                    |
| `09-logging.md`                 | Fluentd, Loki and Grafana                 |
| `10-etcd-backup.md`             | Automated etcd backup and restore         |
| `11-troubleshooting.md`         | Troubleshooting procedures                |

## Validation

After deployment, verify the cluster:

```bash
kubectl get nodes -o wide
```

Check all pods:

```bash
kubectl get pods -A -o wide
```

Check control-plane components:

```bash
kubectl get pods -n kube-system
```

Check storage:

```bash
kubectl get storageclass
kubectl get pv
kubectl get pvc -A
```

Check etcd:

```bash
kubectl get pods -n kube-system | grep etcd
```

Check cluster information:

```bash
kubectl cluster-info
```

## Project Status

| Component                     | Status      |
| ----------------------------- | ----------- |
| Kubernetes Cluster            | Completed   |
| HA Control Plane              | Completed   |
| HAProxy                       | Completed   |
| Calico                        | Completed   |
| Worker Nodes                  | Completed   |
| OpenEBS                       | Completed   |
| Prometheus                    | Completed   |
| Grafana                       | Completed   |
| Fluentd                       | Completed   |
| Loki                          | Completed   |
| etcd Backup                   | Completed   |
| etcd Restore                  | Completed   |
| Troubleshooting Documentation | Completed   |

## Purpose

This project demonstrates the deployment and operation of a multi-node Kubernetes environment with:

* High-availability control plane
* Container networking
* Persistent storage
* Monitoring
* Centralized logging
* Automated etcd backup
* Disaster-recovery procedures

The repository separates deployment configuration, automation scripts, Kubernetes manifests, and detailed technical documentation to keep the project maintainable.
