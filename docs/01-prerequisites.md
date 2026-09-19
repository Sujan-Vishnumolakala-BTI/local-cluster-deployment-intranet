# Part 01 — Prerequisites

This document describes the system, networking, and software requirements required before building the multi-node Kubernetes cluster.

## 1. Cluster Architecture

The cluster consists of:

* 1 HAProxy load balancer
* 3 control-plane nodes
* 3 worker nodes
* 3 etcd members
* Calico CNI
* OpenEBS storage

The control-plane nodes also host the etcd members.

```text
                         HAProxy
                            |
              +-------------+-------------+
              |             |             |
              v             v             v
         Master 01      Master 02      Master 03
          etcd-1         etcd-2         etcd-3
              |             |             |
              +-------------+-------------+
                            |
                 Kubernetes Control Plane
                            |
              +-------------+-------------+
              |             |             |
              v             v             v
          Worker 01      Worker 02      Worker 03
```

## 2. Hardware Requirements

Each node should have sufficient CPU, memory, and disk resources.

Recommended minimum configuration:

| Node      |    CPU |  RAM |  Disk | Role                 |
| --------- | -----: | ---: | ----: | -------------------- |
| HAProxy   | 2 vCPU | 2 GB | 20 GB | Load Balancer        |
| Master 01 | 2 vCPU | 4 GB | 40 GB | Control Plane + etcd |
| Master 02 | 2 vCPU | 4 GB | 40 GB | Control Plane + etcd |
| Master 03 | 2 vCPU | 4 GB | 40 GB | Control Plane + etcd |
| Worker 01 | 2 vCPU | 4 GB | 40 GB | Worker               |
| Worker 02 | 2 vCPU | 4 GB | 40 GB | Worker               |
| Worker 03 | 2 vCPU | 4 GB | 40 GB | Worker               |

For monitoring, logging, and OpenEBS workloads, additional memory and disk capacity may be required.

## 3. Operating System

The nodes should run a supported Linux distribution.

Example:

```text
Ubuntu Server 24.04 LTS
```

Verify the operating system:

```bash
cat /etc/os-release
```

Verify the kernel:

```bash
uname -r
```

## 4. Node Naming

Use unique hostnames for every machine.

Example:

```text
haproxy
master01
master02
master03
worker01
worker02
worker03
```

Set the hostname:

```bash
sudo hostnamectl set-hostname master01
```

Verify:

```bash
hostname
```

Perform the corresponding configuration on every node.

## 5. Network Requirements

All Kubernetes nodes must be able to communicate with each other.

Required communication includes:

```text
HAProxy
   |
   +---- Master 01
   +---- Master 02
   +---- Master 03
              |
              +---- Worker 01
              +---- Worker 02
              +---- Worker 03
```

The nodes must have stable network connectivity.

Verify connectivity:

```bash
ping <node-ip>
```

Check the network interfaces:

```bash
ip addr
```

Check routing:

```bash
ip route
```

## 6. Kubernetes API Port

The Kubernetes API server listens on:

```text
TCP 6443
```

The HAProxy load balancer forwards API traffic to all three control-plane nodes.

```text
Client
   |
   | TCP 6443
   v
HAProxy
   |
   +----> Master 01:6443
   +----> Master 02:6443
   +----> Master 03:6443
```

Verify connectivity from a client or worker:

```bash
nc -vz <haproxy-ip> 6443
```

## 7. Kubernetes Ports

The following ports are commonly required for the cluster.

### Kubernetes API Server

```text
TCP 6443
```

### etcd

```text
TCP 2379
TCP 2380
```

Port `2379` is used for etcd client communication.

Port `2380` is used for etcd peer communication.

### Kubelet

```text
TCP 10250
```

### kube-scheduler

```text
TCP 10259
```

### kube-controller-manager

```text
TCP 10257
```

Additional ports required by the selected CNI and workloads must also be allowed.

## 8. Disable Swap

Kubernetes requires swap to be disabled unless a specific configuration is used.

Check swap:

```bash
free -h
```

Check active swap:

```bash
swapon --show
```

Disable swap temporarily:

```bash
sudo swapoff -a
```

To disable it permanently, edit:

```bash
sudo nano /etc/fstab
```

Comment out the swap entry.

Example:

```text
# /swap.img none swap sw 0 0
```

Verify:

```bash
free -h
```

The swap value should be zero.

## 9. Required Kernel Modules

Load the required modules:

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

Verify:

```bash
lsmod | grep overlay
lsmod | grep br_netfilter
```

To load them automatically after reboot:

```bash
sudo tee /etc/modules-load.d/kubernetes.conf <<EOF
overlay
br_netfilter
EOF
```

## 10. Required Kernel Parameters

Configure Kubernetes networking parameters:

```bash
sudo tee /etc/sysctl.d/99-kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
```

Apply the configuration:

```bash
sudo sysctl --system
```

Verify:

```bash
sysctl net.ipv4.ip_forward
```

Expected:

```text
net.ipv4.ip_forward = 1
```

## 11. Time Synchronization

All nodes should have synchronized system clocks.

Check:

```bash
timedatectl
```

Enable NTP:

```bash
sudo timedatectl set-ntp true
```

Verify:

```bash
timedatectl status
```

Time synchronization is particularly important for distributed components such as etcd.

## 12. Required Software

The following components will be installed during the project:

```text
containerd
kubeadm
kubelet
kubectl
Helm
HAProxy
Calico
OpenEBS
Prometheus
Grafana
Fluentd
Loki
```

The installation procedures are covered in the following documentation.

## 13. SSH Access

SSH access should be available to the required nodes.

Test:

```bash
ssh <username>@<node-ip>
```

Example:

```bash
ssh sujan@192.168.1.101
```

Verify that the nodes can communicate with each other before starting Kubernetes installation.

## 14. DNS / Host Resolution

Every node should be able to resolve the other nodes.

If DNS is not available, `/etc/hosts` can be configured.

Example:

```text
192.168.1.101 master01
192.168.1.102 master02
192.168.1.103 master03
192.168.1.111 worker01
192.168.1.112 worker02
192.168.1.113 worker03
192.168.1.120 haproxy
```

Verify:

```bash
ping master01
ping master02
ping master03
```

## 15. Firewall

If a host firewall is enabled, the required Kubernetes, etcd, CNI, and workload ports must be allowed.

Check firewall status:

```bash
sudo ufw status
```

For a lab environment, the firewall can be disabled temporarily if appropriate:

```bash
sudo ufw disable
```

For a production environment, do not disable the firewall. Configure explicit rules for the required ports instead.

## 16. Validate All Nodes

Before proceeding to the next stage, verify:

```bash
hostname
ip addr
ip route
free -h
swapon --show
timedatectl
```

Verify kernel modules:

```bash
lsmod | grep overlay
lsmod | grep br_netfilter
```

Verify IP forwarding:

```bash
sysctl net.ipv4.ip_forward
```

Verify connectivity:

```bash
ping <other-node-ip>
```

Verify Kubernetes API connectivity after HAProxy is configured:

```bash
nc -vz <haproxy-ip> 6443
```

## 17. Prerequisite Checklist

Before continuing, confirm:

* [ ] All nodes have unique hostnames.
* [ ] All nodes have stable IP addresses.
* [ ] All nodes can communicate with each other.
* [ ] SSH access is available.
* [ ] Swap is disabled.
* [ ] Required kernel modules are loaded.
* [ ] IP forwarding is enabled.
* [ ] System clocks are synchronized.
* [ ] Required firewall ports are available.
* [ ] HAProxy can reach all control-plane nodes.
* [ ] Sufficient CPU, memory, and disk are available.

Once all prerequisites are satisfied, continue with:

`docs/02-containerd.md`
