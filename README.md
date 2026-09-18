# Local Cluster Deployment on Intranet

## Part 01 — Infrastructure and Node Provisioning

---

## 1. Objective

The objective of Part 01 is to create and prepare the infrastructure required for deploying a highly available Kubernetes cluster in an intranet environment.

The infrastructure consists of:

* 3 Control Plane nodes
* 3 Worker nodes
* 1 HAProxy Load Balancer
* 1 External Admin/Client node
* Tailscale for private connectivity between the required machines

At the end of this phase, all required machines should be created, uniquely identified, network-connected, and ready for Kubernetes installation.

Kubernetes itself is configured in the subsequent phases.

---

# 2. Infrastructure Overview

The project uses the following infrastructure topology:

```text
                         INTRANET
                            │
             ┌──────────────┴──────────────┐
             │                             │
             ▼                             ▼
      ┌──────────────┐              ┌──────────────┐
      │ Admin Client │              │   HAProxy    │
      │              │              │ Load Balancer│
      │ kubectl      │              │              │
      └──────┬───────┘              └──────┬───────┘
             │                             │
             └──────────────┬──────────────┘
                            │
                     Tailscale Network
                            │
             ┌──────────────┼──────────────┐
             │              │              │
             ▼              ▼              ▼
       ┌──────────┐   ┌──────────┐   ┌──────────┐
       │ Master 1 │   │ Master 2 │   │ Master 3 │
       │          │   │          │   │          │
       │ Control  │   │ Control  │   │ Control  │
       │ Plane    │   │ Plane    │   │ Plane    │
       │ + etcd   │   │ + etcd   │   │ + etcd   │
       └────┬─────┘   └────┬─────┘   └────┬─────┘
            │              │              │
            └──────────────┼──────────────┘
                           │
                    Kubernetes Cluster
                           │
            ┌──────────────┼──────────────┐
            │              │              │
            ▼              ▼              ▼
       ┌──────────┐   ┌──────────┐   ┌──────────┐
       │ Worker 1 │   │ Worker 2 │   │ Worker 3 │
       └──────────┘   └──────────┘   └──────────┘
```

---

# 3. Node Topology

The complete environment contains **8 machines**.

| Node         | Role                         | Kubernetes Cluster |
| ------------ | ---------------------------- | ------------------ |
| Master 01    | Control Plane + etcd         | Yes                |
| Master 02    | Control Plane + etcd         | Yes                |
| Master 03    | Control Plane + etcd         | Yes                |
| Worker 01    | Worker                       | Yes                |
| Worker 02    | Worker                       | Yes                |
| Worker 03    | Worker                       | Yes                |
| HAProxy      | Kubernetes API Load Balancer | No                 |
| Admin Client | External Administration      | No                 |

### Summary

```text
Control Plane Nodes : 3
Worker Nodes        : 3
HAProxy             : 1
External Client     : 1
--------------------------------
Total Machines      : 8
```

---

# 4. Node Responsibilities

## 4.1 Master 01

Master 01 is the first control-plane node.

It will be used to initialize the Kubernetes cluster using `kubeadm`.

It will later run:

```text
kube-apiserver
kube-controller-manager
kube-scheduler
etcd
kubelet
containerd
```

---

## 4.2 Master 02

Master 02 will be added to the Kubernetes control plane after Master 01 is initialized.

It will later run:

```text
kube-apiserver
kube-controller-manager
kube-scheduler
etcd
kubelet
containerd
```

---

## 4.3 Master 03

Master 03 will be added as the third control-plane node.

It will later run:

```text
kube-apiserver
kube-controller-manager
kube-scheduler
etcd
kubelet
containerd
```

The three control-plane nodes will form the highly available control plane and three-member etcd cluster.

---

## 4.4 Worker 01

Worker 01 is a Kubernetes worker node.

It will later be responsible for running Kubernetes workloads.

---

## 4.5 Worker 02

Worker 02 is a Kubernetes worker node.

It will later be responsible for running Kubernetes workloads.

---

## 4.6 Worker 03

Worker 03 is a Kubernetes worker node.

It will later be responsible for running Kubernetes workloads.

---

## 4.7 HAProxy

The HAProxy machine is outside the Kubernetes cluster.

Its purpose is to provide a single, stable endpoint for Kubernetes API traffic.

The final architecture will be:

```text
                    Kubernetes API
                         :6443
                           │
                           ▼
                    ┌────────────┐
                    │  HAProxy   │
                    └─────┬──────┘
                          │
             ┌────────────┼────────────┐
             │            │            │
             ▼            ▼            ▼
        Master 01     Master 02     Master 03
          :6443         :6443         :6443
```

HAProxy distributes API traffic between the available control-plane API servers.

HAProxy itself is not a Kubernetes node.

---

## 4.8 External Admin Client

The Admin Client is outside the Kubernetes cluster.

It will be used for:

* Kubernetes administration
* `kubectl`
* Helm
* Cluster troubleshooting
* Resource management
* Monitoring access
* Deployment operations

The administrator will access the Kubernetes API through the HAProxy endpoint.

```text
Admin Client
     │
     │ kubectl
     ▼
 HAProxy :6443
     │
     ▼
Kubernetes API
```

The Admin Client is **not joined to the Kubernetes cluster**.

---

# 5. Operating System Preparation

Ubuntu Server is used as the operating system for the infrastructure.

Perform the following checks on the Kubernetes nodes.

## Check Operating System

```bash
cat /etc/os-release
```

## Check Kernel

```bash
uname -r
```

## Check Architecture

```bash
uname -m
```

## Check CPU

```bash
lscpu
```

## Check Memory

```bash
free -h
```

## Check Disk

```bash
df -h
```

These checks help confirm that the machines meet the required infrastructure requirements before Kubernetes installation.

---

# 6. Configure Hostnames

Every machine must have a unique hostname.

The following naming convention is used:

```text
master-01
master-02
master-03

worker-01
worker-02
worker-03

load-balancer
admin-client
```

---

## Master 01

```bash
sudo hostnamectl set-hostname master-01
```

Verify:

```bash
hostname
```

---

## Master 02

```bash
sudo hostnamectl set-hostname master-02
```

Verify:

```bash
hostname
```

---

## Master 03

```bash
sudo hostnamectl set-hostname master-03
```

Verify:

```bash
hostname
```

---

## Worker 01

```bash
sudo hostnamectl set-hostname worker-01
```

Verify:

```bash
hostname
```

---

## Worker 02

```bash
sudo hostnamectl set-hostname worker-02
```

Verify:

```bash
hostname
```

---

## Worker 03

```bash
sudo hostnamectl set-hostname worker-03
```

Verify:

```bash
hostname
```

---

## HAProxy

```bash
sudo hostnamectl set-hostname load-balancer
```

Verify:

```bash
hostname
```

---

## Admin Client

```bash
sudo hostnamectl set-hostname admin-client
```

Verify:

```bash
hostname
```

---

# 7. Verify Hostname Configuration

Run:

```bash
hostnamectl
```

Expected hostnames:

```text
master-01
master-02
master-03
worker-01
worker-02
worker-03
load-balancer
admin-client
```

Each machine must have a unique hostname.

---

# 8. Network Interface Verification

Check the network interfaces:

```bash
ip addr
```

Check the routing table:

```bash
ip route
```

Check the default route:

```bash
ip route | grep default
```

Verify that the required network interface is UP.

---

# 9. Configure Tailscale

Tailscale is used to provide private connectivity between the infrastructure machines.

After installing and authenticating Tailscale on the required machines, verify the service:

```bash
sudo systemctl status tailscaled
```

The service should be running.

---

# 10. Verify Tailscale

Check the Tailscale network:

```bash
tailscale status
```

Retrieve the Tailscale IPv4 address:

```bash
tailscale ip -4
```

Verify the Tailscale interface:

```bash
ip addr show tailscale0
```

Expected interface:

```text
tailscale0
```

---

# 11. Tailscale Connectivity Test

From the required nodes, verify that the other machines are visible:

```bash
tailscale status
```

Test connectivity using the Tailscale IP:

```bash
ping <tailscale-ip>
```

Example:

```bash
ping <master-02-tailscale-ip>
```

Verify that the required nodes are reachable.

---

# 12. SSH Configuration

SSH is required for remote administration and troubleshooting.

Check the SSH service:

```bash
sudo systemctl status ssh
```

If SSH is not installed:

```bash
sudo apt update
sudo apt install -y openssh-server
```

Enable SSH:

```bash
sudo systemctl enable --now ssh
```

Verify:

```bash
sudo systemctl status ssh
```

---

# 13. Test SSH Connectivity

From the administration machine:

```bash
ssh <username>@<node-ip>
```

Example:

```bash
ssh <username>@<master-ip>
```

Test the SSH port:

```bash
nc -vz <node-ip> 22
```

Expected:

```text
Connection to <node-ip> 22 port [tcp/ssh] succeeded!
```

---

# 14. Node-to-Node Connectivity

Test connectivity between the control-plane nodes.

From Master 01:

```bash
ping <master-02-ip>
ping <master-03-ip>
```

From Master 02:

```bash
ping <master-01-ip>
ping <master-03-ip>
```

From Master 03:

```bash
ping <master-01-ip>
ping <master-02-ip>
```

Verify that the control-plane nodes can communicate with each other.

---

# 15. HAProxy-to-Control-Plane Connectivity

The HAProxy node must be able to communicate with all three control-plane nodes.

Test:

```bash
ping <master-01-ip>
ping <master-02-ip>
ping <master-03-ip>
```

The Kubernetes API will later use port `6443`.

Test the API port when the API server is available:

```bash
nc -vz <master-01-ip> 6443
nc -vz <master-02-ip> 6443
nc -vz <master-03-ip> 6443
```

---

# 16. etcd Network Requirements

The three control-plane nodes will later form a three-member etcd cluster.

etcd uses:

| Port | Purpose              |
| ---: | -------------------- |
| 2379 | Client communication |
| 2380 | Peer communication   |

After etcd is deployed, verify:

```bash
nc -vz <master-ip> 2379
```

and:

```bash
nc -vz <master-ip> 2380
```

The three etcd members must be able to communicate with one another.

---

# 17. Kubernetes Network Requirements

The following ports will be required by the final Kubernetes environment.

|  Port | Protocol | Purpose                        |
| ----: | -------- | ------------------------------ |
|    22 | TCP      | SSH                            |
|  6443 | TCP      | Kubernetes API Server          |
|  2379 | TCP      | etcd client                    |
|  2380 | TCP      | etcd peer                      |
| 10250 | TCP      | Kubelet                        |
|  8472 | UDP      | Calico VXLAN, if VXLAN is used |

The exact network requirements can vary depending on the selected Kubernetes and Calico configuration.

Only required traffic should be allowed.

---

# 18. Host Resolution

Verify hostname resolution:

```bash
getent hosts master-01
getent hosts master-02
getent hosts master-03
```

If `/etc/hosts` is used for internal hostname resolution, configure the required entries.

Example:

```text
<master-01-ip> master-01
<master-02-ip> master-02
<master-03-ip> master-03

<worker-01-ip> worker-01
<worker-02-ip> worker-02
<worker-03-ip> worker-03

<load-balancer-ip> load-balancer
```

Use the actual environment-specific addresses.

Do not commit sensitive infrastructure information to a public repository.

---

# 19. Time Synchronization

Accurate system time is important for distributed Kubernetes components, TLS, and etcd.

Check the system time:

```bash
timedatectl
```

Check synchronization:

```bash
timedatectl status
```

The output should indicate that the system clock is synchronized.

All nodes should use a consistent time source.

---

# 20. Firewall Verification

Check the firewall status.

For UFW:

```bash
sudo ufw status
```

If firewall rules are required, allow only the necessary traffic for the environment.

Do not disable the firewall blindly in a production environment.

Required access should be explicitly permitted based on the cluster architecture.

---

# 21. Infrastructure Validation

Before proceeding to Kubernetes installation, validate all machines.

## Master Nodes

```bash
hostname
ip addr
ip route
tailscale status
```

## Worker Nodes

```bash
hostname
ip addr
ip route
tailscale status
```

## HAProxy

```bash
hostname
ip addr
ip route
tailscale status
```

## Admin Client

```bash
hostname
ip addr
ip route
tailscale status
```

---

# 22. Connectivity Validation

The following checks should be completed.

### SSH

```bash
nc -vz <node-ip> 22
```

### Kubernetes API

```bash
nc -vz <master-ip> 6443
```

### etcd Client

```bash
nc -vz <master-ip> 2379
```

### etcd Peer

```bash
nc -vz <master-ip> 2380
```

Note: API and etcd ports will only respond after the corresponding Kubernetes/etcd components have been deployed.

---

# 23. Infrastructure Checklist

Before continuing to Part 02:

```text
Infrastructure
[ ] Master 01 created
[ ] Master 02 created
[ ] Master 03 created
[ ] Worker 01 created
[ ] Worker 02 created
[ ] Worker 03 created
[ ] HAProxy node created
[ ] Admin Client created

Operating System
[ ] Ubuntu Server installed
[ ] Hostnames configured
[ ] CPU verified
[ ] Memory verified
[ ] Disk verified
[ ] System time synchronized

Networking
[ ] Network interfaces verified
[ ] Routing verified
[ ] Tailscale configured
[ ] Tailscale connectivity verified
[ ] SSH configured
[ ] SSH connectivity verified
[ ] Host resolution verified
[ ] Firewall rules verified

Control Plane Connectivity
[ ] Master 01 ↔ Master 02
[ ] Master 01 ↔ Master 03
[ ] Master 02 ↔ Master 03
[ ] HAProxy → Master 01
[ ] HAProxy → Master 02
[ ] HAProxy → Master 03

Administration
[ ] External Admin Client available
[ ] Admin Client can reach HAProxy
```

---

# 24. Expected Infrastructure State

At the end of Part 01, the infrastructure should be ready for Kubernetes installation.

```text
                         INTRANET
                            │
          ┌─────────────────┴─────────────────┐
          │                                   │
          ▼                                   ▼
   ┌──────────────┐                    ┌──────────────┐
   │ Admin Client │                    │   HAProxy    │
   │              │                    │              │
   │ External     │                    │ External     │
   │ to cluster   │                    │ to cluster   │
   └──────────────┘                    └──────┬───────┘
                                              │
                                        Tailscale
                                              │
                 ┌────────────────────────────┼────────────────────────────┐
                 │                            │                            │
                 ▼                            ▼                            ▼
          ┌──────────────┐             ┌──────────────┐             ┌──────────────┐
          │   Master 01  │             │   Master 02  │             │   Master 03  │
          │              │             │              │             │              │
          │  Control     │             │  Control     │             │  Control     │
          │  Plane       │             │  Plane       │             │  Plane       │
          └──────┬───────┘             └──────┬───────┘             └──────┬───────┘
                 │                            │                            │
                 └────────────────────────────┼────────────────────────────┘
                                              │
                                      Kubernetes Cluster
                                              │
                 ┌────────────────────────────┼────────────────────────────┐
                 │                            │                            │
                 ▼                            ▼                            ▼
          ┌──────────────┐             ┌──────────────┐             ┌──────────────┐
          │   Worker 01  │             │   Worker 02  │             │   Worker 03  │
          └──────────────┘             └──────────────┘             └──────────────┘
```

---

# 25. Security Notes

The following information must **not** be committed to the GitHub repository:

```text
Private SSH keys
Kubernetes admin.conf
Kubernetes kubeconfig containing credentials
TLS private keys
Passwords
API tokens
Tailscale authentication keys
Cloud credentials
etcd snapshots
```

Use placeholders in documentation:

```text
<MASTER-01-IP>
<MASTER-02-IP>
<MASTER-03-IP>
<WORKER-01-IP>
<WORKER-02-IP>
<WORKER-03-IP>
<HAProxy-IP>
<TAILSCALE-IP>
```

This allows the README to remain reusable without exposing infrastructure secrets.

---

# 26. Part 01 Completion

Part 01 is complete when:

```text
8 machines
     │
     ├── 3 Control Plane
     ├── 3 Workers
     ├── 1 HAProxy
     └── 1 Admin Client
             │
             ▼
      Network configured
             │
             ▼
      Tailscale configured
             │
             ▼
      SSH connectivity verified
             │
             ▼
      Hostnames configured
             │
             ▼
      Infrastructure validated
```

The infrastructure is now ready for Kubernetes node preparation.

---

# 27. Next Part

## Part 02 — Kubernetes Node Preparation

The next phase prepares the six Kubernetes nodes for cluster deployment.

The following components will be configured:

```text
Disable Swap
      ↓
Kernel Modules
      ↓
Sysctl Parameters
      ↓
containerd
      ↓
Kubernetes Repository
      ↓
kubeadm
      ↓
kubelet
      ↓
kubectl
      ↓
Version Verification
```

After Part 02, the nodes will be ready for Kubernetes cluster initialization.

# Part 02 — Kubernetes Node Preparation

## 28. Objective

The objective of Part 02 is to prepare all six Kubernetes nodes for Kubernetes cluster deployment.

The following nodes must be configured:

```text
Master 01
Master 02
Master 03
Worker 01
Worker 02
Worker 03
```

The following components will be configured:

```text
Swap
Kernel Modules
Linux sysctl parameters
containerd
CRI configuration
Kubernetes package repository
kubeadm
kubelet
kubectl
```

At the end of this phase, all six nodes will have the required Kubernetes dependencies installed and configured.

---

# 29. Node Preparation Architecture

```text
                    Kubernetes Nodes
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
      Master 01        Master 02        Master 03
          │                │                │
          └────────────────┼────────────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
      Worker 01        Worker 02        Worker 03
                           │
                           ▼
                  Common Preparation
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
      Swap             Kernel Modules       Sysctl
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                           ▼
                       containerd
                           │
                           ▼
                    Kubernetes Packages
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
           kubeadm      kubelet       kubectl
```

---

# 30. Prerequisites

Complete Part 01 before starting Part 02.

Verify that the six Kubernetes nodes are available:

```text
Master 01
Master 02
Master 03
Worker 01
Worker 02
Worker 03
```

Verify the operating system:

```bash
cat /etc/os-release
```

Verify hostname:

```bash
hostnamectl
```

Verify network connectivity:

```bash
ip addr
ip route
```

Verify Tailscale if it is being used for the cluster network:

```bash
tailscale status
```

---

# 31. Update System Packages

Perform the following on all six Kubernetes nodes.

```bash
sudo apt update
sudo apt upgrade -y
```

Install basic utilities:

```bash
sudo apt install -y \
    curl \
    wget \
    ca-certificates \
    apt-transport-https \
    gnupg \
    lsb-release \
    software-properties-common \
    socat \
    conntrack \
    ipset
```

Verify:

```bash
curl --version
```

---

# 32. Disable Swap

Kubernetes kubelet requires swap to be disabled for the standard configuration used in this project.

Check current swap:

```bash
free -h
```

Check active swap devices:

```bash
swapon --show
```

Disable swap temporarily:

```bash
sudo swapoff -a
```

Verify:

```bash
swapon --show
```

The command should return no active swap devices.

---

# 33. Disable Swap Permanently

Edit `/etc/fstab`:

```bash
sudo nano /etc/fstab
```

Locate the swap entry and comment it out.

Example:

```text
# /swap.img none swap sw 0 0
```

Alternatively, identify the swap entry using:

```bash
grep -n swap /etc/fstab
```

After making the change, verify:

```bash
swapon --show
```

Then:

```bash
free -h
```

Swap should remain disabled after reboot.

---

# 34. Load Required Kernel Modules

Kubernetes networking and container networking require specific Linux kernel modules.

Load:

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

Verify:

```bash
lsmod | grep overlay
```

and:

```bash
lsmod | grep br_netfilter
```

---

# 35. Configure Kernel Modules to Load at Boot

Create:

```bash
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
```

Verify:

```bash
cat /etc/modules-load.d/k8s.conf
```

Expected:

```text
overlay
br_netfilter
```

---

# 36. Configure Kubernetes sysctl Parameters

Create the Kubernetes networking configuration:

```bash
sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
```

Apply the configuration:

```bash
sudo sysctl --system
```

---

# 37. Verify sysctl Configuration

Check IP forwarding:

```bash
sysctl net.ipv4.ip_forward
```

Expected:

```text
net.ipv4.ip_forward = 1
```

Check bridge netfilter:

```bash
sysctl net.bridge.bridge-nf-call-iptables
```

Expected:

```text
net.bridge.bridge-nf-call-iptables = 1
```

Check IPv6 bridge filtering:

```bash
sysctl net.bridge.bridge-nf-call-ip6tables
```

Expected:

```text
net.bridge.bridge-nf-call-ip6tables = 1
```

---

# 38. Install containerd

Kubernetes requires a container runtime.

This project uses:

```text
containerd
```

Install containerd:

```bash
sudo apt update
sudo apt install -y containerd
```

Verify:

```bash
containerd --version
```

---

# 39. Enable containerd

Enable containerd at boot:

```bash
sudo systemctl enable containerd
```

Start containerd:

```bash
sudo systemctl start containerd
```

Verify:

```bash
sudo systemctl status containerd
```

Expected:

```text
Active: active (running)
```

---

# 40. Generate containerd Configuration

Create the configuration directory:

```bash
sudo mkdir -p /etc/containerd
```

Generate the default configuration:

```bash
containerd config default | sudo tee /etc/containerd/config.toml
```

Verify:

```bash
sudo cat /etc/containerd/config.toml
```

---

# 41. Configure systemd Cgroup Driver

Kubernetes and containerd should use the same cgroup driver.

For this environment, configure containerd to use:

```text
SystemdCgroup = true
```

Edit:

```bash
sudo nano /etc/containerd/config.toml
```

Locate the runc options section:

```text
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
```

Set:

```text
SystemdCgroup = true
```

---

# 42. Restart containerd

Restart:

```bash
sudo systemctl restart containerd
```

Verify:

```bash
sudo systemctl status containerd
```

Confirm that the service is running without errors.

---

# 43. Configure containerd to Start Automatically

Verify:

```bash
systemctl is-enabled containerd
```

Expected:

```text
enabled
```

Verify service status:

```bash
systemctl is-active containerd
```

Expected:

```text
active
```

---

# 44. Install Kubernetes Repository Signing Key

Kubernetes packages should be installed from the appropriate Kubernetes package repository.

Create the keyring directory:

```bash
sudo mkdir -p -m 755 /etc/apt/keyrings
```

Download the repository signing key according to the Kubernetes version/repository being used.

The repository configuration should match the required Kubernetes release.

Do not mix repositories from different Kubernetes major/minor releases.

---

# 45. Configure Kubernetes Package Repository

Configure the Kubernetes repository corresponding to:

```text
Kubernetes v1.34.x
```

The repository should be configured using the official Kubernetes package repository for the required release series.

After configuration:

```bash
sudo apt update
```

Verify that the Kubernetes packages are available:

```bash
apt-cache policy kubeadm
```

---

# 46. Install kubeadm

Install the required kubeadm version.

The cluster uses:

```text
Kubernetes v1.34.11
```

Install the matching kubeadm package version:

```bash
sudo apt install -y kubeadm
```

Verify:

```bash
kubeadm version
```

Expected major/minor release:

```text
v1.34.x
```

If an exact patch version is required by the project, pin the package to that exact version.

---

# 47. Install kubelet

Install:

```bash
sudo apt install -y kubelet
```

Verify:

```bash
kubelet --version
```

Expected:

```text
Kubernetes v1.34.x
```

---

# 48. Enable kubelet

Enable kubelet:

```bash
sudo systemctl enable kubelet
```

Check:

```bash
systemctl is-enabled kubelet
```

Expected:

```text
enabled
```

At this stage, kubelet may not yet be fully operational because the Kubernetes cluster has not been initialized.

This is expected.

---

# 49. Install kubectl

Install:

```bash
sudo apt install -y kubectl
```

Verify:

```bash
kubectl version --client
```

`kubectl` is primarily required on the administration/control-plane machines, but it may also be installed on worker nodes if local administration is required.

---

# 50. Verify Kubernetes Versions

On the Kubernetes nodes:

```bash
kubeadm version
```

```bash
kubelet --version
```

```bash
kubectl version --client
```

The Kubernetes components should use the intended `v1.34.x` release series.

For this project:

```text
Kubernetes Version: v1.34.11
```

Version consistency between kubeadm, kubelet, and the cluster version should be maintained according to Kubernetes upgrade/version-skew rules.

---

# 51. Verify containerd and Kubernetes Runtime

Check containerd:

```bash
containerd --version
```

Check service:

```bash
sudo systemctl is-active containerd
```

Expected:

```text
active
```

Check kubelet:

```bash
sudo systemctl status kubelet
```

Before cluster initialization, kubelet may report that it is waiting for configuration from kubeadm.

This is normal.

---

# 52. Verify Required Kernel Settings

Run:

```bash
lsmod | grep overlay
```

```bash
lsmod | grep br_netfilter
```

Then:

```bash
sysctl net.ipv4.ip_forward
```

Expected:

```text
net.ipv4.ip_forward = 1
```

---

# 53. Verify Swap Status

Run:

```bash
free -h
```

Then:

```bash
swapon --show
```

No active swap should be displayed.

---

# 54. Verify Node Resources

Check CPU:

```bash
nproc
```

Check memory:

```bash
free -h
```

Check disk:

```bash
df -h
```

Ensure sufficient resources are available for Kubernetes components and future workloads.

---

# 55. Verify Network Ports

Before initializing the cluster, verify that the required network paths are available.

### SSH

```bash
nc -vz <node-ip> 22
```

### Kubernetes API

```bash
nc -vz <master-ip> 6443
```

The API port may not respond until kubeadm initializes the control plane.

### etcd

```bash
nc -vz <master-ip> 2379
nc -vz <master-ip> 2380
```

These ports will become active after etcd is deployed.

### Kubelet

```bash
nc -vz <node-ip> 10250
```

The kubelet API becomes available when kubelet is running and configured.

---

# 56. Verify DNS / Hostname Resolution

Verify the control-plane hostnames:

```bash
getent hosts master-01
getent hosts master-02
getent hosts master-03
```

Verify workers:

```bash
getent hosts worker-01
getent hosts worker-02
getent hosts worker-03
```

If the environment uses `/etc/hosts`, verify:

```bash
cat /etc/hosts
```

---

# 57. Verify Tailscale

If Tailscale is used for cluster connectivity:

```bash
tailscale status
```

Get the node address:

```bash
tailscale ip -4
```

Verify the interface:

```bash
ip addr show tailscale0
```

Test another node:

```bash
ping <tailscale-ip>
```

---

# 58. Verify containerd Configuration

Check the configured cgroup driver:

```bash
sudo grep -n "SystemdCgroup" \
  /etc/containerd/config.toml
```

Expected:

```text
SystemdCgroup = true
```

If the configuration was changed, restart containerd:

```bash
sudo systemctl restart containerd
```

---

# 59. Verify Services

Check containerd:

```bash
sudo systemctl status containerd
```

Check kubelet:

```bash
sudo systemctl status kubelet
```

Check enabled services:

```bash
systemctl is-enabled containerd
systemctl is-enabled kubelet
```

Expected:

```text
containerd → enabled
kubelet    → enabled
```

---

# 60. Verify All Six Kubernetes Nodes

Perform the preparation steps on:

```text
Master 01
Master 02
Master 03

Worker 01
Worker 02
Worker 03
```

Each node should have:

```text
✓ Swap disabled
✓ overlay module loaded
✓ br_netfilter module loaded
✓ IP forwarding enabled
✓ containerd installed
✓ containerd running
✓ SystemdCgroup enabled
✓ kubeadm installed
✓ kubelet installed
✓ kubectl available where required
✓ Network connectivity verified
```

---

# 61. Node Preparation Validation Script

The following commands can be used as a quick validation:

```bash
echo "===== Hostname ====="
hostname

echo "===== OS ====="
cat /etc/os-release | grep PRETTY_NAME

echo "===== Swap ====="
swapon --show

echo "===== Kernel Modules ====="
lsmod | grep -E 'overlay|br_netfilter'

echo "===== IP Forwarding ====="
sysctl net.ipv4.ip_forward

echo "===== Containerd ====="
containerd --version
systemctl is-active containerd

echo "===== Kubeadm ====="
kubeadm version

echo "===== Kubelet ====="
kubelet --version

echo "===== Kubectl ====="
kubectl version --client

echo "===== Disk ====="
df -h /

echo "===== Memory ====="
free -h
```

---

# 62. Expected Validation Result

A correctly prepared node should show:

```text
Hostname             → Correct node hostname
Swap                 → Disabled
overlay              → Loaded
br_netfilter         → Loaded
IP forwarding        → 1
containerd           → Active
SystemdCgroup        → true
kubeadm              → v1.34.x
kubelet              → v1.34.x
kubectl               → Installed
```

---

# 63. Important Notes

## kubelet Status

Before `kubeadm init` or `kubeadm join`, kubelet may not appear fully healthy.

For example, kubelet may restart or wait for kubeadm-generated configuration.

This is expected before cluster initialization.

---

## Kubernetes Version

All nodes should use a compatible Kubernetes version.

This project targets:

```text
Kubernetes v1.34.11
```

Avoid accidentally installing a newer major/minor release on one node.

---

## containerd

The container runtime is:

```text
containerd
```

The CRI configuration must be enabled and the cgroup configuration must be compatible with kubelet.

---

# 64. Troubleshooting

## containerd is not running

Check:

```bash
sudo systemctl status containerd
```

Check logs:

```bash
sudo journalctl -u containerd -xe
```

Validate configuration:

```bash
sudo containerd config dump
```

---

## kubelet is failing

Check:

```bash
sudo systemctl status kubelet
```

Logs:

```bash
sudo journalctl -u kubelet -xe
```

Remember that kubelet may not become fully operational until kubeadm configures the node.

---

## Swap is still enabled

Check:

```bash
swapon --show
```

If swap is active:

```bash
sudo swapoff -a
```

Then inspect:

```bash
grep -n swap /etc/fstab
```

Disable the persistent swap entry.

---

## Kernel Module Missing

Check:

```bash
lsmod | grep overlay
lsmod | grep br_netfilter
```

Load manually:

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

---

## IP Forwarding Disabled

Check:

```bash
sysctl net.ipv4.ip_forward
```

Set:

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

Then ensure the persistent configuration exists:

```bash
cat /etc/sysctl.d/k8s.conf
```

---

## containerd Cgroup Configuration

Check:

```bash
sudo grep -n "SystemdCgroup" \
  /etc/containerd/config.toml
```

It should contain:

```text
SystemdCgroup = true
```

Restart:

```bash
sudo systemctl restart containerd
```

---

# 65. Part 02 Checklist

Before proceeding to Part 03, verify:

```text
Operating System
[ ] Ubuntu verified
[ ] Hostname configured
[ ] CPU verified
[ ] Memory verified
[ ] Disk verified

Swap
[ ] Swap disabled
[ ] Swap disabled permanently

Kernel
[ ] overlay loaded
[ ] br_netfilter loaded
[ ] Kernel modules configured persistently

Networking
[ ] IP forwarding enabled
[ ] bridge netfilter enabled
[ ] Node-to-node connectivity verified
[ ] Tailscale verified
[ ] Hostname resolution verified

Container Runtime
[ ] containerd installed
[ ] containerd enabled
[ ] containerd running
[ ] CRI configured
[ ] SystemdCgroup enabled

Kubernetes
[ ] kubeadm installed
[ ] kubelet installed
[ ] kubectl installed where required
[ ] Kubernetes versions verified
```

---

# 66. Expected Final State

After completing Part 02:

```text
                    Kubernetes Infrastructure
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
    Master 01             Master 02             Master 03
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
    Worker 01             Worker 02             Worker 03

All six nodes:
    │
    ├── Ubuntu
    ├── Swap disabled
    ├── Kernel configured
    ├── Sysctl configured
    ├── containerd
    ├── kubeadm
    ├── kubelet
    └── kubectl where required
```

The nodes are now prepared for Kubernetes cluster initialization.

---

# 67. Next Part

## Part 03 — HAProxy Load Balancer Configuration

The next phase will configure the external HAProxy node as the Kubernetes API load balancer.

The flow will be:

```text
External Admin Client
          │
          │ TCP 6443
          ▼
      HAProxy LB
          │
     ┌────┼────┐
     │    │    │
     ▼    ▼    ▼
 Master Master Master
   01     02     03
```

Part 03 will cover:

```text
HAProxy installation
       ↓
HAProxy configuration
       ↓
Kubernetes API frontend
       ↓
Three-master backend
       ↓
Health checks
       ↓
HAProxy validation
       ↓
API connectivity testing
```

# Part 02 Complete

The six Kubernetes nodes are now prepared for the Kubernetes cluster deployment phase.

# Part 03 — HAProxy Load Balancer Configuration

## 68. Objective

The objective of Part 03 is to configure an external HAProxy server as the load balancer for the Kubernetes API Server.

The Kubernetes cluster contains three control-plane nodes:

```text
Master 01
Master 02
Master 03
```

Each control-plane node will later run a Kubernetes API Server on:

```text
TCP 6443
```

Instead of allowing administrators and Kubernetes components to connect directly to an individual control-plane node, HAProxy provides a single stable API endpoint.

The architecture is:

```text
                         External Admin Client
                                  │
                                  │ HTTPS/TCP 6443
                                  ▼
                         ┌─────────────────┐
                         │     HAProxy     │
                         │  Load Balancer  │
                         └────────┬────────┘
                                  │
                   ┌──────────────┼──────────────┐
                   │              │              │
                   ▼              ▼              ▼
              Master 01      Master 02      Master 03
                :6443          :6443          :6443
```

---

# 69. HAProxy Role

HAProxy is deployed on a dedicated machine outside the Kubernetes cluster.

Its responsibilities are:

* Provide a stable Kubernetes API endpoint
* Distribute API traffic across the three control-plane nodes
* Perform health checks against the API servers
* Prevent traffic from being sent to unavailable API servers
* Provide a single endpoint for `kubeadm`, `kubectl`, and Kubernetes components

HAProxy does **not** run Kubernetes components.

```text
HAProxy Node
    │
    ├── HAProxy
    │
    └── No kubelet
        No kubeadm cluster membership
        No etcd
        No kube-apiserver
```

---

# 70. Prerequisites

Part 01 and Part 02 must be completed before starting this phase.

The following should already exist:

```text
Master 01
Master 02
Master 03
Worker 01
Worker 02
Worker 03
HAProxy
Admin Client
```

The three control-plane nodes should be reachable from the HAProxy node.

Verify basic connectivity:

```bash
ping <master-01-ip>
ping <master-02-ip>
ping <master-03-ip>
```

If Tailscale is being used:

```bash
tailscale status
```

---

# 71. Verify HAProxy Host

On the HAProxy machine:

```bash
hostnamectl
```

Expected hostname:

```text
load-balancer
```

Verify the operating system:

```bash
cat /etc/os-release
```

Check network interfaces:

```bash
ip addr
```

Check routing:

```bash
ip route
```

Verify Tailscale if applicable:

```bash
tailscale status
tailscale ip -4
```

---

# 72. Install HAProxy

Update the package index:

```bash
sudo apt update
```

Install HAProxy:

```bash
sudo apt install -y haproxy
```

Verify the installed version:

```bash
haproxy -v
```

---

# 73. Enable HAProxy

Enable HAProxy to start automatically after a reboot:

```bash
sudo systemctl enable haproxy
```

Check:

```bash
systemctl is-enabled haproxy
```

Expected:

```text
enabled
```

---

# 74. Start HAProxy

Start the service:

```bash
sudo systemctl start haproxy
```

Check the service:

```bash
sudo systemctl status haproxy
```

Expected:

```text
Active: active (running)
```

---

# 75. HAProxy Configuration File

The main HAProxy configuration file is:

```text
/etc/haproxy/haproxy.cfg
```

Create a backup before modifying it:

```bash
sudo cp /etc/haproxy/haproxy.cfg \
       /etc/haproxy/haproxy.cfg.backup
```

Verify:

```bash
ls -l /etc/haproxy/
```

---

# 76. Configure Kubernetes API Frontend

HAProxy must listen on port:

```text
6443
```

This is the Kubernetes API Server port.

The frontend receives connections from:

```text
Admin Client
kubeadm
kubectl
other required Kubernetes components
```

and forwards them to the Kubernetes control-plane API servers.

---

# 77. Configure HAProxy Backend

The backend contains the three control-plane nodes:

```text
Master 01 :6443
Master 02 :6443
Master 03 :6443
```

The conceptual configuration is:

```text
frontend kubernetes-api
    bind *:6443
    mode tcp
    default_backend kubernetes-masters

backend kubernetes-masters
    mode tcp
    balance roundrobin

    server master-01 <MASTER-01-IP>:6443 check
    server master-02 <MASTER-02-IP>:6443 check
    server master-03 <MASTER-03-IP>:6443 check
```

Replace the placeholders with the actual addresses used by the environment.

---

# 78. Why TCP Mode Is Used

The Kubernetes API Server uses HTTPS.

HAProxy is configured in TCP mode so that it can forward the encrypted connection without terminating the Kubernetes API TLS connection.

The flow is:

```text
Client
   │
   │ TLS
   ▼
HAProxy
   │
   │ TCP forwarding
   ▼
Kubernetes API Server
```

The Kubernetes API Server remains responsible for TLS termination.

---

# 79. HAProxy Health Checks

The `check` option enables health checks for backend servers.

Example:

```text
server master-01 <MASTER-01-IP>:6443 check
```

HAProxy periodically checks whether the backend server is available.

Conceptually:

```text
                    HAProxy
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
       Master 01    Master 02    Master 03
          │            │            │
       HEALTHY       HEALTHY       DOWN
          │            │            │
          └────────────┴────────────┘
                       │
                Traffic only to
                available servers
```

The exact health-check behavior depends on the HAProxy configuration.

---

# 80. Configure HAProxy

Edit:

```bash
sudo nano /etc/haproxy/haproxy.cfg
```

Add the Kubernetes API frontend/backend configuration appropriate for the environment.

Example:

```text
frontend kubernetes-api
    bind *:6443
    mode tcp
    option tcplog
    default_backend kubernetes-masters

backend kubernetes-masters
    mode tcp
    balance roundrobin

    server master-01 <MASTER-01-IP>:6443 check
    server master-02 <MASTER-02-IP>:6443 check
    server master-03 <MASTER-03-IP>:6443 check
```

Use the actual IP addresses or hostnames from the environment.

---

# 81. Validate HAProxy Configuration

Before restarting HAProxy, always validate the configuration.

Run:

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Expected:

```text
Configuration file is valid
```

Do not restart HAProxy if configuration validation fails.

---

# 82. Restart HAProxy

After successful validation:

```bash
sudo systemctl restart haproxy
```

Check:

```bash
sudo systemctl status haproxy
```

Expected:

```text
Active: active (running)
```

---

# 83. Verify HAProxy Listening Port

Check whether HAProxy is listening on TCP port 6443:

```bash
sudo ss -lntp | grep 6443
```

Expected conceptually:

```text
LISTEN ... :6443 ... haproxy
```

Another option:

```bash
sudo lsof -i :6443
```

---

# 84. Verify Master API Connectivity

At this point, the Kubernetes API Server may not yet be running because the control plane has not been initialized.

Therefore, a connection failure at this stage can be expected.

After Master 01 is initialized, test from HAProxy:

```bash
nc -vz <master-01-ip> 6443
```

After Master 02 is initialized:

```bash
nc -vz <master-02-ip> 6443
```

After Master 03 is initialized:

```bash
nc -vz <master-03-ip> 6443
```

All available API servers should be reachable.

---

# 85. Verify HAProxy Endpoint

Once at least one Kubernetes API Server is running, test the HAProxy endpoint:

```bash
nc -vz <haproxy-ip> 6443
```

Expected:

```text
Connection to <haproxy-ip> 6443 port [tcp/*] succeeded!
```

---

# 86. Test Kubernetes API Through HAProxy

Once the first control plane has been initialized, test the API endpoint:

```bash
curl -k https://<haproxy-ip>:6443/version
```

A successful response should contain Kubernetes version information.

The `-k` option is used only for this connectivity test to avoid local certificate verification issues.

For normal Kubernetes administration, use the configured kubeconfig and certificate validation.

---

# 87. Configure a DNS Name for the API Endpoint

If a DNS name is available for the HAProxy endpoint, use it as the Kubernetes control-plane endpoint.

Example:

```text
k8s-api.example.internal
```

The resulting endpoint becomes:

```text
k8s-api.example.internal:6443
```

If DNS is not available, an approved IP address can be used.

The important requirement is that the endpoint remains stable.

---

# 88. Kubernetes Control Plane Endpoint

The HAProxy endpoint will later be configured as the kubeadm control-plane endpoint.

Conceptually:

```text
controlPlaneEndpoint:
    <HAProxy-ENDPOINT>:6443
```

This allows the Kubernetes cluster to use the HAProxy endpoint rather than a specific master node.

---

# 89. Why a Load Balancer Is Required

Without an external load balancer:

```text
kubectl
   │
   ▼
Master 01
```

If Master 01 becomes unavailable, the API endpoint configured on the client may become unavailable.

With HAProxy:

```text
                 HAProxy
                    │
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
    Master 01   Master 02   Master 03
```

The client communicates with one stable endpoint while HAProxy selects an available control-plane API server.

---

# 90. HAProxy Traffic Flow

The complete API traffic flow is:

```text
External Admin Client
          │
          │ kubectl
          ▼
   HAProxy Endpoint
          │
          │ TCP :6443
          ▼
 ┌───────────────────────┐
 │ HAProxy Backend       │
 └───────────┬───────────┘
             │
       ┌─────┼─────┐
       │     │     │
       ▼     ▼     ▼
     M01    M02    M03
    :6443  :6443  :6443
       │     │     │
       └─────┼─────┘
             │
             ▼
       Kubernetes API
```

---

# 91. Test Backend Failover

After the Kubernetes API is operational on all three masters, HAProxy failover can be tested.

First verify backend status:

```bash
sudo systemctl status haproxy
```

Then verify connectivity:

```bash
nc -vz <haproxy-ip> 6443
```

Stop the API server on a test control-plane node only when performing an approved maintenance/failure test.

Verify that the HAProxy endpoint remains reachable.

Then restore the node and verify that it becomes available again.

Do not perform failure testing on a production cluster without an approved maintenance procedure.

---

# 92. HAProxy Logs

Check HAProxy logs:

```bash
sudo journalctl -u haproxy
```

Follow logs:

```bash
sudo journalctl -u haproxy -f
```

If logging is configured through rsyslog, check the appropriate HAProxy log file.

---

# 93. Troubleshooting HAProxy

## HAProxy Service Failed

Check:

```bash
sudo systemctl status haproxy
```

Check logs:

```bash
sudo journalctl -u haproxy -xe
```

Validate configuration:

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

---

## Backend Has No Available Server

If logs show:

```text
backend kubernetes-masters has no server available
```

check connectivity from HAProxy to the control-plane nodes:

```bash
nc -vz <master-01-ip> 6443
nc -vz <master-02-ip> 6443
nc -vz <master-03-ip> 6443
```

Then check the API server on the corresponding control-plane node.

---

## Connection Refused

If:

```text
Connection refused
```

is returned for port 6443, verify:

```bash
sudo ss -lntp | grep 6443
```

on the control-plane node.

The Kubernetes API server may not yet be initialized.

---

## Connection Timeout

If:

```text
Connection timed out
```

is returned:

Check:

```bash
ip route
```

Check Tailscale:

```bash
tailscale status
```

Check firewall:

```bash
sudo ufw status
```

Check connectivity:

```bash
ping <master-ip>
```

Then:

```bash
nc -vz <master-ip> 6443
```

---

# 94. Verify HAProxy from Admin Client

Once the API server is available, from the external Admin Client:

```bash
nc -vz <haproxy-ip> 6443
```

Then:

```bash
curl -k https://<haproxy-ip>:6443/version
```

The endpoint should respond through HAProxy.

---

# 95. Security Considerations

HAProxy should only expose the ports required by the architecture.

The Kubernetes API endpoint:

```text
6443
```

should only be reachable from approved networks and administration endpoints.

Do not expose etcd ports through HAProxy.

HAProxy should **not** forward:

```text
2379
2380
```

These are etcd ports and should remain restricted to the required control-plane communication paths.

---

# 96. HAProxy Validation Checklist

Complete the following before proceeding:

```text
HAProxy
[ ] HAProxy installed
[ ] HAProxy service enabled
[ ] HAProxy service running
[ ] Configuration file created
[ ] Configuration syntax validated
[ ] Kubernetes API frontend configured
[ ] Kubernetes backend configured
[ ] Master 01 configured
[ ] Master 02 configured
[ ] Master 03 configured
[ ] Health checks configured
[ ] HAProxy listening on 6443

Connectivity
[ ] HAProxy → Master 01 :6443
[ ] HAProxy → Master 02 :6443
[ ] HAProxy → Master 03 :6443
[ ] Admin Client → HAProxy :6443

Security
[ ] etcd ports are not exposed through HAProxy
[ ] API access restricted to approved network
[ ] HAProxy configuration protected
```

---

# 97. Expected Final State

At the end of Part 03, the HAProxy architecture should be:

```text
                         External Admin Client
                                  │
                                  │
                                  │ :6443
                                  ▼
                         ┌─────────────────┐
                         │     HAProxy     │
                         │                 │
                         │ Kubernetes API  │
                         │ Load Balancer   │
                         └────────┬────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │             │             │
                    ▼             ▼             ▼
               Master 01     Master 02     Master 03
                 :6443         :6443         :6443
                    │             │             │
                    │             │             │
                    └─────────────┼─────────────┘
                                  │
                           Control Plane
```

HAProxy provides the stable endpoint that will be used during Kubernetes control-plane initialization.

---

# 98. Important Note Before Part 04

At this stage:

```text
✓ Infrastructure created
✓ Network configured
✓ Tailscale configured
✓ Kubernetes nodes prepared
✓ containerd configured
✓ kubeadm installed
✓ kubelet installed
✓ kubectl installed
✓ HAProxy installed
✓ HAProxy configured
```

The Kubernetes control plane has **not yet been initialized**.

The next phase is where `kubeadm` will initialize Master 01 using the HAProxy endpoint.

---

# 99. Next Part

## Part 04 — Kubernetes Control Plane Initialization

The next phase will cover:

```text
Create kubeadm configuration
        ↓
Configure HAProxy control-plane endpoint
        ↓
Initialize Master 01
        ↓
Configure kubectl
        ↓
Verify kube-apiserver
        ↓
Verify scheduler
        ↓
Verify controller-manager
        ↓
Verify first etcd member
        ↓
Prepare control-plane join command
```

The target architecture after Part 04 will be:

```text
                    HAProxy
                       │
                       │ :6443
                       ▼
                  Master 01
                       │
              ┌────────┼────────┐
              │        │        │
              ▼        ▼        ▼
          API Server Scheduler Controller
                       │
                       ▼
                      etcd
```

# Part 03 Complete

The external HAProxy load balancer is configured and ready to provide the stable Kubernetes API endpoint for the highly available control-plane deployment.

# Part 04 — Kubernetes Control Plane Initialization

## 100. Objective

The objective of Part 04 is to initialize the first Kubernetes control-plane node using `kubeadm`.

Master 01 will become the first control-plane node of the cluster and will host:

* kube-apiserver
* kube-controller-manager
* kube-scheduler
* etcd
* kubelet
* kube-proxy

The Kubernetes API will be exposed through the external HAProxy load balancer.

The architecture at the end of this phase will be:

```text
                         External Admin Client
                                  │
                                  │ :6443
                                  ▼
                         ┌─────────────────┐
                         │     HAProxy     │
                         └────────┬────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │    Master 01    │
                         │                 │
                         │ kube-apiserver  │
                         │ controller-mgr  │
                         │ scheduler       │
                         │ etcd            │
                         │ kubelet         │
                         └─────────────────┘
```

Master 02 and Master 03 will be added in Part 05.

---

# 101. Pre-Initialization Validation

Perform these checks on **Master 01**.

Verify hostname:

```bash
hostnamectl
```

Expected:

```text
master-01
```

Verify Kubernetes versions:

```bash
kubeadm version
kubelet --version
kubectl version --client
```

The cluster target version is:

```text
Kubernetes v1.34.11
```

Verify containerd:

```bash
sudo systemctl status containerd
```

Expected:

```text
Active: active (running)
```

Verify swap:

```bash
swapon --show
```

The command should return no active swap devices.

Verify required kernel modules:

```bash
lsmod | grep overlay
lsmod | grep br_netfilter
```

Verify IP forwarding:

```bash
sysctl net.ipv4.ip_forward
```

Expected:

```text
net.ipv4.ip_forward = 1
```

Verify the Kubernetes API endpoint is reachable through HAProxy:

```bash
nc -vz <HAProxy-IP-or-DNS> 6443
```

---

# 102. Determine the Kubernetes API Endpoint

The Kubernetes API endpoint should be the stable HAProxy endpoint rather than Master 01 directly.

Example:

```text
<HAProxy-IP>:6443
```

or:

```text
k8s-api.example.internal:6443
```

Use the actual endpoint configured in Part 03.

For the remainder of this documentation, the placeholder is:

```text
<HAProxy-ENDPOINT>:6443
```

Do not replace this with a Master IP.

---

# 103. Create kubeadm Configuration

Using a kubeadm configuration file makes the cluster initialization explicit and reproducible.

Create:

```bash
sudo mkdir -p /etc/kubernetes
sudo nano /etc/kubernetes/kubeadm-config.yaml
```

Example:

```yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: <MASTER-01-IP>
  bindPort: 6443

---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: v1.34.11
controlPlaneEndpoint: "<HAProxy-ENDPOINT>:6443"

networking:
  podSubnet: "<POD-CIDR>"
  serviceSubnet: "<SERVICE-CIDR>"
```

Replace:

```text
<MASTER-01-IP>
<HAProxy-ENDPOINT>
<POD-CIDR>
<SERVICE-CIDR>
```

with the actual values used by the cluster.

### Important

The `advertiseAddress` is the address of Master 01.

The `controlPlaneEndpoint` is the HAProxy endpoint.

They serve different purposes:

```text
advertiseAddress
        ↓
Master 01's own API address

controlPlaneEndpoint
        ↓
Stable cluster API endpoint through HAProxy
```

---

# 104. Pod Network CIDR

The `podSubnet` must match the CIDR expected by the selected CNI.

For example, if the Calico configuration used for this cluster expects:

```text
192.168.0.0/16
```

then the kubeadm configuration should use the corresponding Pod CIDR.

Example:

```yaml
networking:
  podSubnet: "192.168.0.0/16"
```

The actual value must match the Calico deployment used for this project.

Do not arbitrarily change the Pod CIDR after cluster initialization.

---

# 105. Service Network CIDR

The default Kubernetes Service CIDR is commonly:

```text
10.96.0.0/12
```

If the project uses the default:

```yaml
networking:
  serviceSubnet: "10.96.0.0/12"
```

The Service CIDR should not overlap with:

* Tailscale network
* node network
* Pod network
* other routed networks

Verify the planned network ranges before initialization.

---

# 106. Validate the kubeadm Configuration

Before initialization, validate the configuration:

```bash
sudo kubeadm config validate --config /etc/kubernetes/kubeadm-config.yaml
```

If the installed kubeadm version supports the command and the configuration is valid, validation should succeed.

If validation reports an error, correct the configuration before continuing.

---

# 107. Run kubeadm Preflight Checks

Run:

```bash
sudo kubeadm init phase preflight \
  --config /etc/kubernetes/kubeadm-config.yaml
```

This checks the node for common Kubernetes initialization requirements.

Typical areas checked include:

* container runtime
* swap
* ports
* kernel configuration
* required binaries
* system configuration

Resolve any blocking preflight errors before proceeding.

---

# 108. Initialize Master 01

Run:

```bash
sudo kubeadm init \
  --config /etc/kubernetes/kubeadm-config.yaml \
  --upload-certs
```

The `--upload-certs` option allows kubeadm to upload the control-plane certificates needed when additional control-plane nodes join.

The initialization process creates the first control-plane node.

Conceptually:

```text
kubeadm init
     │
     ├── PKI certificates
     ├── kubeconfig files
     ├── static Pods
     ├── kube-apiserver
     ├── kube-controller-manager
     ├── kube-scheduler
     └── etcd
```

---

# 109. What kubeadm Creates

After successful initialization, Master 01 contains the initial Kubernetes control-plane components.

Static Pod manifests are stored under:

```text
/etc/kubernetes/manifests/
```

Check:

```bash
sudo ls -l /etc/kubernetes/manifests/
```

Expected components include:

```text
etcd.yaml
kube-apiserver.yaml
kube-controller-manager.yaml
kube-scheduler.yaml
```

These manifests are monitored by kubelet.

---

# 110. Configure kubectl on Master 01

After `kubeadm init` completes successfully, configure `kubectl` for the current user.

Run:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown "$(id -u)":"$(id -g)" $HOME/.kube/config
```

Verify:

```bash
kubectl cluster-info
```

Then:

```bash
kubectl get nodes
```

Expected initially:

```text
NAME        STATUS     ROLES           AGE   VERSION
master-01   NotReady   control-plane   ...   v1.34.11
```

`NotReady` is expected before the CNI is installed.

---

# 111. Verify Cluster Information

Run:

```bash
kubectl cluster-info
```

The output should show the Kubernetes control plane endpoint.

Verify the configured server:

```bash
kubectl config view --minify
```

The server should reference the HAProxy control-plane endpoint rather than a direct Master 01 address.

Conceptually:

```text
server: https://<HAProxy-ENDPOINT>:6443
```

---

# 112. Verify Kubernetes API Server

Check the API server Pod:

```bash
kubectl get pods -n kube-system
```

Look for:

```text
kube-apiserver-master-01
```

Check:

```bash
kubectl get pods -n kube-system -o wide
```

The API server should transition to:

```text
Running
```

---

# 113. Verify Controller Manager

Run:

```bash
kubectl get pods -n kube-system
```

Look for:

```text
kube-controller-manager-master-01
```

Expected:

```text
Running
```

---

# 114. Verify Scheduler

Look for:

```text
kube-scheduler-master-01
```

Expected:

```text
Running
```

---

# 115. Verify etcd

The first etcd member is created on Master 01.

Check:

```bash
kubectl get pods -n kube-system -l component=etcd -o wide
```

Expected conceptually:

```text
etcd-master-01    1/1    Running    ...    <MASTER-01-IP>
```

The etcd member is local to the control-plane node.

At this stage:

```text
Master 01
    │
    └── etcd member 1
```

Master 02 and Master 03 will later become additional etcd members.

---

# 116. Verify etcd Ports

etcd uses:

```text
2379
```

for client communication and:

```text
2380
```

for peer communication.

On Master 01:

```bash
sudo ss -lntp | grep -E '2379|2380'
```

The ports should be associated with the etcd process/container as appropriate for the deployment.

---

# 117. Verify kubelet

Check:

```bash
sudo systemctl status kubelet
```

Expected:

```text
Active: active (running)
```

Check kubelet logs if necessary:

```bash
sudo journalctl -u kubelet -n 100 --no-pager
```

Follow logs:

```bash
sudo journalctl -u kubelet -f
```

---

# 118. Verify containerd

Check:

```bash
sudo systemctl status containerd
```

Verify containers through CRI:

```bash
sudo crictl ps
```

If `crictl` is configured correctly, the Kubernetes control-plane containers should be visible.

---

# 119. Verify Static Pods

Kubernetes control-plane components are initially deployed as static Pods.

Check:

```bash
kubectl get pods -n kube-system -o wide
```

Typical initial control-plane Pods include:

```text
etcd-master-01
kube-apiserver-master-01
kube-controller-manager-master-01
kube-scheduler-master-01
```

---

# 120. Verify Node Role

Run:

```bash
kubectl get nodes
```

Expected:

```text
master-01   NotReady   control-plane   ...   v1.34.11
```

The node is expected to become `Ready` after the CNI is installed.

The control-plane role can be confirmed with:

```bash
kubectl get node master-01
```

---

# 121. Check Node Details

Run:

```bash
kubectl describe node master-01
```

Review:

* Roles
* Conditions
* Addresses
* Capacity
* Allocatable resources
* Taints
* System Info

The control-plane node normally has a control-plane taint before worker scheduling is configured.

---

# 122. Check Control-Plane Taint

Run:

```bash
kubectl describe node master-01 | grep -i taint
```

A control-plane taint may be present, for example:

```text
node-role.kubernetes.io/control-plane:NoSchedule
```

This prevents normal application workloads from being scheduled on the control-plane node.

Do not remove this taint unless there is a specific architectural requirement.

---

# 123. Verify API Access Through HAProxy

The API should be accessible through the same endpoint that was configured as `controlPlaneEndpoint`.

From Master 01:

```bash
curl -k https://<HAProxy-ENDPOINT>:6443/version
```

The response should contain Kubernetes version information.

Test with kubectl:

```bash
kubectl get --raw='/version'
```

---

# 124. Verify HAProxy Backend

On the HAProxy server:

```bash
sudo journalctl -u haproxy -n 100 --no-pager
```

Check whether Master 01 is reachable.

From HAProxy:

```bash
nc -vz <MASTER-01-IP> 6443
```

At this point Master 01 should be accepting API traffic.

Master 02 and Master 03 may still be unavailable because they have not yet joined the cluster.

---

# 125. Verify Kubernetes Certificates

kubeadm creates the Kubernetes PKI under:

```text
/etc/kubernetes/pki/
```

Check:

```bash
sudo ls -l /etc/kubernetes/pki/
```

Important certificate files include certificates associated with:

* Kubernetes API server
* etcd
* front-proxy
* service accounts
* cluster CA

Do not copy private keys into the Git repository.

---

# 126. Verify kubeconfig Files

Check:

```bash
sudo ls -l /etc/kubernetes/
```

Important kubeconfig files include:

```text
admin.conf
controller-manager.conf
scheduler.conf
```

`admin.conf` provides administrative access to the cluster.

Protect it appropriately.

Never commit it to Git.

---

# 127. Generate Control-Plane Join Information

After successful initialization, kubeadm prints join commands.

If the output was lost, generate a new worker join command with:

```bash
kubeadm token create --print-join-command
```

For additional control-plane nodes, the join command also requires the control-plane certificate key.

Generate a new certificate key when required:

```bash
sudo kubeadm init phase upload-certs --upload-certs
```

The command returns a certificate key.

The resulting control-plane join command has the general form:

```bash
kubeadm join <HAProxy-ENDPOINT>:6443 \
    --token <TOKEN> \
    --discovery-token-ca-cert-hash sha256:<HASH> \
    --control-plane \
    --certificate-key <CERTIFICATE-KEY>
```

The actual command printed by kubeadm should be used.

---

# 128. Protect Join Credentials

The following values are sensitive:

```text
TOKEN
DISCOVERY TOKEN CA CERTIFICATE HASH
CERTIFICATE KEY
```

Do not store them in:

```text
README.md
Git repository
public documentation
screenshots
tickets
chat messages
```

If a join token or certificate key is exposed, rotate/recreate the required credentials.

---

# 129. Verify etcd Member Health

The etcd Pod should be running:

```bash
kubectl get pod -n kube-system -l component=etcd -o wide
```

Inspect logs if required:

```bash
kubectl logs -n kube-system -l component=etcd --tail=100
```

For deeper etcd diagnostics, use `etcdctl`/`etcdutl` with the certificates generated by kubeadm and the version-compatible commands for the installed etcd release.

Do not run destructive etcd commands during validation.

---

# 130. Verify Control-Plane Component Logs

API server:

```bash
kubectl logs -n kube-system kube-apiserver-master-01
```

Controller manager:

```bash
kubectl logs -n kube-system kube-controller-manager-master-01
```

Scheduler:

```bash
kubectl logs -n kube-system kube-scheduler-master-01
```

etcd:

```bash
kubectl logs -n kube-system etcd-master-01
```

If Pod names differ, first obtain the actual names:

```bash
kubectl get pods -n kube-system
```

---

# 131. Check Cluster Events

Run:

```bash
kubectl get events -A --sort-by='.lastTimestamp'
```

This helps identify initialization problems.

For a particular namespace:

```bash
kubectl get events -n kube-system --sort-by='.lastTimestamp'
```

---

# 132. Common Problems

## kubeadm Preflight Failure

Check:

```bash
sudo kubeadm init \
  --config /etc/kubernetes/kubeadm-config.yaml \
  --upload-certs
```

Review the exact preflight error before changing the node configuration.

Common causes include:

* swap enabled
* required ports already occupied
* container runtime unavailable
* incorrect cgroup configuration
* stale Kubernetes configuration
* incompatible system settings

---

## kubelet Not Running

Check:

```bash
sudo systemctl status kubelet
```

Then:

```bash
sudo journalctl -u kubelet -xe
```

Also check:

```bash
sudo systemctl status containerd
```

---

## API Server Not Running

Check:

```bash
kubectl get pods -n kube-system
```

Then:

```bash
sudo crictl ps -a
```

Check kubelet:

```bash
sudo journalctl -u kubelet -n 200 --no-pager
```

Check the API server container logs using the CRI runtime if necessary.

---

## API Endpoint Connection Refused

Test locally:

```bash
sudo ss -lntp | grep 6443
```

Test through HAProxy:

```bash
nc -vz <HAProxy-ENDPOINT> 6443
```

Then test:

```bash
curl -k https://<HAProxy-ENDPOINT>:6443/version
```

Determine whether the failure is between:

```text
Client → HAProxy
```

or:

```text
HAProxy → Master 01
```

---

## Master 01 Is NotReady

Before installing Calico, this can be expected.

Check:

```bash
kubectl describe node master-01
```

Look at:

```text
Conditions
```

and:

```text
NetworkUnavailable
```

The CNI installation in Part 07 will provide the Pod network.

---

# 133. Important Architecture Principle

The control-plane endpoint and the individual control-plane addresses are different.

```text
                    Stable API Endpoint
                         :6443
                            │
                         HAProxy
                            │
            ┌───────────────┼───────────────┐
            │               │               │
            ▼               ▼               ▼
         Master 01       Master 02       Master 03
          :6443            :6443            :6443
```

The stable endpoint is used by clients and cluster configuration.

Each control-plane node retains its own address for:

* kube-apiserver
* etcd
* node communication
* control-plane membership

---

# 134. Initial Cluster State

After Part 04, the cluster consists of:

```text
Control Plane:
    Master 01
        ├── kube-apiserver
        ├── kube-controller-manager
        ├── kube-scheduler
        ├── etcd
        └── kubelet

Workers:
    Worker 01   → not joined yet
    Worker 02   → not joined yet
    Worker 03   → not joined yet

Additional Control Planes:
    Master 02   → not joined yet
    Master 03   → not joined yet

External:
    HAProxy
    Admin Client
```

---

# 135. Part 04 Validation Checklist

Before proceeding, verify:

```text
Control Plane
[ ] Master 01 initialized successfully
[ ] Kubernetes version is v1.34.11
[ ] kubelet is running
[ ] containerd is running
[ ] kube-apiserver is Running
[ ] kube-controller-manager is Running
[ ] kube-scheduler is Running
[ ] etcd is Running
[ ] Master 01 is registered as control-plane

API Endpoint
[ ] controlPlaneEndpoint uses HAProxy
[ ] HAProxy :6443 is reachable
[ ] HAProxy → Master 01 :6443 works
[ ] kubectl can access the cluster through HAProxy
[ ] /version API responds successfully

Configuration
[ ] kubeconfig configured
[ ] /etc/kubernetes/pki exists
[ ] admin.conf protected
[ ] join credentials protected
[ ] no credentials committed to Git

Networking
[ ] Pod CIDR selected
[ ] Service CIDR selected
[ ] CIDRs do not overlap with infrastructure networks
[ ] CNI installation is pending

etcD
[ ] First etcd member exists
[ ] etcd ports are available
[ ] etcd is healthy
```

---

# 136. Expected Architecture After Part 04

```text
                         ┌──────────────────┐
                         │   Admin Client   │
                         │                  │
                         │     kubectl      │
                         └────────┬─────────┘
                                  │
                                  │ :6443
                                  ▼
                         ┌──────────────────┐
                         │     HAProxy      │
                         │  API Load Balancer│
                         └────────┬─────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │    Master 01     │
                         │                  │
                         │ kube-apiserver   │
                         │ controller-mgr   │
                         │ scheduler        │
                         │ etcd             │
                         │ kubelet          │
                         └──────────────────┘
```

Only one control-plane node exists at this stage.

The cluster is **not yet highly available** because Master 02 and Master 03 have not joined.

---

# 137. Next Part

## Part 05 — Add Additional Control-Plane Nodes

Part 05 will add:

```text
Master 02
Master 03
```

to the existing cluster.

The architecture will become:

```text
                         HAProxy
                            │
              ┌─────────────┼─────────────┐
              │             │             │
              ▼             ▼             ▼
          Master 01     Master 02     Master 03
              │             │             │
             etcd          etcd          etcd
              └─────────────┼─────────────┘
                            │
                     3-member etcd
                        cluster
```

This establishes the three-control-plane architecture required for the highly available Kubernetes cluster.

# Part 05 — Add Additional Control-Plane Nodes

## 138. Objective

The objective of Part 05 is to add the remaining two control-plane nodes to the Kubernetes cluster:

```text
Master 01
Master 02
Master 03
```

Master 01 was initialized in Part 04.

In this phase:

```text
Master 02 → joins as control-plane + etcd member
Master 03 → joins as control-plane + etcd member
```

The resulting architecture will contain:

* 3 Kubernetes control-plane nodes
* 3 etcd members
* HAProxy in front of the API servers
* A stable Kubernetes API endpoint

---

# 139. Architecture Before Part 05

At the beginning of this phase:

```text
                         HAProxy
                            │
                            │ :6443
                            ▼
                       Master 01
                            │
                         etcd-01
```

Master 02 and Master 03 are prepared machines but are not yet members of the cluster.

---

# 140. Target Architecture

After this phase:

```text
                              Admin Client
                                   │
                                   │ :6443
                                   ▼
                              ┌─────────┐
                              │ HAProxy │
                              └────┬────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                    ▼              ▼              ▼
               Master 01      Master 02      Master 03
                    │              │              │
                  etcd           etcd           etcd
                    │              │              │
                    └──────────────┼──────────────┘
                                   │
                           3-member etcd
                              cluster
```

All three control-plane nodes participate in the Kubernetes control plane.

---

# 141. Prerequisites

Before joining Master 02 and Master 03, verify that Part 04 was completed successfully.

On Master 01:

```bash
kubectl get nodes
```

At this stage, Master 01 should be registered as:

```text
master-01   control-plane
```

The node may still be `NotReady` until the CNI is installed.

This is not necessarily a problem at this stage.

Verify the control-plane Pods:

```bash
kubectl get pods -n kube-system -o wide
```

Verify etcd:

```bash
kubectl get pods -n kube-system -l component=etcd -o wide
```

---

# 142. Verify Master 02 and Master 03 Preparation

On Master 02:

```bash
hostnamectl
```

Expected hostname:

```text
master-02
```

On Master 03:

```bash
hostnamectl
```

Expected:

```text
master-03
```

Verify Kubernetes version on both:

```bash
kubeadm version
kubelet --version
kubectl version --client
```

The target Kubernetes version is:

```text
v1.34.11
```

---

# 143. Verify Container Runtime

On Master 02:

```bash
sudo systemctl status containerd
```

On Master 03:

```bash
sudo systemctl status containerd
```

Expected:

```text
Active: active (running)
```

Also verify:

```bash
sudo crictl info
```

if `crictl` is configured.

---

# 144. Verify Swap

On both nodes:

```bash
swapon --show
```

No active swap should be shown.

Also verify:

```bash
free -h
```

---

# 145. Verify Kernel and Network Configuration

On both control-plane nodes:

```bash
lsmod | grep overlay
lsmod | grep br_netfilter
```

Check:

```bash
sysctl net.ipv4.ip_forward
```

Expected:

```text
net.ipv4.ip_forward = 1
```

Check bridge filtering:

```bash
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
```

The values should be configured according to the Kubernetes node preparation in Part 02.

---

# 146. Verify Connectivity to HAProxy

From Master 02:

```bash
nc -vz <HAProxy-ENDPOINT> 6443
```

From Master 03:

```bash
nc -vz <HAProxy-ENDPOINT> 6443
```

The HAProxy API endpoint must be reachable.

---

# 147. Verify Connectivity Between Control-Plane Nodes

The control-plane nodes must be able to communicate with each other.

Test Master 01 from Master 02:

```bash
nc -vz <MASTER-01-IP> 6443
```

Test etcd client and peer ports as appropriate:

```bash
nc -vz <MASTER-01-IP> 2379
nc -vz <MASTER-01-IP> 2380
```

Repeat the relevant checks between all control-plane nodes.

The required network paths are:

```text
Master 01 ↔ Master 02
Master 01 ↔ Master 03
Master 02 ↔ Master 03
```

---

# 148. Important etcd Ports

The three control-plane nodes will form an etcd cluster.

etcd uses:

| Port | Purpose              |
| ---- | -------------------- |
| 2379 | Client communication |
| 2380 | Peer communication   |

The etcd peer port is especially important because the three etcd members need to communicate with one another.

Do not expose these ports through the external HAProxy Kubernetes API listener.

---

# 149. Obtain the Control-Plane Join Command

The control-plane join command generated during Part 04 contains sensitive temporary credentials.

The general structure is:

```bash
kubeadm join <HAProxy-ENDPOINT>:6443 \
    --token <TOKEN> \
    --discovery-token-ca-cert-hash sha256:<HASH> \
    --control-plane \
    --certificate-key <CERTIFICATE-KEY>
```

Use the actual command generated by kubeadm.

Do not manually invent the token, hash, or certificate key.

---

# 150. Generate a New Join Token if Required

If the original join command has expired, generate a new one on Master 01.

Run:

```bash
sudo kubeadm token create --print-join-command
```

This generates the discovery portion of the join command.

The token has a limited lifetime by default.

For additional control-plane nodes, the certificate key must also be available.

Generate/upload control-plane certificates:

```bash
sudo kubeadm init phase upload-certs --upload-certs
```

The command returns a certificate key.

Use that key with the control-plane join command.

---

# 151. Join Master 02

Log in to Master 02.

Run the control-plane join command generated by kubeadm.

Example structure:

```bash
sudo kubeadm join <HAProxy-ENDPOINT>:6443 \
    --token <TOKEN> \
    --discovery-token-ca-cert-hash sha256:<HASH> \
    --control-plane \
    --certificate-key <CERTIFICATE-KEY>
```

The actual command should use the values generated for this cluster.

---

# 152. What Happens During Control-Plane Join

When Master 02 joins, kubeadm performs several operations.

Conceptually:

```text
Master 02
   │
   ├── Contacts HAProxy
   │
   ├── Discovers cluster CA
   │
   ├── Downloads required configuration
   │
   ├── Installs control-plane certificates
   │
   ├── Creates static Pod manifests
   │
   ├── Starts kube-apiserver
   │
   ├── Starts kube-controller-manager
   │
   ├── Starts kube-scheduler
   │
   └── Adds Master 02 to etcd
```

---

# 153. Verify Master 02 Locally

On Master 02:

```bash
sudo systemctl status kubelet
```

Check containers:

```bash
sudo crictl ps
```

Check Kubernetes manifests:

```bash
sudo ls -l /etc/kubernetes/manifests/
```

Expected control-plane manifests include:

```text
etcd.yaml
kube-apiserver.yaml
kube-controller-manager.yaml
kube-scheduler.yaml
```

---

# 154. Verify Master 02 From Master 01

On Master 01:

```bash
kubectl get nodes -o wide
```

Master 02 should now appear.

Conceptually:

```text
NAME        STATUS     ROLES           VERSION
master-01   ...        control-plane   v1.34.11
master-02   ...        control-plane   v1.34.11
```

The exact `STATUS` depends on whether the CNI has been installed.

---

# 155. Verify Master 02 Control-Plane Pods

Run:

```bash
kubectl get pods -n kube-system -o wide
```

Look for Master 02 components:

```text
etcd-master-02
kube-apiserver-master-02
kube-controller-manager-master-02
kube-scheduler-master-02
```

They should eventually become:

```text
Running
```

---

# 156. Verify Master 02 etcd Membership

Check etcd Pods:

```bash
kubectl get pods -n kube-system -l component=etcd -o wide
```

Expected:

```text
etcd-master-01
etcd-master-02
```

At this point the etcd cluster should contain two members.

Conceptually:

```text
             etcd cluster
                  │
          ┌───────┴───────┐
          │               │
       etcd-01          etcd-02
      Master 01        Master 02
```

---

# 157. Join Master 03

Log in to Master 03.

Use the control-plane join command:

```bash
sudo kubeadm join <HAProxy-ENDPOINT>:6443 \
    --token <TOKEN> \
    --discovery-token-ca-cert-hash sha256:<HASH> \
    --control-plane \
    --certificate-key <CERTIFICATE-KEY>
```

Use the actual values generated by kubeadm.

---

# 158. Verify Master 03

On Master 01:

```bash
kubectl get nodes -o wide
```

Expected:

```text
master-01   ...   control-plane   v1.34.11
master-02   ...   control-plane   v1.34.11
master-03   ...   control-plane   v1.34.11
```

Again, the nodes may not become `Ready` until the CNI is installed.

---

# 159. Verify All Control-Plane Pods

Run:

```bash
kubectl get pods -n kube-system -o wide
```

You should see control-plane components associated with all three masters.

Expected conceptual layout:

```text
Master 01:
    kube-apiserver
    kube-controller-manager
    kube-scheduler
    etcd

Master 02:
    kube-apiserver
    kube-controller-manager
    kube-scheduler
    etcd

Master 03:
    kube-apiserver
    kube-controller-manager
    kube-scheduler
    etcd
```

---

# 160. Verify Three-Member etcd Cluster

Run:

```bash
kubectl get pods -n kube-system -l component=etcd -o wide
```

Expected:

```text
etcd-master-01
etcd-master-02
etcd-master-03
```

The three members should be distributed across the three control-plane nodes.

This is important for the later etcd backup architecture.

---

# 161. Verify etcd Peer Connectivity

The etcd members need connectivity over TCP 2380.

From each control-plane node, test the other members:

```bash
nc -vz <MASTER-01-IP> 2380
nc -vz <MASTER-02-IP> 2380
nc -vz <MASTER-03-IP> 2380
```

Only test the addresses of the other nodes where appropriate.

The goal is:

```text
Master 01 ↔ Master 02
Master 01 ↔ Master 03
Master 02 ↔ Master 03
```

over the etcd peer network.

---

# 162. Verify etcd Client Connectivity

The etcd client port is 2379.

Check:

```bash
sudo ss -lntp | grep 2379
```

and:

```bash
sudo ss -lntp | grep 2380
```

The exact listening addresses depend on kubeadm's generated etcd configuration.

---

# 163. Verify API Server Through HAProxy

The three API servers should now be behind HAProxy.

From the Admin Client:

```bash
kubectl get nodes
```

The kubeconfig should point to:

```text
https://<HAProxy-ENDPOINT>:6443
```

Verify:

```bash
kubectl config view --minify
```

The server should reference the stable HAProxy endpoint.

---

# 164. Verify HAProxy Backend Servers

On the HAProxy machine, verify connectivity to all three API servers:

```bash
nc -vz <MASTER-01-IP> 6443
nc -vz <MASTER-02-IP> 6443
nc -vz <MASTER-03-IP> 6443
```

All three should be reachable once their API servers are running.

Check HAProxy logs:

```bash
sudo journalctl -u haproxy -n 100 --no-pager
```

The backend should no longer report:

```text
backend kubernetes-masters has no server available
```

---

# 165. Verify API Availability

From the Admin Client:

```bash
curl -k https://<HAProxy-ENDPOINT>:6443/version
```

Then:

```bash
kubectl cluster-info
```

Then:

```bash
kubectl get --raw='/version'
```

All requests should reach the Kubernetes API through the HAProxy endpoint.

---

# 166. Verify Control-Plane Node Conditions

Run:

```bash
kubectl get nodes
```

For detailed information:

```bash
kubectl describe node master-01
kubectl describe node master-02
kubectl describe node master-03
```

Review:

* Conditions
* Taints
* Addresses
* Capacity
* Allocatable resources
* Kubernetes version
* Container runtime

---

# 167. Control-Plane Taints

Control-plane nodes normally have a taint similar to:

```text
node-role.kubernetes.io/control-plane:NoSchedule
```

Check:

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

The purpose is to prevent ordinary workloads from being scheduled onto control-plane nodes.

Do not remove the taint unless required by the cluster design.

---

# 168. Verify Cluster Component Health

Check:

```bash
kubectl get pods -n kube-system -o wide
```

Check cluster resources:

```bash
kubectl get --raw='/readyz?verbose'
```

A healthy API server should report successful readiness checks.

This is preferable to relying only on older `componentstatuses` output.

---

# 169. Verify kubelet on All Masters

On Master 01:

```bash
sudo systemctl status kubelet
```

On Master 02:

```bash
sudo systemctl status kubelet
```

On Master 03:

```bash
sudo systemctl status kubelet
```

All should be active.

---

# 170. Verify containerd on All Masters

On each control-plane node:

```bash
sudo systemctl status containerd
```

Then:

```bash
sudo crictl ps
```

Control-plane containers should be visible.

---

# 171. Check Recent Cluster Events

From Master 01 or the Admin Client:

```bash
kubectl get events -A --sort-by='.lastTimestamp'
```

Pay particular attention to:

* FailedMount
* FailedScheduling
* NetworkUnavailable
* Unhealthy
* FailedCreatePodSandBox
* NodeNotReady

Some networking-related events are expected before the CNI is installed.

---

# 172. Check Control-Plane Logs

For Master 02:

```bash
kubectl logs -n kube-system kube-apiserver-master-02
```

For Master 03:

```bash
kubectl logs -n kube-system kube-apiserver-master-03
```

Similarly:

```bash
kubectl logs -n kube-system kube-controller-manager-master-02
kubectl logs -n kube-system kube-scheduler-master-02
```

Use the actual Pod names returned by:

```bash
kubectl get pods -n kube-system
```

---

# 173. etcd Architecture

After both nodes join, the etcd architecture is:

```text
                       Kubernetes Control Plane
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
              ▼                 ▼                 ▼
         Master 01         Master 02         Master 03
              │                 │                 │
              ▼                 ▼                 ▼
           etcd-01            etcd-02            etcd-03
              │                 │                 │
              └─────────────────┼─────────────────┘
                                │
                         etcd cluster
                         3 members
```

The etcd data is replicated between the members.

---

# 174. etcd Quorum

A three-member etcd cluster can tolerate the loss of one member while retaining quorum.

For three members:

```text
Total members = 3
Quorum = 2
```

Therefore:

```text
3 healthy → quorum
2 healthy → quorum
1 healthy → no quorum
```

This is one of the reasons an odd number of etcd members is commonly used.

---

# 175. Important Backup Architecture Implication

The cluster now has three etcd members.

The later backup system should **not** permanently assume:

```text
Master 01 = etcd leader
```

The etcd leader can change.

The backup design in later parts will therefore determine the current etcd leader dynamically and perform the snapshot against the appropriate healthy etcd member.

The architecture will eventually be:

```text
              Kubernetes Cluster
                     │
                CronJob
                     │
             Leader Detection
                     │
          ┌──────────┼──────────┐
          │          │          │
       etcd-01    etcd-02    etcd-03
          │          │          │
          └──────────┼──────────┘
                     │
              etcd Snapshot
                     │
                     ▼
               OpenEBS PVC
```

The backup implementation itself will be covered in later parts.

---

# 176. Failure Scenario

With three control-plane nodes:

```text
Master 01   UP
Master 02   UP
Master 03   UP
```

If Master 01 becomes unavailable:

```text
Master 01   DOWN
Master 02   UP
Master 03   UP
```

the etcd cluster still has two members and can maintain quorum, assuming the remaining members are healthy.

HAProxy can also stop sending API traffic to an unavailable API server if its health check marks that backend unavailable.

This provides independent resilience at the API and etcd layers.

---

# 177. HAProxy and etcd Are Separate

An important architectural distinction is:

```text
HAProxy
    │
    └── Load balances Kubernetes API :6443
```

while:

```text
etcd
    │
    ├── Client :2379
    └── Peer   :2380
```

HAProxy is **not** the etcd load balancer.

Do not configure the Kubernetes API HAProxy frontend to proxy etcd traffic.

---

# 178. Troubleshooting — Control-Plane Join Failure

If:

```bash
kubeadm join ...
```

fails, first inspect the exact error.

Check kubelet:

```bash
sudo journalctl -u kubelet -n 200 --no-pager
```

Check containerd:

```bash
sudo journalctl -u containerd -n 200 --no-pager
```

Check containers:

```bash
sudo crictl ps -a
```

Check:

```bash
sudo ss -lntp
```

for port conflicts.

---

# 179. Troubleshooting — Certificate Key Failure

If kubeadm reports a problem with the certificate key, generate/upload certificates again from an existing control-plane node:

```bash
sudo kubeadm init phase upload-certs --upload-certs
```

Use the newly generated certificate key with the control-plane join command.

Do not store the certificate key in Git.

---

# 180. Troubleshooting — Token Expired

Generate a new token:

```bash
sudo kubeadm token create --print-join-command
```

Then use the new token in the control-plane join command.

---

# 181. Troubleshooting — etcd Member Problems

Check:

```bash
kubectl get pods -n kube-system -l component=etcd -o wide
```

Check etcd logs:

```bash
kubectl logs -n kube-system <etcd-pod-name>
```

Check peer connectivity:

```bash
nc -vz <peer-ip> 2380
```

Check client connectivity:

```bash
nc -vz <peer-ip> 2379
```

Also verify:

```bash
ip route
```

and:

```bash
tailscale status
```

if Tailscale is being used for the node network.

---

# 182. Troubleshooting — HAProxy Shows Backend Down

From the HAProxy server:

```bash
nc -vz <MASTER-01-IP> 6443
nc -vz <MASTER-02-IP> 6443
nc -vz <MASTER-03-IP> 6443
```

If a connection fails, investigate that control-plane node rather than changing HAProxy immediately.

Check the API server:

```bash
kubectl get pods -n kube-system -o wide
```

Check kubelet:

```bash
sudo systemctl status kubelet
```

Check the API server's runtime container:

```bash
sudo crictl ps -a
```

---

# 183. Troubleshooting — Node NotReady

Run:

```bash
kubectl describe node <node-name>
```

Check:

```text
Conditions
```

Before Calico is installed, network-related `NotReady` status can be expected.

After Calico is installed, all nodes should be revalidated.

---

# 184. Security Considerations

Protect the following:

```text
/etc/kubernetes/admin.conf
/etc/kubernetes/pki/
/etc/kubernetes/*.conf
```

Do not commit these files to the repository.

Do not commit:

```text
kubeadm join commands
bootstrap tokens
certificate keys
private CA keys
etcd TLS private keys
```

The control-plane certificate key is especially sensitive because it can be used during control-plane joining.

---

# 185. Control-Plane Validation Checklist

Before proceeding to Part 06:

```text
Master Nodes
[ ] Master 01 initialized
[ ] Master 02 joined as control-plane
[ ] Master 03 joined as control-plane
[ ] All three use Kubernetes v1.34.11
[ ] kubelet running on all masters
[ ] containerd running on all masters

Control Plane
[ ] kube-apiserver running on Master 01
[ ] kube-apiserver running on Master 02
[ ] kube-apiserver running on Master 03
[ ] controller-manager running on all masters
[ ] scheduler running on all masters

etcd
[ ] etcd member on Master 01
[ ] etcd member on Master 02
[ ] etcd member on Master 03
[ ] etcd peer connectivity verified
[ ] etcd client connectivity verified
[ ] Three-member etcd cluster established

HAProxy
[ ] HAProxy reachable
[ ] Master 01 :6443 reachable
[ ] Master 02 :6443 reachable
[ ] Master 03 :6443 reachable
[ ] HAProxy backend recognizes available API servers
[ ] Admin Client reaches API through HAProxy

Security
[ ] Join token protected
[ ] Certificate key protected
[ ] admin.conf protected
[ ] Kubernetes PKI protected
[ ] No credentials committed to Git
```

---

# 186. Expected Final Architecture

```text
                              ┌─────────────────┐
                              │   Admin Client  │
                              │                 │
                              │     kubectl     │
                              └────────┬────────┘
                                       │
                                       │ :6443
                                       ▼
                              ┌─────────────────┐
                              │     HAProxy     │
                              │  API Load       │
                              │  Balancer       │
                              └────────┬────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
                    ▼                  ▼                  ▼
             ┌────────────┐     ┌────────────┐     ┌────────────┐
             │ Master 01  │     │ Master 02  │     │ Master 03  │
             │            │     │            │     │            │
             │ API Server │     │ API Server │     │ API Server │
             │ Scheduler  │     │ Scheduler  │     │ Scheduler  │
             │ Controller │     │ Controller │     │ Controller │
             │ etcd-01    │     │ etcd-02    │     │ etcd-03    │
             └──────┬─────┘     └──────┬─────┘     └──────┬─────┘
                    │                  │                  │
                    └──────────────────┼──────────────────┘
                                       │
                              3-member etcd
                                  cluster
```

At the end of Part 05, the Kubernetes control plane has three members and etcd has three members.

The worker nodes have **not yet been joined**.

---

# 187. Next Part

## Part 06 — Add Worker Nodes

The next phase will join:

```text
Worker 01
Worker 02
Worker 03
```

to the Kubernetes cluster.

The architecture will become:

```text
                              HAProxy
                                 │
                  ┌──────────────┼──────────────┐
                  │              │              │
                  ▼              ▼              ▼
              Master 01      Master 02      Master 03
                  │              │              │
                 etcd           etcd           etcd
                  │              │              │
                  └──────────────┼──────────────┘
                                 │
                         Kubernetes Control Plane
                                 │
                  ┌──────────────┼──────────────┐
                  │              │              │
                  ▼              ▼              ▼
              Worker 01      Worker 02      Worker 03
```

Part 06 will cover worker-node joining, kubelet validation, node registration, scheduling behavior, and verification of the six-node Kubernetes cluster.

# Part 06 — Add Worker Nodes

## 188. Objective

The objective of Part 06 is to join the three worker nodes to the Kubernetes cluster:

```text
Worker 01
Worker 02
Worker 03
```

The three control-plane nodes were configured in Part 05:

```text
Master 01
Master 02
Master 03
```

After this phase, the cluster will contain:

```text
3 Control-Plane Nodes
3 Worker Nodes
```

The target architecture is:

```text
                         ┌─────────────────┐
                         │   Admin Client  │
                         └────────┬────────┘
                                  │
                                  │ :6443
                                  ▼
                         ┌─────────────────┐
                         │     HAProxy     │
                         └────────┬────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
              ▼                   ▼                   ▼
         Master 01           Master 02           Master 03
              │                   │                   │
             etcd                etcd                etcd
              └───────────────────┼───────────────────┘
                                  │
                         Kubernetes Control Plane
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
              ▼                   ▼                   ▼
         Worker 01           Worker 02           Worker 03
```

---

# 189. Cluster State Before Part 06

Before joining the workers, verify the control-plane nodes:

```bash
kubectl get nodes -o wide
```

Expected conceptually:

```text
NAME        STATUS   ROLES           VERSION
master-01   ...      control-plane   v1.34.11
master-02   ...      control-plane   v1.34.11
master-03   ...      control-plane   v1.34.11
```

The workers should not yet appear as cluster members.

---

# 190. Worker Node Prerequisites

The following preparation should already have been completed on all three worker nodes during Part 02:

```text
Worker 01
Worker 02
Worker 03
```

Each worker should have:

* Supported Linux OS
* Kubernetes v1.34.11 packages
* containerd
* kubeadm
* kubelet
* Required kernel modules
* Required sysctl settings
* Swap disabled
* Network connectivity
* Tailscale connectivity if used by the cluster

---

# 191. Verify Worker 01

Log in to Worker 01:

```bash
hostnamectl
```

Expected:

```text
worker-01
```

Verify Kubernetes tools:

```bash
kubeadm version
kubelet --version
kubectl version --client
```

The target Kubernetes version is:

```text
v1.34.11
```

Verify containerd:

```bash
sudo systemctl status containerd
```

Expected:

```text
Active: active (running)
```

---

# 192. Verify Worker 02

On Worker 02:

```bash
hostnamectl
```

Expected:

```text
worker-02
```

Verify:

```bash
kubeadm version
kubelet --version
kubectl version --client
```

Verify containerd:

```bash
sudo systemctl status containerd
```

---

# 193. Verify Worker 03

On Worker 03:

```bash
hostnamectl
```

Expected:

```text
worker-03
```

Verify:

```bash
kubeadm version
kubelet --version
kubectl version --client
```

Verify containerd:

```bash
sudo systemctl status containerd
```

---

# 194. Verify Swap on Workers

Run on all workers:

```bash
swapon --show
```

The command should return no active swap devices.

Also check:

```bash
free -h
```

If swap is enabled:

```bash
sudo swapoff -a
```

Then ensure the swap entry is disabled in:

```text
/etc/fstab
```

---

# 195. Verify Kernel Modules

On each worker:

```bash
lsmod | grep overlay
lsmod | grep br_netfilter
```

If required:

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

---

# 196. Verify IP Forwarding

Run:

```bash
sysctl net.ipv4.ip_forward
```

Expected:

```text
net.ipv4.ip_forward = 1
```

Also verify:

```bash
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
```

The values should match the configuration established in Part 02.

---

# 197. Verify containerd Configuration

Check:

```bash
sudo systemctl status containerd
```

Verify the cgroup configuration:

```bash
grep -n "SystemdCgroup" /etc/containerd/config.toml
```

Expected:

```text
SystemdCgroup = true
```

If the configuration was changed, restart containerd:

```bash
sudo systemctl restart containerd
```

Then verify:

```bash
sudo systemctl status containerd
```

---

# 198. Verify Worker Connectivity

The worker nodes must reach the Kubernetes API endpoint.

From Worker 01:

```bash
nc -vz <HAProxy-ENDPOINT> 6443
```

From Worker 02:

```bash
nc -vz <HAProxy-ENDPOINT> 6443
```

From Worker 03:

```bash
nc -vz <HAProxy-ENDPOINT> 6443
```

The connection should succeed.

The workers do not need to connect directly to an individual API server when the cluster's control-plane endpoint is configured through HAProxy.

---

# 199. Verify Network Connectivity

Check routing:

```bash
ip route
```

Check the Tailscale network if applicable:

```bash
tailscale status
tailscale ip -4
```

Test the HAProxy endpoint:

```bash
ping <HAProxy-IP>
```

Then:

```bash
nc -vz <HAProxy-ENDPOINT> 6443
```

---

# 200. Generate Worker Join Command

The worker join command can be generated from an existing control-plane node.

On Master 01:

```bash
sudo kubeadm token create --print-join-command
```

This produces a command similar to:

```bash
kubeadm join <HAProxy-ENDPOINT>:6443 \
    --token <TOKEN> \
    --discovery-token-ca-cert-hash sha256:<HASH>
```

Use the actual values generated by kubeadm.

Do not manually construct the discovery hash.

---

# 201. Join Worker 01

Log in to Worker 01.

Run the worker join command:

```bash
sudo kubeadm join <HAProxy-ENDPOINT>:6443 \
    --token <TOKEN> \
    --discovery-token-ca-cert-hash sha256:<HASH>
```

Unlike a control-plane join, the worker command does **not** include:

```text
--control-plane
```

and does not require the control-plane certificate key.

---

# 202. What Happens During Worker Join

The worker performs several operations:

```text
Worker 01
    │
    ├── Contacts HAProxy
    │
    ├── Discovers Kubernetes cluster CA
    │
    ├── Performs kubeadm preflight checks
    │
    ├── Creates kubelet configuration
    │
    ├── Creates kube-proxy configuration
    │
    ├── Registers the node
    │
    └── Starts kubelet
```

The worker then becomes a Kubernetes node.

---

# 203. Verify Worker 01

From Master 01 or the Admin Client:

```bash
kubectl get nodes -o wide
```

Expected:

```text
NAME        STATUS   ROLES           VERSION
master-01   ...      control-plane   v1.34.11
master-02   ...      control-plane   v1.34.11
master-03   ...      control-plane   v1.34.11
worker-01   ...      <none>          v1.34.11
```

The worker may initially show:

```text
NotReady
```

before the CNI is installed.

---

# 204. Verify Worker 01 kubelet

On Worker 01:

```bash
sudo systemctl status kubelet
```

Expected:

```text
Active: active (running)
```

Check logs:

```bash
sudo journalctl -u kubelet -n 100 --no-pager
```

Follow logs if necessary:

```bash
sudo journalctl -u kubelet -f
```

---

# 205. Verify Worker 01 Runtime

Run:

```bash
sudo crictl info
```

Then:

```bash
sudo crictl ps
```

The container runtime should be operational.

---

# 206. Join Worker 02

Log in to Worker 02.

Run the same generated worker join command:

```bash
sudo kubeadm join <HAProxy-ENDPOINT>:6443 \
    --token <TOKEN> \
    --discovery-token-ca-cert-hash sha256:<HASH>
```

If the token has expired, generate a new one on Master 01:

```bash
sudo kubeadm token create --print-join-command
```

---

# 207. Verify Worker 02

From the Admin Client or Master 01:

```bash
kubectl get nodes -o wide
```

Worker 02 should appear:

```text
worker-02   ...   <none>   v1.34.11
```

On Worker 02:

```bash
sudo systemctl status kubelet
```

---

# 208. Join Worker 03

Log in to Worker 03.

Run:

```bash
sudo kubeadm join <HAProxy-ENDPOINT>:6443 \
    --token <TOKEN> \
    --discovery-token-ca-cert-hash sha256:<HASH>
```

Verify from the Admin Client:

```bash
kubectl get nodes -o wide
```

Worker 03 should appear.

---

# 209. Verify All Six Nodes

Run:

```bash
kubectl get nodes -o wide
```

Expected cluster membership:

```text
NAME        STATUS   ROLES           VERSION
master-01   ...      control-plane   v1.34.11
master-02   ...      control-plane   v1.34.11
master-03   ...      control-plane   v1.34.11
worker-01   ...      <none>          v1.34.11
worker-02   ...      <none>          v1.34.11
worker-03   ...      <none>          v1.34.11
```

The exact IP addresses and status depend on the environment.

---

# 210. Verify Node Roles

Run:

```bash
kubectl get nodes
```

The expected roles are:

```text
Master 01 → control-plane
Master 02 → control-plane
Master 03 → control-plane

Worker 01 → worker workload node
Worker 02 → worker workload node
Worker 03 → worker workload node
```

Kubernetes may display worker nodes with `<none>` under the `ROLES` column unless an explicit worker role label is applied.

This does not prevent them from functioning as worker nodes.

---

# 211. Optional Worker Role Labels

If the project documentation requires explicit worker roles, labels can be applied:

```bash
kubectl label node worker-01 node-role.kubernetes.io/worker=
kubectl label node worker-02 node-role.kubernetes.io/worker=
kubectl label node worker-03 node-role.kubernetes.io/worker=
```

Verify:

```bash
kubectl get nodes
```

They may then appear as:

```text
worker
```

under `ROLES`.

Labels are optional and are not required for normal worker-node operation.

---

# 212. Verify Node Details

For Worker 01:

```bash
kubectl describe node worker-01
```

For Worker 02:

```bash
kubectl describe node worker-02
```

For Worker 03:

```bash
kubectl describe node worker-03
```

Review:

* Node conditions
* Addresses
* Capacity
* Allocatable resources
* Container runtime
* Kubelet version
* Taints
* Labels

---

# 213. Verify Worker Kubelet Services

On each worker:

```bash
sudo systemctl is-enabled kubelet
```

Expected:

```text
enabled
```

Check:

```bash
sudo systemctl is-active kubelet
```

Expected:

```text
active
```

---

# 214. Verify Worker containerd Services

On each worker:

```bash
sudo systemctl is-enabled containerd
```

Expected:

```text
enabled
```

Check:

```bash
sudo systemctl is-active containerd
```

Expected:

```text
active
```

---

# 215. Verify Kubernetes System Pods

Run:

```bash
kubectl get pods -n kube-system -o wide
```

At this stage, system components should begin appearing on worker nodes.

For example:

```text
kube-proxy-...
```

may run on each node.

The CNI components will be installed in Part 07.

---

# 216. Verify kube-proxy

Run:

```bash
kubectl get daemonset -n kube-system
```

The kube-proxy DaemonSet should have a Pod scheduled on each applicable node.

Check:

```bash
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide
```

There should be kube-proxy Pods across the nodes.

---

# 217. Verify Node Conditions

Run:

```bash
kubectl get nodes
```

For detailed status:

```bash
kubectl describe node worker-01 | sed -n '/Conditions:/,/Addresses:/p'
```

Repeat for Worker 02 and Worker 03.

Before CNI installation, networking-related conditions can prevent a node from reaching `Ready`.

---

# 218. Why Workers May Be NotReady

A worker node can successfully join the cluster but still show:

```text
NotReady
```

This is commonly related to the Pod networking layer not yet being installed.

The cluster currently has:

```text
kubeadm
kubelet
containerd
kube-proxy
```

but the CNI has not yet been deployed.

Calico will be installed in Part 07.

Therefore, do not treat `NotReady` by itself as proof that the worker join failed.

---

# 219. Verify API Connectivity Through HAProxy

The worker nodes should communicate with the Kubernetes API using the configured control-plane endpoint.

From Worker 01:

```bash
curl -k https://<HAProxy-ENDPOINT>:6443/version
```

Repeat on Worker 02 and Worker 03.

The API should return Kubernetes version information.

---

# 220. Verify HAProxy Backend Connectivity

On the HAProxy server:

```bash
nc -vz <MASTER-01-IP> 6443
nc -vz <MASTER-02-IP> 6443
nc -vz <MASTER-03-IP> 6443
```

All three control-plane API servers should be reachable.

The worker nodes should not be configured as HAProxy API backends.

The backend remains:

```text
Master 01 :6443
Master 02 :6443
Master 03 :6443
```

---

# 221. Verify Six-Node Architecture

The cluster now has:

```text
Control Plane:
    Master 01
    Master 02
    Master 03

Workers:
    Worker 01
    Worker 02
    Worker 03
```

External infrastructure:

```text
HAProxy
Admin Client
```

Therefore, the complete infrastructure contains:

```text
3 Masters
3 Workers
1 HAProxy
1 Admin Client
```

Total:

```text
8 machines
```

---

# 222. Test Workload Scheduling

After the CNI is installed and the worker nodes become `Ready`, a test workload can be created.

Example:

```bash
kubectl create deployment nginx \
  --image=nginx
```

Check:

```bash
kubectl get deployment
```

Then:

```bash
kubectl get pods -o wide
```

The Pod should be scheduled on an available worker node.

Clean up the test deployment afterward:

```bash
kubectl delete deployment nginx
```

If the CNI has not yet been installed, wait until Part 07 before using this test as a network validation.

---

# 223. Verify Scheduling Across Workers

Once the CNI is operational, deploy multiple replicas:

```bash
kubectl create deployment nginx \
  --image=nginx \
  --replicas=3
```

Check:

```bash
kubectl get pods -o wide
```

The scheduler may distribute Pods across the available workers according to scheduling decisions and constraints.

This confirms that the workers are available for workload scheduling.

Delete the test:

```bash
kubectl delete deployment nginx
```

---

# 224. Worker Resource Verification

Check cluster capacity:

```bash
kubectl top nodes
```

This command requires Metrics Server or another resource metrics provider.

Without a metrics provider, use:

```bash
kubectl describe node worker-01
kubectl describe node worker-02
kubectl describe node worker-03
```

Review:

```text
Capacity
Allocatable
```

---

# 225. Troubleshooting — Worker Join Failure

If `kubeadm join` fails:

```bash
sudo kubeadm join ...
```

review the exact error.

Check kubelet:

```bash
sudo journalctl -u kubelet -n 200 --no-pager
```

Check containerd:

```bash
sudo journalctl -u containerd -n 200 --no-pager
```

Check runtime:

```bash
sudo crictl info
```

Check network connectivity:

```bash
nc -vz <HAProxy-ENDPOINT> 6443
```

---

# 226. Troubleshooting — Token Expired

If kubeadm reports an expired token:

On Master 01:

```bash
sudo kubeadm token create --print-join-command
```

Use the newly generated command.

---

# 227. Troubleshooting — API Server Unreachable

Test:

```bash
nc -vz <HAProxy-ENDPOINT> 6443
```

If this fails, determine whether the issue is:

```text
Worker → HAProxy
```

or:

```text
HAProxy → Control Plane
```

On HAProxy:

```bash
sudo systemctl status haproxy
```

Then:

```bash
sudo journalctl -u haproxy -n 100 --no-pager
```

---

# 228. Troubleshooting — Worker NotReady

Run:

```bash
kubectl describe node worker-01
```

Check:

```text
Conditions
```

Look for:

```text
NetworkUnavailable
KubeletNotReady
```

Check kubelet:

```bash
sudo journalctl -u kubelet -n 200 --no-pager
```

Check containerd:

```bash
sudo systemctl status containerd
```

If the CNI is not installed yet, complete Part 07 before performing extensive network troubleshooting.

---

# 229. Troubleshooting — Container Runtime

Check:

```bash
sudo systemctl status containerd
```

Check:

```bash
sudo crictl info
```

Check containers:

```bash
sudo crictl ps -a
```

Check containerd logs:

```bash
sudo journalctl -u containerd -n 200 --no-pager
```

---

# 230. Troubleshooting — Node Does Not Appear

On the worker:

```bash
sudo systemctl status kubelet
```

Check:

```bash
sudo journalctl -u kubelet -n 200 --no-pager
```

On the Admin Client:

```bash
kubectl get nodes
```

Check whether the kubelet successfully registered with the API server.

---

# 231. Troubleshooting — Incorrect Node Name

Verify:

```bash
hostnamectl
```

If the hostname is incorrect, correct it before joining:

```bash
sudo hostnamectl set-hostname worker-01
```

Use the appropriate hostname for the node.

Then restart relevant services if required and verify:

```bash
hostnamectl
```

---

# 232. Troubleshooting — Stale kubeadm State

If a worker was previously joined to another cluster and must be rejoined, reset it carefully:

```bash
sudo kubeadm reset -f
```

Then clean up any environment-specific residual configuration if required.

After resetting, verify:

```bash
sudo systemctl restart kubelet
```

and:

```bash
sudo systemctl restart containerd
```

Only reset a node when it is safe to remove its existing cluster membership.

---

# 233. Security Considerations

The worker join command contains a bootstrap token.

Do not commit the complete command to Git.

Do not place it in:

```text
README.md
Git history
Public issue trackers
Screenshots
Public documentation
```

If a token is exposed, generate a new token.

Worker nodes should also not contain unnecessary administrative credentials such as:

```text
/etc/kubernetes/admin.conf
```

Workers only need the kubelet-related credentials and configuration required for their cluster role.

---

# 234. Network Architecture

The resulting network paths are:

```text
Admin Client
     │
     ▼
HAProxy :6443
     │
     ├──────────► Master 01 :6443
     ├──────────► Master 02 :6443
     └──────────► Master 03 :6443


Master 01 ◄────────► Master 02
     │                    │
     └────────► Master 03 ◄┘
          etcd :2379/:2380


Workers
   │
   └──────────────► HAProxy :6443
```

The CNI will provide Pod-to-Pod and Pod-to-Service networking in Part 07.

---

# 235. Six-Node Cluster Validation

Run:

```bash
kubectl get nodes -o wide
```

Verify that all six nodes are registered.

Run:

```bash
kubectl get nodes --show-labels
```

Review node labels.

Run:

```bash
kubectl get pods -A -o wide
```

Review Pod placement.

Run:

```bash
kubectl get events -A --sort-by='.lastTimestamp'
```

Review recent cluster events.

---

# 236. Validation Checklist

Before proceeding to Part 07:

```text
Workers
[ ] Worker 01 prepared
[ ] Worker 02 prepared
[ ] Worker 03 prepared
[ ] Kubernetes v1.34.11 installed
[ ] kubelet installed and enabled
[ ] containerd installed and enabled
[ ] swap disabled
[ ] kernel modules loaded
[ ] IP forwarding enabled

Connectivity
[ ] Worker 01 → HAProxy :6443
[ ] Worker 02 → HAProxy :6443
[ ] Worker 03 → HAProxy :6443
[ ] HAProxy → Master 01 :6443
[ ] HAProxy → Master 02 :6443
[ ] HAProxy → Master 03 :6443

Cluster
[ ] Worker 01 joined
[ ] Worker 02 joined
[ ] Worker 03 joined
[ ] Six nodes visible from kubectl
[ ] All workers use v1.34.11
[ ] kubelet running on all workers
[ ] containerd running on all workers
[ ] kube-proxy deployed

Networking
[ ] CNI not yet installed / installation pending
[ ] NotReady status understood if caused by missing CNI

Security
[ ] Worker join token protected
[ ] No admin.conf copied to workers unnecessarily
[ ] No credentials committed to Git
```

---

# 237. Expected Final State

At the end of Part 06:

```text
                         ┌─────────────────┐
                         │   Admin Client  │
                         └────────┬────────┘
                                  │
                                  │ :6443
                                  ▼
                         ┌─────────────────┐
                         │     HAProxy     │
                         └────────┬────────┘
                                  │
               ┌──────────────────┼──────────────────┐
               │                  │                  │
               ▼                  ▼                  ▼
          Master 01          Master 02          Master 03
               │                  │                  │
              etcd               etcd               etcd
               └──────────────────┼──────────────────┘
                                  │
                         Kubernetes Control Plane
                                  │
               ┌──────────────────┼──────────────────┐
               │                  │                  │
               ▼                  ▼                  ▼
          Worker 01          Worker 02          Worker 03
```

The infrastructure now contains the complete Kubernetes node topology:

```text
3 Control Plane
3 Worker
1 HAProxy
1 Admin Client
```

The next major component is the Kubernetes networking layer.

---

# 238. Next Part

## Part 07 — Install and Configure Calico CNI

Part 07 will cover:

```text
Calico installation
        ↓
CNI configuration
        ↓
Pod CIDR validation
        ↓
Calico node DaemonSet
        ↓
BGP / networking validation
        ↓
NodeReady validation
        ↓
Pod-to-Pod connectivity
        ↓
Pod-to-Service connectivity
        ↓
Cross-node networking
```

After Part 07, the six Kubernetes nodes should be able to participate in the cluster's Pod network and the worker nodes should transition to `Ready`.

# Part 07 — Install and Configure Calico CNI

## 239. Objective

The objective of Part 07 is to install and configure **Calico** as the Container Network Interface (CNI) for the Kubernetes cluster.

Before this phase, the cluster contains:

```text
3 Control-Plane Nodes
3 Worker Nodes
```

but the Pod networking layer has not yet been installed.

Calico will provide:

* Pod-to-Pod networking
* Cross-node Pod networking
* Network routing
* Network policy support
* Node networking integration
* Kubernetes Pod network connectivity

The target architecture is:

```text
                         Kubernetes Cluster
                                │
                         ┌──────┴──────┐
                         │    Calico   │
                         │     CNI     │
                         └──────┬──────┘
                                │
          ┌─────────────────────┼─────────────────────┐
          │                     │                     │
       Master 01             Master 02             Master 03
          │                     │                     │
          └─────────────────────┼─────────────────────┘
                                │
          ┌─────────────────────┼─────────────────────┐
          │                     │                     │
       Worker 01             Worker 02             Worker 03
```

---

# 240. Why Calico Is Required

Kubernetes does not provide the complete Pod networking implementation by itself.

A CNI plugin is required to provide networking for Pods.

Before Calico:

```text
Node
 │
 ├── kubelet
 ├── containerd
 └── Kubernetes components
```

After Calico:

```text
Node
 │
 ├── kubelet
 ├── containerd
 ├── kube-proxy
 └── Calico
       │
       ├── Pod networking
       ├── Routing
       └── Network policy
```

Calico is deployed across the Kubernetes nodes as Kubernetes workloads.

---

# 241. Important Network Planning

The Pod network CIDR configured during `kubeadm init` must match the network configuration used by Calico.

For example, if the cluster was initialized with:

```text
<POD-CIDR>
```

Calico must be configured consistently with that CIDR.

Do not choose a different Pod CIDR during this phase without a deliberate cluster networking redesign.

Also ensure that the Pod CIDR does not overlap with:

* Node IP ranges
* Tailscale IP ranges
* Service CIDR
* Other routed networks
* Corporate/intranet networks

---

# 242. Verify Existing Cluster State

From the Admin Client or Master 01:

```bash id="n9x3x7"
kubectl get nodes -o wide
```

Verify that all six nodes are registered:

```text id="n4a5t0"
master-01
master-02
master-03
worker-01
worker-02
worker-03
```

The nodes may still be:

```text id="kbbm8y"
NotReady
```

before Calico is installed.

---

# 243. Verify kube-system Namespace

Run:

```bash id="r7d7ah"
kubectl get pods -n kube-system -o wide
```

Before Calico installation, you should see the Kubernetes control-plane components and kube-proxy Pods.

Calico components will be added during this phase.

---

# 244. Install Calico

Calico can be installed using the deployment method selected for the project.

A manifest-based installation can be applied using:

```bash id="6v2i0e"
kubectl apply -f <CALICO-MANIFEST>
```

The manifest should correspond to the Calico version selected for the cluster and should be compatible with Kubernetes v1.34.11.

For a production or documented deployment, pin the Calico version rather than using an unversioned "latest" manifest.

---

# 245. Verify Calico Resources

After applying the Calico configuration:

```bash id="z8r84u"
kubectl get pods -n calico-system -o wide
```

Depending on the Calico installation method/version, components may instead appear in another namespace.

First identify Calico namespaces:

```bash id="0x0b1a"
kubectl get namespaces | grep -i calico
```

Then inspect the corresponding namespace.

---

# 246. Verify Calico DaemonSet

Calico's node networking component is normally deployed as a DaemonSet.

Check:

```bash id="b9y5w5"
kubectl get daemonsets -A | grep -i calico
```

A Calico node Pod should be scheduled on each Kubernetes node that requires Calico networking.

Conceptually:

```text id="t7j2eg"
Master 01 → Calico node
Master 02 → Calico node
Master 03 → Calico node
Worker 01 → Calico node
Worker 02 → Calico node
Worker 03 → Calico node
```

The exact DaemonSet name depends on the Calico installation method.

---

# 247. Verify Calico Pods

Run:

```bash id="x3r9am"
kubectl get pods -A -o wide | grep -i calico
```

Check:

* Pod status
* Ready state
* Node placement
* Restart count
* Pod IP

Healthy Calico Pods should eventually show:

```text
Running
```

with the expected number of containers ready.

---

# 248. Wait for Calico Rollout

If Calico is installed through a DaemonSet, check its rollout:

```bash id="1w8e7k"
kubectl rollout status daemonset/<CALICO-DAEMONSET> -n <CALICO-NAMESPACE>
```

Use the actual DaemonSet and namespace returned by:

```bash id="2wdd7m"
kubectl get daemonsets -A | grep -i calico
```

---

# 249. Verify Calico Node Count

Run:

```bash id="eq55yr"
kubectl get daemonset -A | grep -i calico
```

Verify that:

```text
DESIRED = CURRENT = READY
```

for the relevant Calico node DaemonSet once deployment has converged.

The exact numbers depend on the selected Calico deployment and node selectors.

---

# 250. Verify Nodes Become Ready

Run:

```bash id="5s3j6f"
kubectl get nodes -o wide
```

The expected final state is:

```text id="i1d3h8"
master-01   Ready
master-02   Ready
master-03   Ready
worker-01   Ready
worker-02   Ready
worker-03   Ready
```

The exact transition time depends on the environment.

---

# 251. Verify Node Conditions

For each node:

```bash id="v3w1gj"
kubectl describe node master-01
```

and:

```bash id="f9j4d2"
kubectl describe node worker-01
```

Review:

```text
Conditions
```

The networking-related conditions should no longer indicate that the node is unavailable because of the missing CNI.

---

# 252. Verify Pod CIDR

Check the Pod CIDR assigned to each node:

```bash id="7y9o0s"
kubectl get nodes -o custom-columns=NAME:.metadata.name,PODCIDR:.spec.podCIDR
```

Example output:

```text id="8n6g1q"
NAME        PODCIDR
master-01   <CIDR>
master-02   <CIDR>
master-03   <CIDR>
worker-01   <CIDR>
worker-02   <CIDR>
worker-03   <CIDR>
```

Each node should have an appropriate Pod CIDR.

---

# 253. Verify Node Internal IPs

Run:

```bash id="p7qj1z"
kubectl get nodes -o wide
```

Review:

```text
INTERNAL-IP
```

These should correspond to the node addresses used by the cluster networking architecture.

If Tailscale is used for inter-node connectivity, verify that the addresses used by Kubernetes and Calico are consistent with the intended network design.

---

# 254. Verify Calico Configuration

Inspect Calico-related resources:

```bash id="iqj6g3"
kubectl get ippools.crd.projectcalico.org
```

If the Calico CRDs are installed, inspect the IP pool:

```bash id="4d6b3q"
kubectl get ippools.crd.projectcalico.org -o yaml
```

Verify that the configured pool corresponds to the planned Pod network.

---

# 255. Verify Calico Nodes

If the Calico CRDs are available:

```bash id="7k0g4v"
kubectl get nodes.crd.projectcalico.org
```

This provides the Calico view of the Kubernetes nodes.

Inspect an individual Calico node:

```bash id="0y4jzv"
kubectl get node.crd.projectcalico.org <NODE-NAME> -o yaml
```

Use the actual Calico CRD resources installed by the selected Calico version.

---

# 256. Verify Calico Node Interfaces

On a Kubernetes node, inspect interfaces:

```bash id="v7v5e5"
ip addr
```

Look for interfaces associated with the Calico networking configuration.

Also inspect routes:

```bash id="l4yd2y"
ip route
```

Calico may install routes associated with the Pod CIDRs.

The exact interface and routing structure depends on the Calico networking mode.

---

# 257. Verify BGP Configuration

If the project uses Calico BGP networking, inspect BGP-related resources.

For example:

```bash id="r5q8qk"
kubectl get bgppeers.crd.projectcalico.org
```

and:

```bash id="0q1m4b"
kubectl get bgpconfigurations.crd.projectcalico.org
```

If no explicit BGP peers are configured, do not assume that BGP peering is being used.

Calico can operate using different dataplane and routing configurations.

Document the actual mode configured in the cluster.

---

# 258. Verify Calico Logs

Find Calico Pods:

```bash id="j0o2v3"
kubectl get pods -A -o wide | grep -i calico
```

Then inspect the relevant Pod:

```bash id="xjv7p2"
kubectl logs -n <CALICO-NAMESPACE> <CALICO-POD-NAME>
```

For a specific container:

```bash id="9m0kjo"
kubectl logs -n <CALICO-NAMESPACE> <CALICO-POD-NAME> -c <CONTAINER-NAME>
```

---

# 259. Check Calico Events

Run:

```bash id="n2c3f1"
kubectl get events -A --sort-by='.lastTimestamp' | grep -i calico
```

Look for:

```text
Failed
Warning
Unhealthy
FailedMount
FailedCreatePodSandBox
```

---

# 260. Verify CoreDNS

Once networking is working, verify CoreDNS:

```bash id="g6g6mj"
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

Expected:

```text
Running
```

Check:

```bash id="xm5v6v"
kubectl get svc -n kube-system kube-dns
```

The Service should have a ClusterIP from the configured Service CIDR.

---

# 261. DNS Test

Create a temporary Pod:

```bash id="t8i3j5"
kubectl run dns-test \
  --image=busybox:1.36 \
  --restart=Never \
  --command -- sleep 3600
```

Check:

```bash id="6w6m0p"
kubectl get pod dns-test -o wide
```

Once the Pod is running:

```bash id="1j0y8r"
kubectl exec dns-test -- nslookup kubernetes.default.svc.cluster.local
```

A successful DNS response confirms basic Pod-to-Service DNS functionality.

Clean up:

```bash id="5ekqk8"
kubectl delete pod dns-test
```

---

# 262. Verify Pod-to-Pod Networking

Create two temporary Pods:

```bash id="kg0p7h"
kubectl run net-test-1 \
  --image=busybox:1.36 \
  --restart=Never \
  --command -- sleep 3600
```

and:

```bash id="h2x1gk"
kubectl run net-test-2 \
  --image=busybox:1.36 \
  --restart=Never \
  --command -- sleep 3600
```

Check their IP addresses:

```bash id="84k5d8"
kubectl get pods -o wide
```

Test connectivity from one Pod to the other:

```bash id="l1l0p9"
kubectl exec net-test-1 -- ping -c 3 <NET-TEST-2-POD-IP>
```

A successful result confirms Pod-to-Pod connectivity.

Clean up:

```bash id="6l5q4s"
kubectl delete pod net-test-1 net-test-2
```

---

# 263. Verify Cross-Node Pod Networking

To test cross-node networking, ensure that test Pods are scheduled on different worker nodes.

Run:

```bash id="e7m3je"
kubectl get pods -o wide
```

If necessary, use node selectors or other scheduling constraints to place test Pods on different nodes.

Then test:

```text id="l4e5nj"
Pod on Worker 01
       │
       │ network
       ▼
Pod on Worker 02
```

This validates the cross-node networking path provided by Calico.

---

# 264. Verify Service Networking

Create a temporary deployment:

```bash id="t5xq6w"
kubectl create deployment nginx \
  --image=nginx
```

Expose it:

```bash id="3m7jv5"
kubectl expose deployment nginx \
  --port=80 \
  --target-port=80
```

Check:

```bash id="zq4l79"
kubectl get svc nginx
```

Check the endpoints:

```bash id="3x0r2h"
kubectl get endpoints nginx
```

For newer Kubernetes versions, also inspect EndpointSlices:

```bash id="z4x0bb"
kubectl get endpointslices \
  -l kubernetes.io/service-name=nginx
```

---

# 265. Test Service Connectivity

Create a temporary client Pod:

```bash id="b6yn6f"
kubectl run service-test \
  --image=busybox:1.36 \
  --restart=Never \
  --command -- sleep 3600
```

Test the Service:

```bash id="e9l3wd"
kubectl exec service-test -- wget -qO- http://nginx
```

The NGINX default HTTP response should be returned.

Clean up:

```bash id="8m8tq8"
kubectl delete deployment nginx
kubectl delete service nginx
kubectl delete pod service-test
```

---

# 266. Verify kube-proxy

Check the kube-proxy DaemonSet:

```bash id="8n3wsp"
kubectl get daemonset -n kube-system kube-proxy
```

Check Pods:

```bash id="19e7fs"
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide
```

There should be a kube-proxy Pod on each appropriate Kubernetes node.

---

# 267. Verify Kubernetes DNS and Service CIDR

Check the Kubernetes Service:

```bash id="v72wri"
kubectl get svc kubernetes
```

Expected conceptually:

```text
NAME         TYPE        CLUSTER-IP
kubernetes   ClusterIP   10.96.0.1
```

The exact address depends on the Service CIDR configured during cluster initialization.

Verify the API endpoint from inside a Pod only after DNS/networking is confirmed.

---

# 268. Network Policy Capability

One reason Calico is used is its support for Kubernetes NetworkPolicy and Calico-specific network policy capabilities.

A NetworkPolicy can control traffic based on:

* Namespace
* Pod labels
* IP blocks
* Ports
* Protocols

Example conceptual architecture:

```text
Frontend Pods
      │
      │ allowed
      ▼
Backend Pods
      │
      │ allowed
      ▼
Database Pods
```

Network policy implementation should be introduced only after basic connectivity has been validated.

---

# 269. Do Not Apply Restrictive Policies Yet

Before creating NetworkPolicies, first confirm:

```text
Node networking
Pod networking
Service networking
DNS
Cross-node networking
```

Otherwise, a network policy can make troubleshooting more difficult by introducing an additional variable.

---

# 270. Troubleshooting — Calico Pods Not Running

Check:

```bash id="f1l1i5"
kubectl get pods -A -o wide | grep -i calico
```

Then:

```bash id="3q2a1y"
kubectl describe pod -n <CALICO-NAMESPACE> <CALICO-POD>
```

Check events:

```bash id="0k3l7v"
kubectl get events -A --sort-by='.lastTimestamp'
```

---

# 271. Troubleshooting — Calico CrashLoopBackOff

Check:

```bash id="z08q0b"
kubectl logs -n <CALICO-NAMESPACE> <CALICO-POD> --previous
```

Also inspect:

```bash id="1e2j58"
kubectl describe pod -n <CALICO-NAMESPACE> <CALICO-POD>
```

Common areas to investigate include:

* Incorrect Pod CIDR
* Incorrect node address selection
* Kernel configuration
* IP forwarding
* container runtime
* incompatible Calico configuration
* network connectivity between nodes

---

# 272. Troubleshooting — Nodes Remain NotReady

Run:

```bash id="j77f3x"
kubectl get nodes
```

Then:

```bash id="xx4xet"
kubectl describe node <NODE-NAME>
```

Check Calico:

```bash id="dr7t0b"
kubectl get pods -A -o wide | grep -i calico
```

Check kubelet:

```bash id="y53tpf"
sudo journalctl -u kubelet -n 200 --no-pager
```

Check node networking:

```bash id="k8lj2x"
ip addr
ip route
```

---

# 273. Troubleshooting — Pod Sandbox Creation Failure

If events contain:

```text
FailedCreatePodSandBox
```

inspect:

```bash id="6l1kpb"
kubectl describe pod <POD-NAME>
```

Then check the node:

```bash id="q5n2z9"
sudo journalctl -u kubelet -n 200 --no-pager
```

Check Calico logs:

```bash id="2p5cny"
kubectl logs -n <CALICO-NAMESPACE> <CALICO-POD>
```

Also verify containerd:

```bash id="p7m2iz"
sudo systemctl status containerd
```

---

# 274. Troubleshooting — Pod-to-Pod Connectivity Failure

Check Pod placement:

```bash id="f8qg2s"
kubectl get pods -o wide
```

Check Pod IPs:

```bash id="a0v9tg"
kubectl get pods -o wide
```

Check node routes:

```bash id="6j8r51"
ip route
```

Check Calico Pods:

```bash id="b1jv1x"
kubectl get pods -A -o wide | grep -i calico
```

Check network interfaces:

```bash id="2o2a4p"
ip addr
```

---

# 275. Troubleshooting — DNS Failure

Check CoreDNS:

```bash id="aj2g3w"
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

Check DNS Service:

```bash id="8v9g5g"
kubectl get svc -n kube-system kube-dns
```

Check EndpointSlices:

```bash id="1w3j5g"
kubectl get endpointslices \
  -n kube-system \
  -l k8s-app=kube-dns
```

Then run a temporary DNS test Pod and inspect:

```bash id="d5f7k1"
kubectl exec <DNS-TEST-POD> -- cat /etc/resolv.conf
```

---

# 276. Troubleshooting — Cross-Node Networking

If Pods on the same node can communicate but Pods on different nodes cannot:

Check:

```bash id="u6u1a2"
ip route
```

on each node.

Check:

```bash id="y11fzi"
kubectl get pods -A -o wide | grep -i calico
```

Verify node-to-node connectivity:

```bash id="2j0m3r"
nc -vz <OTHER-NODE-IP> <REQUIRED-PORT>
```

Also inspect the Calico configuration and node address selection.

---

# 277. Tailscale Considerations

If Tailscale is used for connectivity between the Kubernetes machines, verify:

```bash id="3l08pd"
tailscale status
```

and:

```bash id="hz9j9d"
tailscale ip -4
```

Check:

```bash id="d0w7j4"
ip addr show tailscale0
```

The selected Kubernetes node addresses must be routable between the participating nodes.

If a node changes its reachable interface or Tailscale state, Calico may be affected depending on the configured node address selection.

---

# 278. Verify All Six Nodes

Run:

```bash id="l2f5e1"
kubectl get nodes -o wide
```

Target state:

```text id="c2t8wl"
NAME        STATUS   ROLES           VERSION
master-01   Ready    control-plane   v1.34.11
master-02   Ready    control-plane   v1.34.11
master-03   Ready    control-plane   v1.34.11
worker-01   Ready    worker          v1.34.11
worker-02   Ready    worker          v1.34.11
worker-03   Ready    worker          v1.34.11
```

The `worker` role may display as `<none>` if explicit worker labels were not added.

The important condition is that the workers are registered and `Ready`.

---

# 279. Verify System Pods

Run:

```bash id="u1c7fw"
kubectl get pods -A -o wide
```

Review:

* Control-plane Pods
* etcd Pods
* kube-proxy Pods
* Calico Pods
* CoreDNS Pods

All required system components should be healthy.

---

# 280. Verify No Unexpected Failures

Run:

```bash id="1i5g44"
kubectl get pods -A | grep -E \
'CrashLoopBackOff|ImagePullBackOff|ErrImagePull|Error|Pending'
```

No unexpected system Pods should remain in these states.

---

# 281. Verify Cluster Readiness

Run:

```bash id="sj3qhv"
kubectl get --raw='/readyz?verbose'
```

The API server should report successful readiness checks.

Then:

```bash id="ydk6ub"
kubectl get nodes
```

All six nodes should be ready.

---

# 282. Final Network Validation

The following communication paths should now work:

```text id="b1b7jf"
Pod A
 │
 ├──── Pod B
 │
 ├──── Kubernetes Service
 │
 └──── DNS

Worker 01
 │
 └──── Worker 02
       │
       └──── Worker 03
```

The exact routing mechanism depends on the Calico dataplane configuration.

---

# 283. Security Considerations

Calico configuration can control network access across the cluster.

At minimum:

* Restrict unnecessary inbound node traffic
* Restrict access to Kubernetes API `6443`
* Restrict etcd ports `2379/2380`
* Avoid exposing Calico management endpoints unnecessarily
* Use NetworkPolicies for workload isolation where required
* Keep Calico configuration under version control
* Never commit cluster credentials or private certificates

Do not commit:

```text
admin.conf
TLS private keys
etcd certificates
bootstrap tokens
certificate keys
cloud credentials
Tailscale authentication keys
```

---

# 284. Calico Validation Checklist

Before proceeding to Part 08:

```text
Calico
[ ] Calico installed
[ ] Calico namespace/resources verified
[ ] Calico node DaemonSet running
[ ] Calico Pods running on required nodes
[ ] Calico rollout completed
[ ] Calico configuration verified
[ ] Pod CIDR verified
[ ] Node Pod CIDRs assigned
[ ] Node routes verified

Nodes
[ ] Master 01 Ready
[ ] Master 02 Ready
[ ] Master 03 Ready
[ ] Worker 01 Ready
[ ] Worker 02 Ready
[ ] Worker 03 Ready

Networking
[ ] Pod-to-Pod connectivity verified
[ ] Cross-node Pod connectivity verified
[ ] Service connectivity verified
[ ] CoreDNS verified
[ ] kube-proxy verified
[ ] Node-to-node connectivity verified

Cluster
[ ] kube-apiserver healthy
[ ] etcd healthy
[ ] CoreDNS healthy
[ ] kube-proxy healthy
[ ] No unexpected CrashLoopBackOff
[ ] No unexpected ImagePullBackOff
[ ] No unexpected Pending system Pods
```

---

# 285. Expected Final Architecture

After Part 07, the cluster networking architecture is:

```text
                              Admin Client
                                   │
                                   │ :6443
                                   ▼
                               HAProxy
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                    ▼              ▼              ▼
                Master 01      Master 02      Master 03
                    │              │              │
                   etcd           etcd           etcd
                    │              │              │
                    └──────────────┼──────────────┘
                                   │
                          Kubernetes Control Plane
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                    ▼              ▼              ▼
                Worker 01      Worker 02      Worker 03
                    │              │              │
                 Calico         Calico         Calico
                    │              │              │
                    └──────────────┼──────────────┘
                                   │
                              Pod Network
```

Calico now provides the networking layer across the Kubernetes cluster.

---

# 286. Next Part

## Part 08 — External Admin Client Configuration

The next phase will configure the external Admin Client as the centralized administration machine.

It will cover:

```text
Admin Client
     │
     ├── kubectl
     ├── kubeconfig
     ├── HAProxy endpoint
     └── cluster administration
             │
             ▼
          HAProxy
             │
       ┌─────┼─────┐
       ▼     ▼     ▼
      M01   M02   M03
```

Part 08 will also validate that the cluster can be administered externally without requiring administrative access to be performed directly from a control-plane node.

# Part 08 — External Admin Client Configuration

## 287. Objective

The objective of Part 08 is to configure a dedicated external machine as the Kubernetes administration client.

The Admin Client is **not a Kubernetes node**.

It does not run:

* kubelet
* kube-apiserver
* kube-controller-manager
* kube-scheduler
* etcd
* Calico node

Instead, it provides administrative access to the Kubernetes cluster through the HAProxy endpoint.

The architecture is:

```text
                         ┌──────────────────┐
                         │   External       │
                         │   Admin Client   │
                         │                  │
                         │ kubectl / Helm   │
                         └────────┬─────────┘
                                  │
                                  │ TCP 6443
                                  ▼
                         ┌──────────────────┐
                         │     HAProxy      │
                         └────────┬─────────┘
                                  │
                   ┌──────────────┼──────────────┐
                   │              │              │
                   ▼              ▼              ▼
               Master 01      Master 02      Master 03
```

---

# 288. Role of the Admin Client

The Admin Client provides a centralized location for:

* `kubectl`
* Helm
* Kubernetes configuration
* Cluster validation
* Application deployment
* Namespace management
* RBAC administration
* Monitoring administration
* Storage administration
* Troubleshooting

The Admin Client communicates with the Kubernetes API through HAProxy.

It should not bypass HAProxy for normal cluster administration.

---

# 289. Infrastructure Topology

The complete infrastructure now contains eight machines:

| Machine      | Role                    | Kubernetes Member |
| ------------ | ----------------------- | ----------------- |
| Master 01    | Control Plane + etcd    | Yes               |
| Master 02    | Control Plane + etcd    | Yes               |
| Master 03    | Control Plane + etcd    | Yes               |
| Worker 01    | Worker                  | Yes               |
| Worker 02    | Worker                  | Yes               |
| Worker 03    | Worker                  | Yes               |
| HAProxy      | API Load Balancer       | No                |
| Admin Client | External Administration | No                |

The distinction is important:

```text
Kubernetes Nodes = 6
External Infrastructure = 2
Total Machines = 8
```

---

# 290. Verify Admin Client Host

On the Admin Client:

```bash id="s7w8k4"
hostnamectl
```

Expected hostname:

```text id="v8e4u1"
admin-client
```

Verify the operating system:

```bash id="f3i5d8"
cat /etc/os-release
```

Check network interfaces:

```bash id="j0z7dc"
ip addr
```

Check routing:

```bash id="x7i7nl"
ip route
```

---

# 291. Verify Network Connectivity

The Admin Client must be able to reach the HAProxy endpoint.

Test basic connectivity:

```bash id="9p3v21"
ping <HAProxy-IP>
```

Test the Kubernetes API port:

```bash id="n7h7x9"
nc -vz <HAProxy-ENDPOINT> 6443
```

Expected:

```text id="3nq4b0"
Connection to <HAProxy-ENDPOINT> 6443 port [tcp/*] succeeded!
```

---

# 292. Verify Tailscale Connectivity

If Tailscale is part of the infrastructure:

```bash id="p6q6k1"
tailscale status
```

Get the local Tailscale IP:

```bash id="1g6y2x"
tailscale ip -4
```

Check the interface:

```bash id="9h1d7c"
ip addr show tailscale0
```

Verify that the Admin Client can reach the HAProxy node over the intended network.

---

# 293. Install kubectl

Update the package index:

```bash id="k3h6g0"
sudo apt update
```

Install the Kubernetes client according to the Kubernetes version used by the project.

Verify:

```bash id="f7x6d9"
kubectl version --client
```

The client should be compatible with the Kubernetes v1.34.11 cluster.

For reproducibility, keep the client version documented rather than relying on an unpinned latest version.

---

# 294. Install Helm

If Helm is used for cluster components such as OpenEBS, monitoring, or application deployment, install Helm on the Admin Client.

Verify:

```bash id="s8x4v5"
helm version
```

The project environment previously used Helm 3.x.

Record the actual installed version in the project's environment documentation.

---

# 295. Create Kubernetes Configuration Directory

Create the kubeconfig directory:

```bash id="x9r5g3"
mkdir -p ~/.kube
chmod 700 ~/.kube
```

The default kubectl configuration path is:

```text id="l3f8g0"
~/.kube/config
```

---

# 296. Obtain the Administrative Kubeconfig

The kubeconfig generated by kubeadm is:

```text id="7qg8o5"
/etc/kubernetes/admin.conf
```

on a control-plane node.

For the Admin Client, transfer the required kubeconfig securely from an authorized control-plane node.

Do not place the file in a public location.

Example secure transfer workflow:

```bash id="b3m9k2"
scp <authorized-user>@<MASTER-01-IP>:/etc/kubernetes/admin.conf \
    ~/.kube/config
```

The exact transfer method depends on the security policies of the environment.

---

# 297. Protect the Kubeconfig

The administrative kubeconfig contains credentials that can provide extensive access to the cluster.

Set appropriate ownership:

```bash id="p8n3q2"
chmod 600 ~/.kube/config
```

Verify:

```bash id="x5w0d1"
ls -l ~/.kube/config
```

The file should not be readable by other users.

---

# 298. Important Kubeconfig Endpoint Check

Open the kubeconfig:

```bash id="6t7f8e"
grep 'server:' ~/.kube/config
```

The server should reference the HAProxy endpoint:

```text id="k3x9s7"
server: https://<HAProxy-ENDPOINT>:6443
```

It should **not** point directly to:

```text id="x7s2n1"
https://<MASTER-01-IP>:6443
```

for the intended external administration architecture.

This ensures that the Admin Client uses the highly available API endpoint.

---

# 299. Verify kubectl Connectivity

Run:

```bash id="z9v8m7"
kubectl cluster-info
```

Then:

```bash id="v4c6p2"
kubectl get nodes
```

Expected cluster membership:

```text id="8x2h4m"
master-01
master-02
master-03
worker-01
worker-02
worker-03
```

---

# 300. Verify Kubernetes API Endpoint

Run:

```bash id="f8g5d1"
kubectl config view --minify
```

Confirm that the server is:

```text id="b7k4n9"
https://<HAProxy-ENDPOINT>:6443
```

This confirms that the Admin Client is communicating through the external load balancer.

---

# 301. Verify Cluster Readiness

Run:

```bash id="w2q5p8"
kubectl get nodes -o wide
```

Target state:

```text id="q9n3x6"
master-01   Ready
master-02   Ready
master-03   Ready
worker-01   Ready
worker-02   Ready
worker-03   Ready
```

All six Kubernetes nodes should be operational after Calico installation.

---

# 302. Verify System Pods

Run:

```bash id="d5k7p1"
kubectl get pods -A -o wide
```

Verify the major components:

```text id="v2r8m4"
Control Plane
    kube-apiserver
    kube-controller-manager
    kube-scheduler
    etcd

Networking
    Calico
    kube-proxy

DNS
    CoreDNS
```

All required system components should be healthy.

---

# 303. Verify API Health

Run:

```bash id="c8m2j5"
kubectl get --raw='/readyz?verbose'
```

The API server should report successful readiness checks.

Also verify:

```bash id="h4w9r2"
kubectl get --raw='/version'
```

This confirms that the Admin Client can access the Kubernetes API.

---

# 304. Verify User Identity

Run:

```bash id="q7x3n8"
kubectl auth whoami
```

This shows the identity associated with the current kubeconfig.

The result should correspond to the administrative identity configured by the cluster.

---

# 305. Verify Administrative Permissions

Check:

```bash id="r8m5k3"
kubectl auth can-i get nodes
```

Then:

```bash id="w6n2p9"
kubectl auth can-i create namespaces
```

For a cluster administrator configuration, the expected result should be:

```text id="2g7m4x"
yes
```

Only perform privileged permission tests when the Admin Client is intentionally configured for cluster administration.

---

# 306. Verify Namespace Access

List namespaces:

```bash id="p9d4k6"
kubectl get namespaces
```

Expected system namespaces include resources such as:

```text id="s4x8q2"
default
kube-node-lease
kube-public
kube-system
```

Additional namespaces will be created in later phases.

---

# 307. Verify Helm Connectivity

If Helm is installed:

```bash id="k6n9m3"
helm list -A
```

Helm should be able to communicate with the Kubernetes cluster through the kubeconfig.

This will later be used for:

* OpenEBS
* Monitoring
* Grafana
* Prometheus
* Other cluster components

---

# 308. Configure KUBECONFIG Explicitly

The default location is:

```text id="x5d3q8"
~/.kube/config
```

If another location is required:

```bash id="m4p7k2"
export KUBECONFIG=/path/to/kubeconfig
```

Verify:

```bash id="r1x6v9"
kubectl config current-context
```

For a persistent configuration, add the required setting to the appropriate shell configuration file.

Do not store credentials directly in shell scripts committed to Git.

---

# 309. Verify Current Context

Run:

```bash id="z8k3m1"
kubectl config get-contexts
```

Then:

```bash id="a7p4n2"
kubectl config current-context
```

The current context should reference the intended cluster.

---

# 310. Verify Configuration Details

Run:

```bash id="c5m8q1"
kubectl config view --minify
```

Verify:

```text id="v6n2x4"
Cluster
Server
User
Context
```

Do not expose certificate data or credentials when sharing this output.

---

# 311. Test API Access From Different Networks

If the infrastructure uses Tailscale or another intranet overlay, verify that the Admin Client can reach HAProxy from the intended network.

Test:

```bash id="e9r3m5"
nc -vz <HAProxy-ENDPOINT> 6443
```

Then:

```bash id="p8k4s2"
kubectl get nodes
```

This confirms the complete path:

```text id="r5c7n1"
Admin Client
      │
      ▼
Network / Tailscale
      │
      ▼
HAProxy
      │
      ▼
Kubernetes API
```

---

# 312. Admin Client Is Not a Kubernetes Node

Verify:

```bash id="y3m8p6"
kubectl get nodes
```

Only the six Kubernetes machines should appear:

```text id="v4n7c2"
master-01
master-02
master-03
worker-01
worker-02
worker-03
```

The following should **not** appear:

```text id="x5d9q1"
load-balancer
admin-client
```

This confirms the separation between cluster nodes and external infrastructure.

---

# 313. Recommended Administration Workflow

Normal cluster administration should follow:

```text id="q8w5n3"
Admin Client
      │
      │ kubectl / helm
      ▼
HAProxy :6443
      │
      ├── Master 01 :6443
      ├── Master 02 :6443
      └── Master 03 :6443
```

This avoids coupling administration to a particular control-plane node.

---

# 314. Verify HAProxy Failover From Admin Client

Once all three API servers are healthy, verify:

```bash id="n5x7c3"
kubectl get nodes
```

Then, during an approved test, make one API server unavailable.

The Admin Client should continue using:

```text id="w2q6m8"
HAProxy :6443
```

while HAProxy routes requests to an available API server.

After the test, restore the affected API server.

Verify:

```bash id="f7k4p1"
kubectl get nodes
```

again.

---

# 315. Troubleshooting — kubectl Cannot Connect

Check the current endpoint:

```bash id="j8m2x6"
kubectl config view --minify
```

Check connectivity:

```bash id="p4r7n9"
nc -vz <HAProxy-ENDPOINT> 6443
```

Test the API:

```bash id="c6w3k8"
curl -k https://<HAProxy-ENDPOINT>:6443/version
```

If the TCP connection fails, investigate:

```text id="h2n5v7"
Admin Client → HAProxy
```

If TCP works but the API request fails, investigate:

```text id="s8q4m1"
HAProxy → Kubernetes API
```

---

# 316. Troubleshooting — TLS Certificate Error

Check the kubeconfig server:

```bash id="y5k8p3"
grep 'server:' ~/.kube/config
```

Ensure it uses the configured cluster endpoint.

If the Kubernetes certificates were generated with a specific API endpoint, ensure the endpoint used by the client is included in the API server certificate's SANs.

Do not bypass TLS verification in the actual administrative kubeconfig.

The following should not be used as a permanent solution:

```text id="v2m7x9"
insecure-skip-tls-verify: true
```

---

# 317. Troubleshooting — HAProxy Connection Refused

From Admin Client:

```bash id="b4n6q2"
nc -vz <HAProxy-ENDPOINT> 6443
```

On HAProxy:

```bash id="k7p3m8"
sudo systemctl status haproxy
```

Check listening port:

```bash id="n9x5c1"
sudo ss -lntp | grep 6443
```

Check logs:

```bash id="d6m8q4"
sudo journalctl -u haproxy -n 100 --no-pager
```

---

# 318. Troubleshooting — HAProxy Has No Backend

On HAProxy:

```bash id="w3p6n8"
nc -vz <MASTER-01-IP> 6443
nc -vz <MASTER-02-IP> 6443
nc -vz <MASTER-03-IP> 6443
```

If one fails, investigate the corresponding API server.

Check from the control-plane node:

```bash id="r8k2m5"
sudo ss -lntp | grep 6443
```

---

# 319. Troubleshooting — Kubeconfig Permissions

Check:

```bash id="v6m9p2"
ls -l ~/.kube/config
```

Set:

```bash id="n4x7q1"
chmod 600 ~/.kube/config
```

Verify ownership:

```bash id="k3p8m5"
ls -l ~/.kube/config
```

---

# 320. Troubleshooting — Wrong Context

Run:

```bash id="w8m2c6"
kubectl config get-contexts
```

Then:

```bash id="r5n9p3"
kubectl config current-context
```

Select the intended context if multiple contexts exist:

```bash id="m7q4x1"
kubectl config use-context <CONTEXT-NAME>
```

---

# 321. Troubleshooting — Admin Client Cannot Reach Tailscale

Check:

```bash id="z4k8p2"
tailscale status
```

Check:

```bash id="j6m3x9"
tailscale ip -4
```

Check:

```bash id="n8q5r1"
ip addr show tailscale0
```

Then test the HAProxy Tailscale address:

```bash id="c2m7p4"
nc -vz <HAProxy-TAILSCALE-IP> 6443
```

If Tailscale reports an offline or relay state, investigate the underlying network connectivity before changing Kubernetes configuration.

---

# 322. Security Considerations

The Admin Client contains a highly privileged kubeconfig.

Treat:

```text id="x8m4q6"
~/.kube/config
```

as a sensitive credential.

Do not commit it to Git.

Do not place it in:

```text id="y3n7p2"
README.md
Public repositories
Public issue trackers
Shared screenshots
Unencrypted shared folders
```

Do not copy `/etc/kubernetes/admin.conf` to worker nodes unnecessarily.

---

# 323. Separate Administrative and Workload Access

The Admin Client is intended for cluster administration.

Application workloads should not use the Admin Client's kubeconfig.

For applications, use:

* Kubernetes ServiceAccounts
* RBAC
* Namespace-scoped permissions
* Dedicated credentials

Avoid distributing cluster-admin credentials to application workloads.

---

# 324. RBAC Validation

Check the permissions of the current identity:

```bash id="p7m3k9"
kubectl auth can-i --list
```

This provides a list of permitted operations.

For security-sensitive environments, use least privilege rather than granting `cluster-admin` access to every user.

---

# 325. Optional Namespace Administration Test

Create a temporary namespace:

```bash id="n6q4r2"
kubectl create namespace admin-test
```

Verify:

```bash id="j3m8p5"
kubectl get namespace admin-test
```

Delete it:

```bash id="w9k2c7"
kubectl delete namespace admin-test
```

This confirms that the Admin Client has the expected namespace-management permissions.

---

# 326. Verify Helm Repository Access

If Helm repositories are required for later components, configure them from the Admin Client.

For example, repositories can be added using:

```bash id="q5m8x2"
helm repo add <REPO-NAME> <REPO-URL>
```

Then:

```bash id="r7n3p6"
helm repo update
```

Use the official repository URL corresponding to the component being installed.

---

# 327. Administration Architecture

The final external administration architecture is:

```text id="m4x8q2"
                    ┌─────────────────────┐
                    │    Admin Client     │
                    │                     │
                    │ kubectl             │
                    │ helm                │
                    │ kubeconfig          │
                    └──────────┬──────────┘
                               │
                               │ :6443
                               ▼
                    ┌─────────────────────┐
                    │      HAProxy        │
                    │                     │
                    │ Kubernetes API LB   │
                    └──────────┬──────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
                ▼              ▼              ▼
           Master 01      Master 02      Master 03
                │              │              │
               etcd           etcd           etcd
```

---

# 328. Admin Client Validation Checklist

Before proceeding to Part 09:

```text
Admin Client
[ ] Admin Client prepared
[ ] kubectl installed
[ ] Helm installed if required
[ ] ~/.kube directory created
[ ] Administrative kubeconfig configured
[ ] kubeconfig permissions restricted
[ ] kubeconfig uses HAProxy endpoint
[ ] Current context verified

Connectivity
[ ] Admin Client → HAProxy :6443
[ ] HAProxy → Master 01 :6443
[ ] HAProxy → Master 02 :6443
[ ] HAProxy → Master 03 :6443
[ ] kubectl can access cluster

Cluster
[ ] Six Kubernetes nodes visible
[ ] Three control-plane nodes visible
[ ] Three worker nodes visible
[ ] System Pods healthy
[ ] Calico healthy
[ ] CoreDNS healthy
[ ] API server ready

Administration
[ ] kubectl cluster-info works
[ ] kubectl get nodes works
[ ] kubectl auth whoami works
[ ] Required RBAC permissions verified
[ ] Helm connectivity verified if required

Security
[ ] admin kubeconfig protected
[ ] kubeconfig not committed to Git
[ ] No cluster credentials stored in README
[ ] Admin credentials not distributed to workers
```

---

# 329. Expected Final State

At the end of Part 08, administration is separated from the Kubernetes cluster:

```text
                         EXTERNAL
┌─────────────────────────────────────────────────────┐
│                                                     │
│                    Admin Client                     │
│                                                     │
│              kubectl       Helm                     │
│                  │           │                      │
│                  └─────┬─────┘                      │
│                        │                            │
└────────────────────────┼────────────────────────────┘
                         │
                         │ TCP 6443
                         ▼
                  ┌──────────────┐
                  │   HAProxy    │
                  └──────┬───────┘
                         │
             ┌───────────┼───────────┐
             │           │           │
             ▼           ▼           ▼
          Master 01   Master 02   Master 03
             │           │           │
            etcd        etcd        etcd
             └───────────┼───────────┘
                         │
                  Kubernetes API
                         │
             ┌───────────┼───────────┐
             ▼           ▼           ▼
          Worker 01   Worker 02   Worker 03
```

The external Admin Client is now ready to manage the six-node Kubernetes cluster.

---

# 330. Next Part

## Part 09 — OpenEBS Installation

The next phase introduces the persistent storage layer required for the project.

The planned architecture is:

```text
                         Kubernetes Cluster
                                │
                             OpenEBS
                                │
                ┌───────────────┼───────────────┐
                │               │               │
                ▼               ▼               ▼
            Storage          Storage         Storage
             Node              Node            Node
                │               │               │
                └───────────────┼───────────────┘
                                │
                              PVC
                                │
                                ▼
                         Backup Workload
                                │
                                ▼
                         etcd Snapshots
```

Part 09 will cover:

* OpenEBS installation
* OpenEBS namespace
* Storage engines
* StorageClasses
* Node prerequisites
* Storage architecture
* Selecting the appropriate StorageClass
* Verifying OpenEBS components
* Creating test PVCs
* Validating PV/PVC binding
* Understanding where OpenEBS data is physically stored
* Preparing the storage layer for the future etcd backup CronJob

# Part 09 — OpenEBS Installation and Storage Foundation

## 331. Objective

The objective of Part 09 is to install **OpenEBS** and establish the persistent-storage foundation for the Kubernetes cluster.

The storage layer will later be used by the etcd backup system.

The planned flow is:

```text
                         etcd Backup CronJob
                                │
                                │ writes snapshot
                                ▼
                             PVC
                                │
                                ▼
                              PV
                                │
                                ▼
                          StorageClass
                                │
                                ▼
                             OpenEBS
                                │
                                ▼
                       Persistent Storage
```

The important architectural principle is:

> The backup workload writes to a Kubernetes PVC. The PVC is backed by an OpenEBS-provisioned PV. The application should not need to know which physical node provides the underlying storage.

---

# 332. Storage Architecture

The Kubernetes cluster contains:

```text
Control Plane:
    Master 01
    Master 02
    Master 03

Workers:
    Worker 01
    Worker 02
    Worker 03
```

OpenEBS will provide Kubernetes persistent storage using one of its supported storage engines.

Conceptually:

```text
                    Kubernetes Cluster
                           │
                        OpenEBS
                           │
                 ┌─────────┴─────────┐
                 │                   │
            StorageClass          Storage Engine
                 │                   │
                 ▼                   ▼
                PVC                 PV
                 │                   │
                 └─────────┬─────────┘
                           │
                    Backup Workload
```

The exact physical storage location depends on the OpenEBS storage engine and StorageClass selected.

---

# 333. Why OpenEBS Is Used

OpenEBS provides Kubernetes-native persistent storage.

It allows applications to request storage using:

```text
PersistentVolumeClaim
```

rather than directly managing host directories.

For the etcd backup system, this gives a clean separation:

```text
Backup application
       │
       ▼
      PVC
       │
       ▼
OpenEBS storage
       │
       ▼
Underlying node storage
```

The backup process does not need to manually select a host directory.

---

# 334. Storage Concepts

The following Kubernetes resources are important:

```text
StorageClass
     │
     ▼
PersistentVolume
     │
     ▼
PersistentVolumeClaim
     │
     ▼
Pod
```

### StorageClass

Defines how storage should be dynamically provisioned.

### PersistentVolume

Represents provisioned storage available to the cluster.

### PersistentVolumeClaim

Represents an application's request for storage.

### Pod

Mounts the PVC and accesses the storage through a filesystem path.

---

# 335. Storage Request Flow

When the etcd backup workload eventually requests:

```yaml
resources:
  requests:
    storage: 10Gi
```

the flow is:

```text
Backup Pod
    │
    ▼
PVC: etcd-backup-pvc
    │
    ▼
StorageClass
    │
    ▼
OpenEBS Provisioner
    │
    ▼
PV
    │
    ▼
OpenEBS Storage
```

The PVC is the interface between the workload and the storage subsystem.

---

# 336. Storage Prerequisites

Before installing OpenEBS, verify:

```text
[ ] Six-node Kubernetes cluster operational
[ ] Calico installed
[ ] Nodes Ready
[ ] containerd operational
[ ] kubelet operational
[ ] Helm installed on Admin Client
[ ] Sufficient disk capacity
[ ] Storage design selected
```

Verify nodes:

```bash id="4v7w8k"
kubectl get nodes -o wide
```

All six nodes should ideally be:

```text
Ready
```

---

# 337. Check Node Disk Capacity

Storage engines use underlying node resources.

Check disk usage on each potential storage node:

```bash id="9p4q2x"
df -h
```

Also check:

```bash id="7n6k3m"
lsblk
```

Review available:

* Root filesystem
* Data disks
* Mount points
* Filesystem types
* Free capacity

Do not allocate more persistent storage than the underlying nodes can safely provide.

---

# 338. Identify Storage Nodes

For this project, storage placement must be deliberately designed.

Possible approaches include:

```text
Option A:
OpenEBS on worker nodes

Option B:
OpenEBS on dedicated storage nodes

Option C:
OpenEBS on selected Kubernetes nodes
```

For the current six-node architecture, storage should generally be kept separate from the control-plane responsibility unless there is a specific reason to use the masters for storage.

The exact placement depends on the OpenEBS engine and StorageClass selected.

---

# 339. Important: OpenEBS Does Not Mean One Fixed Storage Node

A PVC does not simply mean:

```text
PVC → Master 01
```

or:

```text
PVC → Worker 01
```

The actual placement depends on:

* OpenEBS storage engine
* StorageClass
* node topology
* volume scheduling
* replica configuration
* available capacity
* Pod scheduling

Therefore, the project documentation should not claim a fixed physical node unless the actual StorageClass configuration proves it.

---

# 340. Install OpenEBS Repository

From the Admin Client, add the OpenEBS Helm repository:

```bash id="7k2p9m"
helm repo add openebs <OFFICIAL-OPENEBS-HELM-REPOSITORY>
```

Update repositories:

```bash id="f4m6q8"
helm repo update
```

Verify:

```bash id="n8x3r1"
helm search repo openebs
```

Use the official OpenEBS repository and pin the OpenEBS version selected for this project.

---

# 341. Create OpenEBS Namespace

If the Helm chart does not create the namespace automatically, create it:

```bash id="p6m8v3"
kubectl create namespace openebs
```

Verify:

```bash id="j4q7n2"
kubectl get namespace openebs
```

Expected:

```text
openebs
```

If the namespace already exists, do not recreate it.

---

# 342. Install OpenEBS

Install OpenEBS using the selected Helm chart/version.

Conceptual command:

```bash id="z9x5m4"
helm install openebs openebs/openebs \
  --namespace openebs \
  --create-namespace
```

For a reproducible project, record the exact chart and application version used.

After installation:

```bash id="h3k8q1"
helm list -n openebs
```

---

# 343. Verify OpenEBS Deployment

Run:

```bash id="b7m2p6"
kubectl get pods -n openebs -o wide
```

Check:

```text
STATUS
READY
RESTARTS
NODE
```

OpenEBS components should eventually reach their expected healthy state.

---

# 344. Verify OpenEBS Resources

Run:

```bash id="x4n9q2"
kubectl get all -n openebs
```

Also inspect:

```bash id="m6p3r8"
kubectl get daemonsets -n openebs
kubectl get deployments -n openebs
```

The exact resources depend on the OpenEBS version and enabled storage engines.

---

# 345. Verify OpenEBS CRDs

Check:

```bash id="q8v5m2"
kubectl get crds | grep -i openebs
```

OpenEBS uses Kubernetes custom resources for various storage functions.

Do not assume that every OpenEBS CRD shown by an older installation guide exists in the version being deployed.

---

# 346. Verify StorageClasses

Run:

```bash id="f2k7n4"
kubectl get storageclass
```

OpenEBS may provide multiple StorageClasses depending on the enabled storage engines.

Example categories may include:

```text
openebs-hostpath
openebs-localpv-*
openebs-single-replica
openebs-replicated-*
```

The actual names depend on the OpenEBS release and configuration.

---

# 347. Understand the StorageClass Before Using It

Do not select a StorageClass merely because its name contains:

```text
openebs
```

Inspect it:

```bash id="m5n8q2"
kubectl describe storageclass <STORAGECLASS-NAME>
```

Also:

```bash id="q4x7p1"
kubectl get storageclass <STORAGECLASS-NAME> -o yaml
```

Review:

* Provisioner
* Reclaim policy
* Volume binding mode
* Allow volume expansion
* Parameters
* Topology constraints

---

# 348. StorageClass Reclaim Policy

Check:

```bash id="p8k3m6"
kubectl get storageclass \
  -o custom-columns=NAME:.metadata.name,RECLAIM:.reclaimPolicy
```

Common values are:

```text
Delete
Retain
```

For backup storage, consider whether the project requires:

```text
Retain
```

to prevent accidental deletion of the underlying volume when the PVC is deleted.

The final choice should be documented according to the project's backup-retention requirements.

---

# 349. Volume Binding Mode

Check:

```bash id="x2m7q9"
kubectl get storageclass \
  -o custom-columns=NAME:.metadata.name,BINDING:.volumeBindingMode
```

Common modes include:

```text
Immediate
WaitForFirstConsumer
```

`WaitForFirstConsumer` can be useful for topology-aware storage because volume provisioning can wait until the consuming Pod has been scheduled.

Whether it is appropriate depends on the selected OpenEBS storage engine.

---

# 350. OpenEBS Storage Engine Selection

OpenEBS supports multiple storage approaches.

The major architectural distinction is between:

```text
Local storage
```

and:

```text
Replicated/distributed storage
```

The choice should be based on the backup requirements.

For example:

### Local storage

```text
PVC
 │
 ▼
OpenEBS LocalPV
 │
 ▼
One node's local disk
```

Advantages:

* Simple
* Low overhead
* Good local performance

Limitation:

* Data availability is tied to the underlying node/storage unless another backup mechanism exists.

### Replicated storage

```text
             Volume
                │
       ┌────────┼────────┐
       ▼        ▼        ▼
     Node A   Node B   Node C
```

Advantages:

* Storage-level replication
* Better node-level resilience

Trade-offs:

* More resource consumption
* More operational complexity
* Requires suitable node/storage topology

---

# 351. Storage Design for etcd Backups

The etcd backup requirement is:

```text
Every 24 hours
       │
       ▼
Create etcd snapshot
       │
       ▼
Store snapshot
       │
       ▼
OpenEBS-backed PVC
```

The backup system should not rely on the same etcd member's local filesystem as its permanent backup location.

For example, avoid a design where:

```text
etcd on Master 01
       │
       ▼
/var/lib/etcd/backup
```

is treated as the primary backup repository.

Instead:

```text
etcd
 │
 ▼
Backup Pod
 │
 ▼
OpenEBS PVC
```

provides a separate Kubernetes-managed storage layer.

---

# 352. Backup Storage Is Different From etcd Storage

The etcd database itself remains on the control-plane nodes.

Conceptually:

```text
Master 01
    └── etcd data

Master 02
    └── etcd data

Master 03
    └── etcd data
```

The backup is stored separately:

```text
Backup CronJob
      │
      ▼
OpenEBS PVC
      │
      ▼
Backup snapshots
```

The two storage paths should not be confused.

---

# 353. Create a Test Namespace

Create a temporary namespace for storage testing:

```bash id="g7p4m2"
kubectl create namespace storage-test
```

Verify:

```bash id="n3x8q5"
kubectl get namespace storage-test
```

---

# 354. Create a Test PVC

Create:

```bash id="j6m2p8"
nano storage-test-pvc.yaml
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
  storageClassName: <OPENEBS-STORAGECLASS>
  resources:
    requests:
      storage: 1Gi
```

Replace:

```text
<OPENEBS-STORAGECLASS>
```

with the StorageClass selected after inspection.

Apply:

```bash id="r4n7x2"
kubectl apply -f storage-test-pvc.yaml
```

---

# 355. Verify PVC

Run:

```bash id="v8m3q6"
kubectl get pvc -n storage-test
```

Expected:

```text
NAME                STATUS   VOLUME
openebs-test-pvc    Bound    <PV-NAME>
```

The important state is:

```text
Bound
```

---

# 356. Verify PV

Run:

```bash id="x7p2m5"
kubectl get pv
```

Find the PV associated with the test PVC.

Then:

```bash id="k4n8q3"
kubectl describe pv <PV-NAME>
```

Review:

* Capacity
* Access modes
* Reclaim policy
* StorageClass
* Claim
* Node/topology information
* CSI/provisioner information

---

# 357. Understand PVC-to-PV Binding

The relationship is:

```text
PVC
 │
 │ requests 1Gi
 ▼
StorageClass
 │
 │ dynamic provisioning
 ▼
OpenEBS
 │
 ▼
PV
 │
 ▼
PVC
```

The Pod then mounts the PVC.

Therefore, the application normally interacts with:

```text
/mnt/backup
```

rather than directly interacting with:

```text
/dev/...
```

or a host-specific OpenEBS directory.

---

# 358. Create a Storage Test Pod

Create:

```bash id="q6m4p8"
nano storage-test-pod.yaml
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
          while true; do sleep 3600; done
      volumeMounts:
        - name: storage
          mountPath: /mnt/storage

  volumes:
    - name: storage
      persistentVolumeClaim:
        claimName: openebs-test-pvc
```

Apply:

```bash id="h5n7q2"
kubectl apply -f storage-test-pod.yaml
```

---

# 359. Verify Test Pod

Run:

```bash id="w3p8m6"
kubectl get pod -n storage-test -o wide
```

Expected:

```text
openebs-test   Running
```

Check which node hosts the Pod:

```bash id="k7x2q4"
kubectl get pod openebs-test \
  -n storage-test \
  -o wide
```

The `NODE` column shows the node selected for the Pod.

This is useful for understanding storage topology.

---

# 360. Verify Storage Mount

Run:

```bash id="m8q4p2"
kubectl exec -n storage-test openebs-test \
  -- df -h /mnt/storage
```

Also:

```bash id="y6x3n7"
kubectl exec -n storage-test openebs-test \
  -- mount | grep /mnt/storage
```

The PVC should be mounted into:

```text
/mnt/storage
```

inside the container.

---

# 361. Test Persistent Write

Write a test file:

```bash id="p5m8q3"
kubectl exec -n storage-test openebs-test \
  -- sh -c 'echo "OpenEBS persistence test" > /mnt/storage/test.txt'
```

Read it:

```bash id="n4x7m2"
kubectl exec -n storage-test openebs-test \
  -- cat /mnt/storage/test.txt
```

Expected:

```text
OpenEBS persistence test
```

---

# 362. Verify Persistence

Delete the test Pod:

```bash id="r8m3q6"
kubectl delete pod openebs-test -n storage-test
```

Recreate it:

```bash id="h2x7p4"
kubectl apply -f storage-test-pod.yaml
```

Wait for:

```bash id="q6m4n8"
kubectl get pod -n storage-test
```

Then:

```bash id="x3p7m5"
kubectl exec -n storage-test openebs-test \
  -- cat /mnt/storage/test.txt
```

The file should still exist if the PVC/PV and storage engine have retained the data correctly.

This validates persistence across Pod recreation.

---

# 363. Verify PV and PVC Relationship

Run:

```bash id="m7q2x5"
kubectl get pvc -n storage-test
```

Then:

```bash id="p4n8m3"
kubectl get pv
```

The relationship should be:

```text
openebs-test-pvc
       │
       ▼
   <PV-NAME>
       │
       ▼
OpenEBS Storage
```

---

# 364. Determine Storage Placement

The physical location depends on the selected OpenEBS engine.

Start with:

```bash id="f8m3q7"
kubectl get pod openebs-test \
  -n storage-test \
  -o wide
```

Then inspect the PV:

```bash id="j5x8n2"
kubectl describe pv <PV-NAME>
```

Inspect the StorageClass:

```bash id="q7m4p1"
kubectl describe storageclass <STORAGECLASS>
```

For local storage, node affinity or topology information may identify the node on which the volume resides.

For replicated storage, multiple storage nodes may participate.

---

# 365. Important Storage Placement Principle

Do not document:

```text
PVC is always stored on Worker 01
```

unless the actual OpenEBS configuration enforces that.

Instead document:

```text
The PVC is dynamically provisioned through the selected
OpenEBS StorageClass. The physical storage location is
determined by the storage engine, topology, scheduling,
and StorageClass configuration.
```

This accurately represents Kubernetes storage behavior.

---

# 366. Test PVC Expansion

If the selected StorageClass supports expansion, inspect:

```bash id="y2m6q8"
kubectl get storageclass <STORAGECLASS> -o yaml
```

Look for:

```yaml
allowVolumeExpansion: true
```

If supported, a PVC can potentially be expanded.

For example:

```yaml
resources:
  requests:
    storage: 2Gi
```

Do not perform expansion testing on production backup storage without confirming that the selected engine supports it.

---

# 367. Storage Reclaim Policy Test

Inspect:

```bash id="r6m3q9"
kubectl get pv <PV-NAME> \
  -o custom-columns=NAME:.metadata.name,RECLAIM:.spec.persistentVolumeReclaimPolicy
```

The configured policy determines what happens after the PVC is deleted.

For backup data, a `Retain` policy can be useful when preservation of the underlying volume is required.

However, the final retention strategy should be designed together with the backup lifecycle in later parts.

---

# 368. Clean Up Storage Test

After validation:

```bash id="k3x7m2"
kubectl delete pod openebs-test -n storage-test
```

Delete the test PVC:

```bash id="p8m4q6"
kubectl delete pvc openebs-test-pvc -n storage-test
```

Then:

```bash id="y5n2q8"
kubectl get pv
```

Observe the PV behavior according to the configured reclaim policy.

Finally:

```bash id="r7m3x1"
kubectl delete namespace storage-test
```

---

# 369. Verify OpenEBS After Test Cleanup

Run:

```bash id="q2m8p4"
kubectl get pods -n openebs
```

Then:

```bash id="x6n3m7"
kubectl get storageclass
```

The OpenEBS components and StorageClasses should remain healthy.

---

# 370. Troubleshooting — PVC Pending

Check:

```bash id="n5q8m2"
kubectl get pvc -n storage-test
```

Then:

```bash id="v3m7p4"
kubectl describe pvc openebs-test-pvc -n storage-test
```

Check events:

```bash id="j8x2n6"
kubectl get events -n storage-test --sort-by='.lastTimestamp'
```

Then inspect the StorageClass:

```bash id="q4m7p2"
kubectl describe storageclass <STORAGECLASS>
```

Common causes include:

* StorageClass does not exist
* Provisioner unavailable
* Insufficient storage
* Node topology constraints
* Storage engine not healthy
* Incorrect StorageClass parameters

---

# 371. Troubleshooting — PV Not Provisioned

Check:

```bash id="m2x7q5"
kubectl get pv
```

Then:

```bash id="n8p4m3"
kubectl get pods -n openebs -o wide
```

Check OpenEBS events:

```bash id="y6q2m8"
kubectl get events -n openebs --sort-by='.lastTimestamp'
```

Inspect the OpenEBS provisioner/controller logs where applicable.

---

# 372. Troubleshooting — Pod Cannot Mount PVC

Check:

```bash id="x4m8p2"
kubectl describe pod openebs-test -n storage-test
```

Look for:

```text
FailedMount
FailedAttachVolume
FailedMountVolume
```

Check the PVC:

```bash id="q7n3m5"
kubectl describe pvc openebs-test-pvc -n storage-test
```

Then inspect the PV:

```bash id="p5x8m2"
kubectl describe pv <PV-NAME>
```

---

# 373. Troubleshooting — OpenEBS Pod NotReady

Run:

```bash id="m8q3n6"
kubectl get pods -n openebs -o wide
```

Then:

```bash id="x5p7m2"
kubectl describe pod -n openebs <POD-NAME>
```

Check logs:

```bash id="q4m8n1"
kubectl logs -n openebs <POD-NAME>
```

Check node resources:

```bash id="y7x3p5"
kubectl describe node <NODE-NAME>
```

---

# 374. Troubleshooting — Insufficient Disk

On the affected node:

```bash id="n2m7q4"
df -h
```

Then:

```bash id="x8p3m5"
lsblk
```

Check inode usage:

```bash id="q6n4m8"
df -i
```

Storage provisioning can fail even when total disk capacity appears sufficient if inode capacity or filesystem conditions are problematic.

---

# 375. Troubleshooting — Node Failure

The effect of a node failure depends on the OpenEBS storage engine.

For local storage:

```text
Node failure
     │
     ▼
Local volume unavailable
```

For replicated storage:

```text
Node failure
     │
     ▼
Other replicas may remain available
```

Therefore, the selected storage engine must match the project's availability requirements.

---

# 376. Storage and etcd Backup Design

The future backup architecture will be:

```text
                 Kubernetes API
                       │
                       ▼
                 CronJob every 24h
                       │
                       ▼
                Leader Detection
                       │
                       ▼
                 etcd Snapshot
                       │
                       ▼
                Backup Pod Volume
                       │
                       ▼
                     PVC
                       │
                       ▼
                  OpenEBS PV
                       │
                       ▼
             Persistent Backup Data
```

The backup Pod does not directly manipulate OpenEBS.

It simply mounts the PVC.

---

# 377. Example Future Backup Mount

The eventual backup workload will use something conceptually similar to:

```yaml
volumeMounts:
  - name: backup-storage
    mountPath: /backup

volumes:
  - name: backup-storage
    persistentVolumeClaim:
      claimName: etcd-backup-pvc
```

The backup command then writes:

```text
/backup/<snapshot-file>
```

The underlying storage is handled by OpenEBS.

---

# 378. Backup Storage Directory Structure

A future backup repository can use:

```text
/backup/
├── daily/
│   ├── snapshot-YYYY-MM-DD-HHMM.db
│   └── ...
├── metadata/
└── checksums/
```

The exact structure will be finalized in the backup implementation.

---

# 379. Backup Retention Consideration

OpenEBS storage provides persistence, but it does **not automatically implement application-level backup retention**.

The future CronJob must implement retention separately.

For example:

```text
OpenEBS
   │
   ▼
PVC
   │
   ├── Day 1 backup
   ├── Day 2 backup
   ├── Day 3 backup
   └── ...
```

The backup process can later remove snapshots older than the configured retention period.

This will be covered in the backup-retention phase.

---

# 380. Backup Security

etcd snapshots contain sensitive Kubernetes cluster state.

Therefore, the OpenEBS-backed backup volume should be treated as sensitive storage.

Protect:

```text
etcd snapshots
TLS certificates
backup metadata
checksums
restore information
```

Do not expose the backup PVC to arbitrary workloads.

Use a dedicated namespace and ServiceAccount for the backup workload.

---

# 381. Recommended Backup Namespace

The future backup workload should use a dedicated namespace, for example:

```text
etcd-backup
```

Conceptually:

```text
etcd-backup namespace
        │
        ├── ServiceAccount
        ├── RBAC
        ├── PVC
        ├── CronJob
        └── backup configuration
```

This keeps backup resources separate from application workloads.

---

# 382. Storage Validation Checklist

Before proceeding to Part 10:

```text
OpenEBS
[ ] OpenEBS repository configured
[ ] OpenEBS installed
[ ] OpenEBS namespace verified
[ ] OpenEBS Pods healthy
[ ] OpenEBS resources verified
[ ] OpenEBS CRDs verified where applicable

StorageClasses
[ ] StorageClasses listed
[ ] Provisioner inspected
[ ] Reclaim policy inspected
[ ] Volume binding mode inspected
[ ] Storage engine identified
[ ] Topology requirements understood

Storage Test
[ ] Test PVC created
[ ] PVC reached Bound
[ ] PV created
[ ] Test Pod mounted PVC
[ ] File successfully written
[ ] File persisted after Pod recreation
[ ] PV/PVC relationship verified
[ ] Physical placement investigated

Cluster
[ ] Six Kubernetes nodes available
[ ] Nodes Ready
[ ] Calico healthy
[ ] CoreDNS healthy

Backup Preparation
[ ] Backup storage design defined
[ ] Backup namespace planned
[ ] Backup PVC planned
[ ] Retention strategy planned
[ ] Backup security considered
```

---

# 383. Expected Final Architecture

After Part 09, the infrastructure becomes:

```text
                              Admin Client
                                   │
                                   │ kubectl / Helm
                                   ▼
                                HAProxy
                                   │
                                   ▼
                         Kubernetes Control Plane
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
              ▼                    ▼                    ▼
          Master 01            Master 02            Master 03
             etcd                 etcd                 etcd
              │                    │                    │
              └────────────────────┼────────────────────┘
                                   │
                         Kubernetes Networking
                                Calico
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
              ▼                    ▼                    ▼
          Worker 01            Worker 02            Worker 03
              │                    │                    │
              └────────────────────┼────────────────────┘
                                   │
                                OpenEBS
                                   │
                         ┌─────────┴─────────┐
                         │                   │
                     StorageClass          PV
                         │                   │
                         └─────────┬─────────┘
                                   │
                                  PVC
                                   │
                         Future etcd Backup
                              CronJob
```

---

# 384. Important Design Decision

For this project, the OpenEBS StorageClass should be selected based on the required backup durability.

The key question is:

```text
Should the backup remain available if the node
hosting its underlying storage fails?
```

If the answer is **yes**, a storage architecture with appropriate replication/failure tolerance should be evaluated.

If the answer is **no**, a local-storage-based design may be sufficient provided another independent backup destination exists.

For an etcd backup system, storage replication and an additional off-cluster backup destination should be considered separately. OpenEBS should not automatically be treated as the only disaster-recovery copy.

---

# 385. Next Part

## Part 10 — Persistent Storage Configuration

The next phase will turn the OpenEBS foundation into the actual persistent-storage design for the project.

It will cover:

```text
Select StorageClass
        ↓
Create dedicated backup namespace
        ↓
Create etcd-backup PVC
        ↓
Understand PV/PVC lifecycle
        ↓
Mount PVC into backup workload
        ↓
Storage topology
        ↓
Storage capacity
        ↓
Reclaim policy
        ↓
Persistence validation
        ↓
Prepare storage for etcd snapshots
```

The result will be a dedicated persistent storage layer ready for the etcd backup CronJob.

# Part 10 — Persistent Storage Configuration

## 386. Objective

The objective of Part 10 is to create and validate the persistent storage that will eventually hold automated etcd snapshots.

The storage architecture is:

```text
                    etcd Backup CronJob
                            │
                            │ writes
                            ▼
                    /backup directory
                            │
                            ▼
                    PersistentVolumeClaim
                            │
                            ▼
                    PersistentVolume
                            │
                            ▼
                      OpenEBS Storage
                            │
                            ▼
                   Underlying Node Storage
```

The backup workload will interact with the PVC.

It should not directly manage:

* Physical disks
* Host directories
* OpenEBS internal data paths
* Linux block devices

---

# 387. Storage Architecture

The Kubernetes cluster currently contains:

```text
Control Plane:
    Master 01
    Master 02
    Master 03

Workers:
    Worker 01
    Worker 02
    Worker 03
```

OpenEBS provides the storage layer.

The future backup architecture is:

```text
                   ┌─────────────────────┐
                   │   etcd Backup       │
                   │      CronJob        │
                   └──────────┬──────────┘
                              │
                              │ mount
                              ▼
                   ┌─────────────────────┐
                   │  etcd-backup-pvc    │
                   │       10Gi          │
                   └──────────┬──────────┘
                              │
                              ▼
                   ┌─────────────────────┐
                   │ Persistent Volume   │
                   └──────────┬──────────┘
                              │
                              ▼
                         OpenEBS
                              │
                              ▼
                     Persistent Storage
```

---

# 388. Why a Dedicated Backup PVC Is Used

The etcd backup data should have a dedicated storage boundary.

Instead of using a generic application PVC:

```text
Application PVC
      │
      └── mixed application data
```

the project will use:

```text
etcd-backup-pvc
      │
      └── etcd snapshots
```

This provides:

* Clear ownership
* Easier retention management
* Easier monitoring
* Easier restore procedures
* Easier storage capacity management
* Reduced risk of unrelated workloads accessing backups

---

# 389. Create the Backup Namespace

Create a dedicated namespace:

```bash id="u7h2k5"
kubectl create namespace etcd-backup
```

Verify:

```bash id="q3m8p1"
kubectl get namespace etcd-backup
```

Expected:

```text
etcd-backup
```

If the namespace already exists:

```bash id="d6n4r9"
kubectl get namespace etcd-backup
```

Do not recreate it.

---

# 390. Select the OpenEBS StorageClass

List StorageClasses:

```bash id="x8p2m6"
kubectl get storageclass
```

For each candidate StorageClass:

```bash id="k4m7q3"
kubectl describe storageclass <STORAGECLASS-NAME>
```

Review:

```text
Provisioner
Reclaim Policy
Volume Binding Mode
Allow Volume Expansion
Parameters
Topology
```

The selected StorageClass should be documented explicitly.

---

# 391. StorageClass Selection Criteria

For the etcd backup workload, evaluate:

| Requirement             | Reason                                              |
| ----------------------- | --------------------------------------------------- |
| Dynamic provisioning    | Automatically create the PV                         |
| Persistent storage      | Snapshots must survive Pod recreation               |
| Appropriate topology    | Storage must be accessible from the backup workload |
| Suitable reclaim policy | Protect backup data from accidental deletion        |
| Adequate capacity       | Store the required number of snapshots              |
| Expansion support       | Allows future capacity growth                       |
| Appropriate replication | Determines resilience against node/storage failure  |

The StorageClass should be selected based on the actual OpenEBS engine being used.

---

# 392. Local vs Replicated Storage

The most important storage design decision is whether the backup volume should use local or replicated storage.

### Local storage

```text
             PVC
              │
              ▼
          OpenEBS
              │
              ▼
          Node A disk
```

If Node A fails, the local volume may become unavailable.

### Replicated storage

```text
                PVC
                 │
                 ▼
             OpenEBS
                 │
          ┌──────┼──────┐
          ▼      ▼      ▼
       Node A  Node B  Node C
```

The storage engine maintains multiple copies according to its configured replication policy.

The actual OpenEBS engine and StorageClass determine which model is used.

---

# 393. Storage Requirement for etcd Backups

The backup system has a different purpose from the etcd database.

etcd itself requires highly available storage and replication through the etcd cluster.

The backup volume is intended to preserve historical snapshots.

Therefore:

```text
etcd HA
    ≠
backup storage HA
```

Both must be designed independently.

---

# 394. Estimate Backup Storage Capacity

Before creating the PVC, estimate the required capacity.

Let:

```text
S = average etcd snapshot size
R = number of retained snapshots
M = metadata/checksum overhead
B = safety buffer
```

Then:

```text
Required Capacity ≈ (S × R) + M + B
```

For example, if:

```text
Average snapshot = 500 MB
Retention = 14 snapshots
```

then:

```text
500 MB × 14
= 7 GB
```

A PVC larger than the calculated minimum should be used to provide operational headroom.

The actual etcd snapshot size should be measured from the deployed cluster rather than assumed.

---

# 395. Measure Current etcd Database Size

On an authorized control-plane node, inspect the etcd data directory:

```bash id="p6m3q8"
sudo du -sh /var/lib/etcd
```

The exact location depends on the kubeadm/etcd configuration.

You can also inspect the etcd database size using version-compatible etcd tooling.

This provides a baseline for backup storage planning.

---

# 396. Determine Snapshot Size

After the backup process is implemented, record the actual snapshot size.

For example:

```text
Snapshot 01 → 420 MB
Snapshot 02 → 430 MB
Snapshot 03 → 435 MB
```

Use actual measurements to refine the PVC size and retention policy.

---

# 397. Create the Backup PVC

Create:

```bash id="m5q8n2"
nano etcd-backup-pvc.yaml
```

Example:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: etcd-backup-pvc
  namespace: etcd-backup
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: <OPENEBS-STORAGECLASS>
  resources:
    requests:
      storage: 10Gi
```

Replace:

```text
<OPENEBS-STORAGECLASS>
```

with the StorageClass selected during the previous step.

The `10Gi` value is an example and should be adjusted according to the actual backup-size calculation.

---

# 398. Apply the PVC

Run:

```bash id="r7m3x9"
kubectl apply -f etcd-backup-pvc.yaml
```

Verify:

```bash id="q5n8p2"
kubectl get pvc -n etcd-backup
```

Expected:

```text
NAME              STATUS   VOLUME
etcd-backup-pvc   Bound    <PV-NAME>
```

---

# 399. Verify PVC Details

Run:

```bash id="x4m7q2"
kubectl describe pvc etcd-backup-pvc -n etcd-backup
```

Review:

```text
Name
Namespace
StorageClass
Status
Volume
Capacity
Access Modes
Events
```

The expected state is:

```text
Status: Bound
```

---

# 400. Verify the PV

Run:

```bash id="k8p3m5"
kubectl get pv
```

Then:

```bash id="n6q2x8"
kubectl describe pv <PV-NAME>
```

Verify:

```text
Capacity
Access Modes
Reclaim Policy
Status
Claim
StorageClass
Provisioner
```

The relationship should be:

```text
etcd-backup-pvc
       │
       ▼
   <PV-NAME>
       │
       ▼
OpenEBS StorageClass
```

---

# 401. Verify StorageClass Binding

Run:

```bash id="m3x7q5"
kubectl get pvc etcd-backup-pvc \
  -n etcd-backup \
  -o jsonpath='{.spec.storageClassName}{"\n"}'
```

Expected:

```text
<OPENEBS-STORAGECLASS>
```

Verify the PV:

```bash id="q8m4p1"
kubectl get pv <PV-NAME> \
  -o jsonpath='{.spec.storageClassName}{"\n"}'
```

Both should reference the intended StorageClass.

---

# 402. Verify PVC Capacity

Run:

```bash id="p7x3m8"
kubectl get pvc etcd-backup-pvc \
  -n etcd-backup \
  -o custom-columns=NAME:.metadata.name,CAPACITY:.status.capacity.storage,REQUESTED:.spec.resources.requests.storage
```

Example:

```text
NAME              CAPACITY   REQUESTED
etcd-backup-pvc   10Gi       10Gi
```

---

# 403. Verify Access Mode

Run:

```bash id="n5m8q2"
kubectl get pvc etcd-backup-pvc \
  -n etcd-backup \
  -o jsonpath='{.status.accessModes}{"\n"}'
```

The example configuration uses:

```text
ReadWriteOnce
```

The correct access mode depends on the selected OpenEBS storage engine and how the backup workload is scheduled.

---

# 404. Why ReadWriteOnce Is Usually Sufficient

The backup workload will normally have a single active Pod writing to the backup volume.

Therefore:

```text
CronJob
   │
   ▼
One active backup Pod
   │
   ▼
RWO PVC
```

is sufficient for many designs.

The backup architecture should prevent multiple concurrent writers to the same snapshot path.

---

# 405. Verify Volume Binding Mode

Run:

```bash id="x7m3q5"
kubectl get storageclass <OPENEBS-STORAGECLASS> \
  -o jsonpath='{.volumeBindingMode}{"\n"}'
```

Possible results include:

```text
Immediate
```

or:

```text
WaitForFirstConsumer
```

The behavior matters because it influences when and where the volume is provisioned.

---

# 406. Understand WaitForFirstConsumer

If the StorageClass uses:

```text
WaitForFirstConsumer
```

the volume provisioning can be delayed until a Pod requiring the PVC is scheduled.

Conceptually:

```text
PVC created
    │
    ▼
No PV yet
    │
    ▼
Backup Pod scheduled
    │
    ▼
Storage topology determined
    │
    ▼
PV provisioned
```

This can be useful for topology-aware storage.

---

# 407. Understand Immediate Binding

If the StorageClass uses:

```text
Immediate
```

the PV can be provisioned as soon as the PVC is created.

Conceptually:

```text
PVC created
    │
    ▼
PV provisioned
    │
    ▼
PVC Bound
    │
    ▼
Pod scheduled
```

Whether this is appropriate depends on the OpenEBS storage engine.

---

# 408. Reclaim Policy

Check:

```bash id="m4q8p2"
kubectl get pv <PV-NAME> \
  -o jsonpath='{.spec.persistentVolumeReclaimPolicy}{"\n"}'
```

Possible values include:

```text
Delete
Retain
```

For backup storage, `Retain` may be appropriate when the underlying volume must survive accidental PVC deletion.

However, `Retain` also means that storage may require manual cleanup.

Therefore, the reclaim policy must be coordinated with the backup retention process.

---

# 409. Backup Retention vs PV Reclaim Policy

These are different concepts.

### Backup retention

Controls:

```text
How long individual snapshot files remain
```

Example:

```text
Delete snapshots older than 14 days
```

### PV reclaim policy

Controls:

```text
What happens to the PersistentVolume after its PVC is deleted
```

Therefore:

```text
Snapshot retention
       ≠
PV reclaim policy
```

Both must be configured separately.

---

# 410. Test Pod for the Backup PVC

Before implementing the actual CronJob, validate the PVC with a temporary Pod.

Create:

```bash id="n7p3m5"
nano backup-storage-test.yaml
```

Example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: backup-storage-test
  namespace: etcd-backup
spec:
  containers:
    - name: test
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          while true; do
            sleep 3600
          done
      volumeMounts:
        - name: backup-storage
          mountPath: /backup

  volumes:
    - name: backup-storage
      persistentVolumeClaim:
        claimName: etcd-backup-pvc
```

Apply:

```bash id="q8m4x2"
kubectl apply -f backup-storage-test.yaml
```

---

# 411. Verify Backup Test Pod

Run:

```bash id="x3p7m5"
kubectl get pod -n etcd-backup -o wide
```

Expected:

```text
backup-storage-test   Running
```

The `NODE` column identifies where the test Pod is scheduled.

---

# 412. Verify PVC Mount

Run:

```bash id="m6q2p8"
kubectl exec -n etcd-backup backup-storage-test \
  -- df -h /backup
```

Then:

```bash id="r4x8n3"
kubectl exec -n etcd-backup backup-storage-test \
  -- mount | grep /backup
```

The PVC should be mounted inside the container at:

```text
/backup
```

---

# 413. Test Backup File Creation

Write a test file:

```bash id="p7m3q5"
kubectl exec -n etcd-backup backup-storage-test \
  -- sh -c 'echo "etcd backup storage test" > /backup/test.txt'
```

Verify:

```bash id="n8x4m2"
kubectl exec -n etcd-backup backup-storage-test \
  -- cat /backup/test.txt
```

Expected:

```text
etcd backup storage test
```

---

# 414. Test Persistence

Delete the test Pod:

```bash id="q5m8x3"
kubectl delete pod backup-storage-test -n etcd-backup
```

Recreate it:

```bash id="x7p2m4"
kubectl apply -f backup-storage-test.yaml
```

Wait:

```bash id="m3q8n6"
kubectl get pod -n etcd-backup
```

Then:

```bash id="p4x7m2"
kubectl exec -n etcd-backup backup-storage-test \
  -- cat /backup/test.txt
```

The file should remain available because the data is stored through the PVC rather than inside the Pod's ephemeral filesystem.

---

# 415. Verify Storage After Pod Recreation

Run:

```bash id="n6m3q8"
kubectl get pvc -n etcd-backup
```

The PVC should remain:

```text
Bound
```

Then:

```bash id="x2p7m4"
kubectl get pv
```

The associated PV should remain bound to the PVC.

---

# 416. Verify Storage Location

Determine the test Pod's node:

```bash id="q8m4x3"
kubectl get pod backup-storage-test \
  -n etcd-backup \
  -o wide
```

Then inspect:

```bash id="p5n7m2"
kubectl describe pv <PV-NAME>
```

Depending on the OpenEBS storage engine, the PV may expose:

* Node affinity
* Topology
* CSI information
* VolumeHandle
* Storage engine-specific metadata

This is how the actual storage placement should be documented.

---

# 417. Do Not Hard-Code the Storage Node

The README should not state:

```text
The etcd backup is stored on Worker 01.
```

unless the selected StorageClass explicitly guarantees that behavior.

Instead:

```text
The backup PVC is dynamically provisioned through the selected
OpenEBS StorageClass. Storage placement is determined by the
OpenEBS storage engine, volume topology, node scheduling, and
StorageClass configuration.
```

---

# 418. Verify Underlying Storage

For the selected OpenEBS engine, inspect its documentation and actual resources to determine the underlying storage path.

At the Kubernetes level, start with:

```bash id="v6m2x8"
kubectl describe pv <PV-NAME>
```

Then inspect the relevant OpenEBS resources:

```bash id="q3n8m5"
kubectl get all -n openebs
```

and:

```bash id="m7x4p2"
kubectl get pods -n openebs -o wide
```

Do not manually modify OpenEBS-managed storage paths.

---

# 419. Storage Capacity Monitoring

Check PVC usage from inside the mounted Pod:

```bash id="x5m8q3"
kubectl exec -n etcd-backup backup-storage-test \
  -- df -h /backup
```

The backup system should eventually monitor:

```text
Total capacity
Used capacity
Available capacity
```

This is particularly important because daily snapshots accumulate over time.

---

# 420. Backup Capacity Calculation

If:

```text
Average snapshot size = S
Retention period = R days
Daily snapshots = 1
Safety factor = F
```

then:

```text
Required storage ≈ S × R × F
```

For example:

```text
Average snapshot = 500 MB
Retention = 14 days
Safety factor = 2

500 MB × 14 × 2
= 14,000 MB
≈ 14 GB
```

A PVC of approximately 20 GiB could then provide additional operational headroom.

This is an example calculation only. Use the actual snapshot size from the cluster.

---

# 421. Snapshot File Naming

The future backup process should use predictable names.

Example:

```text
/backup/daily/
    etcd-snapshot-2026-09-18-020000.db
    etcd-snapshot-2026-09-19-020000.db
    etcd-snapshot-2026-09-20-020000.db
```

The actual CronJob implementation will define the timestamp format.

---

# 422. Backup Metadata

In addition to the snapshot, the backup system can maintain metadata such as:

```text
Snapshot timestamp
Snapshot size
etcd endpoint
etcd revision
Snapshot checksum
Backup status
```

Example directory:

```text
/backup/
├── daily/
│   ├── snapshot-2026-09-18.db
│   └── snapshot-2026-09-19.db
│
├── metadata/
│   ├── snapshot-2026-09-18.json
│   └── snapshot-2026-09-19.json
│
└── checksums/
    ├── snapshot-2026-09-18.sha256
    └── snapshot-2026-09-19.sha256
```

This structure will be finalized in the backup implementation phase.

---

# 423. Backup File Integrity

The backup process should eventually verify the generated snapshot.

A checksum can be created using:

```bash
sha256sum <snapshot-file>
```

Example:

```text
<sha256>  etcd-snapshot-YYYY-MM-DD-HHMMSS.db
```

The checksum can later be used to detect accidental corruption.

---

# 424. Snapshot Validation

A snapshot should not be considered successfully backed up merely because the file exists.

The eventual backup workflow should be:

```text
Create snapshot
      │
      ▼
Verify file exists
      │
      ▼
Verify file size
      │
      ▼
Validate snapshot
      │
      ▼
Generate checksum
      │
      ▼
Store metadata
      │
      ▼
Mark backup successful
```

The exact etcd snapshot-validation command must match the deployed etcd version.

---

# 425. Backup Storage Security

The backup PVC contains Kubernetes cluster state.

Access should therefore be restricted.

The future `etcd-backup` namespace should contain only the resources required by the backup system.

Conceptually:

```text
etcd-backup namespace
        │
        ├── CronJob
        ├── ServiceAccount
        ├── RBAC
        ├── PVC
        └── backup configuration
```

Avoid granting unrelated workloads access to the PVC.

---

# 426. Access Mode and Concurrent Backups

The backup process should prevent overlapping executions.

For a daily CronJob:

```text
Day 1 backup
     │
     ▼
Completed
     │
     ▼
Day 2 backup
```

Avoid:

```text
Backup A ────────────────►
Backup B       ────────────────►
```

writing simultaneously to the same backup directory unless the design explicitly supports concurrent writers.

The CronJob configuration in a later phase should use an appropriate concurrency policy.

---

# 427. PVC Lifecycle

The intended lifecycle is:

```text
Create PVC
    │
    ▼
OpenEBS dynamically provisions PV
    │
    ▼
PVC becomes Bound
    │
    ▼
Backup Pod mounts PVC
    │
    ▼
Snapshots written
    │
    ▼
Snapshots retained/deleted according to policy
```

The PVC should normally remain present for the lifetime of the backup system.

---

# 428. Do Not Delete the PVC During Normal Retention

Deleting:

```bash
kubectl delete pvc etcd-backup-pvc -n etcd-backup
```

should not be part of normal backup rotation.

Retention should remove old snapshot files from the mounted filesystem.

The PVC itself is the persistent storage boundary.

---

# 429. Storage Expansion

Check whether the selected StorageClass supports expansion:

```bash id="m8p3q6"
kubectl get storageclass <OPENEBS-STORAGECLASS> \
  -o jsonpath='{.allowVolumeExpansion}{"\n"}'
```

If:

```text
true
```

the PVC may be expandable.

For example:

```yaml
resources:
  requests:
    storage: 20Gi
```

Expansion should only be performed after confirming that the selected OpenEBS engine supports it and that the filesystem can be expanded safely.

---

# 430. Storage Monitoring

The storage layer should eventually be monitored for:

```text
PVC capacity
PVC usage
PV state
OpenEBS health
Node disk usage
Storage engine health
Backup success/failure
```

Prometheus and Grafana, which will be configured in a later phase, can be used to provide operational visibility.

---

# 431. Troubleshooting — PVC Pending

Run:

```bash id="p7m4x2"
kubectl get pvc -n etcd-backup
```

Then:

```bash id="n8q3m6"
kubectl describe pvc etcd-backup-pvc -n etcd-backup
```

Check events:

```bash id="x5m7p2"
kubectl get events -n etcd-backup --sort-by='.lastTimestamp'
```

Then inspect:

```bash id="q4n8m3"
kubectl get storageclass
```

and:

```bash id="m6x2p7"
kubectl get pods -n openebs -o wide
```

---

# 432. Troubleshooting — PV Not Created

Check:

```bash id="p8m3x6"
kubectl get pv
```

Check the PVC:

```bash id="q5n7m2"
kubectl describe pvc etcd-backup-pvc -n etcd-backup
```

Check OpenEBS:

```bash id="x3m8p4"
kubectl get pods -n openebs
```

Review OpenEBS events:

```bash id="n6q2p8"
kubectl get events -n openebs --sort-by='.lastTimestamp'
```

---

# 433. Troubleshooting — Pod Cannot Mount PVC

Run:

```bash id="m4x7q2"
kubectl describe pod backup-storage-test -n etcd-backup
```

Look for:

```text
FailedMount
FailedAttachVolume
FailedMountVolume
```

Then inspect:

```bash id="p8n3m5"
kubectl describe pvc etcd-backup-pvc -n etcd-backup
```

and:

```bash id="x6q4m8"
kubectl describe pv <PV-NAME>
```

---

# 434. Troubleshooting — OpenEBS Storage Failure

Check:

```bash id="q3m7x5"
kubectl get pods -n openebs -o wide
```

Then:

```bash id="m8p4n2"
kubectl describe pod -n openebs <POD-NAME>
```

Check logs:

```bash id="x5q8m3"
kubectl logs -n openebs <POD-NAME>
```

Inspect the corresponding OpenEBS storage resources according to the selected engine.

---

# 435. Troubleshooting — Disk Full

On the affected node:

```bash id="n7m3q5"
df -h
```

Check inode usage:

```bash id="p4x8m2"
df -i
```

Check block devices:

```bash id="q6m2n8"
lsblk
```

A full underlying filesystem can prevent new volumes or backup writes from succeeding.

---

# 436. Troubleshooting — Backup PVC Full

From the backup Pod:

```bash id="m3x7p8"
df -h /backup
```

If usage is high:

1. Check retention.
2. Identify old snapshots.
3. Verify backup rotation.
4. Expand the PVC if supported.
5. Review the average snapshot size.
6. Recalculate retention capacity.

Do not delete snapshots blindly if they are required for recovery.

---

# 437. Storage Test Cleanup

After completing validation:

```bash id="x8m3q5"
kubectl delete pod backup-storage-test -n etcd-backup
```

The PVC should remain:

```text
Bound
```

Do not delete:

```text
etcd-backup-pvc
```

if it is intended to become the permanent backup volume.

---

# 438. Final Storage Verification

Run:

```bash id="m7q2x5"
kubectl get pvc -n etcd-backup
```

Expected:

```text
NAME              STATUS   VOLUME
etcd-backup-pvc   Bound    <PV-NAME>
```

Run:

```bash id="q4n8m3"
kubectl get pv <PV-NAME>
```

Expected:

```text
STATUS: Bound
```

Verify StorageClass:

```bash id="x6m3p8"
kubectl get pv <PV-NAME> \
  -o custom-columns=NAME:.metadata.name,STORAGECLASS:.spec.storageClassName,RECLAIM:.spec.persistentVolumeReclaimPolicy
```

---

# 439. Storage Validation Checklist

Before proceeding to Part 11:

```text
Namespace
[ ] etcd-backup namespace created
[ ] Namespace verified

StorageClass
[ ] OpenEBS StorageClasses inspected
[ ] Selected StorageClass documented
[ ] Provisioner verified
[ ] Reclaim policy verified
[ ] Volume binding mode verified
[ ] Volume expansion capability verified
[ ] Storage engine identified

PVC
[ ] etcd-backup-pvc created
[ ] PVC is Bound
[ ] Requested capacity verified
[ ] Access mode verified
[ ] StorageClass verified

PV
[ ] PV dynamically provisioned
[ ] PV is Bound
[ ] PV capacity verified
[ ] PV reclaim policy verified
[ ] PV topology/placement investigated

Storage Test
[ ] Test Pod created
[ ] PVC mounted successfully
[ ] Test file written
[ ] Test file read successfully
[ ] Test Pod recreated
[ ] Test file persisted
[ ] Storage remains Bound

Backup Preparation
[ ] Backup capacity estimated
[ ] Snapshot size baseline considered
[ ] Retention capacity considered
[ ] Backup directory planned
[ ] Backup security considered
[ ] Concurrent-write behavior considered
```

---

# 440. Expected Final Architecture

At the end of Part 10:

```text
                              Admin Client
                                   │
                                   │ kubectl / Helm
                                   ▼
                                HAProxy
                                   │
                                   ▼
                         Kubernetes Control Plane
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
              ▼                    ▼                    ▼
          Master 01            Master 02            Master 03
             etcd                 etcd                 etcd
              │                    │                    │
              └────────────────────┼────────────────────┘
                                   │
                                Calico
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
              ▼                    ▼                    ▼
          Worker 01            Worker 02            Worker 03
              │                    │                    │
              └────────────────────┼────────────────────┘
                                   │
                                OpenEBS
                                   │
                            StorageClass
                                   │
                                   ▼
                                  PV
                                   │
                                   ▼
                                  PVC
                                   │
                         etcd-backup-pvc
                                   │
                                   ▼
                         Future Backup CronJob
```

---

# 441. Important Design Principle

The storage layer is now separated into clear responsibilities:

```text
etcd
 │
 ├── Maintains Kubernetes cluster state
 │
 └── Runs as a three-member etcd cluster


OpenEBS
 │
 └── Provides persistent storage


PVC
 │
 └── Represents backup storage requested by Kubernetes


Backup CronJob
 │
 └── Writes and manages etcd snapshots
```

This separation allows the backup implementation to be changed without redesigning the underlying Kubernetes storage layer.

---

# 442. Next Part

## Part 11 — Monitoring with Prometheus and Grafana

The next phase will introduce monitoring for the cluster.

The monitoring architecture will cover:

```text
Kubernetes Nodes
       │
       ▼
Node Metrics
       │
       ▼
Prometheus
       │
       ▼
Grafana
```

Monitoring will eventually be used to observe:

* Node CPU
* Node memory
* Node disk
* Kubernetes resources
* Pod health
* Container health
* etcd health
* OpenEBS health
* Persistent-volume usage
* Backup workload status

The monitoring layer will be especially important later when validating the automated etcd backup system.

# Part 11 — Monitoring with Prometheus and Grafana

## 443. Objective

The objective of Part 11 is to implement a monitoring stack for the Kubernetes cluster using:

* Prometheus
* Grafana
* kube-state-metrics
* Node Exporter
* Prometheus Operator / kube-prometheus-stack

The monitoring architecture will provide visibility into:

```text
Kubernetes Cluster
       │
       ├── Control Plane
       ├── Worker Nodes
       ├── Pods
       ├── Services
       ├── etcd
       ├── OpenEBS
       └── Backup workloads
              │
              ▼
         Prometheus
              │
              ▼
           Grafana
```

Monitoring is particularly important for this project because the later etcd backup system depends on:

* Control-plane availability
* etcd health
* Node health
* Storage availability
* PVC capacity
* CronJob execution
* Backup Pod health

---

# 444. Monitoring Architecture

The monitoring stack is deployed inside Kubernetes.

```text
                         Kubernetes Cluster
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
              ▼                 ▼                 ▼
          Master Nodes      Worker Nodes      Kubernetes API
              │                 │                 │
              ▼                 ▼                 ▼
        Node Exporter      Node Exporter    kube-state-metrics
              │                 │                 │
              └─────────────────┼─────────────────┘
                                │
                                ▼
                           Prometheus
                                │
                                │ PromQL
                                ▼
                             Grafana
                                │
                                ▼
                           Dashboards
```

---

# 445. Monitoring Components

The project uses the following components.

| Component           | Purpose                                         |
| ------------------- | ----------------------------------------------- |
| Prometheus          | Collects and stores time-series metrics         |
| Grafana             | Visualizes metrics and creates dashboards       |
| Node Exporter       | Provides Linux host metrics                     |
| kube-state-metrics  | Exposes Kubernetes object-state metrics         |
| Prometheus Operator | Manages Prometheus-related Kubernetes resources |
| ServiceMonitor      | Defines targets that Prometheus should scrape   |
| PrometheusRule      | Defines alerting/recording rules                |

The exact components installed depend on the selected Helm chart version.

---

# 446. Create Monitoring Namespace

Create a dedicated namespace:

```bash
kubectl create namespace monitoring
```

Verify:

```bash
kubectl get namespace monitoring
```

Expected:

```text
monitoring
```

If the namespace already exists:

```bash
kubectl get namespace monitoring
```

---

# 447. Add the Prometheus Community Helm Repository

Add the Helm repository:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

Update repositories:

```bash
helm repo update
```

Verify:

```bash
helm repo list
```

The repository should appear as:

```text
prometheus-community
```

---

# 448. Select a Chart Version

Before installing the monitoring stack, inspect available versions:

```bash
helm search repo prometheus-community/kube-prometheus-stack --versions
```

Select a tested chart version rather than relying on an unpinned `latest` installation.

Record the selected version in the project documentation.

Example:

```text
Chart:
prometheus-community/kube-prometheus-stack

Chart Version:
<VERSION>

App Version:
<VERSION>
```

The exact version should be selected according to the Kubernetes version and project testing requirements.

---

# 449. Inspect the Helm Chart

Before installation:

```bash
helm show values prometheus-community/kube-prometheus-stack > kube-prometheus-stack-values-reference.yaml
```

This creates a local reference file containing the available configuration options.

Do not blindly modify every available option.

Only configure the components required by the project.

---

# 450. Monitoring Configuration

Create:

```bash
nano monitoring-values.yaml
```

A basic project configuration can start with:

```yaml
grafana:
  enabled: true

prometheus:
  enabled: true

kubeStateMetrics:
  enabled: true

nodeExporter:
  enabled: true
```

The exact values should be adjusted according to the selected chart version.

---

# 451. Install kube-prometheus-stack

Install the stack:

```bash
helm install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring-values.yaml
```

Verify:

```bash
helm list -n monitoring
```

Expected release:

```text
kube-prometheus-stack
```

---

# 452. Verify Monitoring Pods

Run:

```bash
kubectl get pods -n monitoring
```

Depending on the chart version, resources may include:

```text
Prometheus
Grafana
Alertmanager
Node Exporter
kube-state-metrics
Prometheus Operator
```

Wait until the required Pods reach:

```text
Running
```

and the required containers show:

```text
READY
```

---

# 453. Verify All Monitoring Resources

Run:

```bash
kubectl get all -n monitoring
```

Then:

```bash
kubectl get servicemonitor -n monitoring
```

and:

```bash
kubectl get prometheusrule -n monitoring
```

Verify that the expected monitoring resources have been created.

---

# 454. Verify Prometheus Operator

Check:

```bash
kubectl get deployment -n monitoring
```

Identify the Prometheus Operator deployment.

Then:

```bash
kubectl describe deployment -n monitoring <PROMETHEUS-OPERATOR-DEPLOYMENT>
```

The Operator manages Prometheus-related custom resources and configuration.

---

# 455. Verify Prometheus

Check:

```bash
kubectl get prometheus -n monitoring
```

Then:

```bash
kubectl describe prometheus -n monitoring <PROMETHEUS-NAME>
```

Check the Prometheus Pod:

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus
```

The exact labels may vary by chart version.

---

# 456. Verify Grafana

Check:

```bash
kubectl get pods -n monitoring | grep grafana
```

Then:

```bash
kubectl get svc -n monitoring | grep grafana
```

Grafana should have a Kubernetes Service.

---

# 457. Access Grafana

For a local/intranet environment, port-forwarding can be used for initial validation:

```bash
kubectl port-forward \
  -n monitoring \
  svc/<GRAFANA-SERVICE> \
  3000:80
```

Then access:

```text
http://localhost:3000
```

If Grafana is accessed from another machine, use an appropriate internal exposure mechanism such as:

* Ingress
* Internal LoadBalancer
* NodePort

Do not expose Grafana directly to the public Internet unless explicitly required and secured.

---

# 458. Retrieve Grafana Credentials

If the Helm chart creates a Kubernetes Secret for the Grafana administrator password, inspect:

```bash
kubectl get secrets -n monitoring
```

Identify the Grafana Secret:

```bash
kubectl get secret -n monitoring <GRAFANA-SECRET>
```

Retrieve the password using the Secret's configured key.

For example:

```bash
kubectl get secret -n monitoring <GRAFANA-SECRET> \
  -o jsonpath='{.data.<PASSWORD-KEY>}' | base64 -d
```

The exact Secret name and key depend on the chart configuration.

Do not commit Grafana credentials to Git.

---

# 459. Verify Prometheus Targets

Open the Prometheus UI using port-forwarding:

```bash
kubectl port-forward \
  -n monitoring \
  svc/<PROMETHEUS-SERVICE> \
  9090:9090
```

Access:

```text
http://localhost:9090
```

Open:

```text
Status → Targets
```

Targets should include the monitoring endpoints configured by the stack.

Targets should transition to:

```text
UP
```

---

# 460. Verify Prometheus Query

From the Prometheus UI, run:

```promql
up
```

A successful monitoring installation should return active targets.

You can also query:

```promql
count(up)
```

This provides the number of currently discovered targets.

---

# 461. Verify Node Metrics

Query:

```promql
node_uname_info
```

This should return node information from Node Exporter.

CPU utilization can be examined with:

```promql
100 - (
  avg by (instance) (
    rate(node_cpu_seconds_total{mode="idle"}[5m])
  ) * 100
)
```

Memory utilization:

```promql
100 * (
  1 -
  node_memory_MemAvailable_bytes /
  node_memory_MemTotal_bytes
)
```

Disk utilization:

```promql
100 * (
  1 -
  node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"}
  /
  node_filesystem_size_bytes{fstype!~"tmpfs|overlay"}
)
```

These queries can later be incorporated into Grafana dashboards.

---

# 462. Verify Kubernetes Object Metrics

kube-state-metrics exposes Kubernetes object-state information.

Test:

```promql
kube_node_info
```

Then:

```promql
kube_pod_info
```

and:

```promql
kube_persistentvolumeclaim_info
```

These metrics are useful for monitoring:

* Nodes
* Pods
* Deployments
* StatefulSets
* Jobs
* CronJobs
* PVCs
* PVs

---

# 463. Monitor Node Availability

Use:

```promql
kube_node_status_condition{
  condition="Ready",
  status="true"
}
```

This helps identify Kubernetes nodes that are currently Ready.

The project should monitor all six Kubernetes nodes:

```text
master-01
master-02
master-03
worker-01
worker-02
worker-03
```

The external HAProxy and Admin Client are not Kubernetes nodes and therefore will not appear in `kubectl get nodes`.

---

# 464. Monitor Pod Health

A useful query is:

```promql
kube_pod_status_phase
```

For example, Pods in the Pending state can be investigated using:

```promql
kube_pod_status_phase{
  phase="Pending"
} == 1
```

Pod restarts can be examined using:

```promql
rate(kube_pod_container_status_restarts_total[15m])
```

---

# 465. Monitor Kubernetes API Server

The Kubernetes API server is critical because:

```text
Admin Client
     │
     ▼
HAProxy
     │
     ▼
Kubernetes API Server
```

Prometheus should monitor API server metrics where exposed and scraped by the monitoring configuration.

Useful metrics include API request and latency metrics.

For example, inspect available metrics:

```promql
apiserver_request_total
```

If the metric is available:

```promql
rate(apiserver_request_total[5m])
```

can be used to observe API request rates.

---

# 466. Monitor etcd

etcd is one of the most important components in this project.

The cluster contains:

```text
Master 01 → etcd member
Master 02 → etcd member
Master 03 → etcd member
```

The monitoring stack should eventually provide visibility into:

* etcd member availability
* leader status
* database size
* backend commit performance
* WAL/fsync latency
* peer communication
* client request activity

The exact metric names depend on the deployed etcd and Prometheus configuration.

---

# 467. Verify etcd Metrics

First determine whether etcd metrics are being discovered.

In Prometheus, search for:

```text
etcd_
```

Examples of metrics commonly available in etcd monitoring include:

```text
etcd_server_has_leader
etcd_server_leader_changes_seen_total
etcd_mvcc_db_total_size_in_bytes
```

Do not assume that every metric is available until it is confirmed in the actual Prometheus installation.

---

# 468. Monitor etcd Leader

A three-member etcd cluster should have one active leader.

The monitoring objective is to detect:

```text
Leader present
```

versus:

```text
No leader
```

A commonly used metric is:

```promql
etcd_server_has_leader
```

If available:

```promql
etcd_server_has_leader == 0
```

can identify an etcd member that does not currently observe a leader.

The alerting logic should be designed around the cluster's actual metric labels and topology.

---

# 469. Monitor etcd Database Size

The etcd database size should be monitored because it affects:

* Disk consumption
* Snapshot size
* Backup storage requirements
* etcd performance

If available:

```promql
etcd_mvcc_db_total_size_in_bytes
```

can be used to observe database growth.

This value should be compared against:

```text
etcd storage capacity
backup PVC capacity
retention policy
```

---

# 470. Monitor OpenEBS

OpenEBS is responsible for persistent storage used by the project.

The monitoring system should eventually cover:

```text
OpenEBS Pods
Storage engine health
PV health
PVC state
Node storage
Disk utilization
Volume capacity
```

First inspect OpenEBS resources:

```bash
kubectl get pods -n openebs -o wide
```

Then identify which metrics are exposed by the selected OpenEBS engine.

The exact OpenEBS metrics and ServiceMonitor configuration depend on the installed OpenEBS version and storage engine.

---

# 471. Monitor PersistentVolumeClaims

The backup PVC is:

```text
etcd-backup-pvc
```

Check its Kubernetes state:

```bash
kubectl get pvc -n etcd-backup
```

Prometheus can monitor PVC-related metrics exposed by kube-state-metrics.

For example:

```promql
kube_persistentvolumeclaim_status_phase
```

can be used to observe PVC states.

A backup PVC should normally remain:

```text
Bound
```

---

# 472. Monitor PVC Capacity

Storage monitoring should distinguish between:

```text
PVC requested capacity
```

and:

```text
actual filesystem usage
```

Kubernetes object metrics provide information about the PVC itself, while filesystem metrics from the node/storage layer can provide usage information where supported.

This distinction is important because:

```text
PVC = allocated capacity
Filesystem = consumed capacity
```

---

# 473. Monitor CronJobs

The future etcd backup system will run as a Kubernetes CronJob.

Once implemented, the monitoring system should observe:

```text
CronJob schedule
Job creation
Job completion
Job failure
Backup Pod failure
Backup duration
Last successful backup
```

Useful kube-state-metrics metrics may include:

```text
kube_cronjob_info
kube_cronjob_status_last_schedule_time
kube_job_status_failed
kube_job_status_succeeded
```

Metric availability should be confirmed against the installed kube-state-metrics version.

---

# 474. Backup Monitoring Architecture

The final monitoring relationship will be:

```text
                    etcd Cluster
                         │
                         ▼
                    Prometheus
                         │
             ┌───────────┼───────────┐
             │           │           │
             ▼           ▼           ▼
          etcd        OpenEBS      Kubernetes
         metrics      metrics       metrics
             │           │           │
             └───────────┼───────────┘
                         │
                         ▼
                      Grafana
                         │
                         ▼
                   Backup Dashboard
```

---

# 475. Grafana Dashboards

The project should maintain dashboards for:

## Cluster Overview

Display:

```text
Node status
CPU utilization
Memory utilization
Disk utilization
Pod count
Namespace count
```

## Kubernetes Control Plane

Display:

```text
API server availability
API request rate
API latency
Scheduler health
Controller-manager health
etcd health
```

## Worker Nodes

Display:

```text
CPU
Memory
Disk
Network
Pod count
Container restarts
```

## Storage

Display:

```text
PV status
PVC status
PVC capacity
Node disk usage
OpenEBS health
```

## Backup

Display:

```text
Last successful backup
Last failed backup
Backup Job status
Backup duration
Snapshot size
Backup storage usage
Retention status
```

---

# 476. Dashboard Provisioning

Dashboards may be:

* Imported manually
* Created manually
* Provisioned through ConfigMaps
* Provisioned through Grafana configuration
* Managed as code

For a project intended to be reproducible, dashboards should eventually be stored as configuration rather than relying exclusively on manually created dashboards.

Do not commit passwords or API tokens inside dashboard configuration.

---

# 477. Alerting Strategy

Monitoring should eventually generate alerts for important conditions.

Examples:

```text
Node NotReady
etcd has no leader
etcd member unavailable
High CPU
High memory usage
High disk usage
PVC nearly full
OpenEBS component unhealthy
Backup Job failed
Backup did not run
No recent successful backup
```

Not every metric needs an alert.

Alerts should represent conditions requiring operator attention.

---

# 478. Example Backup Alert Concept

Once the backup CronJob exists, an alert can be designed around the time of the last successful backup.

Conceptually:

```text
Current time
      │
      ▼
Last successful backup
      │
      ▼
Age of last backup
      │
      ├── < expected interval → OK
      │
      └── > expected interval → ALERT
```

For a 24-hour backup schedule, the threshold should account for:

* CronJob scheduling
* Pod startup
* Snapshot creation
* Storage latency
* Temporary cluster conditions

The alert should not be configured with an unrealistically tight threshold.

---

# 479. Monitoring Namespace Validation

Run:

```bash
kubectl get pods -n monitoring
```

Then:

```bash
kubectl get svc -n monitoring
```

Then:

```bash
kubectl get servicemonitor -n monitoring
```

Then:

```bash
kubectl get prometheusrule -n monitoring
```

Finally:

```bash
helm status kube-prometheus-stack -n monitoring
```

---

# 480. Monitoring Troubleshooting — Prometheus Pod Not Running

Check:

```bash
kubectl get pods -n monitoring
```

Then:

```bash
kubectl describe pod -n monitoring <PROMETHEUS-POD>
```

Check events:

```bash
kubectl get events -n monitoring --sort-by='.lastTimestamp'
```

Check logs:

```bash
kubectl logs -n monitoring <PROMETHEUS-POD>
```

---

# 481. Monitoring Troubleshooting — Grafana Not Running

Run:

```bash
kubectl get pods -n monitoring | grep grafana
```

Then:

```bash
kubectl describe pod -n monitoring <GRAFANA-POD>
```

Check logs:

```bash
kubectl logs -n monitoring <GRAFANA-POD>
```

Also verify:

```bash
kubectl get svc -n monitoring
```

---

# 482. Monitoring Troubleshooting — Targets Down

In Prometheus:

```text
Status → Targets
```

Identify the failed target.

Then inspect the associated ServiceMonitor:

```bash
kubectl get servicemonitor -A
```

Inspect:

```bash
kubectl describe servicemonitor -n <NAMESPACE> <SERVICEMONITOR>
```

Check the target Service:

```bash
kubectl get svc -n <NAMESPACE>
```

Then check its Endpoints/EndpointSlices:

```bash
kubectl get endpoints -n <NAMESPACE>
```

and:

```bash
kubectl get endpointslice -n <NAMESPACE>
```

---

# 483. Monitoring Troubleshooting — Node Metrics Missing

Check Node Exporter:

```bash
kubectl get pods -n monitoring -o wide | grep node-exporter
```

Because Node Exporter is normally deployed as a DaemonSet, verify that the expected nodes have corresponding Pods.

Run:

```bash
kubectl get daemonset -n monitoring
```

Then:

```bash
kubectl describe daemonset -n monitoring <NODE-EXPORTER-DAEMONSET>
```

---

# 484. Monitoring Troubleshooting — Prometheus Storage

Prometheus itself may require persistent storage if historical metrics must survive Prometheus Pod recreation.

Inspect:

```bash
kubectl get pvc -n monitoring
```

If the selected configuration uses a PVC:

```bash
kubectl describe pvc -n monitoring <PROMETHEUS-PVC>
```

The Prometheus storage design is separate from:

```text
etcd-backup-pvc
```

Do not use the etcd backup PVC for Prometheus data.

---

# 485. Monitoring Storage Separation

The architecture should remain:

```text
Prometheus
    │
    └── Prometheus-specific PVC


etcd Backup
    │
    └── etcd-backup-pvc
```

This prevents monitoring data from being mixed with recovery data.

---

# 486. Resource Consumption

Monitoring itself consumes cluster resources.

Monitor:

```text
Prometheus CPU
Prometheus memory
Grafana CPU
Grafana memory
Node Exporter resources
kube-state-metrics resources
```

Prometheus resource usage generally grows with:

* Number of targets
* Number of scraped series
* Scrape frequency
* Retention period
* Number of recording rules

The project should avoid enabling unnecessary exporters and metrics.

---

# 487. Prometheus Retention

Prometheus stores time-series data for a configured retention period.

Retention should be selected based on:

```text
Available storage
Number of metrics
Operational requirements
Query requirements
```

Prometheus retention is independent of etcd backup retention.

Therefore:

```text
Prometheus retention
        ≠
etcd snapshot retention
```

---

# 488. Security

Grafana and Prometheus should remain internal services.

Recommended architecture:

```text
Admin Client
     │
     │ internal access
     ▼
Grafana
     │
     ▼
Prometheus
```

Avoid exposing Prometheus directly to untrusted networks.

Grafana credentials must be protected.

Monitoring endpoints should not unnecessarily expose sensitive cluster information.

---

# 489. Monitoring Validation

Verify the following:

```text
[ ] monitoring namespace exists
[ ] Helm repository configured
[ ] kube-prometheus-stack installed
[ ] Prometheus Operator running
[ ] Prometheus running
[ ] Grafana running
[ ] kube-state-metrics running
[ ] Node Exporter running on expected nodes
[ ] Prometheus targets discovered
[ ] Prometheus targets are UP
[ ] PromQL queries return data
[ ] Kubernetes node metrics available
[ ] Kubernetes object metrics available
[ ] Grafana accessible
[ ] Grafana can query Prometheus
[ ] Basic dashboards available
[ ] Monitoring storage checked
[ ] Monitoring resources checked
[ ] No credentials committed to Git
```

---

# 490. Final Monitoring Architecture

After Part 11, the project architecture becomes:

```text
                           Admin Client
                                │
                         kubectl / browser
                                │
                                ▼
                             HAProxy
                                │
                                ▼
                     Kubernetes API Endpoint
                                │
          ┌─────────────────────┼─────────────────────┐
          │                     │                     │
          ▼                     ▼                     ▼
      Master 01             Master 02             Master 03
        etcd                   etcd                   etcd
          │                     │                     │
          └─────────────────────┼─────────────────────┘
                                │
                              Calico
                                │
          ┌─────────────────────┼─────────────────────┐
          │                     │                     │
          ▼                     ▼                     ▼
      Worker 01             Worker 02             Worker 03
          │                     │                     │
          └─────────────────────┼─────────────────────┘
                                │
                 ┌──────────────┴──────────────┐
                 │                             │
                 ▼                             ▼
              OpenEBS                     Monitoring
                 │                             │
                 ▼                             ▼
              Storage                     Prometheus
                 │                             │
                 ▼                             ▼
                PVC                         Grafana
                 │
                 ▼
          etcd-backup-pvc
```

---

# 491. Monitoring Responsibilities

The monitoring system now provides visibility into the major infrastructure layers:

```text
Infrastructure
      │
      ▼
Kubernetes Nodes
      │
      ▼
Control Plane
      │
      ▼
etcd
      │
      ▼
OpenEBS
      │
      ▼
Persistent Volumes
      │
      ▼
Backup Workloads
```

The next phases will use this monitoring foundation to observe the etcd backup system.

---

# 492. Next Part

## Part 12 — etcd Architecture

The next phase will document the etcd architecture in detail:

```text
                 Kubernetes Control Plane
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
       Master 01        Master 02        Master 03
          │                │                │
         etcd             etcd             etcd
          │                │                │
          └────────────────┼────────────────┘
                           │
                     etcd Cluster
                           │
                     Leader Election
                           │
                           ▼
                    Future Backup Job
```

Part 12 will explain:

* Three-member etcd topology
* etcd leader election
* quorum
* client and peer ports
* etcd data directory
* kubeadm static Pod architecture
* identifying the current etcd leader
* leader-aware snapshot strategy
* etcd health validation
* relationship between etcd and the Kubernetes API server
* why the backup process must dynamically identify the current leader

# Part 12 — etcd Architecture

## 493. Objective

The objective of Part 12 is to document the etcd architecture used by the Kubernetes cluster and establish the design requirements for automated etcd backups.

The Kubernetes cluster uses a three-member etcd cluster:

```text
                 Kubernetes Control Plane
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
      Master 01        Master 02        Master 03
          │                │                │
        etcd             etcd             etcd
          │                │                │
          └────────────────┼────────────────┘
                           │
                    3-Member etcd
                       Cluster
```

The three etcd members maintain the Kubernetes cluster's persistent state.

---

# 494. Role of etcd in Kubernetes

etcd is the distributed key-value store used by Kubernetes to persist cluster state.

Important Kubernetes information stored in etcd includes:

```text
Namespaces
Pods
Deployments
Services
ConfigMaps
Secrets
Roles
RoleBindings
Nodes
PersistentVolumeClaims
PersistentVolumes
Custom Resources
Cluster configuration
```

The Kubernetes API server communicates with etcd.

Conceptually:

```text
                 kubectl
                    │
                    ▼
             Kubernetes API
                    │
                    ▼
                  etcd
                    │
                    ▼
             Cluster State
```

The API server is the primary interface through which Kubernetes components and administrators interact with cluster state.

---

# 495. Three-Member etcd Architecture

The cluster contains three etcd members:

```text
Master 01
└── etcd member 01

Master 02
└── etcd member 02

Master 03
└── etcd member 03
```

Conceptually:

```text
             ┌─────────────────────┐
             │     etcd Cluster     │
             │                     │
             │  Member 01          │
             │  Member 02          │
             │  Member 03          │
             └─────────────────────┘
```

Each member participates in the distributed consensus protocol.

One member acts as the current leader while the remaining members act as followers.

---

# 496. etcd Leader Election

etcd uses the Raft consensus algorithm.

At any point in time, a healthy three-member cluster normally has:

```text
1 Leader
2 Followers
```

Example:

```text
              etcd Cluster

           ┌───────────────┐
           │   Master 01   │
           │     etcd      │
           │    LEADER     │
           └───────┬───────┘
                   │
          ┌────────┴────────┐
          │                 │
          ▼                 ▼
   ┌──────────────┐  ┌──────────────┐
   │  Master 02   │  │  Master 03   │
   │     etcd     │  │     etcd     │
   │   FOLLOWER   │  │   FOLLOWER   │
   └──────────────┘  └──────────────┘
```

The leader is not permanently associated with a particular master.

For example, after a failure:

```text
Before:

Master 01 → Leader
Master 02 → Follower
Master 03 → Follower


After Master 01 failure:

Master 01 → Unavailable
Master 02 → Leader
Master 03 → Follower
```

Therefore, the backup system must not permanently assume:

```text
Master 01 = etcd Leader
```

---

# 497. Why Leader Detection Matters

The project's backup requirement is leader-aware.

The future backup workflow should determine the current etcd leader dynamically.

Incorrect design:

```text
CronJob
   │
   ▼
Always connect to Master 01
   │
   ▼
Take snapshot
```

This can fail if Master 01 is unavailable or is not the appropriate endpoint at the time of the backup.

The intended design is:

```text
CronJob
   │
   ▼
Discover etcd members
   │
   ▼
Determine current leader
   │
   ▼
Select healthy endpoint
   │
   ▼
Create snapshot
   │
   ▼
Validate snapshot
   │
   ▼
Store snapshot on OpenEBS PVC
```

---

# 498. etcd Client Port

etcd normally exposes the client API on:

```text
2379
```

The Kubernetes API server uses the etcd client interface.

Conceptually:

```text
kube-apiserver
      │
      │ TCP 2379
      ▼
    etcd
```

The exact listen and advertised addresses should be verified from the deployed static Pod configuration.

---

# 499. etcd Peer Port

etcd normally uses:

```text
2380
```

for peer-to-peer cluster communication.

Conceptually:

```text
        etcd Member 01
             │
        TCP 2380
        ┌────┴────┐
        ▼         ▼
 Member 02     Member 03
```

Port 2380 is therefore different from the client port 2379.

---

# 500. etcd Port Summary

| Port | Purpose                 |
| ---- | ----------------------- |
| 2379 | Client communication    |
| 2380 | etcd peer communication |

Kubernetes API server:

| Port | Purpose               |
| ---- | --------------------- |
| 6443 | Kubernetes API server |

HAProxy:

```text
HAProxy :6443
      │
      ├── Master 01 :6443
      ├── Master 02 :6443
      └── Master 03 :6443
```

HAProxy should not be used as the etcd peer communication path.

---

# 501. etcd and HAProxy Separation

The project architecture deliberately separates:

```text
Kubernetes API traffic
```

from:

```text
etcd cluster traffic
```

The API path is:

```text
Admin Client
     │
     ▼
 HAProxy
     │
     ▼
Kubernetes API Server
     │
     ▼
    etcd
```

The etcd peer path is:

```text
Master 01 etcd
      │
      ├──────── Master 02 etcd
      │
      └──────── Master 03 etcd
```

HAProxy does not participate in etcd consensus.

---

# 502. etcd Data Directory

With kubeadm, stacked etcd is normally deployed as a static Pod on each control-plane node.

The etcd data directory is commonly:

```text
/var/lib/etcd
```

Verify on each control-plane node:

```bash
sudo ls -lah /var/lib/etcd
```

Check disk usage:

```bash
sudo du -sh /var/lib/etcd
```

The actual path should always be confirmed from the deployed etcd configuration.

---

# 503. etcd Static Pod

On a kubeadm control-plane node, inspect:

```bash
sudo ls -lah /etc/kubernetes/manifests/
```

You should find:

```text
etcd.yaml
```

Inspect it:

```bash
sudo less /etc/kubernetes/manifests/etcd.yaml
```

The manifest defines the etcd static Pod.

It contains configuration such as:

```text
Image
Command
Client URLs
Peer URLs
Data directory
Certificates
Health checks
```

Do not modify the generated manifest casually.

Incorrect changes can make the control plane unavailable.

---

# 504. Verify etcd Pods

From an administrative client:

```bash
kubectl get pods -n kube-system -l component=etcd -o wide
```

Depending on the kubeadm labels and Kubernetes version, the selector may differ.

A more general check is:

```bash
kubectl get pods -n kube-system -o wide | grep etcd
```

Expected architecture:

```text
etcd-master-01
etcd-master-02
etcd-master-03
```

The exact Pod names depend on the node hostnames.

---

# 505. Verify etcd Member Count

Use an authorized control-plane node and the etcd client tooling compatible with the deployed etcd version.

A typical command is:

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  member list
```

The exact certificate intended for client authentication should be confirmed from the etcd static Pod configuration.

The result should show three members.

Conceptually:

```text
Member 01
Member 02
Member 03
```

---

# 506. Verify etcd Endpoint Health

Check the local etcd endpoint:

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  endpoint health
```

A healthy endpoint should report a successful health check.

Run equivalent checks against the other members where appropriate.

---

# 507. Verify etcd Endpoint Status

Use:

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  endpoint status
```

This can provide information such as:

```text
Endpoint
ID
Version
DB Size
Leader
Raft Term
Raft Index
Raft Applied Index
```

The exact columns depend on the installed etcdctl version.

---

# 508. Identify the Current Leader

The endpoint status output can be used to identify the current leader.

Conceptually:

```text
Endpoint             Leader
--------------------------------
Master 01:2379       Master 02
Master 02:2379       Master 02
Master 03:2379       Master 02
```

This indicates:

```text
Master 02 = current etcd leader
```

The leader may change later.

Therefore, leader detection should happen at backup execution time rather than being permanently configured.

---

# 509. Verify Leader from the Cluster

Run the endpoint status command against all three members.

For example:

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://<MASTER-01>:2379,https://<MASTER-02>:2379,https://<MASTER-03>:2379 \
  --cacert=<ETCD-CA-CERT> \
  --cert=<ETCD-CLIENT-CERT> \
  --key=<ETCD-CLIENT-KEY> \
  endpoint status
```

Use the actual certificates and endpoints from the cluster.

Do not copy credentials into the Git repository.

---

# 510. Quorum

For a three-member etcd cluster:

```text
Total members = 3
Quorum = 2
```

Therefore:

```text
3 healthy members → quorum
2 healthy members → quorum
1 healthy member  → no quorum
```

The cluster can therefore tolerate the failure of one member while retaining quorum.

---

# 511. Quorum Architecture

```text
                  etcd Cluster
                       │
              ┌────────┼────────┐
              │        │        │
              ▼        ▼        ▼
            M01      M02      M03
           etcd     etcd     etcd

             3 Members
                 │
                 ▼
              Quorum = 2
```

If one member fails:

```text
M01 → DOWN
M02 → UP
M03 → UP

Healthy members = 2
Quorum = maintained
```

If two members fail:

```text
M01 → DOWN
M02 → DOWN
M03 → UP

Healthy members = 1
Quorum = lost
```

---

# 512. Why Quorum Matters for Backup

A backup system should not interpret:

```text
One reachable etcd endpoint
```

as automatically meaning:

```text
Healthy etcd cluster
```

The backup workflow should perform health validation before taking a snapshot.

Conceptually:

```text
Discover members
      │
      ▼
Check endpoint health
      │
      ▼
Check cluster status
      │
      ▼
Identify leader
      │
      ▼
Proceed with backup
```

If the cluster is unhealthy, the backup system should fail safely rather than producing a misleading "successful" backup.

---

# 513. etcd Certificates

The kubeadm etcd installation uses TLS.

Common certificate locations include:

```text
/etc/kubernetes/pki/etcd/
```

Inspect:

```bash
sudo ls -lah /etc/kubernetes/pki/etcd/
```

Typical files can include:

```text
ca.crt
ca.key
server.crt
server.key
peer.crt
peer.key
healthcheck-client.crt
healthcheck-client.key
```

The exact files depend on the kubeadm configuration.

---

# 514. Protect etcd Private Keys

Private keys such as:

```text
*.key
```

must be treated as sensitive credentials.

Never commit:

```text
/etc/kubernetes/pki/etcd/*.key
```

to Git.

Do not include them in:

```text
README.md
```

or configuration files stored in the repository.

---

# 515. Backup Authentication

The future backup workload must authenticate securely to etcd.

The backup process will require appropriate TLS material to connect to etcd.

The design should avoid placing private keys directly inside the container image.

Possible mechanisms include Kubernetes Secrets containing the required certificate material, provided access is tightly restricted.

The exact implementation will be covered in Part 13.

---

# 516. etcd Snapshot

An etcd snapshot is a point-in-time representation of the etcd database.

Conceptually:

```text
              etcd
               │
               │ snapshot
               ▼
       etcd-snapshot.db
               │
               ▼
           Backup PVC
               │
               ▼
            OpenEBS
```

The snapshot is separate from the live etcd data directory.

---

# 517. Snapshot vs Live etcd Data

The live database:

```text
/var/lib/etcd
```

belongs to the running etcd member.

The backup:

```text
/backup/etcd-snapshot-<timestamp>.db
```

is an independent recovery artifact.

Therefore:

```text
Live etcd storage
       ≠
Backup storage
```

The backup should not be created by copying the live data directory while etcd is running unless the procedure is specifically supported and designed for that purpose.

Use the etcd-supported snapshot mechanism.

---

# 518. Snapshot Creation Strategy

The project will eventually implement:

```text
CronJob
   │
   ▼
Discover etcd cluster
   │
   ▼
Identify current leader
   │
   ▼
Validate cluster health
   │
   ▼
Create etcd snapshot
   │
   ▼
Validate snapshot
   │
   ▼
Calculate checksum
   │
   ▼
Write snapshot to PVC
```

The implementation will be introduced in Part 13.

---

# 519. Leader-Aware Backup Design

The project requirement is explicitly leader-aware.

The conceptual algorithm is:

```text
START
  │
  ▼
Discover all etcd members
  │
  ▼
Check member health
  │
  ▼
Determine current leader
  │
  ▼
Is leader reachable?
  │
 ┌┴─────────────┐
 │              │
YES             NO
 │              │
 ▼              ▼
Proceed       Re-check
 │
 ▼
Create snapshot
 │
 ▼
Validate snapshot
 │
 ▼
Store on PVC
 │
 ▼
END
```

The implementation must also account for leader changes during execution.

---

# 520. Leader Changes

etcd leadership is dynamic.

For example:

```text
02:00

Master 01 → Leader
Master 02 → Follower
Master 03 → Follower
```

Later:

```text
02:05

Master 01 → Follower
Master 02 → Leader
Master 03 → Follower
```

The backup system should therefore perform leader discovery for each backup execution.

It should not store:

```text
leader = master-01
```

as a permanent configuration value.

---

# 521. Backup Failure During Leader Change

A leader change may occur during snapshot creation.

The backup process should therefore distinguish:

```text
Snapshot command started
```

from:

```text
Snapshot successfully completed and validated
```

Only the latter should be considered a successful backup.

Conceptually:

```text
Snapshot started
      │
      ▼
Leader changes
      │
      ▼
Snapshot command fails
      │
      ▼
Backup marked FAILED
      │
      ▼
Retry according to policy
```

The exact retry behavior will be implemented later.

---

# 522. etcd Endpoint Selection

The backup system should maintain knowledge of the three etcd members:

```text
https://<MASTER-01>:2379
https://<MASTER-02>:2379
https://<MASTER-03>:2379
```

The addresses should correspond to the actual etcd client endpoints configured on the cluster.

The backup process can use endpoint status information to determine:

```text
Healthy endpoint
Leader member
Database status
```

---

# 523. Do Not Use HAProxy for etcd Backup

The backup workload should not be designed as:

```text
Backup Pod
    │
    ▼
HAProxy :6443
    │
    ▼
Kubernetes API
    │
    ▼
etcd
```

That path is unnecessary for taking an etcd snapshot.

The backup workload needs direct authenticated access to the etcd client endpoints or another explicitly designed etcd-access mechanism.

---

# 524. Kubernetes API vs etcd Backup

These are two separate paths:

### Normal Kubernetes administration

```text
Admin Client
      │
      ▼
HAProxy :6443
      │
      ▼
Kubernetes API
```

### etcd backup

```text
Backup Pod
      │
      ▼
etcd client endpoint :2379
      │
      ▼
etcd cluster
```

This distinction is important for the final architecture.

---

# 525. Verify Network Connectivity

From an authorized location, verify etcd client connectivity:

```bash
nc -vz <MASTER-01-IP> 2379
nc -vz <MASTER-02-IP> 2379
nc -vz <MASTER-03-IP> 2379
```

Verify peer connectivity:

```bash
nc -vz <MASTER-01-IP> 2380
nc -vz <MASTER-02-IP> 2380
nc -vz <MASTER-03-IP> 2380
```

These checks only verify TCP connectivity.

They do not prove that the etcd service is healthy.

TLS-aware etcd health checks should also be performed.

---

# 526. Verify etcd Peer Communication

The three members must be able to communicate over the peer network.

Conceptually:

```text
Master 01
   │
   ├── 2380 ── Master 02
   │
   └── 2380 ── Master 03

Master 02
   │
   └── 2380 ── Master 03
```

The actual network addresses depend on the cluster configuration.

---

# 527. Verify etcd from Kubernetes

Check the etcd static Pods:

```bash
kubectl get pods -n kube-system -o wide | grep etcd
```

Check restart counts:

```bash
kubectl get pods -n kube-system -o wide | grep etcd
```

A healthy etcd member should not repeatedly restart.

For a detailed view:

```bash
kubectl describe pod -n kube-system <ETCD-POD>
```

---

# 528. Inspect etcd Logs

For a specific etcd Pod:

```bash
kubectl logs -n kube-system <ETCD-POD>
```

For the previous container instance, if applicable:

```bash
kubectl logs -n kube-system <ETCD-POD> --previous
```

Look for issues involving:

```text
TLS
peer connection
leader election
disk I/O
WAL
database corruption
authentication
timeouts
```

---

# 529. etcd Disk Usage

Check:

```bash
sudo du -sh /var/lib/etcd
```

Also check the underlying filesystem:

```bash
df -h /var/lib/etcd
```

Check inode availability:

```bash
df -i /var/lib/etcd
```

Insufficient disk space can affect etcd operation and therefore Kubernetes availability.

---

# 530. etcd and Backup Storage Are Independent

The project has two separate storage paths:

```text
                 etcd
                  │
                  ▼
          /var/lib/etcd
                  │
                  │ live cluster state
                  ▼
          Control Plane Node
```

and:

```text
              Backup Job
                  │
                  ▼
           etcd-backup-pvc
                  │
                  ▼
              OpenEBS
                  │
                  ▼
          Backup Persistent Data
```

The backup must remain available even if the original etcd member experiences a failure.

---

# 531. Monitoring Relationship

The monitoring stack from Part 11 observes the etcd cluster.

```text
                  etcd
                   │
                   ▼
               Prometheus
                   │
                   ▼
                 Grafana
```

The monitoring system should eventually show:

```text
Member health
Leader state
Database size
Request activity
Latency
Storage-related metrics
```

This provides operational visibility before and after backup execution.

---

# 532. Backup and Monitoring Relationship

The final operational architecture is:

```text
                 etcd Cluster
                     │
          ┌──────────┴──────────┐
          │                     │
          ▼                     ▼
      Prometheus             Backup CronJob
          │                     │
          ▼                     ▼
       Grafana             Leader Detection
                                │
                                ▼
                           etcd Snapshot
                                │
                                ▼
                         etcd-backup-pvc
                                │
                                ▼
                             OpenEBS
```

Monitoring observes the backup system while the backup system protects etcd data.

---

# 533. etcd Failure Scenarios

The backup design must consider:

### Scenario 1 — One member fails

```text
3 → 2 healthy members
```

Quorum remains available.

The backup system should verify cluster health before proceeding.

### Scenario 2 — Two members fail

```text
3 → 1 healthy member
```

Quorum is lost.

The backup system should not assume that the remaining member represents a normally functioning etcd cluster.

### Scenario 3 — Leader changes

The backup system must dynamically identify the new leader.

### Scenario 4 — Backup storage unavailable

The snapshot should not be considered successfully stored until the file has been written and validated on the backup PVC.

---

# 534. etcd Backup Success Criteria

A backup execution should eventually be considered successful only when all required stages complete:

```text
[1] etcd members discovered
        │
        ▼
[2] etcd health validated
        │
        ▼
[3] Leader identified
        │
        ▼
[4] Snapshot created
        │
        ▼
[5] Snapshot file exists
        │
        ▼
[6] Snapshot validated
        │
        ▼
[7] Checksum generated
        │
        ▼
[8] Snapshot stored on PVC
        │
        ▼
[9] Metadata recorded
        │
        ▼
[10] Backup marked successful
```

A failure at any critical stage should cause the backup Job to report failure.

---

# 535. Security Requirements

etcd contains sensitive Kubernetes state.

The backup system therefore requires protection against:

* Unauthorized access
* Snapshot theft
* Accidental deletion
* Credential leakage
* Unauthorized restore
* Storage compromise

The backup PVC should not be mounted by arbitrary workloads.

The backup ServiceAccount should receive only the Kubernetes permissions required by the implementation.

etcd TLS credentials should be protected using an appropriate secret-management mechanism.

---

# 536. Files That Must Not Be Committed

The repository must not contain:

```text
admin.conf
*.key
etcd snapshots
*.db
Kubernetes client certificates
Kubernetes tokens
Tailscale auth keys
Cloud credentials
Passwords
Private SSH keys
```

Example:

```text
DO NOT COMMIT:

etcd-snapshot-2026-09-18.db
admin.conf
etcd/peer.key
etcd/server.key
credentials.yaml
```

Use placeholders in the README.

---

# 537. Recommended Repository Structure

The root repository can contain:

```text
local-cluster-deployment-intranet/
│
├── README.md
│
├── kubernetes/
│   ├── kubeadm/
│   ├── calico/
│   └── storage/
│
├── haproxy/
│   └── haproxy.cfg.example
│
├── monitoring/
│   └── values.yaml
│
├── etcd-backup/
│   ├── namespace.yaml
│   ├── pvc.yaml
│   ├── cronjob.yaml
│   ├── serviceaccount.yaml
│   ├── role.yaml
│   ├── rolebinding.yaml
│   └── configmap.yaml
│
└── .gitignore
```

Actual secrets and backup artifacts must remain outside Git.

---

# 538. Recommended .gitignore Entries

The project should include entries similar to:

```gitignore
# Kubernetes credentials
admin.conf
kubeconfig
*.kubeconfig

# TLS/private keys
*.key
*.pem

# etcd backups
*.db
*.snapshot

# Secrets
secrets.yaml
credentials.yaml

# Local configuration
.env
.env.*

# SSH
*.pem
id_rsa
id_ed25519
```

Review the `.gitignore` carefully so that legitimate project configuration files are not unintentionally excluded.

---

# 539. etcd Architecture Validation Checklist

Before proceeding to Part 13:

```text
etcd Cluster
[ ] Master 01 runs etcd
[ ] Master 02 runs etcd
[ ] Master 03 runs etcd
[ ] Three etcd members confirmed
[ ] etcd Pods are healthy
[ ] etcd client port 2379 verified
[ ] etcd peer port 2380 verified
[ ] etcd peer connectivity verified
[ ] etcd TLS configuration verified

Leader
[ ] Current leader identified
[ ] Leader is not hard-coded
[ ] Leader can change during cluster operation
[ ] Endpoint status can identify leader

Quorum
[ ] Three-member cluster confirmed
[ ] Quorum = 2 understood
[ ] One-member failure scenario understood
[ ] Two-member failure scenario understood

Storage
[ ] /var/lib/etcd location verified
[ ] etcd disk usage checked
[ ] Backup PVC exists
[ ] Backup storage is separate from live etcd storage

Security
[ ] etcd certificates protected
[ ] Private keys not committed
[ ] admin.conf not committed
[ ] etcd snapshots not committed

Monitoring
[ ] Prometheus installed
[ ] etcd metrics investigated
[ ] Grafana available
[ ] etcd health can be monitored
```

---

# 540. Final etcd Architecture

The complete architecture at this stage is:

```text
                         Admin Client
                              │
                              │ kubectl
                              ▼
                           HAProxy
                              │
                           TCP 6443
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
      Master 01           Master 02           Master 03
          │                   │                   │
      kube-apiserver      kube-apiserver      kube-apiserver
          │                   │                   │
          ▼                   ▼                   ▼
        etcd  ◄──────────► etcd  ◄──────────► etcd
          │                   │                   │
          └───────────────────┼───────────────────┘
                              │
                       3-Member Raft
                           Cluster
                              │
                    ┌─────────┴─────────┐
                    │                   │
                 Leader             Followers
                    │
                    ▼
             Future Backup Job
                    │
                    ▼
             etcd Snapshot
                    │
                    ▼
             etcd-backup-pvc
                    │
                    ▼
                 OpenEBS
```

Alongside this:

```text
             Kubernetes Cluster
                    │
                    ▼
                Prometheus
                    │
                    ▼
                 Grafana
                    │
                    ▼
              Observability
```

---

# 541. Key Design Decisions

The project establishes the following etcd design decisions:

1. The cluster uses **three etcd members**.
2. etcd runs on the three Kubernetes control-plane nodes.
3. etcd uses port **2379** for client communication.
4. etcd uses port **2380** for peer communication.
5. Kubernetes API traffic uses **6443** and is load-balanced by the external HAProxy.
6. HAProxy does not participate in etcd consensus.
7. etcd leader election is dynamic.
8. The backup system must dynamically determine the current leader.
9. Backup storage is separate from live etcd storage.
10. Backup snapshots will be stored on the OpenEBS-backed PVC.
11. Snapshot existence alone does not constitute backup success.
12. Snapshot validation and integrity verification are required.
13. Backup credentials and etcd private keys must be protected.
14. Backup retention will be implemented separately from the PV reclaim policy.

---

# 542. Next Part

## Part 13 — etcd Backup Implementation

Part 13 will implement the actual backup mechanism.

The workflow will become:

```text
                    Kubernetes CronJob
                           │
                           ▼
                  Leader Detection
                           │
                           ▼
                  etcd Health Check
                           │
                           ▼
                  etcd Snapshot
                           │
                           ▼
                  Snapshot Validation
                           │
                           ▼
                     SHA-256 Checksum
                           │
                           ▼
                   OpenEBS PVC
                           │
                           ▼
                    Backup Storage
```

Part 13 will cover:

* etcd backup container design
* etcdctl/etcdutl compatibility
* TLS authentication
* discovering etcd members
* determining the current leader
* creating the snapshot
* validating the snapshot
* generating checksums
* writing metadata
* handling failures
* Kubernetes Secret design
* ServiceAccount requirements
* backup directory structure
* manual backup testing before converting the process into a 24-hour CronJob

# Part 13 — etcd Backup Implementation

## 543. Objective

The objective of Part 13 is to implement a reliable etcd snapshot backup mechanism for the three-member Kubernetes control-plane cluster.

The backup process will:

1. Discover the etcd members.
2. Check etcd health.
3. Identify the current etcd leader.
4. Connect securely using TLS.
5. Create an etcd snapshot.
6. Validate the generated snapshot.
7. Generate a checksum.
8. Store the snapshot on the OpenEBS-backed PVC.
9. Record backup metadata.
10. Return a failure status if any critical step fails.

The architecture is:

```text
                  etcd Cluster
                       │
                       ▼
                Leader Detection
                       │
                       ▼
                 Health Check
                       │
                       ▼
               Snapshot Creation
                       │
                       ▼
              Snapshot Validation
                       │
                       ▼
                 SHA-256 Hash
                       │
                       ▼
                Backup Directory
                       │
                       ▼
              etcd-backup-pvc
                       │
                       ▼
                    OpenEBS
```

---

# 544. Backup Design Principles

The backup implementation follows these principles:

```text
[1] Do not hard-code the etcd leader
[2] Do not copy /var/lib/etcd directly
[3] Use the supported etcd snapshot mechanism
[4] Use TLS authentication
[5] Validate the generated snapshot
[6] Store backups outside the live etcd data directory
[7] Keep backup storage separate from Prometheus storage
[8] Do not store credentials in Git
[9] Do not consider a file-exists check sufficient
[10] Fail the backup Job when a critical operation fails
```

---

# 545. Backup Architecture

The three etcd members are:

```text
Master 01
└── etcd-01

Master 02
└── etcd-02

Master 03
└── etcd-03
```

The backup system will communicate with the etcd client interfaces:

```text
https://<MASTER-01>:2379
https://<MASTER-02>:2379
https://<MASTER-03>:2379
```

The backup workload will run inside Kubernetes.

```text
                    Kubernetes
                        │
                        ▼
                 Backup Pod
                        │
              ┌─────────┴─────────┐
              │                   │
              ▼                   ▼
         etcd endpoints       Backup PVC
              │                   │
              ▼                   ▼
        etcd Cluster           OpenEBS
```

---

# 546. Important: Backup Pod Placement

The backup Pod is not an etcd member.

It is a Kubernetes workload.

Therefore:

```text
Backup Pod
     ≠
etcd Pod
```

The backup Pod may run on a worker node or, depending on the scheduling design, another eligible Kubernetes node.

The Pod should not require the physical host's `/var/lib/etcd` directory.

Instead, it communicates with etcd through the authenticated etcd client API.

---

# 547. Why the Backup Pod Does Not Copy `/var/lib/etcd`

The live etcd database is managed by etcd itself.

Avoid:

```text
Backup Pod
    │
    ▼
/var/lib/etcd
    │
    ▼
Copy database files
```

while etcd is running.

Instead:

```text
Backup Pod
    │
    ▼
etcd snapshot API
    │
    ▼
Snapshot file
    │
    ▼
OpenEBS PVC
```

This uses the supported etcd backup mechanism.

---

# 548. etcd Tooling

The backup process requires an etcd client utility compatible with the deployed etcd version.

Depending on the etcd version, this may involve:

```text
etcdctl
```

and/or:

```text
etcdutl
```

Before implementing the container, verify the versions on the cluster:

```bash
etcdctl version
```

and, if available:

```bash
etcdutl version
```

Also inspect the etcd image used by the cluster:

```bash
kubectl get pod -n kube-system <ETCD-POD> \
  -o jsonpath='{.spec.containers[0].image}{"\n"}'
```

The backup image should use tooling compatible with the deployed etcd version.

---

# 549. Verify etcdctl API Version

For etcd v3:

```bash
export ETCDCTL_API=3
```

Verify:

```bash
echo $ETCDCTL_API
```

Expected:

```text
3
```

For the Kubernetes cluster, all backup operations should use the v3 API.

---

# 550. Verify etcd Endpoints

On a control-plane node, inspect the etcd static Pod:

```bash
sudo grep -E \
  -- '--listen-client-urls|--advertise-client-urls|--listen-peer-urls|--initial-advertise-peer-urls' \
  /etc/kubernetes/manifests/etcd.yaml
```

This identifies the actual URLs configured for the member.

Do not blindly use:

```text
127.0.0.1:2379
```

from the backup Pod.

`127.0.0.1` inside a Pod refers to the Pod itself, not the control-plane node.

---

# 551. Define the Backup Endpoints

For the project, document the actual etcd client endpoints as:

```text
ETCD_ENDPOINT_01=https://<MASTER-01-ETCD-IP>:2379
ETCD_ENDPOINT_02=https://<MASTER-02-ETCD-IP>:2379
ETCD_ENDPOINT_03=https://<MASTER-03-ETCD-IP>:2379
```

The values must match the actual cluster configuration.

Example:

```text
https://<MASTER-01-IP>:2379
https://<MASTER-02-IP>:2379
https://<MASTER-03-IP>:2379
```

Do not use HAProxy's Kubernetes API endpoint for these values.

---

# 552. TLS Authentication

The etcd cluster uses TLS.

The backup client therefore requires:

```text
CA certificate
Client certificate
Client private key
```

Conceptually:

```text
Backup Pod
    │
    ├── ca.crt
    ├── client.crt
    └── client.key
    │
    ▼
etcd :2379
```

The exact certificate intended for backup-client authentication must be verified from the deployed etcd configuration.

---

# 553. Inspect Existing etcd Certificates

On an authorized control-plane node:

```bash
sudo ls -lah /etc/kubernetes/pki/etcd/
```

Inspect the etcd static Pod configuration:

```bash
sudo grep -E \
  -- '--trusted-ca-file|--cert-file|--key-file|--peer-trusted-ca-file|--peer-cert-file|--peer-key-file' \
  /etc/kubernetes/manifests/etcd.yaml
```

This helps determine which certificates are being used.

---

# 554. Do Not Copy the CA Private Key

The backup workload does not need the etcd CA private key.

Do not copy:

```text
ca.key
```

into the backup container.

The backup workload should receive only the credentials required for TLS client authentication.

Conceptually:

```text
Required:
    ca.crt
    client.crt
    client.key

Not required:
    ca.key
```

---

# 555. Kubernetes Secret for TLS Credentials

The TLS material should eventually be provided to the backup Pod through a Kubernetes Secret.

Create a dedicated Secret rather than embedding private keys into:

```text
Dockerfile
ConfigMap
CronJob YAML
Git repository
```

The Secret should be restricted to the backup workload.

---

# 556. Create Backup Namespace

If not already created in Part 10:

```bash
kubectl create namespace etcd-backup
```

Verify:

```bash
kubectl get namespace etcd-backup
```

---

# 557. Create etcd TLS Secret

Assuming the required client certificate files have been identified:

```bash
kubectl create secret generic etcd-backup-tls \
  -n etcd-backup \
  --from-file=ca.crt=<PATH-TO-CA-CERT> \
  --from-file=client.crt=<PATH-TO-CLIENT-CERT> \
  --from-file=client.key=<PATH-TO-CLIENT-KEY>
```

Verify:

```bash
kubectl get secret etcd-backup-tls -n etcd-backup
```

Do not print the Secret contents.

Do not commit the command containing real private-key paths or credential material into public documentation if those paths expose sensitive information.

---

# 558. Verify Secret Keys

Run:

```bash
kubectl get secret etcd-backup-tls \
  -n etcd-backup \
  -o jsonpath='{.data}' | tr ',' '\n'
```

A safer metadata check is:

```bash
kubectl describe secret etcd-backup-tls -n etcd-backup
```

The Secret should contain the expected keys:

```text
ca.crt
client.crt
client.key
```

`kubectl describe secret` does not display the decoded Secret values.

---

# 559. Secret Security

Restrict access to the Secret.

The backup ServiceAccount should be the only workload identity that needs access to the credentials.

The project should avoid giving broad access such as:

```text
get secrets in all namespaces
```

The required RBAC permissions should be defined as narrowly as possible.

---

# 560. Backup Directory

The PVC will be mounted at:

```text
/backup
```

The backup directory structure will be:

```text
/backup/
├── snapshots/
├── metadata/
└── checksums/
```

Therefore:

```text
/backup/snapshots/
    etcd-snapshot-<timestamp>.db

/backup/metadata/
    etcd-snapshot-<timestamp>.json

/backup/checksums/
    etcd-snapshot-<timestamp>.sha256
```

---

# 561. Create Backup Storage Directory

The backup Pod can initialize the directory structure:

```bash
mkdir -p /backup/snapshots
mkdir -p /backup/metadata
mkdir -p /backup/checksums
```

The directories should be created automatically by the backup process rather than requiring manual intervention.

---

# 562. Backup Timestamp

Use UTC timestamps for backup filenames to avoid ambiguity across nodes and environments.

Example:

```text
etcd-snapshot-2026-09-18T02-00-00Z.db
```

A filename-safe timestamp format should be used.

The timestamp should be generated by the backup process at execution time.

---

# 563. Leader Discovery

The backup process should query all configured etcd endpoints.

Conceptually:

```text
Endpoint 1 ──┐
Endpoint 2 ──┼──► endpoint status
Endpoint 3 ──┘
                    │
                    ▼
              Leader information
```

A typical command is:

```bash
ETCDCTL_API=3 etcdctl endpoint status \
  --endpoints="<ENDPOINT-1>,<ENDPOINT-2>,<ENDPOINT-3>" \
  --cacert=/etc/etcd-tls/ca.crt \
  --cert=/etc/etcd-tls/client.crt \
  --key=/etc/etcd-tls/client.key \
  --write-out=table
```

The exact output format depends on the etcdctl version.

---

# 564. Identify the Leader

The endpoint-status result can expose a leader identifier.

Conceptually:

```text
Endpoint                  ID          Leader
------------------------------------------------
https://master-01:2379    12345       67890
https://master-02:2379    67890       67890
https://master-03:2379    54321       67890
```

The member whose:

```text
ID == Leader
```

is the current leader.

The actual output should be interpreted using the installed etcdctl version.

---

# 565. Leader Detection Must Be Dynamic

Do not create:

```text
LEADER_ENDPOINT=https://master-01:2379
```

as a permanent configuration value.

Instead:

```text
ETCD_ENDPOINTS
      │
      ▼
endpoint status
      │
      ▼
current leader ID
      │
      ▼
matching endpoint
```

The leader can change at any time.

---

# 566. Health Check

Before taking the snapshot:

```bash
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints="<ENDPOINT-1>,<ENDPOINT-2>,<ENDPOINT-3>" \
  --cacert=/etc/etcd-tls/ca.crt \
  --cert=/etc/etcd-tls/client.crt \
  --key=/etc/etcd-tls/client.key
```

The backup process should verify that the cluster is sufficiently healthy before proceeding.

---

# 567. Health Check Failure

If the health check fails:

```text
Do not:
    create a misleading successful backup

Instead:
    log the failure
    exit with non-zero status
    allow the Job to be marked failed
```

Conceptually:

```text
Health Check
     │
     ├── Healthy ──► Continue
     │
     └── Unhealthy ──► FAIL BACKUP
```

---

# 568. Snapshot Creation

Once the endpoint is selected and authenticated, create the snapshot using the supported etcd snapshot command for the deployed etcd version.

A typical etcdctl v3 pattern is:

```bash
ETCDCTL_API=3 etcdctl snapshot save \
  /backup/snapshots/etcd-snapshot-<TIMESTAMP>.db \
  --endpoints="<SELECTED-ENDPOINT>" \
  --cacert=/etc/etcd-tls/ca.crt \
  --cert=/etc/etcd-tls/client.crt \
  --key=/etc/etcd-tls/client.key
```

The exact snapshot command should be verified against the installed etcd tooling before production use.

---

# 569. Snapshot Output

After a successful snapshot, verify:

```bash
ls -lh /backup/snapshots/
```

Expected:

```text
etcd-snapshot-<TIMESTAMP>.db
```

The file size should be greater than zero.

---

# 570. File Existence Is Not Enough

This check:

```bash
test -s /backup/snapshots/<SNAPSHOT>.db
```

only proves that a non-empty file exists.

It does not prove that the snapshot is valid.

The backup process must perform an etcd-supported snapshot validation step.

---

# 571. Snapshot Validation

Use the snapshot validation functionality appropriate for the deployed etcd version.

Modern etcd releases may provide snapshot inspection through:

```bash
etcdutl snapshot status <SNAPSHOT>
```

Older workflows may use:

```bash
etcdctl snapshot status <SNAPSHOT>
```

Do not hard-code one command until the installed etcd version has been verified.

The validation should confirm that the generated file is a valid etcd snapshot.

---

# 572. Snapshot Metadata

Record useful metadata after successful validation.

Example:

```json
{
  "timestamp": "YYYY-MM-DDTHH:MM:SSZ",
  "snapshot_file": "etcd-snapshot-<TIMESTAMP>.db",
  "endpoint": "https://<ETCD-ENDPOINT>:2379",
  "status": "successful"
}
```

Additional fields can be added based on information available from the snapshot-status command.

Do not store TLS private keys or other credentials in the metadata.

---

# 573. Generate SHA-256 Checksum

After snapshot validation:

```bash
sha256sum \
  /backup/snapshots/<SNAPSHOT>.db \
  > /backup/checksums/<SNAPSHOT>.sha256
```

Verify:

```bash
cat /backup/checksums/<SNAPSHOT>.sha256
```

The checksum provides an integrity reference.

---

# 574. Verify the Checksum

Run:

```bash
cd /backup/snapshots
sha256sum -c ../checksums/<SNAPSHOT>.sha256
```

Expected:

```text
<SNAPSHOT>: OK
```

The backup process should perform this validation before reporting success.

---

# 575. Backup Completion Criteria

The backup should be marked successful only when:

```text
[1] etcd endpoints discovered
        │
        ▼
[2] Health check successful
        │
        ▼
[3] Leader identified
        │
        ▼
[4] Snapshot created
        │
        ▼
[5] Snapshot is non-empty
        │
        ▼
[6] Snapshot validated
        │
        ▼
[7] Checksum generated
        │
        ▼
[8] Checksum verified
        │
        ▼
[9] Metadata written
        │
        ▼
[10] Backup successful
```

---

# 576. Backup Failure Criteria

The backup process should exit with a non-zero status if:

```text
etcd endpoints are unreachable
TLS authentication fails
cluster health check fails
leader cannot be determined
snapshot creation fails
snapshot file is empty
snapshot validation fails
checksum generation fails
checksum verification fails
backup storage cannot be written
metadata cannot be written
```

This allows Kubernetes Job/CronJob status to reflect the actual backup result.

---

# 577. Backup Script

Create a dedicated script:

```bash
mkdir -p etcd-backup
nano etcd-backup/backup.sh
```

A production implementation should contain logic similar to:

```text
START

Read etcd endpoints

Create backup directories

Check etcd health

Query endpoint status

Determine current leader

Select healthy endpoint

Generate timestamp

Create snapshot

Verify snapshot exists

Validate snapshot

Generate checksum

Verify checksum

Write metadata

Report success

EXIT 0
```

For any critical failure:

```text
Log error
EXIT non-zero
```

The exact parsing logic for leader detection should be implemented against the actual `etcdctl endpoint status` output produced by the installed version.

---

# 578. Backup Container

The backup script should run inside a purpose-built container.

Conceptually:

```text
Backup Container
├── etcdctl / etcdutl
├── backup.sh
└── required shell utilities
```

The container should not contain:

```text
etcd private keys
admin.conf
Kubernetes credentials
Tailscale credentials
```

Runtime credentials should be injected through Kubernetes Secrets.

---

# 579. Example Dockerfile Structure

A project-specific image can be structured as:

```dockerfile
FROM <ETCD-COMPATIBLE-BASE-IMAGE>

COPY backup.sh /usr/local/bin/backup.sh

RUN chmod +x /usr/local/bin/backup.sh

ENTRYPOINT ["/usr/local/bin/backup.sh"]
```

The base image and etcd utility version should be pinned to a version compatible with the cluster.

Avoid:

```dockerfile
FROM latest
```

for a production backup implementation.

---

# 580. Build the Backup Image

After creating the Dockerfile:

```bash
docker build -t <REGISTRY>/etcd-backup:<VERSION> .
```

Example structure:

```text
<REGISTRY>/etcd-backup:v1
```

If the cluster cannot pull from an external registry, the image must be made available through the project's internal image distribution mechanism.

---

# 581. Image Versioning

Use explicit versions:

```text
etcd-backup:v1.0.0
```

rather than:

```text
etcd-backup:latest
```

This makes backup behavior reproducible.

Document:

```text
Backup image version
etcdctl/etcdutl version
etcd cluster version
```

---

# 582. Mount the TLS Secret

The future backup Pod should mount the Secret as files.

Conceptually:

```yaml
volumes:
  - name: etcd-tls
    secret:
      secretName: etcd-backup-tls
```

Then:

```yaml
volumeMounts:
  - name: etcd-tls
    mountPath: /etc/etcd-tls
    readOnly: true
```

The backup container can then access:

```text
/etc/etcd-tls/ca.crt
/etc/etcd-tls/client.crt
/etc/etcd-tls/client.key
```

---

# 583. Mount the Backup PVC

The backup Pod also mounts:

```yaml
volumes:
  - name: backup-storage
    persistentVolumeClaim:
      claimName: etcd-backup-pvc
```

and:

```yaml
volumeMounts:
  - name: backup-storage
    mountPath: /backup
```

The resulting container filesystem is:

```text
/etc/etcd-tls/
    ca.crt
    client.crt
    client.key

/backup/
    snapshots/
    metadata/
    checksums/
```

---

# 584. Read-Only TLS Mount

The TLS Secret should be mounted:

```yaml
readOnly: true
```

The backup process only needs to read the certificates and private key.

It does not need to modify them.

---

# 585. ServiceAccount

Create a dedicated ServiceAccount:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: etcd-backup
  namespace: etcd-backup
```

Apply:

```bash
kubectl apply -f serviceaccount.yaml
```

Verify:

```bash
kubectl get serviceaccount etcd-backup -n etcd-backup
```

---

# 586. Minimize Kubernetes Permissions

The backup process primarily communicates with etcd directly.

It does not need cluster-admin permissions merely to create an etcd snapshot.

Therefore, avoid:

```text
cluster-admin
```

for the backup ServiceAccount.

If the backup process needs to access Kubernetes Secrets or other Kubernetes API resources, grant only the minimum required permissions.

---

# 587. Important Distinction: etcd Access vs Kubernetes API Access

There are two separate authentication systems:

```text
Kubernetes API
    │
    └── Kubernetes RBAC


etcd
    │
    └── etcd TLS authentication/authorization
```

A Kubernetes ServiceAccount does not automatically grant access to etcd.

The backup workload therefore requires appropriate etcd TLS credentials separately.

---

# 588. Manual Backup Test

Before creating the CronJob, run the backup process manually.

This is important because debugging a CronJob adds unnecessary complexity.

The sequence should be:

```text
Manual backup
      │
      ▼
Verify snapshot
      │
      ▼
Verify storage
      │
      ▼
Verify restore-readiness
      │
      ▼
Convert to CronJob
```

---

# 589. Manual Backup Pod

Create a temporary Pod using the backup image.

Conceptually:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: etcd-backup-test
  namespace: etcd-backup
spec:
  serviceAccountName: etcd-backup

  restartPolicy: Never

  containers:
    - name: backup
      image: <ETCD-BACKUP-IMAGE>:<VERSION>

      volumeMounts:
        - name: backup-storage
          mountPath: /backup

        - name: etcd-tls
          mountPath: /etc/etcd-tls
          readOnly: true

  volumes:
    - name: backup-storage
      persistentVolumeClaim:
        claimName: etcd-backup-pvc

    - name: etcd-tls
      secret:
        secretName: etcd-backup-tls
```

The exact environment variables for the etcd endpoints should be added according to the implementation.

---

# 590. Execute the Manual Backup

Apply:

```bash
kubectl apply -f etcd-backup-test.yaml
```

Check:

```bash
kubectl get pod -n etcd-backup
```

Inspect logs:

```bash
kubectl logs -n etcd-backup etcd-backup-test
```

The expected log flow is approximately:

```text
Starting etcd backup
Checking etcd health
Discovering etcd leader
Leader identified
Creating snapshot
Validating snapshot
Generating checksum
Writing metadata
Backup completed successfully
```

The actual output depends on the implementation.

---

# 591. Verify Snapshot on the PVC

After successful execution:

```bash
kubectl run backup-inspector \
  -n etcd-backup \
  --image=busybox:1.36 \
  --restart=Never \
  --command -- sleep 3600
```

Then mount the PVC using an appropriate temporary Pod if necessary and inspect:

```bash
ls -lh /backup/snapshots/
```

Verify:

```text
Snapshot exists
Snapshot is non-zero
Checksum exists
Metadata exists
```

---

# 592. Verify Snapshot Metadata

Inspect:

```bash
ls -lh /backup/metadata/
```

Then:

```bash
cat /backup/metadata/<METADATA-FILE>
```

Verify:

```text
Timestamp
Snapshot filename
Selected endpoint/leader information
Backup status
```

Do not include credentials in metadata.

---

# 593. Verify Checksum

Run:

```bash
sha256sum -c /backup/checksums/<SNAPSHOT>.sha256
```

Expected:

```text
OK
```

This verifies that the snapshot has not changed since the checksum was generated.

---

# 594. Verify Snapshot Validation

Run the version-compatible snapshot inspection command.

For example:

```bash
etcdutl snapshot status \
  /backup/snapshots/<SNAPSHOT>.db
```

or, where appropriate for the installed tooling:

```bash
etcdctl snapshot status \
  /backup/snapshots/<SNAPSHOT>.db
```

Use the command supported by the exact etcd tool version packaged in the backup image.

---

# 595. Test Backup After Pod Deletion

Delete the backup test Pod:

```bash
kubectl delete pod etcd-backup-test -n etcd-backup
```

The snapshot must remain on the PVC.

Verify using another temporary Pod that mounts:

```text
etcd-backup-pvc
```

This confirms:

```text
Backup Pod lifecycle
        ≠
Backup data lifecycle
```

---

# 596. Test Second Backup

Run the backup process again.

The directory should contain multiple snapshots:

```text
/backup/snapshots/
├── etcd-snapshot-<TIME-1>.db
└── etcd-snapshot-<TIME-2>.db
```

Each should have its corresponding:

```text
checksum
metadata
```

This validates that the storage design supports multiple backup generations.

---

# 597. Prevent Snapshot Overwriting

Snapshot filenames should contain a sufficiently precise timestamp.

Avoid:

```text
/backup/etcd.db
```

because every execution would overwrite the same file.

Prefer:

```text
/backup/snapshots/etcd-snapshot-<TIMESTAMP>.db
```

This supports retention and historical recovery.

---

# 598. Backup Logging

The backup script should log important events.

Recommended messages:

```text
Backup started
Endpoints discovered
Health check completed
Leader identified
Snapshot creation started
Snapshot creation completed
Snapshot validation completed
Checksum generated
Checksum verified
Metadata written
Backup completed
```

Failures should clearly identify the failed stage.

Example:

```text
ERROR: etcd health check failed
```

rather than:

```text
ERROR: backup failed
```

without additional context.

---

# 599. Exit Codes

The backup script should use meaningful process status.

Success:

```text
exit 0
```

Failure:

```text
exit 1
```

or another non-zero exit code.

Kubernetes Jobs use the container exit status to determine whether the Job succeeded or failed.

This becomes important when the backup is converted into a CronJob.

---

# 600. Backup Workflow

The complete implementation is:

```text
                  Backup Container
                         │
                         ▼
               Load configuration
                         │
                         ▼
                Create directories
                         │
                         ▼
                 Health check etcd
                         │
                         ▼
               Query endpoint status
                         │
                         ▼
                 Identify leader
                         │
                         ▼
              Select valid endpoint
                         │
                         ▼
                 Create snapshot
                         │
                         ▼
              Validate snapshot
                         │
                         ▼
                Generate SHA-256
                         │
                         ▼
                 Verify checksum
                         │
                         ▼
                 Write metadata
                         │
                         ▼
                  Backup SUCCESS
```

Failure at a critical stage:

```text
                  Backup FAILURE
                         │
                         ▼
                   exit non-zero
                         │
                         ▼
                    Job FAILED
```

---

# 601. Backup Data Layout

After successful backups:

```text
/backup/
│
├── snapshots/
│   ├── etcd-snapshot-2026-09-18T020000Z.db
│   ├── etcd-snapshot-2026-09-19T020000Z.db
│   └── etcd-snapshot-2026-09-20T020000Z.db
│
├── checksums/
│   ├── etcd-snapshot-2026-09-18T020000Z.sha256
│   ├── etcd-snapshot-2026-09-19T020000Z.sha256
│   └── etcd-snapshot-2026-09-20T020000Z.sha256
│
└── metadata/
    ├── etcd-snapshot-2026-09-18T020000Z.json
    ├── etcd-snapshot-2026-09-19T020000Z.json
    └── etcd-snapshot-2026-09-20T020000Z.json
```

This structure makes retention and troubleshooting easier.

---

# 602. What the Backup Does Not Do

The backup process does not:

```text
Modify etcd cluster membership
Modify etcd leader election
Modify the live etcd database
Modify Kubernetes API configuration
Modify HAProxy
Modify OpenEBS configuration
Delete the live etcd database
```

Its primary purpose is:

```text
Read etcd state
     │
     ▼
Create snapshot
     │
     ▼
Persist snapshot
```

---

# 603. Failure Scenario — No etcd Leader

If endpoint status indicates that no leader exists:

```text
etcd member 01 → no leader
etcd member 02 → no leader
etcd member 03 → no leader
```

the backup should fail.

Do not create a backup marked as successful.

The failure should be visible through:

```text
Job status
Pod logs
Prometheus
Grafana
```

once the CronJob and alerting system are implemented.

---

# 604. Failure Scenario — One Member Down

Example:

```text
Master 01 → DOWN
Master 02 → LEADER
Master 03 → FOLLOWER
```

The remaining cluster may still maintain quorum.

The backup system should:

```text
Discover members
      │
      ▼
Identify healthy endpoints
      │
      ▼
Identify current leader
      │
      ▼
Proceed if cluster health criteria are satisfied
```

It should not blindly fail simply because one configured endpoint is unavailable if the configured health policy permits operation with the remaining healthy cluster.

The precise health policy should be documented in the production implementation.

---

# 605. Failure Scenario — Two Members Down

Example:

```text
Master 01 → DOWN
Master 02 → DOWN
Master 03 → ALONE
```

The three-member cluster has lost quorum.

The backup process should not treat this as a normal healthy backup condition.

Investigate the etcd cluster before considering recovery actions.

---

# 606. Failure Scenario — OpenEBS PVC Unavailable

If:

```text
etcd = healthy
PVC = unavailable
```

then:

```text
Snapshot creation
       │
       ▼
Cannot write backup
       │
       ▼
Backup FAILED
```

The snapshot should not be reported as successfully stored.

---

# 607. Failure Scenario — Snapshot Validation Fails

If the snapshot file exists but validation fails:

```text
Snapshot exists
      │
      ▼
Validation failed
      │
      ▼
Backup FAILED
```

The invalid snapshot should not be treated as a valid recovery artifact.

The failed artifact may be retained temporarily for troubleshooting, or cleaned up according to the implementation's failure policy.

---

# 608. Failure Scenario — Checksum Verification Fails

If:

```text
Checksum generation → success
Checksum verification → failure
```

the backup must be considered failed.

Do not proceed to retention as though the backup were valid.

---

# 609. Security Validation

Verify that:

```bash
kubectl get secret etcd-backup-tls -n etcd-backup
```

does not expose credentials in normal output.

Verify that:

```bash
kubectl get serviceaccount -n etcd-backup
```

shows the dedicated backup identity.

Verify that no backup credentials exist in:

```text
Dockerfile
backup.sh
Git
ConfigMap
README.md
```

---

# 610. Manual Backup Validation Checklist

Before converting the implementation to a CronJob:

```text
Backup Implementation
[ ] Backup image built
[ ] etcd utility version verified
[ ] etcd endpoints verified
[ ] TLS certificates identified
[ ] TLS Secret created
[ ] ServiceAccount created
[ ] Backup PVC mounted
[ ] Backup directories created

etcd
[ ] Three endpoints discovered
[ ] Health check successful
[ ] Current leader identified
[ ] Leader is selected dynamically

Snapshot
[ ] Snapshot created
[ ] Snapshot file exists
[ ] Snapshot size verified
[ ] Snapshot validated
[ ] SHA-256 checksum generated
[ ] Checksum verified
[ ] Metadata generated

Storage
[ ] Snapshot stored on OpenEBS PVC
[ ] Snapshot survives Pod deletion
[ ] Multiple snapshots can coexist
[ ] Snapshot filenames are unique

Failure Handling
[ ] Health failure returns non-zero
[ ] Snapshot failure returns non-zero
[ ] Validation failure returns non-zero
[ ] Storage failure returns non-zero

Security
[ ] TLS private key protected
[ ] No credentials in image
[ ] No credentials in Git
[ ] No admin.conf in backup image
[ ] Backup ServiceAccount has minimal permissions
```

---

# 611. Final Backup Architecture

At the end of Part 13:

```text
                              Kubernetes Cluster
                                      │
                 ┌────────────────────┼────────────────────┐
                 │                    │                    │
                 ▼                    ▼                    ▼
             Master 01            Master 02            Master 03
                etcd                  etcd                  etcd
                 │                    │                    │
                 └────────────────────┼────────────────────┘
                                      │
                                etcd Cluster
                                      │
                              Leader Detection
                                      │
                                      ▼
                             Backup Workload
                                      │
                         ┌────────────┴────────────┐
                         │                         │
                         ▼                         ▼
                    TLS Secret               Backup PVC
                         │                         │
                         ▼                         ▼
                    etcd :2379                 OpenEBS
                         │                         │
                         └────────────┬────────────┘
                                      │
                                      ▼
                             Snapshot + Checksum
                                      │
                                      ▼
                               Backup Storage
```

The backup process is now designed independently of:

```text
HAProxy
Admin Client
Prometheus
Grafana
```

while remaining observable through the monitoring layer.

---

# 612. Next Part

## Part 14 — Backup Storage and OpenEBS Integration

Part 14 will focus specifically on the persistent backup-storage lifecycle:

```text
etcd Snapshot
     │
     ▼
Backup PVC
     │
     ▼
OpenEBS PV
     │
     ▼
Persistent Storage
```

It will cover:

* OpenEBS storage engine selection
* backup PVC design
* storage topology
* volume attachment/mounting
* backup directory structure
* capacity planning
* storage monitoring
* backup storage failure handling
* PVC/PV lifecycle
* backup-data durability
* storage validation
* separation between live etcd storage and backup storage
* preparing the storage layer for the 24-hour CronJob

# Part 14 — Backup Storage and OpenEBS Integration

## 613. Objective

The objective of Part 14 is to define and validate the persistent storage architecture used for etcd backups.

The backup data path is:

```text
                    etcd Cluster
                         │
                         ▼
                  Backup Workload
                         │
                         ▼
                  etcd Snapshot
                         │
                         ▼
                etcd-backup-pvc
                         │
                         ▼
                PersistentVolume
                         │
                         ▼
                     OpenEBS
                         │
                         ▼
               Underlying Storage
```

The purpose of OpenEBS in this architecture is to provide Kubernetes-managed persistent storage for backup artifacts.

---

# 614. Backup Storage Requirements

The backup storage layer must provide:

```text
Persistent storage
Dynamic provisioning
Appropriate storage topology
Sufficient capacity
Controlled access
Backup-data persistence
Operational visibility
Storage failure detection
Capacity expansion where supported
```

The storage system must be independent from the live etcd database.

---

# 615. Live etcd Storage vs Backup Storage

There are two separate storage paths in the project.

### Live etcd storage

```text
Master 01
   │
   └── /var/lib/etcd

Master 02
   │
   └── /var/lib/etcd

Master 03
   │
   └── /var/lib/etcd
```

### Backup storage

```text
Backup Pod
    │
    ▼
etcd-backup-pvc
    │
    ▼
OpenEBS PV
    │
    ▼
Persistent storage
```

These must not be treated as the same storage system.

---

# 616. Why the Backup PVC Is Necessary

Without a PVC, a backup written to the container filesystem is ephemeral.

Example:

```text
Backup Pod
   │
   ▼
/backup
   │
   ▼
Container filesystem
```

If the Pod is deleted:

```text
Pod deleted
   │
   ▼
Container filesystem deleted
   │
   ▼
Backup lost
```

With a PVC:

```text
Backup Pod
   │
   ▼
/backup
   │
   ▼
PVC
   │
   ▼
PV
   │
   ▼
OpenEBS
```

The Pod can be recreated without losing the persisted backup data.

---

# 617. Backup Storage Namespace

The backup storage is maintained in:

```text
etcd-backup
```

Verify:

```bash
kubectl get namespace etcd-backup
```

Expected:

```text
NAME          STATUS
etcd-backup   Active
```

---

# 618. Backup PVC

The project uses:

```text
etcd-backup-pvc
```

Verify:

```bash
kubectl get pvc -n etcd-backup
```

Expected:

```text
NAME              STATUS   VOLUME
etcd-backup-pvc   Bound    <PV-NAME>
```

The PVC is the interface between the backup workload and OpenEBS.

---

# 619. PVC-to-PV Relationship

The relationship is:

```text
                    Kubernetes
                        │
                        ▼
               PersistentVolumeClaim
                  etcd-backup-pvc
                        │
                        │ claim
                        ▼
                 PersistentVolume
                    <PV-NAME>
                        │
                        ▼
                OpenEBS provisioner
                        │
                        ▼
               Underlying storage
```

The Pod does not directly select the PV.

The PVC requests storage and Kubernetes/OpenEBS handles the binding.

---

# 620. Verify PVC

Run:

```bash
kubectl get pvc etcd-backup-pvc -n etcd-backup -o wide
```

Verify:

```text
Status
Volume
Capacity
Access Modes
StorageClass
```

Then:

```bash
kubectl describe pvc etcd-backup-pvc -n etcd-backup
```

---

# 621. Verify PV

Run:

```bash
kubectl get pv
```

Identify the PV associated with:

```text
etcd-backup-pvc
```

Then:

```bash
kubectl describe pv <PV-NAME>
```

Verify:

```text
Capacity
Access Modes
Reclaim Policy
Status
Claim
StorageClass
Provisioner
VolumeHandle
Node affinity/topology
```

The available fields depend on the OpenEBS storage engine.

---

# 622. StorageClass

The PVC references an OpenEBS StorageClass:

```yaml
storageClassName: <OPENEBS-STORAGECLASS>
```

Verify:

```bash
kubectl get pvc etcd-backup-pvc \
  -n etcd-backup \
  -o jsonpath='{.spec.storageClassName}{"\n"}'
```

Then:

```bash
kubectl describe storageclass <OPENEBS-STORAGECLASS>
```

---

# 623. StorageClass Responsibilities

The StorageClass defines how Kubernetes requests storage from OpenEBS.

Important properties include:

```text
Provisioner
Parameters
Reclaim Policy
Volume Binding Mode
Allow Volume Expansion
Topology
```

The selected StorageClass should be documented in the final project configuration.

---

# 624. OpenEBS Storage Engine

OpenEBS supports different storage engines and deployment models.

The exact behavior of:

```text
Volume placement
Replication
Node affinity
Attachment
Failure recovery
Expansion
```

depends on the selected engine.

Therefore, the project should record the actual engine being used rather than generically assuming all OpenEBS volumes behave identically.

---

# 625. Identify the Storage Engine

Inspect the installed OpenEBS resources:

```bash
kubectl get pods -n openebs -o wide
```

Then:

```bash
kubectl get storageclass
```

Inspect the selected StorageClass:

```bash
kubectl describe storageclass <OPENEBS-STORAGECLASS>
```

Also inspect:

```bash
kubectl get crd | grep -i openebs
```

These commands help identify which OpenEBS components and storage engine are installed.

---

# 626. Local Storage Model

If the selected StorageClass uses local storage, the conceptual model is:

```text
             etcd-backup-pvc
                     │
                     ▼
                OpenEBS
                     │
                     ▼
                Local volume
                     │
                     ▼
                  Node X
                     │
                     ▼
               Local disk
```

The volume is associated with a particular storage location.

If that node becomes unavailable, the volume may also become unavailable.

---

# 627. Replicated Storage Model

If the selected OpenEBS engine provides replication, the conceptual architecture becomes:

```text
                 PVC
                  │
                  ▼
               OpenEBS
                  │
          ┌───────┼───────┐
          ▼       ▼       ▼
        Node A  Node B  Node C
          │       │       │
          ▼       ▼       ▼
        Copy 1  Copy 2  Copy 3
```

Replication improves storage resilience, but the exact number of replicas and failure behavior must be configured and verified.

---

# 628. Backup Storage Durability

The backup architecture must distinguish:

```text
Backup persistence
```

from:

```text
Backup redundancy
```

A PVC provides persistence across Pod recreation.

Replication, if configured by the OpenEBS storage engine, provides additional protection against certain storage/node failures.

Therefore:

```text
PVC
  ≠ automatically replicated backup
```

The actual durability level depends on the StorageClass and OpenEBS engine.

---

# 629. Which Node Stores the Backup?

The backup Pod may be scheduled on any node permitted by Kubernetes scheduling.

Check:

```bash
kubectl get pod -n etcd-backup -o wide
```

Example:

```text
NAME                 READY   STATUS    NODE
etcd-backup-test     1/1     Running   worker-02
```

This only identifies the node where the Pod is running.

It does not necessarily mean:

```text
worker-02 owns all physical backup data
```

Storage placement depends on the OpenEBS storage engine and its topology.

---

# 630. Pod Placement vs Storage Placement

These are separate concepts.

```text
Pod scheduling
      │
      ▼
Where the backup container runs
```

while:

```text
Storage provisioning
      │
      ▼
Where OpenEBS places/manages volume data
```

Depending on the storage engine, they may be related by topology constraints, but they should not be assumed to be identical.

---

# 631. Inspect PV Node Affinity

Run:

```bash
kubectl get pv <PV-NAME> -o yaml
```

Look for:

```yaml
nodeAffinity:
```

If present, inspect the topology constraints.

This can show whether the volume is restricted to particular nodes.

---

# 632. Inspect Volume Topology

Depending on the StorageClass and CSI implementation, inspect:

```bash
kubectl describe pv <PV-NAME>
```

Look for:

```text
Node Affinity
Topology
CSI
VolumeHandle
```

The actual fields depend on the storage implementation.

---

# 633. CSI Architecture

OpenEBS storage may use the Kubernetes Container Storage Interface.

Conceptually:

```text
Backup Pod
    │
    ▼
Kubernetes PVC
    │
    ▼
PersistentVolume
    │
    ▼
CSI Driver
    │
    ▼
OpenEBS
    │
    ▼
Storage
```

The CSI layer allows Kubernetes to request and mount persistent storage without the workload needing to understand the underlying storage implementation.

---

# 634. Volume Mount Lifecycle

When the backup Pod starts:

```text
Backup Pod scheduled
        │
        ▼
PVC identified
        │
        ▼
PV identified
        │
        ▼
Storage attachment/provisioning
        │
        ▼
Volume mounted
        │
        ▼
Container sees /backup
```

The backup process then writes:

```text
/backup/snapshots/
```

---

# 635. Verify the Backup Mount

When the backup Pod is running:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- df -h /backup
```

Then:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- mount | grep /backup
```

Verify that `/backup` is backed by the expected persistent volume.

---

# 636. Verify Write Access

Run:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> \
  -- sh -c 'echo storage-test > /backup/storage-test.txt'
```

Verify:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> \
  -- cat /backup/storage-test.txt
```

Expected:

```text
storage-test
```

---

# 637. Verify Persistence

Delete the test Pod:

```bash
kubectl delete pod <BACKUP-POD> -n etcd-backup
```

Start another Pod using the same PVC.

Then:

```bash
kubectl exec -n etcd-backup <NEW-POD> \
  -- cat /backup/storage-test.txt
```

Expected:

```text
storage-test
```

This demonstrates persistence across Pod recreation.

---

# 638. Do Not Confuse Pod Restart with Storage Recovery

Successful persistence after Pod recreation proves:

```text
Pod lifecycle
      ≠
PVC data lifecycle
```

It does not prove that the backup volume will survive every possible infrastructure failure.

Storage-engine-specific failure testing must be performed separately.

---

# 639. Backup Storage Capacity

The PVC capacity should be based on:

```text
Snapshot size
×
Number of retained snapshots
×
Safety margin
```

For example:

```text
Average snapshot = 500 MB
Retention = 14 snapshots
Safety factor = 2

500 MB × 14 × 2
= 14 GB
```

A larger PVC can be selected to provide operational headroom.

The actual etcd snapshot size should be measured from the production-like cluster.

---

# 640. Monitor PVC Usage

Inside the backup Pod:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> \
  -- df -h /backup
```

Example:

```text
Filesystem      Size  Used Avail Use%
/dev/...         20G  6.0G   14G  30%
```

The actual filesystem output depends on the storage engine and mount configuration.

---

# 641. Storage Usage Thresholds

The project can define operational thresholds.

Example:

```text
< 70%   Normal
70–80%  Monitor
80–90%  Warning
> 90%   Critical
```

These are operational examples and should be adjusted based on the actual capacity, retention policy, and recovery requirements.

The monitoring system should alert before the PVC reaches a condition that prevents a new backup from being written.

---

# 642. Storage Expansion

Check:

```bash
kubectl get storageclass <OPENEBS-STORAGECLASS> \
  -o jsonpath='{.allowVolumeExpansion}{"\n"}'
```

If supported:

```text
true
```

the PVC can potentially be expanded.

Example:

```yaml
resources:
  requests:
    storage: 20Gi
```

After applying the new request:

```bash
kubectl apply -f etcd-backup-pvc.yaml
```

Verify:

```bash
kubectl get pvc etcd-backup-pvc -n etcd-backup
```

The exact expansion procedure depends on the OpenEBS engine and filesystem.

---

# 643. Do Not Shrink the PVC

PersistentVolumeClaims generally should not be treated as shrinkable storage.

If capacity has been over-provisioned, do not attempt an unsupported filesystem/PVC shrink operation.

Plan the requested capacity carefully.

---

# 644. Reclaim Policy

Inspect:

```bash
kubectl get pv <PV-NAME> \
  -o jsonpath='{.spec.persistentVolumeReclaimPolicy}{"\n"}'
```

Possible values include:

```text
Retain
Delete
```

For backup data, understand the consequence before choosing or changing this behavior.

---

# 645. Retain Policy

With:

```text
Retain
```

deleting the PVC does not necessarily mean that the underlying PV/storage is immediately deleted.

This can help protect against accidental deletion.

However, it also means abandoned storage may require manual cleanup.

---

# 646. Delete Policy

With:

```text
Delete
```

deleting the PVC may cause the dynamically provisioned storage to be deleted according to the storage provisioner's behavior.

This can be dangerous for backup data if the PVC is accidentally deleted.

The selected policy must therefore match the project's recovery requirements.

---

# 647. Backup Retention

Backup file retention is handled separately.

For example:

```text
Daily snapshots:
14 days
```

The retention process removes:

```text
snapshot files older than retention period
```

It does not normally delete:

```text
etcd-backup-pvc
```

---

# 648. Backup Directory

The recommended structure is:

```text
/backup/
│
├── snapshots/
│   ├── etcd-snapshot-YYYY-MM-DDTHH-MM-SSZ.db
│   └── ...
│
├── checksums/
│   ├── etcd-snapshot-YYYY-MM-DDTHH-MM-SSZ.sha256
│   └── ...
│
└── metadata/
    ├── etcd-snapshot-YYYY-MM-DDTHH-MM-SSZ.json
    └── ...
```

This keeps backup artifacts organized.

---

# 649. Do Not Store Temporary Files Permanently

The backup process may create temporary files while generating a snapshot.

Use a temporary location where appropriate.

After a successful backup:

```text
Temporary files
      │
      ▼
Removed
```

Only required recovery artifacts should remain on the PVC.

---

# 650. Atomic Backup File Handling

To reduce the possibility of retention processing a partially written snapshot, the backup process can use a temporary filename.

Example:

```text
/backup/snapshots/
    .etcd-snapshot-<TIMESTAMP>.tmp
```

After successful creation and validation:

```text
.etcd-snapshot-<TIMESTAMP>.tmp
          │
          ▼
etcd-snapshot-<TIMESTAMP>.db
```

This prevents a partially written file from being mistaken for a completed backup.

---

# 651. Backup Storage Permissions

The backup process should write only to its designated directory.

For example:

```text
/backup
```

The container should not require write access to:

```text
/
/etc
/var
/etc/kubernetes
/var/lib/etcd
```

Only the required paths should be writable.

---

# 652. Read-Only Root Filesystem

Where compatible with the backup image, the container can use:

```yaml
securityContext:
  readOnlyRootFilesystem: true
```

The writable locations should then be explicitly mounted.

For example:

```text
Writable:
    /backup
    /tmp (if required)

Read-only:
    container root filesystem
    TLS Secret
```

This improves container isolation.

---

# 653. Backup PVC Access Control

The PVC should be mounted only by the intended backup workload.

Avoid allowing unrelated applications to use:

```text
etcd-backup-pvc
```

The backup namespace should remain dedicated to backup-related resources.

---

# 654. Backup Storage and Secrets

The backup PVC contains:

```text
etcd snapshots
```

The TLS Secret contains:

```text
etcd authentication credentials
```

These are separate resources:

```text
PVC
 └── backup data


Secret
 └── authentication material
```

Do not store the TLS credentials as files on the PVC.

---

# 655. Backup Storage and Monitoring Storage

Prometheus storage should remain separate:

```text
Prometheus
    │
    ▼
Prometheus PVC
```

etcd backup storage:

```text
Backup CronJob
    │
    ▼
etcd-backup-pvc
```

Do not combine them into a single PVC.

---

# 656. OpenEBS Health

Check OpenEBS:

```bash
kubectl get pods -n openebs -o wide
```

Then:

```bash
kubectl get all -n openebs
```

Check for:

```text
Running
Ready
Completed
```

and investigate unexpected:

```text
CrashLoopBackOff
Pending
Error
Failed
```

states.

---

# 657. OpenEBS Events

Inspect events:

```bash
kubectl get events \
  -n openebs \
  --sort-by='.lastTimestamp'
```

For a specific component:

```bash
kubectl describe pod -n openebs <OPENEBS-POD>
```

Logs:

```bash
kubectl logs -n openebs <OPENEBS-POD>
```

The exact troubleshooting procedure depends on the selected OpenEBS engine.

---

# 658. PV Failure Investigation

If the backup PVC becomes unavailable:

```bash
kubectl get pvc -n etcd-backup
```

Then:

```bash
kubectl describe pvc etcd-backup-pvc -n etcd-backup
```

Check:

```bash
kubectl get pv
```

Then:

```bash
kubectl describe pv <PV-NAME>
```

Finally inspect OpenEBS resources.

---

# 659. Backup Pod Cannot Mount Volume

Check:

```bash
kubectl describe pod -n etcd-backup <BACKUP-POD>
```

Look for:

```text
FailedMount
FailedAttachVolume
MountVolume
```

Then inspect:

```bash
kubectl describe pvc etcd-backup-pvc -n etcd-backup
```

and:

```bash
kubectl describe pv <PV-NAME>
```

---

# 660. Backup Storage Node Failure

If the storage is node-local:

```text
Storage Node
     │
     ▼
Node failure
     │
     ▼
Volume unavailable
```

The backup system cannot write new snapshots until storage becomes available or an appropriate recovery mechanism is used.

If replicated storage is configured:

```text
Node failure
     │
     ▼
OpenEBS storage recovery
     │
     ▼
Volume remains/rebecomes available
```

The exact behavior depends on the OpenEBS engine and replication configuration.

---

# 661. Storage Failure Must Not Be Hidden

A backup Job should fail if the backup PVC cannot be written.

The system should not report:

```text
Backup successful
```

when:

```text
Snapshot generated
BUT
Snapshot was not persisted
```

The success condition is:

```text
Snapshot
   │
   ▼
Validated
   │
   ▼
Written to persistent storage
   │
   ▼
Verified
```

---

# 662. Verify Snapshot Persistence

After a backup:

```bash
kubectl get pvc -n etcd-backup
```

Confirm:

```text
etcd-backup-pvc → Bound
```

Then verify the snapshot from a newly created Pod.

This proves that:

```text
Snapshot
   │
   ▼
PVC
   │
   ▼
OpenEBS
```

is functioning correctly.

---

# 663. Storage Failure Drill

A controlled storage failure test can be performed in a non-production environment.

The objective is to verify:

```text
Storage failure
      │
      ▼
Backup detects failure
      │
      ▼
Job reports failure
      │
      ▼
Monitoring detects failure
```

Do not perform destructive storage tests against the production cluster without an approved recovery plan.

---

# 664. Backup Capacity Monitoring

The monitoring system from Part 11 should eventually expose:

```text
Backup PVC capacity
Backup PVC usage
Available storage
Backup growth rate
```

This allows the team to determine when the current retention policy needs adjustment.

---

# 665. Backup Growth Model

If:

```text
S = average snapshot size
D = backups per day
R = retention days
```

then approximately:

```text
Storage Required = S × D × R
```

For one backup per day:

```text
D = 1
```

so:

```text
Storage Required ≈ S × R
```

Add additional headroom for:

```text
Metadata
Checksums
Temporary files
Snapshot growth
Operational buffer
```

---

# 666. Example Capacity Model

Example only:

```text
Average snapshot = 600 MB
Daily backups = 1
Retention = 14 days
Base requirement = 8.4 GB
```

Add operational headroom:

```text
Recommended capacity > 8.4 GB
```

A 20 GiB PVC could provide substantial working headroom in this example.

The actual value must be based on measured snapshot sizes.

---

# 667. Backup Storage Naming

Use a clear naming convention:

```text
PVC:
etcd-backup-pvc

Namespace:
etcd-backup

Directory:
 /backup/snapshots

Metadata:
 /backup/metadata

Checksums:
 /backup/checksums
```

This makes the architecture easy to understand and operate.

---

# 668. Backup Storage Documentation

The final project documentation should record:

```text
StorageClass:
<OPENEBS-STORAGECLASS>

Provisioner:
<OPENEBS-PROVISIONER>

Storage Engine:
<OPENEBS-ENGINE>

PVC:
etcd-backup-pvc

Requested Capacity:
<XXGi>

Access Mode:
<ACCESS-MODE>

Volume Binding Mode:
<BINDING-MODE>

Reclaim Policy:
<RECLAIM-POLICY>

Replication:
<IF-APPLICABLE>

Expansion:
<SUPPORTED/NOT-SUPPORTED>
```

Actual values should be populated from the deployed cluster.

---

# 669. Recommended Storage Configuration

The project should aim for:

```text
Dedicated namespace
        │
        ▼
Dedicated PVC
        │
        ▼
Dedicated OpenEBS StorageClass
        │
        ▼
Appropriate persistence/redundancy
        │
        ▼
Controlled backup workload access
```

A dedicated StorageClass can be useful when the project needs backup-specific storage behavior.

However, creating a dedicated StorageClass is not mandatory if an existing OpenEBS StorageClass already satisfies the requirements.

---

# 670. Dedicated StorageClass Consideration

If the cluster requires special backup storage behavior, a dedicated StorageClass may define:

```text
Replication factor
Volume binding
Topology
Expansion
Reclaim behavior
Storage engine parameters
```

This should only be introduced after understanding the existing OpenEBS configuration.

Avoid creating unnecessary StorageClasses.

---

# 671. Backup Storage Lifecycle

The complete lifecycle is:

```text
                    Create PVC
                       │
                       ▼
                OpenEBS Provisioning
                       │
                       ▼
                    PV Bound
                       │
                       ▼
                  Backup Pod
                       │
                       ▼
                 Volume Mounted
                       │
                       ▼
                Snapshot Written
                       │
                       ▼
               Snapshot Validated
                       │
                       ▼
                Backup Retained
                       │
                       ▼
              Old Snapshot Removed
                       │
                       ▼
                 PVC Continues
```

The PVC remains available while the backup system is active.

---

# 672. Restore Relationship

The storage architecture must support the future restore process.

The restore flow will eventually be:

```text
OpenEBS PVC
     │
     ▼
Valid etcd snapshot
     │
     ▼
Snapshot validation
     │
     ▼
Restore procedure
     │
     ▼
New/Recovered etcd data
```

Restore is not implemented in this part.

It will be documented in Part 17.

---

# 673. Backup Storage Security

The backup PVC contains the Kubernetes cluster's etcd state.

Therefore:

```text
Backup PVC
     │
     ├── Access controlled
     ├── Namespace isolated
     ├── Credentials separated
     └── Recovery access restricted
```

If the storage platform supports encryption at rest, the project should evaluate enabling it according to the environment's security requirements.

---

# 674. Do Not Store Backup Credentials on PVC

Avoid:

```text
/backup/
├── client.key
├── client.crt
└── ca.crt
```

Instead:

```text
Secret
 └── TLS credentials

PVC
 └── Backup artifacts
```

This reduces the chance that backup-data retention accidentally retains authentication credentials indefinitely.

---

# 675. Verify Final Storage Architecture

Run:

```bash
kubectl get pvc -n etcd-backup
```

Then:

```bash
kubectl get pv
```

Then:

```bash
kubectl get storageclass
```

Then:

```bash
kubectl get pods -n openebs -o wide
```

Then:

```bash
kubectl get pods -n etcd-backup -o wide
```

Confirm that all storage components are healthy.

---

# 676. Final Storage Validation Checklist

```text
Namespace
[ ] etcd-backup namespace exists
[ ] Namespace is Active

PVC
[ ] etcd-backup-pvc exists
[ ] PVC is Bound
[ ] Capacity is sufficient
[ ] Access mode verified
[ ] StorageClass verified

PV
[ ] PV exists
[ ] PV is Bound
[ ] Capacity verified
[ ] Reclaim policy verified
[ ] Topology/node affinity investigated
[ ] CSI information verified where applicable

OpenEBS
[ ] OpenEBS components are healthy
[ ] Storage engine identified
[ ] StorageClass provisioner verified
[ ] Volume behavior understood

Mount
[ ] Backup Pod can mount PVC
[ ] /backup is accessible
[ ] Write operation succeeds
[ ] Read operation succeeds
[ ] Data survives Pod recreation

Capacity
[ ] Snapshot size measured
[ ] Retention requirement calculated
[ ] Capacity headroom provided
[ ] Expansion capability checked

Security
[ ] PVC access restricted
[ ] TLS Secret separated from PVC
[ ] No private keys stored on PVC
[ ] Backup artifacts protected

Monitoring
[ ] PVC status monitored
[ ] Storage capacity monitored
[ ] OpenEBS health monitored
[ ] Backup failures will be observable
```

---

# 677. Final Backup Storage Architecture

After Part 14:

```text
                         Kubernetes Cluster
                                │
                                ▼
                        etcd Backup Workload
                                │
                     ┌──────────┴──────────┐
                     │                     │
                     ▼                     ▼
                TLS Secret          etcd-backup-pvc
                     │                     │
                     │                     ▼
                     │              PersistentVolume
                     │                     │
                     │                     ▼
                     │                  OpenEBS
                     │                     │
                     │                     ▼
                     │             Persistent Storage
                     │
                     ▼
                etcd :2379
```

The responsibilities are clearly separated:

```text
etcd
 └── Cluster state

TLS Secret
 └── etcd authentication

Backup Workload
 └── Snapshot creation

PVC
 └── Backup storage request

PV
 └── Persistent volume representation

OpenEBS
 └── Storage provisioning/management
```

---

# 678. Key Design Decisions

The project establishes the following storage decisions:

1. etcd live data and backup data use separate storage paths.
2. Backup data is stored through a dedicated PVC.
3. The PVC is provisioned through OpenEBS.
4. The backup workload mounts the PVC at `/backup`.
5. The physical storage location depends on the selected OpenEBS engine and StorageClass.
6. The Pod's node must not be assumed to be the physical storage location.
7. Backup retention operates on snapshot files, not by deleting the PVC.
8. Backup storage capacity must be based on measured snapshot size and retention.
9. TLS credentials remain in a Kubernetes Secret rather than on the backup PVC.
10. Prometheus storage remains separate from etcd backup storage.
11. Storage failure must cause the backup process to report failure.
12. Snapshot persistence must be tested by recreating the backup Pod.
13. Storage topology and replication must be documented from the actual OpenEBS configuration.

---

# 679. Next Part

## Part 15 — etcd Backup CronJob

Part 15 will convert the manually tested backup process into an automated Kubernetes CronJob.

The target architecture is:

```text
                    Kubernetes CronJob
                           │
                    Every 24 Hours
                           │
                           ▼
                    Backup Pod
                           │
                           ▼
                    Leader Detection
                           │
                           ▼
                    etcd Health Check
                           │
                           ▼
                   etcd Snapshot
                           │
                           ▼
                  Snapshot Validation
                           │
                           ▼
                    SHA-256 Checksum
                           │
                           ▼
                    OpenEBS PVC
                           │
                           ▼
                    Backup Storage
```

Part 15 will cover:

* CronJob configuration
* 24-hour schedule
* `concurrencyPolicy`
* `startingDeadlineSeconds`
* Job history limits
* ServiceAccount
* Secret mounting
* PVC mounting
* backup image
* environment configuration
* resource requests/limits
* Pod security context
* restart behavior
* manual Job execution from the CronJob
* verifying successful executions
* handling failed executions
* preventing overlapping backups
* validating that the CronJob actually runs every 24 hours

# Part 15 — etcd Backup CronJob

## 680. Objective

The objective of Part 15 is to automate the etcd backup process so that an etcd snapshot is created **once every 24 hours** and stored on the OpenEBS-backed `etcd-backup-pvc`.

The final workflow is:

```text
                         Kubernetes CronJob
                                │
                         Every 24 Hours
                                │
                                ▼
                         Backup Job
                                │
                                ▼
                         Backup Pod
                                │
                   ┌────────────┴────────────┐
                   │                         │
                   ▼                         ▼
             etcd Cluster              OpenEBS PVC
                   │                         │
                   ▼                         ▼
            Leader Detection          /backup/snapshots
                   │
                   ▼
             Health Check
                   │
                   ▼
            Snapshot Creation
                   │
                   ▼
            Snapshot Validation
                   │
                   ▼
             SHA-256 Checksum
                   │
                   ▼
            Backup Completion
```

The CronJob should execute automatically without requiring an administrator to manually start the backup.

---

# 681. Why Kubernetes CronJob

A Kubernetes CronJob is appropriate because the backup is a scheduled Kubernetes workload.

It provides:

* Scheduled execution
* Job creation
* Retry handling
* Job history
* Kubernetes-native status
* Pod lifecycle management
* Integration with Kubernetes monitoring
* Integration with the existing PVC

The architecture becomes:

```text
CronJob
   │
   ├── creates Job
   │
   └── Job creates Pod
              │
              ├── mounts TLS Secret
              ├── mounts backup PVC
              └── executes backup script
```

---

# 682. CronJob vs Job vs Pod

These resources have different responsibilities.

### CronJob

Defines:

```text
When the backup should run
```

### Job

Represents:

```text
One backup execution
```

### Pod

Runs:

```text
The actual backup container
```

Therefore:

```text
CronJob
   │
   ▼
Job
   │
   ▼
Pod
   │
   ▼
Backup Script
```

---

# 683. Backup Schedule

The requirement is:

```text
One backup every 24 hours
```

A Kubernetes CronJob can use:

```text id="n2qv7r"
0 2 * * *
```

This means:

```text
Every day at 02:00
```

The schedule uses the timezone configured for the CronJob/controller behavior.

The project should explicitly define the intended timezone rather than assuming the administrator's local timezone.

---

# 684. CronJob Timezone

Where supported by the Kubernetes version and CronJob configuration, the timezone can be explicitly defined.

Example:

```yaml id="x0q9mh"
spec:
  schedule: "0 2 * * *"
  timeZone: "Asia/Kolkata"
```

This means:

```text
02:00 IST
```

The project uses India Standard Time for the example.

If timezone support is not being used, document the controller's effective timezone and ensure the schedule is interpreted correctly.

---

# 685. Recommended Backup Time

The backup should ideally execute during a period of relatively low cluster activity.

Example:

```text
02:00 IST
```

The exact time can be changed according to the operational requirements of the environment.

The important requirement is:

```text
One successful backup approximately every 24 hours
```

---

# 686. Create the CronJob Manifest

Create:

```bash id="t3m8q7"
nano etcd-backup/cronjob.yaml
```

The CronJob will reference:

```text
Backup image
ServiceAccount
TLS Secret
Backup PVC
etcd endpoints
```

---

# 687. CronJob Example

A starting configuration is:

```yaml id="o7yq0m"
apiVersion: batch/v1
kind: CronJob
metadata:
  name: etcd-backup
  namespace: etcd-backup

spec:
  schedule: "0 2 * * *"
  timeZone: "Asia/Kolkata"

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
          serviceAccountName: etcd-backup

          restartPolicy: Never

          containers:
            - name: etcd-backup
              image: <ETCD-BACKUP-IMAGE>:<VERSION>

              imagePullPolicy: IfNotPresent

              env:
                - name: ETCD_ENDPOINTS
                  value: "https://<MASTER-01-ETCD-IP>:2379,https://<MASTER-02-ETCD-IP>:2379,https://<MASTER-03-ETCD-IP>:2379"

              volumeMounts:
                - name: backup-storage
                  mountPath: /backup

                - name: etcd-tls
                  mountPath: /etc/etcd-tls
                  readOnly: true

          volumes:
            - name: backup-storage
              persistentVolumeClaim:
                claimName: etcd-backup-pvc

            - name: etcd-tls
              secret:
                secretName: etcd-backup-tls
```

The placeholders must be replaced with the actual environment values.

---

# 688. Important CronJob Configuration

The key settings are:

```text
schedule
timeZone
concurrencyPolicy
successfulJobsHistoryLimit
failedJobsHistoryLimit
backoffLimit
restartPolicy
```

These determine how the backup behaves operationally.

---

# 689. Concurrency Policy

The project should use:

```yaml id="5b7c2m"
concurrencyPolicy: Forbid
```

This prevents a new backup Job from starting while a previous execution is still running.

Conceptually:

```text
Backup A
████████████████

Backup B
        X
```

Instead of:

```text
Backup A
████████████████

Backup B
        ███████████████
```

The second model could result in multiple processes writing to the same backup PVC simultaneously.

---

# 690. Why `Forbid` Is Used

The backup process should normally have:

```text
One active backup
```

at a time.

This avoids:

* Concurrent snapshot operations
* Conflicting retention operations
* Duplicate backup writes
* Unnecessary storage load
* Multiple Pods manipulating the same directory

---

# 691. What Happens If a Backup Takes Too Long

Suppose:

```text
02:00 → Backup starts
02:30 → Backup still running
```

At the next scheduled execution:

```text
02:00 next day
```

if the previous Job is still active, `Forbid` prevents overlapping execution.

The exact missed-schedule behavior should be understood and monitored.

The system should not silently create simultaneous backup writers.

---

# 692. Job Backoff

The example uses:

```yaml id="1r3pjd"
backoffLimit: 2
```

This allows the Job to retry after failures according to Kubernetes Job behavior.

Conceptually:

```text
Attempt 1
   │
   ├── Success → DONE
   │
   └── Failure
          │
          ▼
       Attempt 2
          │
          ├── Success → DONE
          │
          └── Failure
                 │
                 ▼
              Attempt 3
                 │
                 ▼
              FAILED
```

The exact retry timing is controlled by Kubernetes Job behavior.

---

# 693. Retry vs New Daily Backup

A Job retry is different from the next CronJob schedule.

For example:

```text
02:00
Daily backup starts

02:01
Backup fails

Kubernetes retries Job

02:xx
Retry succeeds
```

This is one backup execution recovering from a transient failure.

The next scheduled backup still occurs on the following schedule.

---

# 694. Restart Policy

For a Job Pod, use:

```yaml id="07s4q4"
restartPolicy: Never
```

This allows the Job controller to create/retry Pods according to Job semantics.

Do not use:

```yaml
restartPolicy: Always
```

for this Job workload.

---

# 695. Job History

The CronJob can retain a limited number of completed Jobs:

```yaml id="at2p7s"
successfulJobsHistoryLimit: 3
failedJobsHistoryLimit: 3
```

This prevents unlimited accumulation of completed Job resources.

Important:

```text
Job history retention
       ≠
snapshot retention
```

Deleting a completed Kubernetes Job does not delete the backup file stored on the PVC.

---

# 696. Snapshot Retention vs Job History

The project has two independent retention systems.

### Kubernetes Job history

Controls:

```text
How many completed Job objects remain
```

### Backup retention

Controls:

```text
How many snapshot files remain on the PVC
```

Therefore:

```text
successfulJobsHistoryLimit
        ≠
backup snapshot retention
```

Backup snapshot retention will be implemented in Part 16.

---

# 697. ServiceAccount

The CronJob uses:

```yaml id="1d6e08"
serviceAccountName: etcd-backup
```

Verify:

```bash id="r4p8k2"
kubectl get serviceaccount etcd-backup -n etcd-backup
```

The ServiceAccount should be dedicated to the backup workload.

---

# 698. Kubernetes RBAC

The backup workload should use least privilege.

Do not assign:

```text
cluster-admin
```

unless there is a clearly documented requirement.

The backup process primarily needs:

```text
etcd TLS credentials
etcd endpoint access
PVC access through volume mounting
```

A Kubernetes ServiceAccount does not itself provide etcd authentication.

---

# 699. TLS Secret

The CronJob mounts:

```text
etcd-backup-tls
```

at:

```text
/etc/etcd-tls
```

Expected files:

```text
/etc/etcd-tls/ca.crt
/etc/etcd-tls/client.crt
/etc/etcd-tls/client.key
```

Verify:

```bash id="c4r9m2"
kubectl get secret etcd-backup-tls -n etcd-backup
```

Do not expose Secret contents in logs.

---

# 700. Backup PVC

The CronJob mounts:

```text
etcd-backup-pvc
```

at:

```text
/backup
```

Verify:

```bash id="u8m3q5"
kubectl get pvc etcd-backup-pvc -n etcd-backup
```

Expected:

```text
STATUS: Bound
```

---

# 701. etcd Endpoints

The CronJob requires the three etcd endpoints.

Example:

```text id="f8n3x2"
https://<MASTER-01-ETCD-IP>:2379
https://<MASTER-02-ETCD-IP>:2379
https://<MASTER-03-ETCD-IP>:2379
```

Do not configure:

```text
https://<HAProxy>:6443
```

as an etcd endpoint.

HAProxy handles Kubernetes API traffic, not etcd backup traffic.

---

# 702. Endpoint Configuration

The endpoint list can be supplied as an environment variable:

```yaml id="y0n8m4"
env:
  - name: ETCD_ENDPOINTS
    value: "https://<MASTER-01>:2379,https://<MASTER-02>:2379,https://<MASTER-03>:2379"
```

The backup script parses this list.

The actual endpoint values must match the etcd configuration.

---

# 703. Leader Detection at Runtime

The CronJob must not contain:

```text
LEADER=master-01
```

Instead:

```text id="4ldq65"
ETCD_ENDPOINTS
       │
       ▼
endpoint status
       │
       ▼
Current leader
       │
       ▼
Snapshot
```

This allows the backup process to continue functioning when leadership changes between:

```text
Master 01
Master 02
Master 03
```

---

# 704. CronJob Execution Flow

Every scheduled execution follows:

```text id="u70vbn"
CronJob Schedule
      │
      ▼
Create Job
      │
      ▼
Schedule Backup Pod
      │
      ▼
Mount Secret
      │
      ▼
Mount PVC
      │
      ▼
Start Backup Script
      │
      ▼
Check etcd Health
      │
      ▼
Determine Leader
      │
      ▼
Create Snapshot
      │
      ▼
Validate Snapshot
      │
      ▼
Generate Checksum
      │
      ▼
Write Metadata
      │
      ▼
Exit 0
      │
      ▼
Job Successful
```

---

# 705. Apply the CronJob

Before applying:

```bash id="9t0g3r"
kubectl apply --dry-run=client \
  -f etcd-backup/cronjob.yaml
```

If the manifest is valid:

```bash id="q3m7x8"
kubectl apply -f etcd-backup/cronjob.yaml
```

Verify:

```bash id="n6p2m4"
kubectl get cronjob -n etcd-backup
```

Expected:

```text
NAME          SCHEDULE
etcd-backup   0 2 * * *
```

---

# 706. Inspect CronJob

Run:

```bash id="x7m4p2"
kubectl describe cronjob etcd-backup -n etcd-backup
```

Check:

```text
Schedule
Time Zone
Concurrency Policy
Suspend
Active Jobs
Last Schedule Time
Successful Job History Limit
Failed Job History Limit
Job Template
```

---

# 707. Verify CronJob Status

Run:

```bash id="p5n8m3"
kubectl get cronjob etcd-backup -n etcd-backup -o wide
```

Check:

```text
SCHEDULE
SUSPEND
ACTIVE
LAST SCHEDULE
```

The `LAST SCHEDULE` field should update after the scheduled execution.

---

# 708. Manual Job Trigger

Do not wait 24 hours for the first test.

Create a Job from the CronJob:

```bash id="m2x7q5"
kubectl create job \
  --from=cronjob/etcd-backup \
  etcd-backup-manual-$(date +%s) \
  -n etcd-backup
```

Verify:

```bash id="q8m3p4"
kubectl get jobs -n etcd-backup
```

---

# 709. Watch the Backup Pod

Run:

```bash id="x4p7m2"
kubectl get pods -n etcd-backup -w
```

The Pod should transition through:

```text
Pending
   │
   ▼
Running
   │
   ▼
Completed
```

A successful backup Pod should eventually show:

```text
STATUS: Completed
```

---

# 710. Check Backup Logs

Identify the Pod:

```bash id="m7q3x5"
kubectl get pods -n etcd-backup
```

Then:

```bash id="p4n8m2"
kubectl logs -n etcd-backup <BACKUP-POD>
```

Expected workflow:

```text
Starting etcd backup
Checking etcd health
Discovering leader
Leader identified
Creating snapshot
Validating snapshot
Generating checksum
Writing metadata
Backup completed successfully
```

---

# 711. Check Job Status

Run:

```bash id="q6m3p8"
kubectl get job <JOB-NAME> -n etcd-backup
```

For detailed information:

```bash id="x2p7m4"
kubectl describe job <JOB-NAME> -n etcd-backup
```

A successful Job should indicate:

```text
Complete
```

---

# 712. Check Backup Files

Mount the PVC using an inspection Pod if the completed backup Pod has already terminated.

Then inspect:

```bash id="m8q4p2"
ls -lh /backup/snapshots/
```

Expected:

```text
etcd-snapshot-<TIMESTAMP>.db
```

Check:

```bash id="p3x7m5"
ls -lh /backup/checksums/
```

and:

```bash id="n6m2q8"
ls -lh /backup/metadata/
```

---

# 713. Verify Snapshot

Check that the snapshot:

```text
exists
```

and:

```text
is non-zero
```

Then perform the version-compatible etcd snapshot validation.

For example:

```bash id="q4m8x3"
etcdutl snapshot status /backup/snapshots/<SNAPSHOT>.db
```

or, where appropriate:

```bash id="p7n3m5"
etcdctl snapshot status /backup/snapshots/<SNAPSHOT>.db
```

The command must match the etcd utility version used by the backup image.

---

# 714. Verify Checksum

Run:

```bash id="m4x8q2"
sha256sum -c \
  /backup/checksums/<SNAPSHOT>.sha256
```

Expected:

```text
<snapshot>: OK
```

---

# 715. Verify Metadata

Inspect:

```bash id="x7m3p8"
cat /backup/metadata/<METADATA-FILE>
```

Verify:

```text
Timestamp
Snapshot filename
Leader/endpoint information
Backup status
```

Do not store TLS credentials in metadata.

---

# 716. Verify PVC Persistence

After the Job completes:

```bash id="n5q8m2"
kubectl get pvc -n etcd-backup
```

Expected:

```text
etcd-backup-pvc   Bound
```

Delete the completed Pod if it remains:

```bash id="p3m7x4"
kubectl delete pod <BACKUP-POD> -n etcd-backup
```

The snapshot must remain on the PVC.

---

# 717. Verify Multiple Executions

Run another manual Job:

```bash id="x6m2p8"
kubectl create job \
  --from=cronjob/etcd-backup \
  etcd-backup-manual-$(date +%s) \
  -n etcd-backup
```

Verify that another snapshot is created.

The directory should contain:

```text
/backup/snapshots/
├── snapshot-<TIME-1>.db
└── snapshot-<TIME-2>.db
```

This confirms that the CronJob can create multiple backup generations.

---

# 718. Verify Concurrency Policy

Check:

```bash id="q3m8x5"
kubectl get cronjob etcd-backup \
  -n etcd-backup \
  -o jsonpath='{.spec.concurrencyPolicy}{"\n"}'
```

Expected:

```text
Forbid
```

---

# 719. Verify Schedule

Run:

```bash id="p7m4x2"
kubectl get cronjob etcd-backup \
  -n etcd-backup \
  -o jsonpath='{.spec.schedule}{"\n"}'
```

Expected:

```text
0 2 * * *
```

---

# 720. Verify Timezone

Run:

```bash id="m8x3q5"
kubectl get cronjob etcd-backup \
  -n etcd-backup \
  -o jsonpath='{.spec.timeZone}{"\n"}'
```

Expected:

```text
Asia/Kolkata
```

if the timezone was explicitly configured.

---

# 721. CronJob Suspension

Verify:

```bash id="x4p8m3"
kubectl get cronjob etcd-backup \
  -n etcd-backup \
  -o jsonpath='{.spec.suspend}{"\n"}'
```

If the field is absent, it normally behaves as:

```text
false
```

The CronJob should not be suspended during normal operation.

---

# 722. Manually Suspend the CronJob

If maintenance is required:

```bash id="n7m3q8"
kubectl patch cronjob etcd-backup \
  -n etcd-backup \
  -p '{"spec":{"suspend":true}}'
```

Verify:

```bash id="p5x2m7"
kubectl get cronjob etcd-backup -n etcd-backup
```

After maintenance:

```bash id="q8m4x3"
kubectl patch cronjob etcd-backup \
  -n etcd-backup \
  -p '{"spec":{"suspend":false}}'
```

Suspension should be used deliberately because it creates a gap in backup coverage.

---

# 723. Backup Deadline

For a production backup CronJob, consider:

```yaml id="z3p8m5"
startingDeadlineSeconds: 3600
```

This allows the controller to treat a schedule that is delayed beyond the defined deadline as missed.

The exact value should be chosen according to:

```text
Expected cluster availability
Maintenance windows
Control-plane downtime tolerance
Backup requirements
```

Do not select a value arbitrarily.

---

# 724. Resource Requests

The backup container should have explicit resource requests.

Example:

```yaml id="6m4x8p"
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

These are starting examples.

Actual values should be adjusted based on observed resource consumption.

---

# 725. Why Resource Requests Matter

Without requests, the backup Pod may compete unpredictably with other workloads.

With requests:

```text
Kubernetes Scheduler
        │
        ▼
Reserves requested resources
        │
        ▼
Schedules backup Pod appropriately
```

The backup workload should remain lightweight compared with application workloads.

---

# 726. Backup Pod Scheduling

The backup Pod can normally run on a worker node.

Example:

```text
Worker 01
Worker 02
Worker 03
```

The backup workload should not require direct access to:

```text
/var/lib/etcd
```

because it uses the etcd client API.

---

# 727. Optional Node Affinity

If the storage design requires the backup workload to run on specific nodes, node affinity can be configured.

Example:

```yaml id="69f8is"
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: <LABEL>
              operator: In
              values:
                - <VALUE>
```

Only use this if there is a documented operational reason.

Do not unnecessarily restrict the backup Pod to one worker.

---

# 728. Backup Pod Tolerations

If the project intentionally permits backup workloads on tainted control-plane nodes, appropriate tolerations would be required.

However, the default design should not require the backup workload to run on control-plane nodes.

The backup process communicates with etcd over the network rather than accessing its local filesystem.

---

# 729. Container Security Context

The backup container should run with the minimum privileges required.

A possible baseline is:

```yaml id="8u4qj2"
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

A non-root user can also be used if the backup image and mounted storage permissions support it.

The actual security context must be tested with the selected OpenEBS mount behavior and backup image.

---

# 730. Read-Only Filesystems

Where compatible:

```yaml id="0s5kq6"
securityContext:
  readOnlyRootFilesystem: true
```

The backup volume remains writable:

```text
/backup
```

TLS credentials remain read-only:

```text
/etc/etcd-tls
```

This creates a more restricted container filesystem.

---

# 731. Environment Variables

The backup container may use:

```text
ETCD_ENDPOINTS
ETCDCTL_API
BACKUP_DIR
```

Example:

```yaml id="n7x3m8"
env:
  - name: ETCDCTL_API
    value: "3"

  - name: ETCD_ENDPOINTS
    value: "https://<MASTER-01>:2379,https://<MASTER-02>:2379,https://<MASTER-03>:2379"

  - name: BACKUP_DIR
    value: "/backup"
```

Do not place passwords or private keys in environment variables.

TLS credentials should remain mounted from the Secret.

---

# 732. ConfigMap vs Secret

Use:

```text
ConfigMap
    │
    └── non-sensitive configuration
```

and:

```text
Secret
    │
    └── sensitive credentials
```

For example:

```text
ETCD_ENDPOINTS → ConfigMap/environment configuration
CA certificate → Secret
Client certificate → Secret
Client private key → Secret
```

The exact implementation may combine endpoint configuration into the CronJob if it is static.

---

# 733. ConfigMap for Endpoints

If preferred, create:

```yaml id="b7m3q5"
apiVersion: v1
kind: ConfigMap
metadata:
  name: etcd-backup-config
  namespace: etcd-backup

data:
  ETCD_ENDPOINTS: "https://<MASTER-01>:2379,https://<MASTER-02>:2379,https://<MASTER-03>:2379"
  BACKUP_DIR: "/backup"
```

The CronJob can then use:

```yaml id="5xq2m8"
envFrom:
  - configMapRef:
      name: etcd-backup-config
```

This makes non-sensitive configuration easier to maintain.

---

# 734. Secret and ConfigMap Separation

The resulting configuration is:

```text
ConfigMap
├── ETCD_ENDPOINTS
└── BACKUP_DIR

Secret
├── ca.crt
├── client.crt
└── client.key

PVC
└── snapshots
```

This cleanly separates:

```text
Configuration
Credentials
Persistent data
```

---

# 735. Backup Image Pull Policy

For a versioned image:

```yaml id="w8m3q5"
imagePullPolicy: IfNotPresent
```

can reduce unnecessary pulls when the image is already present.

If images are always expected to be fetched from a registry, the policy can be adjusted accordingly.

Avoid relying on mutable `latest` tags.

---

# 736. Private Registry

If the backup image is stored in a private registry, the CronJob may require an image-pull Secret.

Conceptually:

```text
Private Registry
       │
       ▼
imagePullSecret
       │
       ▼
Backup Pod
```

Do not embed registry credentials into the container image.

---

# 737. Network Requirements

The backup Pod must be able to reach:

```text
Master 01 → etcd :2379
Master 02 → etcd :2379
Master 03 → etcd :2379
```

Test connectivity from the backup Pod where possible.

For example:

```bash id="p4x7m3"
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  nc -vz <MASTER-01-ETCD-IP> 2379
```

Repeat for the other members.

TCP connectivity alone does not validate TLS or etcd health.

---

# 738. NetworkPolicy Consideration

If Calico NetworkPolicy is used, ensure the backup namespace can reach etcd client endpoints.

Conceptually:

```text
Backup Pod
    │
    │ TCP 2379
    ▼
Control Plane etcd
```

A restrictive NetworkPolicy must not unintentionally block this traffic.

The policy should allow only the required traffic.

---

# 739. Backup CronJob and Calico

Calico controls Pod networking.

The backup Pod therefore requires:

```text
Pod networking
        │
        ▼
Route to etcd endpoints
        │
        ▼
TCP 2379
```

If the backup Pod cannot reach etcd:

```text
Check Calico
Check routes
Check firewall
Check NetworkPolicy
Check etcd listener
Check TLS
```

---

# 740. Failure Handling

The CronJob must expose failures through Kubernetes.

Example:

```text
Backup script
     │
     ▼
exit 1
     │
     ▼
Pod Failed
     │
     ▼
Job Failed
     │
     ▼
CronJob execution recorded as failed
```

This allows administrators and monitoring systems to detect backup failures.

---

# 741. Verify Failed Job

List Jobs:

```bash id="m8q3x7"
kubectl get jobs -n etcd-backup
```

Find a failed Job and inspect:

```bash id="p5n7m2"
kubectl describe job <JOB-NAME> -n etcd-backup
```

Then:

```bash id="q4m8x3"
kubectl get pods -n etcd-backup
```

Inspect logs:

```bash id="x7p3m5"
kubectl logs -n etcd-backup <FAILED-POD>
```

---

# 742. CronJob Monitoring

The monitoring system from Part 11 should eventually monitor:

```text
CronJob status
Job failures
Job successes
Pod failures
Last successful backup
Backup duration
PVC usage
```

This provides operational visibility.

---

# 743. Backup Success Metric

The project should eventually expose or derive:

```text
Last successful backup timestamp
```

Conceptually:

```text
Current Time
     │
     ▼
Last Successful Backup
     │
     ▼
Backup Age
```

If the age exceeds the expected backup interval plus an operational tolerance, an alert should be generated.

---

# 744. Backup Duration

Record:

```text
Backup start time
Backup end time
Backup duration
```

For example:

```text
Start: 02:00:01
End:   02:02:14

Duration: 2m13s
```

Monitoring duration over time helps identify:

* etcd growth
* storage performance degradation
* network issues
* resource contention

---

# 745. Backup Snapshot Size

Record the snapshot size:

```bash id="n8m4x2"
stat -c%s /backup/snapshots/<SNAPSHOT>.db
```

or:

```bash id="p5q7m3"
du -h /backup/snapshots/<SNAPSHOT>.db
```

Track snapshot growth over time.

This feeds directly into the storage-capacity planning from Part 14.

---

# 746. Backup Storage Usage

The backup process can report:

```bash id="m3x8q5"
df -h /backup
```

This allows the logs to contain storage information after a successful backup.

---

# 747. Backup Completion Log

A useful final log entry is:

```text
Backup completed successfully
Snapshot: <FILENAME>
Size: <SIZE>
Checksum: <CHECKSUM>
Duration: <DURATION>
```

Do not log:

```text
TLS private keys
Secret values
Authentication tokens
```

---

# 748. Manual Trigger Procedure

For operational testing:

```bash id="x4m7p8"
kubectl create job \
  --from=cronjob/etcd-backup \
  etcd-backup-manual-$(date +%s) \
  -n etcd-backup
```

Then:

```bash id="q6m3x8"
kubectl get jobs -n etcd-backup
```

Then:

```bash id="p8n4m2"
kubectl logs -n etcd-backup job/<JOB-NAME>
```

This provides a safe way to test the production CronJob configuration without waiting for its scheduled execution.

---

# 749. CronJob Update Procedure

After modifying:

```text
cronjob.yaml
```

apply:

```bash id="m7x3q5"
kubectl apply -f etcd-backup/cronjob.yaml
```

Verify:

```bash id="q4n8m2"
kubectl describe cronjob etcd-backup -n etcd-backup
```

Trigger a manual Job again to validate the updated configuration.

---

# 750. Helm Consideration

The etcd backup CronJob can be managed through:

* Plain Kubernetes YAML
* Helm
* Kustomize

For this project, plain Kubernetes YAML is sufficient if the backup deployment is small.

If multiple environments require different:

```text
Endpoints
StorageClass
Schedule
Retention
Image
```

then Helm or Kustomize may be introduced later.

---

# 751. Git Repository Structure

The backup configuration can be stored as:

```text id="z4k6p8"
etcd-backup/
├── cronjob.yaml
├── pvc.yaml
├── serviceaccount.yaml
├── configmap.yaml
├── secret-example.yaml
├── backup.sh
├── Dockerfile
└── README.md
```

However, the actual project requirement is to maintain **one root README**.

Therefore:

```text id="t5q3m7"
README.md
```

at the repository root remains the primary documentation.

The files above are deployment manifests/scripts, not separate documentation files.

---

# 752. Secret Template

If a Secret example is committed, it must not contain real credentials.

Use a template such as:

```yaml id="n8m4x2"
apiVersion: v1
kind: Secret
metadata:
  name: etcd-backup-tls
  namespace: etcd-backup

type: Opaque

data:
  ca.crt: <BASE64-PLACEHOLDER>
  client.crt: <BASE64-PLACEHOLDER>
  client.key: <BASE64-PLACEHOLDER>
```

Alternatively, document the `kubectl create secret` procedure without committing the Secret itself.

---

# 753. CronJob Security

The CronJob should:

```text
Run with dedicated ServiceAccount
Use minimal privileges
Mount TLS credentials read-only
Mount backup PVC only where required
Avoid privileged containers
Avoid hostPath access
Avoid access to /var/lib/etcd
Avoid storing secrets in images
```

---

# 754. HostPath Must Not Be Required

The backup CronJob should not require:

```yaml
hostPath:
```

for the etcd data directory.

Avoid:

```text
hostPath → /var/lib/etcd
```

because the design is based on the etcd API snapshot mechanism.

This also allows the backup Pod to remain independent of a particular control-plane node.

---

# 755. Control-Plane Failure Scenario

Suppose:

```text
Master 01 → unavailable
Master 02 → Leader
Master 03 → Follower
```

The CronJob should still be able to discover:

```text
Master 02
Master 03
```

and determine the current leader dynamically.

The backup design therefore avoids:

```text
Backup Pod
   │
   ▼
Master 01 only
```

---

# 756. Worker Failure Scenario

If the worker hosting the backup Pod fails:

```text
Worker 02 → unavailable
```

Kubernetes can create another Pod for the Job according to Job behavior, subject to:

* PVC accessibility
* Storage topology
* Scheduling constraints
* Remaining cluster capacity

The backup data remains on the PVC.

---

# 757. OpenEBS Storage Failure Scenario

If the backup PVC cannot be mounted:

```text
Backup Job
    │
    ▼
PVC mount failure
    │
    ▼
Pod cannot execute
    │
    ▼
Job fails/retries
```

The CronJob should not report a successful backup.

---

# 758. etcd Failure Scenario

If etcd has no usable leader:

```text
Backup Pod
    │
    ▼
Health check
    │
    ▼
No valid leader
    │
    ▼
Backup FAILED
```

The failed Job should become visible to administrators and monitoring.

---

# 759. Backup Success Scenario

A successful execution should look like:

```text
02:00
CronJob creates Job

02:00
Backup Pod starts

02:00
TLS credentials mounted

02:00
PVC mounted

02:00
etcd health verified

02:00
Leader identified

02:01
Snapshot created

02:01
Snapshot validated

02:01
Checksum verified

02:01
Metadata written

02:01
Pod exits 0

02:01
Job Complete
```

The exact duration depends on the cluster and storage performance.

---

# 760. Backup Failure Scenario

Example:

```text
02:00
CronJob creates Job

02:00
Backup Pod starts

02:00
etcd health check fails

02:00
Backup exits non-zero

02:00
Job fails

02:xx
Job retry occurs

02:xx
Backup succeeds
```

The final operational status should reflect the successful retry while preserving enough Job history to investigate the initial failure.

---

# 761. Verify 24-Hour Scheduling

After deployment, monitor:

```bash id="q8m4x3"
kubectl get cronjob etcd-backup -n etcd-backup
```

Then:

```bash id="p7m3x8"
kubectl get jobs -n etcd-backup
```

Over multiple days, verify that a new Job is created approximately every 24 hours.

Record:

```text
Schedule
Job start time
Job completion time
Job result
Snapshot timestamp
Snapshot size
```

---

# 762. Backup Schedule Verification

A successful schedule should produce:

```text
Day 1 → Job 1 → Snapshot 1
Day 2 → Job 2 → Snapshot 2
Day 3 → Job 3 → Snapshot 3
...
```

The backup files should remain on:

```text
etcd-backup-pvc
```

until the retention process removes them.

---

# 763. Backup Schedule Does Not Equal Backup Success

A CronJob being scheduled does not prove that backups are working.

These are separate states:

```text
CronJob exists
       ≠
Backup succeeded
```

A proper validation requires:

```text
CronJob scheduled
       │
       ▼
Job created
       │
       ▼
Pod completed
       │
       ▼
Snapshot created
       │
       ▼
Snapshot validated
       │
       ▼
Snapshot persisted
```

---

# 764. Final CronJob Validation

Run:

```bash id="m5x8q3"
kubectl get cronjob -n etcd-backup
```

Then:

```bash id="q7n3m2"
kubectl get jobs -n etcd-backup
```

Then:

```bash id="x4p8m5"
kubectl get pods -n etcd-backup
```

Then:

```bash id="n6m3q8"
kubectl get pvc -n etcd-backup
```

Finally:

```bash id="p7x2m4"
kubectl get pv
```

All relevant resources should be healthy.

---

# 765. CronJob Validation Checklist

```text
CronJob
[ ] CronJob exists
[ ] Namespace is etcd-backup
[ ] Schedule is configured
[ ] Timezone verified
[ ] CronJob is not suspended
[ ] ConcurrencyPolicy = Forbid
[ ] Successful Job history configured
[ ] Failed Job history configured
[ ] backoffLimit configured

Backup Pod
[ ] Correct backup image
[ ] Image version pinned
[ ] ServiceAccount configured
[ ] TLS Secret mounted
[ ] TLS mount is read-only
[ ] Backup PVC mounted
[ ] /backup is writable
[ ] Security context reviewed
[ ] Resource requests/limits configured

etcd
[ ] All etcd endpoints configured
[ ] TLS authentication works
[ ] Health check works
[ ] Leader discovered dynamically
[ ] Snapshot created
[ ] Snapshot validated

Storage
[ ] Snapshot written to PVC
[ ] Checksum created
[ ] Metadata created
[ ] Snapshot survives Pod deletion
[ ] Multiple snapshots can coexist
[ ] PVC remains Bound

Failure Handling
[ ] etcd failure produces failed Job
[ ] Snapshot failure produces failed Job
[ ] Storage failure produces failed Job
[ ] Retry behavior tested
[ ] No overlapping backup executions

Monitoring
[ ] Job status visible
[ ] Failed Jobs visible
[ ] PVC usage monitored
[ ] Backup age monitored
[ ] Backup success/failure observable
```

---

# 766. Final Automated Backup Architecture

After Part 15, the complete automated backup path is:

```text
                         Kubernetes Cluster
                                │
             ┌──────────────────┼──────────────────┐
             │                  │                  │
             ▼                  ▼                  ▼
         Master 01          Master 02          Master 03
            etcd                etcd                etcd
             │                  │                  │
             └──────────────────┼──────────────────┘
                                │
                         etcd Cluster
                                │
                         Leader Election
                                │
                                ▼
                     ┌─────────────────────┐
                     │   Backup CronJob     │
                     │   Every 24 Hours     │
                     └──────────┬──────────┘
                                │
                                ▼
                         Backup Job
                                │
                                ▼
                         Backup Pod
                         │          │
                         │          │
                         ▼          ▼
                    TLS Secret     PVC
                         │          │
                         ▼          ▼
                       etcd       OpenEBS
                      :2379          │
                                    ▼
                             Backup Snapshots
```

---

# 767. Operational Flow

The complete operational process is:

```text
Every 24 hours
       │
       ▼
CronJob starts
       │
       ▼
Backup Pod scheduled
       │
       ▼
Mount TLS credentials
       │
       ▼
Mount OpenEBS PVC
       │
       ▼
Check etcd health
       │
       ▼
Find current leader
       │
       ▼
Create snapshot
       │
       ▼
Validate snapshot
       │
       ▼
Generate checksum
       │
       ▼
Write metadata
       │
       ▼
Backup SUCCESS
```

If a critical operation fails:

```text
Critical failure
       │
       ▼
Backup Pod exits non-zero
       │
       ▼
Job FAILED
       │
       ▼
Kubernetes retries according to Job policy
       │
       ▼
Monitoring detects failure
```

---

# 768. Key Design Decisions

The project establishes the following CronJob decisions:

1. etcd backups execute automatically every 24 hours.
2. The backup runs as a Kubernetes CronJob.
3. The CronJob creates a Job, which creates the backup Pod.
4. `concurrencyPolicy: Forbid` prevents overlapping executions.
5. The backup Pod uses a dedicated ServiceAccount.
6. etcd TLS credentials are supplied through a Kubernetes Secret.
7. Backup data is written to `etcd-backup-pvc`.
8. The backup Pod does not access `/var/lib/etcd`.
9. etcd endpoints are configured separately from the HAProxy Kubernetes API endpoint.
10. The current etcd leader is discovered dynamically during every backup execution.
11. Snapshot validation is required before declaring success.
12. SHA-256 checksum verification is performed.
13. Kubernetes Job history and backup-file retention are separate mechanisms.
14. Failed backup executions must be visible through Kubernetes status and monitoring.
15. The CronJob uses a versioned backup image rather than a mutable `latest` image.
16. Backup credentials and snapshots are never committed to Git.

---

# 769. Next Part

## Part 16 — Backup Retention and Lifecycle Management

Part 16 will implement the retention policy for the snapshots stored on the OpenEBS PVC.

The target architecture becomes:

```text
                     etcd Backup CronJob
                              │
                              ▼
                         New Snapshot
                              │
                              ▼
                      /backup/snapshots
                              │
             ┌────────────────┴────────────────┐
             │                                 │
             ▼                                 ▼
       Recent Backups                    Old Backups
             │                                 │
             ▼                                 ▼
          RETAIN                             DELETE
```

Part 16 will cover:

* Snapshot retention period
* Daily backup retention
* File age calculation
* Safe deletion
* Retaining the newest valid backup
* Metadata/checksum cleanup
* Storage-capacity management
* Retention failure handling
* Preventing deletion of active/incomplete backups
* Backup integrity checks before cleanup
* Handling failed backup executions
* Interaction between CronJob history and snapshot retention
* Monitoring backup storage growth
* Final backup lifecycle design

# Part 16 — Backup Retention and Lifecycle Management

## 770. Objective

The etcd backup process creates a new snapshot every 24 hours and stores the snapshot on an OpenEBS-backed PersistentVolumeClaim.

Without a retention mechanism, the backup directory will continuously grow and eventually consume the available PVC capacity.

This part implements a controlled backup lifecycle that:

* Retains backups for a configurable number of days.
* Deletes backups older than the retention period.
* Keeps snapshot, checksum, and metadata files synchronized.
* Never deletes the backup currently being created.
* Never deletes the PVC as part of file retention.
* Preserves at least the newest valid backup where possible.
* Prevents incomplete or unvalidated snapshots from becoming retention candidates.
* Provides storage-capacity monitoring.
* Supports future restore operations.

The resulting lifecycle is:

```text
etcd Snapshot
      |
      v
Temporary File
      |
      v
Snapshot Validation
      |
      v
SHA-256 Checksum
      |
      v
Metadata
      |
      v
Mark Backup Complete
      |
      v
Retention Check
      |
      v
Delete Expired Backup Set
      |
      v
OpenEBS PVC
```

---

## 771. Backup Retention Policy

The retention period should be configurable rather than hard-coded into the application.

For example:

```text
Backup frequency:       Every 24 hours
Retention period:       14 days
Expected backups:       Approximately 14
Storage:                OpenEBS-backed PVC
```

A 14-day retention policy means that backups older than the configured retention window become eligible for deletion.

Example:

```text
Day 01  → etcd-snapshot-20260901-020000.db
Day 02  → etcd-snapshot-20260902-020000.db
Day 03  → etcd-snapshot-20260903-020000.db
...
Day 14  → etcd-snapshot-20260914-020000.db
Day 15  → new backup created
          old backup becomes eligible for deletion
```

The retention policy should be documented as part of the cluster backup configuration.

Recommended configuration:

```text
BACKUP_INTERVAL=24h
RETENTION_DAYS=14
```

The actual retention period should be selected according to the recovery requirements and available storage capacity.

---

## 772. Backup Storage Layout

The backup PVC uses a structured directory layout:

```text
/backup/
├── snapshots/
│   ├── etcd-snapshot-20260901-020000.db
│   ├── etcd-snapshot-20260902-020000.db
│   └── etcd-snapshot-20260903-020000.db
│
├── checksums/
│   ├── etcd-snapshot-20260901-020000.sha256
│   ├── etcd-snapshot-20260902-020000.sha256
│   └── etcd-snapshot-20260903-020000.sha256
│
├── metadata/
│   ├── etcd-snapshot-20260901-020000.json
│   ├── etcd-snapshot-20260902-020000.json
│   └── etcd-snapshot-20260903-020000.json
│
└── tmp/
```

The three permanent backup artifacts are associated by the same timestamp:

```text
Snapshot:
etcd-snapshot-20260903-020000.db

Checksum:
etcd-snapshot-20260903-020000.sha256

Metadata:
etcd-snapshot-20260903-020000.json
```

These files should be treated as one logical backup set.

---

## 773. Backup Completeness

A backup should not be considered complete simply because the `.db` file exists.

A valid backup set should contain:

```text
Snapshot
+
Checksum
+
Metadata
```

The snapshot should also have successfully passed the configured etcd snapshot validation procedure from Part 13.

For example:

```text
etcd-snapshot-20260903-020000.db
etcd-snapshot-20260903-020000.sha256
etcd-snapshot-20260903-020000.json
```

Only after these steps succeed should the backup become eligible for retention management.

---

## 774. Use Temporary Files During Backup Creation

A snapshot should not be written directly to its final filename.

Instead, the backup process should first write to a temporary location:

```text
/backup/tmp/etcd-snapshot-20260903-020000.db.tmp
```

After successful snapshot creation:

```text
Snapshot validation
        |
        v
Checksum generation
        |
        v
Metadata generation
        |
        v
Move to final location
```

Example:

```bash
SNAPSHOT_NAME="etcd-snapshot-${TIMESTAMP}.db"

etcdctl snapshot save \
  "/backup/tmp/${SNAPSHOT_NAME}.tmp" \
  --endpoints="${SELECTED_ENDPOINT}" \
  --cacert=/etc/etcd-tls/ca.crt \
  --cert=/etc/etcd-tls/client.crt \
  --key=/etc/etcd-tls/client.key
```

After successful validation:

```bash
mv \
  "/backup/tmp/${SNAPSHOT_NAME}.tmp" \
  "/backup/snapshots/${SNAPSHOT_NAME}"
```

This prevents the retention process from mistaking an actively written temporary file for a completed backup.

---

## 775. Why Temporary Files Are Important

Consider a snapshot that takes several minutes to complete.

If the final filename is created immediately:

```text
/backup/snapshots/etcd-snapshot-20260903-020000.db
```

another process could interpret the file as a completed backup while it is still being written.

This can cause problems such as:

```text
Retention process
        |
        v
Sees old/incomplete file
        |
        v
Deletes or processes incorrect artifact
```

Using a temporary filename provides a clear distinction:

```text
.tmp
  |
  | backup in progress
  |
  v
validated final file
```

Retention should only operate on completed backup files.

---

## 776. Recommended Retention Design

For this project, retention should be performed **after a successful backup has been created and validated**.

The recommended sequence is:

```text
CronJob starts
      |
      v
Check OpenEBS PVC
      |
      v
Detect etcd leader
      |
      v
Check etcd health
      |
      v
Create snapshot
      |
      v
Validate snapshot
      |
      v
Generate checksum
      |
      v
Generate metadata
      |
      v
Commit backup set
      |
      v
Run retention
      |
      v
Finish Job
```

This design is preferable for the project because the backup and retention operations use the same PVC.

The backup should be safely established before old backups are removed.

---

## 777. Why Retention Runs After Backup

Retention should not execute before creating the new backup.

For example, if the PVC is almost full:

```text
Available space = 500 MB
New snapshot    = 700 MB
```

Deleting old backups first could recover storage, but it would introduce a failure mode where the newest backup has not yet been created.

The safer sequence is:

```text
Attempt new backup
       |
       +---- Success ----> Validate ----> Retention
       |
       +---- Failure ----> Keep existing backups
```

If the new backup fails, existing valid backups should remain available for recovery.

---

## 778. Retention Configuration

A configurable environment variable can be used:

```yaml
env:
  - name: RETENTION_DAYS
    value: "14"
```

Example:

```yaml
containers:
  - name: etcd-backup
    image: <ETCD-BACKUP-IMAGE>:<VERSION>

    env:
      - name: RETENTION_DAYS
        value: "14"
```

This allows the retention period to be changed without changing the backup logic.

Example:

```text
RETENTION_DAYS=7
```

means approximately one week of daily backups.

```text
RETENTION_DAYS=14
```

means approximately two weeks.

```text
RETENTION_DAYS=30
```

means approximately one month.

The value should be selected according to the project's recovery requirements and PVC capacity.

---

## 779. Retention Eligibility

A backup should be deleted only when all of the following conditions are true:

```text
Backup is complete
        AND
Backup is older than retention period
        AND
Backup is not currently being written
        AND
Backup is not the newest valid backup
```

The retention process should not delete files merely because they have an old modification time.

It should identify backup sets using the project's naming convention and associated metadata.

---

## 780. Safe Retention Logic

A simplified retention algorithm is:

```text
1. List snapshot files.
2. Ignore temporary files.
3. Identify valid backup sets.
4. Determine the newest valid backup.
5. Calculate the retention cutoff time.
6. Identify backup sets older than the cutoff.
7. Never delete the newest valid backup.
8. Delete snapshot + checksum + metadata together.
9. Report deleted backup sets.
10. Verify remaining storage.
```

Conceptually:

```text
                Backup Directory
                       |
                       v
              Discover backup sets
                       |
                       v
                Validate metadata
                       |
                       v
              Determine backup age
                       |
                       v
              Apply retention policy
                       |
             +---------+---------+
             |                   |
          Keep                 Delete
             |                   |
             v                   v
      Valid backups       Complete backup set
```

---

## 781. Example Retention Script

The backup image can contain a retention script such as:

```bash
#!/usr/bin/env bash

set -euo pipefail

BACKUP_ROOT="${BACKUP_ROOT:-/backup}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

SNAPSHOT_DIR="${BACKUP_ROOT}/snapshots"
CHECKSUM_DIR="${BACKUP_ROOT}/checksums"
METADATA_DIR="${BACKUP_ROOT}/metadata"

echo "Starting backup retention"
echo "Retention period: ${RETENTION_DAYS} days"

if [[ ! -d "${SNAPSHOT_DIR}" ]]; then
    echo "Snapshot directory does not exist"
    exit 1
fi

CUTOFF="$(date -d "${RETENTION_DAYS} days ago" +%s)"

mapfile -t SNAPSHOTS < <(
    find "${SNAPSHOT_DIR}" \
        -maxdepth 1 \
        -type f \
        -name 'etcd-snapshot-*.db' \
        -print | sort
)

if [[ "${#SNAPSHOTS[@]}" -eq 0 ]]; then
    echo "No completed snapshots found"
    exit 0
fi

NEWEST_SNAPSHOT="${SNAPSHOTS[-1]}"

echo "Newest snapshot: ${NEWEST_SNAPSHOT}"

for SNAPSHOT in "${SNAPSHOTS[@]}"; do

    if [[ "${SNAPSHOT}" == "${NEWEST_SNAPSHOT}" ]]; then
        echo "Keeping newest snapshot: ${SNAPSHOT}"
        continue
    fi

    SNAPSHOT_MTIME="$(stat -c %Y "${SNAPSHOT}")"

    if (( SNAPSHOT_MTIME >= CUTOFF )); then
        echo "Keeping recent snapshot: ${SNAPSHOT}"
        continue
    fi

    BASENAME="$(basename "${SNAPSHOT}" .db)"

    CHECKSUM="${CHECKSUM_DIR}/${BASENAME}.sha256"
    METADATA="${METADATA_DIR}/${BASENAME}.json"

    echo "Deleting expired backup set: ${BASENAME}"

    rm -f "${SNAPSHOT}"

    if [[ -f "${CHECKSUM}" ]]; then
        rm -f "${CHECKSUM}"
    fi

    if [[ -f "${METADATA}" ]]; then
        rm -f "${METADATA}"
    fi

done

echo "Backup retention completed successfully"
```

This is a baseline implementation. The production script should additionally validate the project's exact filename conventions and metadata structure before deletion.

---

## 782. Important Improvement — Protect Incomplete Backups

The retention script should ignore temporary files:

```text
*.tmp
```

For example:

```text
/backup/tmp/
```

should not be scanned as a completed snapshot directory.

If temporary files remain after a failed backup, they can be cleaned separately using a conservative temporary-file policy.

For example:

```text
/tmp backup artifact
       |
       v
Older than configured temporary-file threshold?
       |
       +---- No ----> Keep
       |
       +---- Yes ---> Delete
```

Temporary-file cleanup should never remove a recently created file.

---

## 783. Keep the Newest Valid Backup

A critical safety rule is:

> Retention must not remove the newest valid backup.

For example, if the retention calculation is incorrect or the system clock changes, the newest valid backup should still remain available.

Example:

```text
Backup 01 → expired
Backup 02 → expired
Backup 03 → expired
Backup 04 → newest valid backup
```

The result should be:

```text
Backup 01 → delete
Backup 02 → delete
Backup 03 → delete
Backup 04 → KEEP
```

This provides a minimum recovery point even when the retention policy has unexpected conditions.

---

## 784. Delete Backup Artifacts as a Set

A snapshot and its associated metadata should not be treated as independent files.

For:

```text
etcd-snapshot-20260903-020000.db
```

the associated files are:

```text
etcd-snapshot-20260903-020000.sha256
etcd-snapshot-20260903-020000.json
```

Deletion should therefore occur as:

```text
Delete backup set
        |
        +── .db
        +── .sha256
        └── .json
```

Do not leave orphaned checksum or metadata files after deleting a snapshot.

---

## 785. What Retention Must Never Delete

The retention process must not delete:

```text
/var/lib/etcd
```

or any live etcd data.

It must not delete:

```text
/etc/kubernetes/manifests/etcd.yaml
```

It must not delete Kubernetes control-plane resources.

It must not delete:

```text
etcd-backup-pvc
```

It must not delete OpenEBS storage resources.

Retention operates only on backup artifacts:

```text
/backup/snapshots/*
/backup/checksums/*
/backup/metadata/*
```

---

## 786. PVC Lifecycle vs Backup File Lifecycle

These are two separate lifecycle mechanisms.

### Backup file lifecycle

```text
Snapshot created
      |
      v
Stored on PVC
      |
      v
Retention period
      |
      v
File deleted
```

### PVC lifecycle

```text
PVC
 |
 +--> PV
       |
       +--> OpenEBS
             |
             +--> underlying storage
```

Deleting an old backup file does **not** delete the PVC.

Similarly, deleting the PVC is not part of normal backup retention.

The PVC should remain available for future backups.

---

## 787. Reclaim Policy

The PV reclaim policy should be checked:

```bash
kubectl get pv
```

and:

```bash
kubectl get pv <PV-NAME> -o jsonpath='{.spec.persistentVolumeReclaimPolicy}{"\n"}'
```

Possible policies include:

```text
Retain
Delete
```

For backup storage, the operational behavior of the selected policy should be explicitly documented.

A `Retain` policy can provide an additional safeguard against accidental PVC deletion by retaining the underlying volume resource after PVC deletion.

However, reclaim policy does not replace application-level backup retention.

---

## 788. Storage Capacity Calculation

Backup capacity should be estimated before choosing the PVC size.

A simple planning formula is:

```text
Required Storage
=
Snapshot Size
×
Backups Per Day
×
Retention Days
+
Safety Headroom
```

For daily backups:

```text
Backups Per Day = 1
```

Example:

```text
Average snapshot size = 500 MB
Backups per day       = 1
Retention             = 14 days

Estimated backup data
= 500 MB × 1 × 14
= 7 GB
```

Additional capacity should be reserved for:

```text
Metadata
Checksums
Temporary files
Snapshot growth
Filesystem overhead
Operational headroom
```

The actual etcd snapshot size should be measured from the running cluster rather than assumed.

---

## 789. Check PVC Capacity

Check the PVC:

```bash
kubectl get pvc -n etcd-backup
```

Example:

```text
NAME                STATUS   VOLUME       CAPACITY
etcd-backup-pvc     Bound    <PV-NAME>    <CAPACITY>
```

Check storage from the backup Pod:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- df -h /backup
```

For a Job Pod:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  df -h /backup
```

This should be part of regular backup validation.

---

## 790. Detect Low Disk Space

The backup process should check available storage before writing a large snapshot.

Example:

```bash
df -h /backup
```

For scripted validation:

```bash
AVAILABLE_KB="$(df -Pk /backup | awk 'NR==2 {print $4}')"

echo "Available backup storage: ${AVAILABLE_KB} KB"
```

A configurable minimum threshold can be used.

For example:

```text
MIN_FREE_SPACE_MB=1024
```

If available space is below the threshold:

```text
Backup Job
    |
    v
Storage check
    |
    v
Insufficient space
    |
    +--> Do not create unsafe backup
    |
    +--> Log failure
    |
    +--> Preserve existing backups
    |
    └--> Job fails
```

The threshold should be selected based on the expected snapshot size and PVC capacity.

---

## 791. Retention and Storage Pressure

If storage usage becomes high:

```text
PVC usage
   |
   v
80%
   |
   v
90%
   |
   v
95%
```

the system should raise an operational alert rather than waiting for the backup to fail.

Prometheus can later monitor the PVC and backup workload.

Useful metrics include:

```text
PVC capacity
PVC available space
PVC usage percentage
Latest successful backup timestamp
Backup duration
Backup size
Retention deletions
Backup failures
```

---

## 792. Interaction with Kubernetes Job History

Kubernetes CronJob history and etcd snapshot retention are different.

CronJob configuration:

```yaml
successfulJobsHistoryLimit: 3
failedJobsHistoryLimit: 3
```

controls how many Kubernetes Job objects remain.

It does **not** control how many `.db` snapshots remain on the PVC.

For example:

```text
Kubernetes Job History
        |
        +--> Job objects

Backup Retention
        |
        +--> Snapshot files
```

Therefore both mechanisms must be configured independently.

---

## 793. Backup Job History Example

Suppose:

```yaml
successfulJobsHistoryLimit: 3
```

The cluster may retain only three successful Job objects.

However, the PVC may contain:

```text
14 etcd snapshots
```

This is expected.

The Job object represents the execution of the backup process.

The snapshot represents the recovery artifact.

They have different lifecycles.

---

## 794. Retention Failure Handling

Retention failure should not automatically invalidate a successfully created backup.

For example:

```text
Snapshot creation
       |
       v
Validation
       |
       v
Checksum
       |
       v
Metadata
       |
       v
Backup committed
       |
       v
Retention fails
```

In this situation:

```text
New backup = available
Retention = failed
```

The system should report the retention failure and raise an operational alert.

The newly created valid backup should not be deleted merely because cleanup failed.

This prevents a cleanup problem from destroying the most recent recovery point.

---

## 795. Retention Logging

Retention operations should produce clear logs.

Example:

```text
Starting backup retention
Retention period: 14 days

Newest valid backup:
etcd-snapshot-20260918-020000.db

Keeping:
etcd-snapshot-20260918-091500.db

Deleting expired backup set:
etcd-snapshot-20260903-020000

Deleting:
  snapshot
  checksum
  metadata

Backup retention completed successfully
```

For troubleshooting, the logs should make it possible to determine:

* which files were scanned
* which backup was considered newest
* which backups were retained
* which backups were deleted
* why a backup was skipped
* whether cleanup succeeded.

---

## 796. Manual Retention Testing

Retention logic should be tested before enabling destructive cleanup against real backups.

Create a temporary test directory:

```bash
mkdir -p /tmp/etcd-retention-test/{snapshots,checksums,metadata,tmp}
```

Create mock backup files:

```bash
touch /tmp/etcd-retention-test/snapshots/etcd-snapshot-test-old.db
touch /tmp/etcd-retention-test/checksums/etcd-snapshot-test-old.sha256
touch /tmp/etcd-retention-test/metadata/etcd-snapshot-test-old.json
```

Create another backup:

```bash
touch /tmp/etcd-retention-test/snapshots/etcd-snapshot-test-new.db
touch /tmp/etcd-retention-test/checksums/etcd-snapshot-test-new.sha256
touch /tmp/etcd-retention-test/metadata/etcd-snapshot-test-new.json
```

Inspect:

```bash
find /tmp/etcd-retention-test -type f -print
```

The retention script should be tested against this isolated directory before using it against production backup data.

---

## 797. Test Retention Without Destructive Deletion

The retention script should support a dry-run mode.

Example:

```bash
DRY_RUN=true
```

The script can then report:

```text
Would delete:
etcd-snapshot-20260901-020000.db

Would delete:
etcd-snapshot-20260901-020000.sha256

Would delete:
etcd-snapshot-20260901-020000.json
```

but perform no deletion.

A typical implementation pattern is:

```bash
if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo "DRY RUN: would delete ${FILE}"
else
    rm -f "${FILE}"
fi
```

This should be used when initially validating the retention logic.

---

## 798. Test Retention on the OpenEBS PVC

After local dry-run testing, retention should be tested against the actual backup PVC.

First identify the PVC:

```bash
kubectl get pvc -n etcd-backup
```

Then use a temporary test Pod that mounts:

```text
etcd-backup-pvc
```

Example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: retention-test
  namespace: etcd-backup
spec:
  restartPolicy: Never
  containers:
    - name: test
      image: <TEST-IMAGE>
      command:
        - sleep
        - "3600"
      volumeMounts:
        - name: backup-storage
          mountPath: /backup
  volumes:
    - name: backup-storage
      persistentVolumeClaim:
        claimName: etcd-backup-pvc
```

Only perform destructive tests after confirming that test files are isolated from real backup artifacts.

Delete the test Pod afterward:

```bash
kubectl delete pod retention-test -n etcd-backup
```

---

## 799. Recommended Retention Execution Model

For this project, the recommended design is:

```text
One CronJob
     |
     v
One Job
     |
     +-------------------------+
     |                         |
     v                         v
Backup Process           Retention Process
     |                         |
     +-----------+-------------+
                 |
                 v
          Same OpenEBS PVC
```

The sequence is:

```text
1. Create backup
2. Validate backup
3. Create checksum
4. Create metadata
5. Commit backup
6. Run retention
7. Report final status
```

This avoids creating a second scheduled workload that could compete for the same backup PVC.

---

## 800. Why a Separate Retention CronJob Is Not the Default Design

A separate CronJob is possible:

```text
Backup CronJob
      |
      v
OpenEBS PVC

Retention CronJob
      |
      v
OpenEBS PVC
```

However, this introduces additional scheduling and concurrency considerations.

For example:

```text
Backup CronJob
      |
      | writing snapshot
      v
PVC

Retention CronJob
      |
      | deleting old files
      v
Same PVC
```

This can make coordination more complicated.

If a separate retention CronJob is required later, it should have its own:

```yaml
concurrencyPolicy: Forbid
```

and its schedule should be deliberately separated from the backup window.

For the current project, running retention after successful backup creation keeps the lifecycle simpler.

---

## 801. Backup Lifecycle State Model

A useful logical state model is:

```text
CREATING
    |
    v
VALIDATING
    |
    v
VALID
    |
    v
RETAINED
    |
    v
EXPIRED
    |
    v
DELETED
```

Failure paths:

```text
CREATING
    |
    +---- failure ----> FAILED
```

or:

```text
VALIDATING
    |
    +---- failure ----> INVALID
```

Invalid or incomplete backups should not become normal retention candidates.

---

## 802. Metadata for Retention

Each backup metadata file should contain enough information to identify the backup.

Example:

```json
{
  "backup_name": "etcd-snapshot-<TIMESTAMP>.db",
  "created_at": "<TIMESTAMP>",
  "source_endpoint": "<ETCD-ENDPOINT>",
  "cluster_member": "<ETCD-MEMBER-ID>",
  "snapshot_size_bytes": "<SIZE>",
  "sha256": "<SHA256>",
  "validation_status": "valid"
}
```

The exact metadata schema should match the implementation from Part 13.

Retention can use this metadata to distinguish a completed valid backup from an incomplete artifact.

---

## 803. Backup Integrity After Retention

After retention completes, verify:

```bash
find /backup/snapshots -type f -name '*.db' | sort
```

Then:

```bash
find /backup/checksums -type f -name '*.sha256' | sort
```

And:

```bash
find /backup/metadata -type f -name '*.json' | sort
```

The expected relationship is:

```text
Number of valid snapshots
=
Number of corresponding checksums
=
Number of corresponding metadata files
```

Any mismatch should be investigated.

---

## 804. Orphan Detection

The backup process can periodically detect orphaned files.

Examples:

```text
Snapshot exists
but checksum missing

Snapshot exists
but metadata missing

Checksum exists
but snapshot missing

Metadata exists
but snapshot missing
```

Example check:

```bash
for SNAPSHOT in /backup/snapshots/*.db; do
    [[ -e "${SNAPSHOT}" ]] || continue

    BASENAME="$(basename "${SNAPSHOT}" .db)"

    if [[ ! -f "/backup/checksums/${BASENAME}.sha256" ]]; then
        echo "WARNING: checksum missing for ${BASENAME}"
    fi

    if [[ ! -f "/backup/metadata/${BASENAME}.json" ]]; then
        echo "WARNING: metadata missing for ${BASENAME}"
    fi
done
```

This can later be integrated into monitoring.

---

## 805. Clock Considerations

Retention depends on time calculations.

The Kubernetes nodes and backup Pod should have correct system time.

Verify on the Kubernetes nodes:

```bash
timedatectl
```

Check:

```text
System clock synchronized: yes
```

The backup filename should use a consistent timestamp format.

Example:

```text
YYYYMMDD-HHMMSS
```

Example:

```text
etcd-snapshot-20260918-020000.db
```

Consistent timestamps make backup ordering and operational investigation easier.

---

## 806. Time Zone

The CronJob schedule from Part 15 uses:

```yaml
timeZone: "Asia/Kolkata"
```

The timestamp-generation logic should also use a clearly defined timezone policy.

The project should document whether filenames are generated in:

```text
UTC
```

or:

```text
Asia/Kolkata
```

A common operational choice is to use UTC in filenames while scheduling the CronJob in the local operational timezone.

Whichever convention is selected should remain consistent.

---

## 807. Backup Retention Security

Backup files contain Kubernetes control-plane state and should be treated as sensitive data.

Retention operations must not expose:

```text
TLS private keys
Kubeconfig credentials
ServiceAccount tokens
Passwords
Tailscale credentials
Cloud credentials
```

These credentials should remain in Kubernetes Secrets or another appropriate secret-management mechanism.

The PVC should contain backup artifacts only.

---

## 808. OpenEBS and Retention

OpenEBS provides persistent storage for:

```text
/backup
```

It does not determine which backup files should be retained.

Therefore:

```text
OpenEBS
    |
    +--> Provides persistent storage
```

while:

```text
Backup application
    |
    +--> Determines retention
```

The responsibilities are separate:

| Component          | Responsibility                         |
| ------------------ | -------------------------------------- |
| etcd               | Provides cluster state                 |
| Backup workload    | Creates snapshots                      |
| Validation logic   | Confirms snapshot integrity            |
| Checksum logic     | Provides integrity verification        |
| Retention logic    | Removes expired backups                |
| PVC                | Provides persistent filesystem storage |
| OpenEBS            | Provides the storage backend           |
| Prometheus/Grafana | Monitors storage and backup health     |

---

## 809. Backup Lifecycle Summary

The complete lifecycle is:

```text
Every 24 Hours
      |
      v
CronJob
      |
      v
Create Job
      |
      v
Detect etcd Leader
      |
      v
Health Check
      |
      v
Create Temporary Snapshot
      |
      v
Validate Snapshot
      |
      v
Generate SHA-256
      |
      v
Generate Metadata
      |
      v
Commit Backup Set
      |
      v
Apply Retention Policy
      |
      v
Delete Expired Backup Sets
      |
      v
Verify Storage
      |
      v
Job Complete
```

---

## 810. Failure-Safe Lifecycle

The desired failure behavior is:

```text
Backup succeeds
    |
    +--> Retention succeeds
    |       |
    |       +--> Job succeeds
    |
    +--> Retention fails
            |
            +--> New backup remains
            +--> Cleanup failure logged
            +--> Alert generated
```

If snapshot creation fails:

```text
Snapshot fails
    |
    +--> Existing backups remain
    +--> Temporary artifact cleaned
    +--> Job fails
    +--> Kubernetes retries according to Job policy
```

If validation fails:

```text
Validation fails
    |
    +--> Backup not committed
    +--> Invalid artifact removed/quarantined
    +--> Existing valid backups preserved
```

This prioritizes preservation of usable recovery points.

---

## 811. Final Validation Checklist

### Retention configuration

```text
[ ] Retention period is explicitly configured
[ ] Backup frequency is documented
[ ] Retention policy is documented
```

### Backup completeness

```text
[ ] Snapshot validation occurs before retention
[ ] Checksum is generated
[ ] Metadata is generated
[ ] Temporary files are not treated as completed backups
```

### Safe deletion

```text
[ ] Expired backups are identified correctly
[ ] Newest valid backup is protected
[ ] Snapshot/checksum/metadata are deleted together
[ ] Live etcd data is never touched
[ ] PVC is never deleted by retention
```

### Storage

```text
[ ] etcd-backup-pvc is Bound
[ ] OpenEBS storage is healthy
[ ] PVC capacity is sufficient
[ ] Free-space monitoring is configured
[ ] Storage headroom is documented
```

### Operational behavior

```text
[ ] Retention runs after successful backup creation
[ ] Retention failures are logged
[ ] Backup failures preserve existing backups
[ ] Kubernetes Job history is configured separately
[ ] Orphan detection is available
```

### Testing

```text
[ ] Retention tested using dry-run
[ ] Retention tested with isolated test files
[ ] PVC persistence verified
[ ] Backup files verified after cleanup
[ ] Restore workflow is planned
```

---

## 812. Final Backup Lifecycle Architecture

The completed design is:

```text
                    Kubernetes Cluster
                    ==================

                         etcd Cluster
                    +-------------------+
                    | Master 01         |
                    | Master 02         |
                    | Master 03         |
                    +---------+---------+
                              |
                              | TLS :2379
                              v
                    +-------------------+
                    | Backup CronJob    |
                    |                   |
                    | Leader Detection  |
                    | Snapshot          |
                    | Validation        |
                    | Checksum          |
                    | Metadata          |
                    | Retention         |
                    +---------+---------+
                              |
                              | /backup
                              v
                    +-------------------+
                    | etcd-backup-pvc   |
                    +---------+---------+
                              |
                              v
                    +-------------------+
                    | OpenEBS           |
                    +---------+---------+
                              |
                              v
                    +-------------------+
                    | Persistent        |
                    | Storage           |
                    +-------------------+
```

The resulting backup lifecycle provides:

```text
Automated backup
        +
Leader-aware snapshot
        +
Snapshot validation
        +
Checksum verification
        +
Persistent OpenEBS storage
        +
Controlled retention
        +
Storage monitoring
        +
Failure-safe cleanup
```

This establishes the backup storage lifecycle required before implementing the restore procedure.

---

## 813. Part 16 Completion Criteria

Part 16 is complete when:

```text
[ ] etcd backups are created every 24 hours
[ ] Backups are stored on the OpenEBS-backed PVC
[ ] Retention period is configurable
[ ] Backup sets contain snapshot/checksum/metadata
[ ] Temporary files cannot be mistaken for completed backups
[ ] Expired backup sets are safely removed
[ ] Newest valid backup is protected
[ ] PVC is not deleted during retention
[ ] Storage capacity is monitored
[ ] Retention has been tested safely
[ ] Failure handling is documented
```

---

## 814. Next Part

**Part 17 — Restore**

The next part will document the etcd restore procedure, including:

```text
Backup Selection
      |
      v
Snapshot Validation
      |
      v
Restore Directory
      |
      v
etcd Restore
      |
      v
Control-Plane Recovery
      |
      v
Cluster Validation
```

The restore procedure should be treated as a controlled disaster-recovery operation and should be tested separately from the normal daily backup process.

# Part 17 — etcd Restore and Disaster Recovery

## 815. Objective

The purpose of the restore process is to recover the Kubernetes control-plane state from a previously validated etcd snapshot.

The etcd snapshot contains the Kubernetes cluster's persistent control-plane data, including resources such as:

* Namespaces
* Deployments
* Services
* ConfigMaps
* Secrets
* RBAC objects
* ServiceAccounts
* PersistentVolume and PersistentVolumeClaim objects
* Custom Resources
* Other Kubernetes API state stored in etcd

The restore process is a **disaster-recovery operation** and must be performed carefully.

The normal backup flow is:

```text
etcd
 |
 v
Snapshot
 |
 v
Validation
 |
 v
Checksum
 |
 v
OpenEBS PVC
```

The restore flow reverses this process:

```text
OpenEBS PVC
 |
 v
Backup Selection
 |
 v
Checksum Verification
 |
 v
Snapshot Validation
 |
 v
etcd Restore
 |
 v
Control-Plane Recovery
 |
 v
Cluster Validation
```

---

## 816. Important Restore Principle

An etcd snapshot should **not** be restored by simply copying the `.db` file over the running etcd data directory.

Do not perform:

```bash
cp etcd-snapshot.db /var/lib/etcd/
```

or:

```bash
mv etcd-snapshot.db /var/lib/etcd/member/snap/
```

against a running etcd member.

The restore operation must use the supported etcd restore tooling and a controlled etcd startup procedure.

---

## 817. Restore Scenarios

There are several possible recovery scenarios.

### Scenario 1 — Accidental Kubernetes Object Deletion

Example:

```text
Deployment deleted
Secret deleted
ConfigMap deleted
Namespace deleted
```

If the deleted state existed in the selected snapshot, restoring etcd can recover the cluster state represented by that snapshot.

However, restoring an entire etcd snapshot also rolls the cluster state back to the snapshot's point in time.

Therefore, a full etcd restore should not be used casually for a single-object recovery without understanding the consequences.

---

### Scenario 2 — etcd Data Corruption

```text
etcd
 |
 +--> data corruption
 |
 v
Healthy backup snapshot
 |
 v
Restore etcd
```

The snapshot can be used as a recovery source.

---

### Scenario 3 — Complete Control-Plane Failure

If all three control-plane nodes are lost or their etcd data becomes unusable:

```text
Master 01 ──X
Master 02 ──X
Master 03 ──X

        |
        v

OpenEBS Backup
        |
        v
Valid etcd Snapshot
        |
        v
Control-Plane Recovery
```

The recovery procedure becomes a disaster-recovery operation for the entire control plane.

---

## 818. Restore Safety Requirements

Before restoring etcd:

```text
[ ] Confirm incident and recovery requirement
[ ] Stop normal backup activity
[ ] Select the correct snapshot
[ ] Verify checksum
[ ] Validate snapshot
[ ] Record current cluster state if possible
[ ] Confirm etcd version compatibility
[ ] Confirm TLS configuration
[ ] Stop affected etcd members
[ ] Restore to a separate directory first
[ ] Validate restored data
[ ] Start etcd using the restored data
```

Do not begin a restore while the normal backup CronJob is simultaneously creating a snapshot.

---

## 819. Stop the Backup CronJob

Before a planned restore, suspend the backup CronJob:

```bash
kubectl patch cronjob etcd-backup \
  -n etcd-backup \
  -p '{"spec":{"suspend":true}}'
```

Verify:

```bash
kubectl get cronjob etcd-backup -n etcd-backup
```

Expected:

```text
NAME          SUSPEND
etcd-backup   True
```

This prevents a new backup Job from starting while recovery is in progress.

Existing backup Jobs should also be checked:

```bash
kubectl get jobs -n etcd-backup
```

If a backup Job is currently running, determine whether it must be stopped before proceeding.

---

## 820. Select the Backup

List available snapshots:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  find /backup/snapshots \
  -maxdepth 1 \
  -type f \
  -name '*.db' \
  -print | sort
```

Example:

```text
/backup/snapshots/etcd-snapshot-20260915-020000.db
/backup/snapshots/etcd-snapshot-20260916-020000.db
/backup/snapshots/etcd-snapshot-20260917-020000.db
/backup/snapshots/etcd-snapshot-20260918-020000.db
```

The selected backup should be explicitly recorded.

Example:

```text
Selected snapshot:

etcd-snapshot-20260918-020000.db
```

Do not automatically assume that the newest file is the correct recovery point.

The recovery operator should consider:

* When the incident occurred
* When the backup was created
* Whether the backup passed validation
* Whether the backup is known to contain the desired cluster state

---

## 821. Verify Backup Checksum

Locate the checksum:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  ls -l /backup/checksums/
```

Verify it:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  sha256sum -c \
  /backup/checksums/<SNAPSHOT-NAME>.sha256
```

Expected result:

```text
<SNAPSHOT-NAME>.db: OK
```

If verification fails:

```text
Checksum failure
      |
      v
DO NOT RESTORE
```

Select another validated backup.

---

## 822. Validate the Snapshot

The snapshot should be inspected using a version-compatible etcd utility.

Depending on the installed etcd version and tooling:

```bash
etcdutl snapshot status <SNAPSHOT>
```

or:

```bash
etcdctl snapshot status <SNAPSHOT>
```

The exact command should match the etcd tooling installed in the backup image.

Check the tool version:

```bash
etcdutl version
```

or:

```bash
etcdctl version
```

The snapshot validation should provide information such as:

```text
Revision
Hash
Total Keys
Database Size
```

The exact output depends on the etcd version.

---

## 823. Check Snapshot Metadata

Inspect the associated metadata:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  cat /backup/metadata/<SNAPSHOT-NAME>.json
```

Confirm:

```text
[ ] Snapshot filename
[ ] Creation timestamp
[ ] Snapshot size
[ ] SHA-256
[ ] Validation status
[ ] Source etcd member information
[ ] Other metadata defined in Part 13
```

The metadata should agree with the selected snapshot.

---

## 824. Preserve the Current etcd State

Before replacing the current etcd data, preserve the existing state whenever possible.

The exact procedure depends on the failure scenario.

If the current etcd data is still accessible, create a separate copy or snapshot for forensic/recovery purposes before destructive changes.

Do not overwrite the only copy of potentially useful current state.

Example conceptual layout:

```text
/var/lib/etcd/
      |
      +--> current etcd data
      |
      +--> preserved recovery copy
      |
      +--> restored etcd data
```

The preservation strategy should be documented before executing a production restore.

---

## 825. Restore to a Separate Directory

The etcd restore should initially target a new directory rather than the existing live data directory.

Example:

```text
/var/lib/etcd-restore/
```

instead of:

```text
/var/lib/etcd/
```

Conceptually:

```text
Snapshot
   |
   v
etcd restore
   |
   v
/var/lib/etcd-restore/
```

This makes it possible to inspect the restored filesystem before replacing the live etcd data.

---

## 826. Restore Tooling

The restore command must match the installed etcd version.

A modern etcd restore operation can use:

```bash
etcdutl snapshot restore
```

Example structure:

```bash
etcdutl snapshot restore \
  /path/to/<SNAPSHOT-NAME>.db \
  --data-dir=/var/lib/etcd-restore
```

Additional cluster parameters may be required depending on the etcd deployment.

For a kubeadm-managed stacked-etcd cluster, the restore procedure must account for the existing static Pod configuration and the three-member etcd topology.

Do not copy this command unchanged into a production recovery procedure without verifying the installed etcd version and restore options.

---

## 827. Three-Member etcd Cluster Restore Strategy

This project has:

```text
Master 01 → etcd member
Master 02 → etcd member
Master 03 → etcd member
```

Normal operation:

```text
             +----------------+
             |    etcd        |
             |    cluster     |
             +-------+--------+
                     |
          +----------+----------+
          |          |          |
          v          v          v
      Master 01  Master 02  Master 03
```

A full restore should not be performed by independently restoring the same snapshot into three existing etcd members and starting them simultaneously.

The restored cluster must be treated as a **new logical etcd cluster state**.

The recovery procedure must therefore preserve a consistent member configuration.

---

## 828. Why the Existing etcd Members Must Be Controlled

Suppose the snapshot represents:

```text
Revision = R
```

while the currently running cluster has:

```text
Revision = R + N
```

The restored cluster represents an earlier point in the cluster's history.

If old and restored members are allowed to communicate incorrectly, the recovery can become inconsistent.

Therefore:

```text
Existing etcd cluster
        |
        X
        |
Restored etcd cluster
```

must be carefully separated during recovery.

---

## 829. Control-Plane Static Pod Consideration

With kubeadm, etcd is commonly managed as a static Pod.

Inspect:

```bash
sudo cat /etc/kubernetes/manifests/etcd.yaml
```

The manifest defines important settings such as:

```text
Image
Name
Data directory
Client URLs
Peer URLs
Certificates
Cluster configuration
```

Before a restore, record the existing configuration.

Example:

```bash
sudo cp \
  /etc/kubernetes/manifests/etcd.yaml \
  /etc/kubernetes/manifests/etcd.yaml.backup
```

This backup should be stored outside Git if it contains environment-specific sensitive information.

---

## 830. Stop etcd Through Static Pod Control

Because kubelet manages the static etcd Pod, simply deleting the Pod may cause kubelet to recreate it.

For controlled recovery, the etcd static Pod manifest must be handled carefully.

A common approach is to temporarily move the manifest out of:

```text
/etc/kubernetes/manifests/
```

so kubelet no longer manages that static Pod.

For example:

```bash
sudo mkdir -p /etc/kubernetes/manifests-disabled
sudo mv \
  /etc/kubernetes/manifests/etcd.yaml \
  /etc/kubernetes/manifests-disabled/
```

Then verify the etcd container stops.

The exact sequence should be coordinated with kubelet and the container runtime.

Do not perform this step casually on a healthy production cluster.

---

## 831. Restore Directory Preparation

After the affected etcd member is stopped, prepare the restore directory.

Example:

```bash
sudo mkdir -p /var/lib/etcd-restore
sudo chown -R root:root /var/lib/etcd-restore
```

The directory permissions must match the requirements of the etcd process.

---

## 832. Copy the Selected Snapshot

The selected snapshot must be made available to the restore host.

If the snapshot is on the OpenEBS PVC, the recovery workflow can use a temporary recovery Pod to expose the file to the recovery environment.

Conceptually:

```text
OpenEBS PVC
      |
      v
Recovery Pod
      |
      v
Selected Snapshot
      |
      v
Recovery Host
```

The exact transfer mechanism depends on the recovery environment.

Do not expose the backup PVC publicly.

---

## 833. Verify the Snapshot Again on the Restore Host

After transferring the snapshot, calculate:

```bash
sha256sum <SNAPSHOT-NAME>.db
```

Compare the result with the stored checksum.

Example:

```bash
sha256sum <SNAPSHOT-NAME>.db
cat <SNAPSHOT-NAME>.sha256
```

The values must match.

This provides an additional integrity check after file transfer.

---

## 834. Restore the Snapshot

Use the version-compatible restore utility.

Example structure:

```bash
sudo etcdutl snapshot restore \
  <SNAPSHOT-NAME>.db \
  --data-dir=/var/lib/etcd-restore
```

The actual restore command may require cluster-specific parameters such as:

```text
--name
--initial-cluster
--initial-cluster-token
--initial-advertise-peer-urls
```

These values must correspond to the intended restored cluster topology.

Do not invent or reuse values without verifying the actual cluster configuration.

---

## 835. Restored etcd Data Directory

After restore:

```bash
sudo find /var/lib/etcd-restore -maxdepth 3 -type f
```

The restored directory should contain the etcd data structure generated by the restore tool.

The restore operation should produce a new data directory rather than modifying the original live directory.

---

## 836. Three-Member Recovery

For a complete three-member restore, the recovery plan should define:

```text
Member 01
    |
    +--> restored data

Member 02
    |
    +--> restored data

Member 03
    |
    +--> restored data
```

The members must be configured as members of the **same restored cluster**.

They must not accidentally form separate independent clusters.

Conceptually:

```text
              Restored etcd cluster
                       |
        +--------------+--------------+
        |              |              |
        v              v              v
    Member 01      Member 02      Member 03
```

The initial cluster configuration must use the correct peer addresses and member names.

---

## 837. Peer Connectivity

The restored etcd members need peer connectivity on:

```text
TCP 2380
```

Client/API components communicate with etcd on:

```text
TCP 2379
```

Validate connectivity between the control-plane nodes:

```bash
nc -vz <MASTER-02-IP> 2380
nc -vz <MASTER-03-IP> 2380
```

and similarly from the other restored members.

Do not route etcd peer traffic through the Kubernetes API HAProxy.

The HAProxy node is for Kubernetes API traffic:

```text
HAProxy → TCP 6443 → Kubernetes API servers
```

etcd peer communication remains:

```text
Master 01 ←→ Master 02 ←→ Master 03
             TCP 2380
```

---

## 838. Start the Restored etcd Cluster

After the restored data and cluster configuration are ready, restore the static Pod manifest to its expected location.

For example:

```bash
sudo mv \
  /etc/kubernetes/manifests-disabled/etcd.yaml \
  /etc/kubernetes/manifests/etcd.yaml
```

Kubelet should detect the manifest and recreate the etcd static Pod.

Monitor:

```bash
sudo journalctl -u kubelet -f
```

And:

```bash
sudo crictl ps | grep etcd
```

---

## 839. Verify etcd Containers

On each control-plane node:

```bash
sudo crictl ps | grep etcd
```

Check logs:

```bash
sudo crictl logs <ETCD-CONTAINER-ID>
```

Look for:

```text
[ ] etcd starts successfully
[ ] TLS certificates load successfully
[ ] Peer connections establish
[ ] Member joins restored cluster
[ ] No data-directory errors
[ ] No cluster-ID mismatch errors
```

---

## 840. Check etcd Endpoint Health

After the restored cluster is running:

```bash
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints="<ENDPOINT-1>,<ENDPOINT-2>,<ENDPOINT-3>" \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key
```

The certificate paths must match the actual kubeadm configuration.

Do not assume these paths if the cluster uses a different configuration.

---

## 841. Check etcd Endpoint Status

Run:

```bash
ETCDCTL_API=3 etcdctl endpoint status \
  --endpoints="<ENDPOINT-1>,<ENDPOINT-2>,<ENDPOINT-3>" \
  --cacert=<CA-CERT> \
  --cert=<CLIENT-CERT> \
  --key=<CLIENT-KEY> \
  --write-out=table
```

Verify:

```text
[ ] All expected members are visible
[ ] Endpoints respond
[ ] Exactly one leader is reported
[ ] Revisions are consistent
[ ] No endpoint reports unhealthy
```

---

## 842. Check etcd Member List

Run:

```bash
ETCDCTL_API=3 etcdctl member list \
  --endpoints="<ENDPOINT-1>" \
  --cacert=<CA-CERT> \
  --cert=<CLIENT-CERT> \
  --key=<CLIENT-KEY> \
  --write-out=table
```

Confirm the intended three-member topology.

Example conceptual result:

```text
Member 01 → started
Member 02 → started
Member 03 → started
```

The actual member IDs will be different in the real cluster.

---

## 843. Verify Kubernetes API Server

Once etcd is healthy, verify the API server.

From the Admin Client:

```bash
kubectl cluster-info
```

Then:

```bash
kubectl get nodes -o wide
```

Expected:

```text
master-01   Ready
master-02   Ready
master-03   Ready
worker-01   Ready
worker-02   Ready
worker-03   Ready
```

The exact node state depends on the incident and recovery progress.

---

## 844. Verify Core Kubernetes Resources

Check:

```bash
kubectl get namespaces
```

Then:

```bash
kubectl get pods -A
```

Check:

```bash
kubectl get deployments -A
kubectl get services -A
kubectl get configmaps -A
kubectl get secrets -A
```

The resources should correspond to the selected snapshot's point in time.

Remember that objects created **after the snapshot timestamp** will not exist in the restored etcd state.

---

## 845. Verify Cluster Networking

Because the cluster uses Calico, verify:

```bash
kubectl get pods -n kube-system -o wide
```

Check Calico:

```bash
kubectl get pods -n kube-system \
  -l k8s-app=calico-node \
  -o wide
```

Verify:

```text
[ ] Calico Pods running
[ ] Nodes have Pod CIDRs
[ ] CoreDNS running
[ ] Pod-to-Pod connectivity working
[ ] Service networking working
```

A successful etcd restore does not automatically guarantee that every cluster component has recovered.

---

## 846. Verify OpenEBS

Check:

```bash
kubectl get pods -A | grep -i openebs
```

Check storage:

```bash
kubectl get storageclass
```

Then:

```bash
kubectl get pv
kubectl get pvc -A
```

Verify that the backup PVC still exists:

```bash
kubectl get pvc etcd-backup-pvc -n etcd-backup
```

The restore operation should not remove the OpenEBS backup storage.

---

## 847. Verify Backup Data After Recovery

Once the cluster is operational:

```bash
kubectl get pods -n etcd-backup
```

Access the backup storage:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  find /backup -maxdepth 2 -type f -print
```

Verify that the previously stored backups remain available.

Example:

```text
/backup/snapshots/etcd-snapshot-<TIMESTAMP>.db
/backup/checksums/etcd-snapshot-<TIMESTAMP>.sha256
/backup/metadata/etcd-snapshot-<TIMESTAMP>.json
```

---

## 848. Re-enable the Backup CronJob

Do not immediately resume scheduled backups until the restored cluster has been validated.

After successful recovery:

```bash
kubectl patch cronjob etcd-backup \
  -n etcd-backup \
  -p '{"spec":{"suspend":false}}'
```

Verify:

```bash
kubectl get cronjob etcd-backup -n etcd-backup
```

Expected:

```text
NAME          SUSPEND
etcd-backup   False
```

Then manually trigger a backup:

```bash
kubectl create job \
  --from=cronjob/etcd-backup \
  etcd-backup-post-restore-$(date +%s) \
  -n etcd-backup
```

Monitor:

```bash
kubectl get jobs -n etcd-backup
kubectl get pods -n etcd-backup -w
```

---

## 849. Validate Post-Restore Backup

Check the Job:

```bash
kubectl get job -n etcd-backup
```

Check logs:

```bash
kubectl logs -n etcd-backup <BACKUP-POD>
```

Verify:

```text
[ ] Leader detection succeeds
[ ] etcd health succeeds
[ ] Snapshot creation succeeds
[ ] Snapshot validation succeeds
[ ] Checksum succeeds
[ ] Metadata is generated
[ ] Retention succeeds
```

This confirms that the backup system itself recovered correctly.

---

## 850. Application-Level Validation

After restoring etcd, cluster applications should be tested.

Example:

```bash
kubectl get deployments -A
kubectl get pods -A
kubectl get services -A
```

For important applications:

```bash
kubectl rollout status deployment/<DEPLOYMENT-NAME> \
  -n <NAMESPACE>
```

Test application endpoints where applicable.

The restore is not complete merely because etcd reports healthy.

The complete recovery criterion is:

```text
etcd healthy
      +
API server healthy
      +
Kubernetes resources available
      +
Networking healthy
      +
Storage healthy
      +
Applications healthy
```

---

## 851. Restore Verification Matrix

| Layer        | Validation                        |
| ------------ | --------------------------------- |
| Snapshot     | Checksum verified                 |
| Snapshot     | Snapshot status validated         |
| etcd         | All intended members healthy      |
| etcd         | Leader elected                    |
| etcd         | Member list correct               |
| API server   | `kubectl cluster-info` succeeds   |
| Nodes        | Control-plane and workers recover |
| Calico       | Network components healthy        |
| CoreDNS      | DNS resolution works              |
| OpenEBS      | Storage components healthy        |
| PVC          | Backup PVC remains available      |
| Backup       | New post-restore backup succeeds  |
| Applications | Critical workloads validated      |

---

## 852. What Happens to Kubernetes Objects Created After the Snapshot?

This is one of the most important restore considerations.

Suppose:

```text
02:00 → Backup created
03:00 → Deployment created
04:00 → Secret changed
05:00 → Incident
```

If the 02:00 snapshot is restored:

```text
02:00 snapshot
     |
     v
Restore
```

the 03:00 and 04:00 changes are not represented in the restored etcd state.

Therefore:

```text
Restore Point = Snapshot Timestamp
```

The restore procedure must explicitly document this potential data loss.

---

## 853. Restore Point Selection

The recovery operator should select the snapshot according to the required recovery point.

Example:

```text
Available backups:

02:00
02:00
02:00
02:00
```

The correct recovery point depends on the incident timeline.

If the unwanted change occurred at:

```text
03:30
```

a snapshot from:

```text
02:00
```

may represent a desired pre-incident state.

This is a recovery decision and should be documented during an incident.

---

## 854. Restore Runbook

The condensed operational runbook is:

```text
1. Declare recovery operation.
2. Suspend etcd backup CronJob.
3. Identify recovery snapshot.
4. Verify checksum.
5. Validate snapshot.
6. Inspect snapshot metadata.
7. Preserve current etcd state if possible.
8. Stop affected etcd members.
9. Restore snapshot to a separate directory.
10. Configure restored etcd cluster membership.
11. Start restored etcd members.
12. Verify etcd health.
13. Verify etcd member list.
14. Verify Kubernetes API server.
15. Verify all Kubernetes nodes.
16. Verify Calico and CoreDNS.
17. Verify OpenEBS.
18. Verify critical workloads.
19. Verify backup PVC.
20. Run a new post-restore backup.
21. Re-enable the backup CronJob.
22. Document recovery results.
```

---

## 855. Restore Failure Scenarios

### Snapshot checksum mismatch

```text
Checksum mismatch
       |
       v
Do not restore
       |
       v
Select another backup
```

---

### Snapshot validation failure

```text
Invalid snapshot
       |
       v
Do not restore
       |
       v
Select another validated snapshot
```

---

### etcd member cannot start

Check:

```bash
sudo journalctl -u kubelet -n 200
sudo crictl ps -a | grep etcd
```

Then inspect:

```bash
sudo crictl logs <ETCD-CONTAINER-ID>
```

Look for:

```text
TLS errors
Peer connectivity errors
Cluster configuration errors
Data directory errors
Permission errors
Address binding errors
```

---

### API server unavailable

Check:

```bash
kubectl cluster-info
```

Then from a control-plane node:

```bash
sudo crictl ps | grep kube-apiserver
```

Inspect:

```bash
sudo crictl logs <API-SERVER-CONTAINER-ID>
```

Also verify the HAProxy backend:

```bash
sudo systemctl status haproxy
```

and:

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

---

## 856. Do Not Use HAProxy for etcd Restore Traffic

HAProxy is responsible for:

```text
Admin Client
     |
     v
HAProxy
     |
     +--> Master 01 :6443
     +--> Master 02 :6443
     └--> Master 03 :6443
```

It is not the etcd restore endpoint.

etcd recovery uses direct etcd member communication:

```text
Master 01 :2379
Master 02 :2379
Master 03 :2379
```

and peer communication:

```text
Master 01 :2380
Master 02 :2380
Master 03 :2380
```

---

## 857. Backup Storage Must Survive Control-Plane Failure

A key property of the architecture is that backup storage is separate from the live etcd data directory.

Normal operation:

```text
Master 01
   |
   +--> /var/lib/etcd
```

Backup:

```text
OpenEBS
   |
   +--> etcd-backup-pvc
           |
           +--> /backup
```

Therefore, losing an etcd member does not inherently remove the backup files stored on the PVC.

However, the actual failure-recovery characteristics depend on the selected OpenEBS storage engine, replication model, topology, and underlying infrastructure.

---

## 858. Disaster-Recovery Architecture

The overall recovery architecture is:

```text
                     Backup Storage
                          |
                          v
                  +---------------+
                  | OpenEBS PVC    |
                  | /backup        |
                  +-------+-------+
                          |
                          | selected snapshot
                          v
                  +---------------+
                  | Restore        |
                  | Procedure      |
                  +-------+-------+
                          |
                          v
                +-------------------+
                | Restored etcd     |
                | Cluster            |
                +---------+---------+
                          |
                          v
                +-------------------+
                | Kubernetes API    |
                +---------+---------+
                          |
                          v
                +-------------------+
                | Kubernetes        |
                | Workloads         |
                +-------------------+
```

---

## 859. Recovery Objectives

The backup and restore design should define two operational objectives.

### RPO — Recovery Point Objective

RPO represents the maximum amount of cluster state that may be lost between backups.

With a daily backup schedule:

```text
RPO ≈ up to 24 hours
```

The actual RPO depends on when the last successful backup occurred.

---

### RTO — Recovery Time Objective

RTO represents the target time required to restore the control plane.

The actual RTO depends on:

```text
Snapshot size
Storage performance
Number of etcd members
Control-plane recovery complexity
Network availability
Operator actions
Validation time
```

RTO should be measured through a controlled recovery test rather than assumed.

---

## 860. Restore Testing

A restore process should not be considered production-ready until it has been tested.

Recommended testing environment:

```text
Production Backup
       |
       v
Controlled Recovery Environment
       |
       v
Restore Snapshot
       |
       v
Validate Kubernetes State
```

The test should record:

```text
Snapshot size
Restore start time
Restore completion time
etcd startup time
API server recovery time
Application recovery time
Total recovery time
```

These measurements can be used to establish an operational RTO.

---

## 861. Restore Test Checklist

```text
[ ] Select a known-good backup
[ ] Verify checksum
[ ] Validate snapshot
[ ] Restore to isolated environment
[ ] Start etcd
[ ] Verify etcd health
[ ] Verify etcd member topology
[ ] Start Kubernetes API server
[ ] Verify kubectl access
[ ] Verify Kubernetes objects
[ ] Verify Calico
[ ] Verify CoreDNS
[ ] Verify OpenEBS
[ ] Verify critical workloads
[ ] Create post-restore backup
[ ] Record recovery duration
```

---

## 862. Security During Restore

Restore operations require highly privileged access.

The operator should protect:

```text
etcd TLS certificates
etcd private keys
Kubernetes admin kubeconfig
Snapshot files
Backup PVC
Restore directories
```

Do not copy these files into Git.

Do not place sensitive credentials directly in shell history when avoidable.

Do not expose the backup PVC through an external service.

Do not transfer snapshots over an untrusted network without appropriate protection.

---

## 863. Final Restore Validation

The restore operation is considered successful only when:

```text
[ ] Selected snapshot is correct
[ ] Checksum matches
[ ] Snapshot validation succeeds
[ ] etcd restored successfully
[ ] etcd members form the intended cluster
[ ] etcd leader is elected
[ ] API server is available
[ ] kubectl works through HAProxy
[ ] All expected nodes are available
[ ] Calico is healthy
[ ] CoreDNS is healthy
[ ] OpenEBS is healthy
[ ] Backup PVC remains available
[ ] Critical workloads are validated
[ ] New backup succeeds
[ ] CronJob is re-enabled
[ ] Recovery operation is documented
```

---

## 864. Part 17 Completion Criteria

Part 17 is complete when:

```text
[ ] A validated etcd snapshot can be selected
[ ] Snapshot checksum can be verified
[ ] Snapshot can be validated before restore
[ ] Restore is performed using version-compatible etcd tooling
[ ] Live etcd data is not overwritten blindly
[ ] Three-member etcd recovery is documented
[ ] Kubernetes API recovery is documented
[ ] Calico and OpenEBS validation is documented
[ ] Backup CronJob can be safely suspended and resumed
[ ] Post-restore backup is verified
[ ] RPO and RTO are documented
[ ] Restore testing procedure is documented
```

---

## 865. Next Part

**Part 18 — Troubleshooting**

The next part will consolidate troubleshooting procedures for:

```text
HAProxy
Kubernetes API Server
etcd
kubelet
containerd
Calico
OpenEBS
PVC/PV
CronJob
Backup Jobs
Snapshot Validation
Network Connectivity
TLS
DNS
Node Readiness
```

The troubleshooting section will provide symptoms, diagnostic commands, likely causes, and recovery actions for the complete cluster architecture.

# Part 18 — Troubleshooting

## 866. Objective

This part provides a centralized troubleshooting guide for the complete Kubernetes cluster deployment.

The environment consists of:

```text
Infrastructure
├── Master 01
├── Master 02
├── Master 03
├── Worker 01
├── Worker 02
├── Worker 03
├── HAProxy / Load Balancer
└── Admin Client
```

Core components:

```text
HAProxy
Kubernetes API Server
etcd
kubeadm
kubelet
containerd
Calico
CoreDNS
OpenEBS
PV / PVC
CronJob
Backup Job
etcd Snapshot
Prometheus
Grafana
Tailscale
```

The general troubleshooting methodology is:

```text
Symptom
   |
   v
Identify affected layer
   |
   v
Check status
   |
   v
Check logs
   |
   v
Check network connectivity
   |
   v
Check configuration
   |
   v
Apply targeted fix
   |
   v
Validate
```

---

## 867. Troubleshooting Order

When a component is not working, troubleshoot from the lowest dependency layer upward.

Recommended order:

```text
1. Host
2. Network
3. Container runtime
4. kubelet
5. Kubernetes control plane
6. etcd
7. CNI
8. Storage
9. Workload
10. Backup
```

For example, if a Pod cannot start:

```text
Pod failure
    |
    +--> Node available?
    |
    +--> kubelet healthy?
    |
    +--> containerd healthy?
    |
    +--> CNI healthy?
    |
    +--> Storage available?
    |
    +--> Application healthy?
```

Avoid changing multiple components simultaneously. Diagnose the failing layer first.

---

# 868. General Node Health

Run on the affected node:

```bash
hostnamectl
```

Check OS:

```bash
cat /etc/os-release
```

Check uptime:

```bash
uptime
```

Check CPU and memory:

```bash
free -h
nproc
```

Check disk:

```bash
df -h
```

Check inode usage:

```bash
df -i
```

Check mounted filesystems:

```bash
mount
```

Check system load:

```bash
top
```

or:

```bash
htop
```

---

## 869. Disk Space Problems

One of the most common causes of Kubernetes component failures is insufficient disk space.

Check:

```bash
df -h
```

Then:

```bash
df -i
```

Check large directories:

```bash
sudo du -xhd1 / | sort -h
```

For containerd:

```bash
sudo du -sh /var/lib/containerd
```

For Kubernetes:

```bash
sudo du -sh /var/lib/kubelet
```

For etcd:

```bash
sudo du -sh /var/lib/etcd
```

For logs:

```bash
sudo du -sh /var/log/*
```

A full filesystem can cause:

```text
Pods stuck in ContainerCreating
CrashLoopBackOff
Prometheus failures
etcd failures
containerd failures
kubelet failures
No space left on device
```

Do not delete Kubernetes or etcd data directories blindly.

---

## 870. Memory Pressure

Check:

```bash
free -h
```

Check processes:

```bash
ps aux --sort=-%mem | head
```

Check Kubernetes node conditions:

```bash
kubectl describe node <NODE-NAME>
```

Look for:

```text
MemoryPressure
DiskPressure
PIDPressure
```

If a node has memory pressure:

```text
Memory pressure
      |
      v
Kubelet
      |
      v
Pod eviction / scheduling impact
```

Identify the workload consuming memory before terminating anything.

---

# 871. Tailscale Connectivity

Because Tailscale is used for connectivity between machines, check:

```bash
tailscale status
```

Check local Tailscale address:

```bash
tailscale ip -4
```

Check interface:

```bash
ip addr show tailscale0
```

Check service:

```bash
sudo systemctl status tailscaled
```

If a node is offline:

```text
Node offline
    |
    +--> Check tailscaled
    +--> Check network connectivity
    +--> Check Tailscale authentication
    +--> Check firewall
    +--> Check whether node is reachable through another network path
```

---

## 872. Test Tailscale Connectivity

From one node:

```bash
ping <TAILSCALE-IP>
```

Test SSH:

```bash
ssh <USER>@<TAILSCALE-IP>
```

Test a Kubernetes API port:

```bash
nc -vz -w 3 <TAILSCALE-IP> 6443
```

Test etcd client port:

```bash
nc -vz -w 3 <TAILSCALE-IP> 2379
```

Test etcd peer port:

```bash
nc -vz -w 3 <TAILSCALE-IP> 2380
```

A successful connection to `2380` does not imply that `6443` is reachable. Each service must be tested independently.

---

# 873. DNS / Hostname Resolution

Check:

```bash
hostname
hostname -f
```

Resolve a hostname:

```bash
getent hosts <HOSTNAME>
```

Check `/etc/hosts`:

```bash
cat /etc/hosts
```

If the cluster relies on hostname resolution, verify that all required machines resolve consistently.

For example:

```text
master-01
master-02
master-03
worker-01
worker-02
worker-03
load-balancer
admin-client
```

Do not create conflicting hostname-to-IP mappings.

---

# 874. Time Synchronization

Time synchronization is important for TLS and distributed systems.

Check:

```bash
timedatectl
```

Look for:

```text
System clock synchronized: yes
```

Check time:

```bash
date
```

If available:

```bash
chronyc tracking
```

or:

```bash
systemctl status systemd-timesyncd
```

Large clock differences can cause:

```text
TLS validation errors
Certificate problems
Distributed-system timing problems
```

---

# 875. SSH Troubleshooting

If SSH times out:

```text
ssh: connect to host <IP> port 22: Connection timed out
```

check:

```bash
ping <IP>
```

then:

```bash
nc -vz -w 3 <IP> 22
```

On the target machine:

```bash
sudo systemctl status ssh
```

Check whether SSH is listening:

```bash
sudo ss -lntp | grep ':22'
```

Check firewall:

```bash
sudo ufw status
```

or:

```bash
sudo nft list ruleset
```

A timeout usually indicates a network path, firewall, routing, or listener problem rather than an SSH-key problem.

---

# 876. Kubernetes Node Status

From the Admin Client:

```bash
kubectl get nodes -o wide
```

If a node is `NotReady`:

```bash
kubectl describe node <NODE-NAME>
```

Look at:

```text
Conditions
Events
Taints
Addresses
Allocatable resources
PodCIDR
```

Then connect to the node and check:

```bash
sudo systemctl status kubelet
```

and:

```bash
sudo systemctl status containerd
```

---

# 877. kubelet Troubleshooting

Check service:

```bash
sudo systemctl status kubelet
```

Check logs:

```bash
sudo journalctl -u kubelet -n 200 --no-pager
```

Follow logs:

```bash
sudo journalctl -u kubelet -f
```

Check kubelet configuration:

```bash
sudo systemctl cat kubelet
```

Common problems include:

```text
Container runtime unavailable
CNI unavailable
Certificate problems
Disk pressure
Memory pressure
API server unreachable
Static Pod failures
```

---

# 878. containerd Troubleshooting

Check:

```bash
sudo systemctl status containerd
```

Logs:

```bash
sudo journalctl -u containerd -n 200 --no-pager
```

Check version:

```bash
containerd --version
```

Check configuration:

```bash
sudo containerd config dump
```

Check CRI connectivity:

```bash
sudo crictl info
```

List containers:

```bash
sudo crictl ps
```

List all containers:

```bash
sudo crictl ps -a
```

List Pods:

```bash
sudo crictl pods
```

---

# 879. Containerd and crictl Configuration

Check:

```bash
sudo crictl info
```

If CRI communication fails, inspect:

```bash
cat /etc/crictl.yaml
```

The endpoint should correspond to the actual containerd CRI socket used by the node.

Do not assume the socket path if the environment has been customized.

---

# 880. Kubernetes API Server Unavailable

If:

```bash
kubectl cluster-info
```

fails, first determine whether the problem is:

```text
Admin Client
      |
      v
HAProxy
      |
      v
API Server
      |
      v
etcd
```

Check the configured API endpoint:

```bash
kubectl config view --minify
```

Verify connectivity from Admin Client:

```bash
nc -vz -w 3 <HAProxy-ENDPOINT> 6443
```

---

# 881. HAProxy Troubleshooting

On the load-balancer node:

```bash
sudo systemctl status haproxy
```

Validate configuration:

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Check listener:

```bash
sudo ss -lntp | grep ':6443'
```

Check logs:

```bash
sudo journalctl -u haproxy -n 200 --no-pager
```

If HAProxy reports:

```text
backend kubernetes-masters has no server available
```

check connectivity to each master:

```bash
nc -vz -w 3 <MASTER-01-IP> 6443
nc -vz -w 3 <MASTER-02-IP> 6443
nc -vz -w 3 <MASTER-03-IP> 6443
```

---

# 882. HAProxy Backend Diagnosis

The desired topology is:

```text
                 HAProxy
                    |
          +---------+---------+
          |         |         |
          v         v         v
       Master01  Master02  Master03
        :6443     :6443     :6443
```

If all three checks fail:

```text
HAProxy
   |
   X
   |
All API servers
```

investigate:

```text
Network
API server
kubelet
container runtime
control-plane static Pods
```

If only one backend fails:

```text
HAProxy
   |
   +--> Master 01 ✓
   +--> Master 02 X
   └--> Master 03 ✓
```

investigate Master 02 specifically.

---

# 883. kube-apiserver Troubleshooting

On a control-plane node:

```bash
sudo crictl ps -a | grep kube-apiserver
```

Check logs:

```bash
sudo crictl logs <API-SERVER-CONTAINER-ID>
```

Check static manifest:

```bash
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml
```

Check kubelet:

```bash
sudo journalctl -u kubelet -n 200 --no-pager
```

Common causes:

```text
etcd unavailable
Certificate failure
Incorrect advertise address
Incorrect API endpoint
Port conflict
Container runtime failure
Resource exhaustion
```

---

# 884. API Server TLS Errors

If `kubectl` reports a certificate error, inspect the configured endpoint:

```bash
kubectl config view --minify
```

Test TLS:

```bash
openssl s_client \
  -connect <HAProxy-ENDPOINT>:6443 \
  -servername <HAProxy-DNS-NAME>
```

Do not disable TLS verification as a troubleshooting shortcut.

Instead determine:

```text
Certificate
    |
    +--> Subject
    +--> SAN
    +--> Issuer
    +--> Expiry
```

Check kubeadm certificates where appropriate:

```bash
sudo kubeadm certs check-expiration
```

---

# 885. etcd Troubleshooting

Check static Pod:

```bash
sudo crictl ps -a | grep etcd
```

Check logs:

```bash
sudo crictl logs <ETCD-CONTAINER-ID>
```

Check manifest:

```bash
sudo cat /etc/kubernetes/manifests/etcd.yaml
```

Check etcd data directory:

```bash
sudo ls -lah /var/lib/etcd
```

Check disk:

```bash
df -h /var/lib/etcd
```

---

# 886. etcd Endpoint Health

Use the appropriate TLS credentials:

```bash
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints="<ENDPOINT-1>,<ENDPOINT-2>,<ENDPOINT-3>" \
  --cacert=<CA-CERT> \
  --cert=<CLIENT-CERT> \
  --key=<CLIENT-KEY>
```

Check status:

```bash
ETCDCTL_API=3 etcdctl endpoint status \
  --endpoints="<ENDPOINT-1>,<ENDPOINT-2>,<ENDPOINT-3>" \
  --cacert=<CA-CERT> \
  --cert=<CLIENT-CERT> \
  --key=<CLIENT-KEY> \
  --write-out=table
```

Check members:

```bash
ETCDCTL_API=3 etcdctl member list \
  --endpoints="<HEALTHY-ENDPOINT>" \
  --cacert=<CA-CERT> \
  --cert=<CLIENT-CERT> \
  --key=<CLIENT-KEY> \
  --write-out=table
```

---

# 887. etcd Leader Problems

A three-member etcd cluster normally requires quorum.

Architecture:

```text
Master 01 → etcd
Master 02 → etcd
Master 03 → etcd
```

For three members:

```text
Total members = 3
Quorum        = 2
```

If one member fails:

```text
2 healthy members
       |
       v
Quorum maintained
```

If two members fail:

```text
1 healthy member
       |
       v
No quorum
```

The cluster may stop accepting writes until quorum is restored.

Do not arbitrarily delete etcd members to resolve a leader problem.

---

# 888. etcd Peer Port Troubleshooting

Check port `2380` between control-plane nodes:

```bash
nc -vz -w 3 <MASTER-02-IP> 2380
```

and:

```bash
nc -vz -w 3 <MASTER-03-IP> 2380
```

Check listeners:

```bash
sudo ss -lntp | grep ':2380'
```

If peer communication fails, inspect:

```text
Firewall
Tailscale routing
Peer URLs
Advertise addresses
etcd configuration
Network interface
```

---

# 889. etcd Client Port Troubleshooting

Check `2379`:

```bash
nc -vz -w 3 <MASTER-IP> 2379
```

Check listener:

```bash
sudo ss -lntp | grep ':2379'
```

A successful TCP connection does not guarantee that etcd is healthy.

Always follow the network test with:

```bash
etcdctl endpoint health
```

---

# 890. kube-controller-manager Troubleshooting

Check:

```bash
sudo crictl ps -a | grep kube-controller-manager
```

Logs:

```bash
sudo crictl logs <CONTAINER-ID>
```

Static manifest:

```bash
sudo cat /etc/kubernetes/manifests/kube-controller-manager.yaml
```

A controller-manager problem can result in:

```text
Deployments not reconciling
ReplicaSets not updating
Node lifecycle problems
ServiceAccount-related problems
```

---

# 891. kube-scheduler Troubleshooting

Check:

```bash
sudo crictl ps -a | grep kube-scheduler
```

Logs:

```bash
sudo crictl logs <CONTAINER-ID>
```

If Pods remain:

```text
Pending
```

inspect:

```bash
kubectl describe pod <POD-NAME> -n <NAMESPACE>
```

Look at:

```text
Events
Node selectors
Taints
Resource requests
Affinity
Scheduling constraints
```

---

# 892. Pods Stuck in Pending

Run:

```bash
kubectl get pods -A
```

Then:

```bash
kubectl describe pod <POD-NAME> -n <NAMESPACE>
```

Check events:

```bash
kubectl get events -A --sort-by=.lastTimestamp
```

Common causes:

```text
Insufficient CPU
Insufficient memory
Node taint
Node selector mismatch
Affinity constraints
PVC not bound
No suitable node
Scheduler failure
```

---

# 893. Pods Stuck in ContainerCreating

Check:

```bash
kubectl describe pod <POD-NAME> -n <NAMESPACE>
```

Then inspect node:

```bash
kubectl describe node <NODE-NAME>
```

Check kubelet:

```bash
sudo journalctl -u kubelet -n 200 --no-pager
```

Check containerd:

```bash
sudo journalctl -u containerd -n 200 --no-pager
```

Common causes:

```text
CNI failure
Image pull failure
Volume mount failure
CSI failure
Permission problem
Container runtime problem
```

---

# 894. CrashLoopBackOff

Check:

```bash
kubectl get pod <POD-NAME> -n <NAMESPACE>
```

Logs:

```bash
kubectl logs <POD-NAME> -n <NAMESPACE>
```

For the previous crashed container:

```bash
kubectl logs <POD-NAME> \
  -n <NAMESPACE> \
  --previous
```

Then:

```bash
kubectl describe pod <POD-NAME> -n <NAMESPACE>
```

Determine whether the failure is:

```text
Application
Configuration
Secret
Volume
Network
Resource
Dependency
```

---

# 895. ImagePullBackOff

Check:

```bash
kubectl describe pod <POD-NAME> -n <NAMESPACE>
```

Look at Events.

Common causes:

```text
Incorrect image name
Incorrect tag
Private registry authentication
Registry unavailable
Network failure
Image architecture mismatch
```

Test the container runtime independently where appropriate.

---

# 896. Calico Troubleshooting

Check:

```bash
kubectl get pods -n kube-system \
  -l k8s-app=calico-node \
  -o wide
```

Check DaemonSet:

```bash
kubectl get daemonset -n kube-system
```

Describe a Calico Pod:

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

# 897. Verify Pod CIDRs

Run:

```bash
kubectl get nodes \
  -o custom-columns=NAME:.metadata.name,PODCIDR:.spec.podCIDR
```

The configured Pod CIDR must be compatible with the Calico IPPool configuration.

Inspect:

```bash
kubectl get ippools.crd.projectcalico.org -o yaml
```

if the installed Calico version and CRDs support this resource.

Do not modify the cluster Pod CIDR or Calico IPPool casually on an established cluster.

---

# 898. Pod-to-Pod Connectivity

Create a temporary test Pod:

```bash
kubectl run network-test \
  --image=busybox:stable \
  --restart=Never \
  -- sleep 3600
```

Check:

```bash
kubectl get pod network-test -o wide
```

Test DNS:

```bash
kubectl exec network-test -- nslookup kubernetes.default
```

Test another Pod:

```bash
kubectl exec network-test -- ping <POD-IP>
```

Clean up:

```bash
kubectl delete pod network-test
```

The exact test image may need to be replaced if the environment cannot pull it.

---

# 899. CoreDNS Troubleshooting

Check:

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
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

Test:

```bash
kubectl run dns-test \
  --image=busybox:stable \
  --restart=Never \
  -- sleep 3600
```

Then:

```bash
kubectl exec dns-test -- nslookup kubernetes.default
```

---

# 900. Service Connectivity

Check Service:

```bash
kubectl get svc -A
```

Check Endpoints:

```bash
kubectl get endpoints -A
```

For newer Kubernetes environments, EndpointSlices can also be inspected:

```bash
kubectl get endpointslices -A
```

If a Service has no endpoints:

```text
Service
   |
   X
   |
No matching Pods
```

Check:

```bash
kubectl get pod -n <NAMESPACE> --show-labels
```

and:

```bash
kubectl describe svc <SERVICE-NAME> -n <NAMESPACE>
```

Verify that Service selectors match Pod labels.

---

# 901. OpenEBS Troubleshooting

Check OpenEBS Pods:

```bash
kubectl get pods -n openebs -o wide
```

Check StorageClasses:

```bash
kubectl get storageclass
```

Inspect:

```bash
kubectl describe storageclass <STORAGECLASS>
```

Check PVC:

```bash
kubectl get pvc -A
```

If a PVC is stuck in `Pending`:

```bash
kubectl describe pvc <PVC-NAME> -n <NAMESPACE>
```

Then inspect:

```bash
kubectl get pv
kubectl get events -n <NAMESPACE> --sort-by=.lastTimestamp
```

---

# 902. PVC Stuck in Pending

A PVC may remain `Pending` because of:

```text
StorageClass missing
Provisioner unavailable
Insufficient storage
Topology constraints
Node constraints
CSI failure
Incorrect access mode
```

Check:

```bash
kubectl get storageclass
```

Then:

```bash
kubectl describe pvc <PVC-NAME> -n <NAMESPACE>
```

Do not manually create a PV unless the storage architecture explicitly requires static provisioning.

---

# 903. PV and PVC Mismatch

Check:

```bash
kubectl get pv
kubectl get pvc -A
```

Verify:

```text
PVC → PV → StorageClass → OpenEBS
```

Inspect PV:

```bash
kubectl describe pv <PV-NAME>
```

Look at:

```text
Capacity
Access Modes
Reclaim Policy
StorageClass
Status
Node Affinity
CSI Driver
```

---

# 904. Volume Mount Failure

If a Pod reports volume mount errors:

```bash
kubectl describe pod <POD-NAME> -n <NAMESPACE>
```

Check events.

Then:

```bash
kubectl describe pvc <PVC-NAME> -n <NAMESPACE>
```

Check OpenEBS components:

```bash
kubectl get pods -n openebs
```

Also inspect the affected node:

```bash
kubectl describe node <NODE-NAME>
```

---

# 905. Backup CronJob Troubleshooting

Check CronJob:

```bash
kubectl get cronjob -n etcd-backup
```

Describe:

```bash
kubectl describe cronjob etcd-backup -n etcd-backup
```

Check Jobs:

```bash
kubectl get jobs -n etcd-backup
```

Check Pods:

```bash
kubectl get pods -n etcd-backup -o wide
```

Check logs:

```bash
kubectl logs -n etcd-backup <BACKUP-POD>
```

---

# 906. Manually Trigger a Backup

If the schedule has not yet occurred:

```bash
kubectl create job \
  --from=cronjob/etcd-backup \
  etcd-backup-manual-$(date +%s) \
  -n etcd-backup
```

Watch:

```bash
kubectl get pods -n etcd-backup -w
```

This is useful for distinguishing:

```text
Cron scheduling problem
```

from:

```text
Backup application problem
```

---

# 907. Backup Pod Cannot Reach etcd

Test network connectivity from the backup Pod.

First identify the Pod:

```bash
kubectl get pods -n etcd-backup -o wide
```

Then use a suitable diagnostic container/image if required.

Check the configured endpoints:

```bash
kubectl get job <JOB-NAME> \
  -n etcd-backup \
  -o yaml
```

Verify:

```text
<MASTER-01>:2379
<MASTER-02>:2379
<MASTER-03>:2379
```

The backup Pod should communicate directly with etcd.

It should not use the Kubernetes API HAProxy endpoint for etcd traffic.

---

# 908. Backup TLS Failure

Typical symptoms include:

```text
certificate signed by unknown authority
tls: bad certificate
connection refused
permission denied
```

Check the Secret:

```bash
kubectl get secret etcd-backup-tls -n etcd-backup
```

Do not print private-key contents into logs.

Check Secret keys:

```bash
kubectl describe secret etcd-backup-tls -n etcd-backup
```

Verify the backup Pod mounts:

```text
/etc/etcd-tls/
```

Then verify the application is referencing the correct certificate paths.

---

# 909. Backup Snapshot Creation Failure

Check logs:

```bash
kubectl logs -n etcd-backup <BACKUP-POD>
```

Possible causes:

```text
No etcd endpoint available
TLS failure
Insufficient PVC space
Invalid etcd credentials
etcd unhealthy
Incorrect etcdctl/etcdutl version
Permission problem
Filesystem failure
```

Check PVC:

```bash
kubectl get pvc etcd-backup-pvc -n etcd-backup
```

Check storage:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  df -h /backup
```

---

# 910. Leader Detection Failure

The backup process must not assume:

```text
Master 01 = etcd leader
```

Instead, use etcd endpoint status to determine the current leader.

Check manually:

```bash
ETCDCTL_API=3 etcdctl endpoint status \
  --endpoints="<ENDPOINT-1>,<ENDPOINT-2>,<ENDPOINT-3>" \
  --cacert=<CA-CERT> \
  --cert=<CLIENT-CERT> \
  --key=<CLIENT-KEY> \
  --write-out=table
```

Compare:

```text
Member ID
Leader ID
```

The endpoint whose member ID matches the leader ID is the current leader.

---

# 911. Snapshot Validation Failure

If:

```bash
etcdutl snapshot status <SNAPSHOT>
```

or the version-compatible equivalent fails, do not treat the snapshot as valid.

Check:

```text
Snapshot file size
Checksum
Filesystem
etcd utility version
File permissions
File completeness
```

If the backup was copied between systems, recalculate the checksum after transfer.

---

# 912. Backup PVC Is Full

Check:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  df -h /backup
```

Then:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  du -sh /backup/*
```

Identify:

```text
Snapshots
Metadata
Checksums
Temporary files
```

If retention has failed, investigate retention logs first.

Do not manually delete the newest valid snapshot just to free space.

---

# 913. Retention Is Not Deleting Old Backups

Check:

```bash
kubectl logs -n etcd-backup <BACKUP-POD>
```

Verify:

```text
RETENTION_DAYS
```

Check timestamps:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  find /backup/snapshots \
  -maxdepth 1 \
  -type f \
  -name '*.db' \
  -printf '%TY-%Tm-%Td %TH:%TM:%TS %p\n'
```

Possible causes:

```text
Incorrect retention value
Clock mismatch
Filename mismatch
Dry-run mode enabled
Newest-backup protection
Retention process failed
```

---

# 914. Backup Job Is Not Starting

Check:

```bash
kubectl get cronjob etcd-backup -n etcd-backup
```

Check:

```bash
kubectl describe cronjob etcd-backup -n etcd-backup
```

Verify:

```text
SUSPEND = False
Schedule is correct
No concurrency conflict
CronJob exists
```

Remember that:

```yaml
concurrencyPolicy: Forbid
```

prevents a new Job from starting while the previous Job is still running.

---

# 915. Backup Job Fails Repeatedly

Check:

```bash
kubectl get jobs -n etcd-backup
```

Then:

```bash
kubectl describe job <JOB-NAME> -n etcd-backup
```

Check Pod logs:

```bash
kubectl logs -n etcd-backup <BACKUP-POD>
```

Check:

```text
Exit code
Events
Image
Environment variables
Mounted volumes
ServiceAccount
PVC
TLS Secret
```

---

# 916. Admin Client Cannot Access Cluster

Check kubeconfig:

```bash
kubectl config view --minify
```

Verify the server points to the HAProxy endpoint:

```text
https://<HAProxy-ENDPOINT>:6443
```

Test:

```bash
nc -vz -w 3 <HAProxy-ENDPOINT> 6443
```

Then:

```bash
kubectl cluster-info
```

If the Admin Client is configured to connect directly to a master instead of HAProxy, verify whether this is intentional.

The standard project architecture is:

```text
Admin Client
      |
      v
HAProxy
      |
      +--> Master 01
      +--> Master 02
      └--> Master 03
```

---

# 917. RBAC Problems

If:

```bash
kubectl get pods
```

returns:

```text
Forbidden
```

check:

```bash
kubectl auth whoami
```

Then:

```bash
kubectl auth can-i get pods
```

For a namespace:

```bash
kubectl auth can-i get pods \
  -n <NAMESPACE>
```

For another identity:

```bash
kubectl auth can-i get pods \
  --as=<USER> \
  -n <NAMESPACE>
```

Do not grant `cluster-admin` simply to bypass an RBAC problem.

Identify the missing permission and correct the appropriate Role or ClusterRole.

---

# 918. Kubernetes Events

Events are one of the first places to look for workload failures.

Run:

```bash
kubectl get events -A \
  --sort-by=.lastTimestamp
```

For a namespace:

```bash
kubectl get events \
  -n <NAMESPACE> \
  --sort-by=.lastTimestamp
```

Look for:

```text
FailedScheduling
FailedMount
FailedAttachVolume
FailedCreatePodSandBox
BackOff
Unhealthy
Failed
```

---

# 919. Kubernetes Component Status Summary

Useful commands:

```bash
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
kubectl get pvc -A
kubectl get pv
kubectl get storageclass
```

Control-plane containers:

```bash
sudo crictl ps | grep -E \
  'etcd|kube-apiserver|kube-controller-manager|kube-scheduler'
```

System services:

```bash
sudo systemctl status kubelet
sudo systemctl status containerd
```

---

# 920. Troubleshooting by Symptom

| Symptom                  | First Checks                              |
| ------------------------ | ----------------------------------------- |
| `kubectl` cannot connect | HAProxy, port 6443, API server            |
| HAProxy has no backend   | Master API port 6443                      |
| Node `NotReady`          | kubelet, containerd, CNI                  |
| Pod `Pending`            | Scheduler, resources, taints, PVC         |
| Pod `ContainerCreating`  | CNI, image, volume                        |
| Pod `CrashLoopBackOff`   | Application logs, previous logs           |
| PVC `Pending`            | StorageClass, OpenEBS, events             |
| etcd unhealthy           | etcd logs, ports 2379/2380                |
| No etcd leader           | Member health and quorum                  |
| Backup fails             | etcd connectivity, TLS, PVC               |
| Backup PVC full          | Retention, snapshot sizes, capacity       |
| Retention fails          | Script logs, timestamps, permissions      |
| DNS fails                | CoreDNS, Calico, Service                  |
| Service has no traffic   | Endpoints, selectors, Pods                |
| TLS error                | Certificate, SAN, CA, time                |
| SSH timeout              | Network, firewall, SSH listener           |
| Tailscale offline        | `tailscale status`, `tailscaled`, network |

---

# 921. Troubleshooting Decision Tree

## API Access Failure

```text
kubectl fails
    |
    v
Can Admin Client reach HAProxy:6443?
    |
    +-- No --> Network / Firewall / HAProxy listener
    |
    +-- Yes
          |
          v
Can HAProxy reach any Master:6443?
          |
          +-- No --> API Server / Node / Network
          |
          +-- Yes
                |
                v
          API server healthy?
                |
                +-- No --> kube-apiserver / etcd
                |
                +-- Yes --> kubeconfig / TLS / RBAC
```

---

## Node NotReady

```text
Node NotReady
     |
     v
kubelet healthy?
     |
     +-- No --> kubelet logs
     |
     +-- Yes
           |
           v
containerd healthy?
           |
           +-- No --> containerd
           |
           +-- Yes
                 |
                 v
CNI healthy?
                 |
                 +-- No --> Calico
                 |
                 +-- Yes
                       |
                       v
Resources / disk / network?
```

---

## Backup Failure

```text
Backup failed
     |
     v
PVC mounted?
     |
     +-- No --> OpenEBS / PVC
     |
     +-- Yes
           |
           v
etcd reachable?
           |
           +-- No --> Network / etcd
           |
           +-- Yes
                 |
                 v
TLS valid?
                 |
                 +-- No --> Secret / certificate
                 |
                 +-- Yes
                       |
                       v
Snapshot succeeds?
                       |
                       +-- No --> etcdctl / storage / permissions
                       |
                       +-- Yes
                             |
                             v
Validation succeeds?
                             |
                             +-- No --> Snapshot/tooling
                             |
                             +-- Yes
                                   |
                                   v
Retention succeeds?
```

---

# 922. Log Collection

For a complete incident, collect logs from the relevant layers.

### Kubernetes

```bash
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get events -A --sort-by=.lastTimestamp
```

### kubelet

```bash
sudo journalctl -u kubelet -n 300 --no-pager
```

### containerd

```bash
sudo journalctl -u containerd -n 300 --no-pager
```

### etcd

```bash
sudo crictl ps -a | grep etcd
sudo crictl logs <ETCD-CONTAINER-ID>
```

### API server

```bash
sudo crictl ps -a | grep kube-apiserver
sudo crictl logs <API-SERVER-CONTAINER-ID>
```

### HAProxy

```bash
sudo journalctl -u haproxy -n 300 --no-pager
```

### Tailscale

```bash
tailscale status
sudo journalctl -u tailscaled -n 200 --no-pager
```

---

# 923. Avoid Destructive Troubleshooting

Do not immediately execute commands such as:

```bash
kubeadm reset
```

or:

```bash
rm -rf /var/lib/etcd
```

or:

```bash
rm -rf /var/lib/kubelet
```

or:

```bash
rm -rf /var/lib/containerd
```

or:

```bash
kubectl delete namespace <NAMESPACE>
```

without understanding the consequences.

These operations can destroy cluster state or make recovery significantly more difficult.

First collect:

```text
Logs
Configuration
Events
Network information
Resource status
Storage status
```

Then apply a targeted recovery procedure.

---

# 924. Safe Diagnostic Commands

The following commands are generally useful for investigation:

```bash
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get events -A --sort-by=.lastTimestamp
kubectl describe node <NODE>
kubectl describe pod <POD> -n <NAMESPACE>
kubectl get pvc -A
kubectl get pv
kubectl get storageclass
```

On nodes:

```bash
systemctl status kubelet
systemctl status containerd
journalctl -u kubelet
journalctl -u containerd
df -h
free -h
ss -lntp
```

For etcd:

```bash
etcdctl endpoint health
etcdctl endpoint status
etcdctl member list
```

using the appropriate TLS configuration.

---

# 925. Troubleshooting Checklist

## Infrastructure

```text
[ ] Host is reachable
[ ] Tailscale is connected where required
[ ] SSH works
[ ] DNS/hosts resolution works
[ ] Time is synchronized
[ ] Disk space is sufficient
[ ] Memory is sufficient
```

## HAProxy

```text
[ ] HAProxy service is running
[ ] Configuration validates
[ ] Port 6443 is listening
[ ] Master 01 is reachable
[ ] Master 02 is reachable
[ ] Master 03 is reachable
```

## Control Plane

```text
[ ] kubelet is running
[ ] containerd is running
[ ] etcd is healthy
[ ] etcd has a leader
[ ] kube-apiserver is running
[ ] kube-controller-manager is running
[ ] kube-scheduler is running
```

## Workers

```text
[ ] kubelet is running
[ ] containerd is running
[ ] Calico is running
[ ] Node is Ready
[ ] Pod networking works
```

## Storage

```text
[ ] OpenEBS is healthy
[ ] StorageClass exists
[ ] PVC is Bound
[ ] PV exists
[ ] Volume mounts successfully
[ ] Free storage is sufficient
```

## Backup

```text
[ ] CronJob exists
[ ] CronJob is not suspended
[ ] Job starts
[ ] Leader detection succeeds
[ ] etcd health succeeds
[ ] Snapshot succeeds
[ ] Snapshot validation succeeds
[ ] Checksum succeeds
[ ] Metadata succeeds
[ ] Retention succeeds
```

---

# 926. Emergency Recovery Principle

For major failures, preserve evidence before making destructive changes.

Recommended sequence:

```text
Incident
   |
   v
Collect current state
   |
   v
Collect logs
   |
   v
Identify failure layer
   |
   v
Check latest valid etcd backup
   |
   v
Determine recovery requirement
   |
   v
Execute appropriate recovery procedure
   |
   v
Validate
   |
   v
Create new backup
   |
   v
Document incident
```

This ensures that troubleshooting does not accidentally destroy the information required for recovery.

---

# 927. Final Troubleshooting Architecture

The complete troubleshooting dependency chain is:

```text
                         Admin Client
                              |
                              v
                           HAProxy
                              |
                              | :6443
                              v
                  +-------------------------+
                  | Kubernetes API Servers   |
                  | Master 01/02/03         |
                  +------------+------------+
                               |
                               v
                             etcd
                       :2379 / :2380
                               |
               +---------------+---------------+
               |               |               |
               v               v               v
          Master 01        Master 02        Master 03
               |
               v
            kubelet
               |
               v
           containerd
               |
        +------+------+
        |             |
        v             v
      Calico       OpenEBS
        |             |
        v             v
     Network        Storage
                      |
                      v
                Backup PVC
                      |
                      v
                Backup Job
                      |
                      v
              etcd Snapshots
```

Troubleshooting should follow this dependency chain rather than treating each component independently.

---

# 928. Part 18 Completion Criteria

Part 18 is complete when:

```text
[ ] Infrastructure troubleshooting is documented
[ ] Tailscale troubleshooting is documented
[ ] SSH troubleshooting is documented
[ ] HAProxy troubleshooting is documented
[ ] Kubernetes API troubleshooting is documented
[ ] etcd troubleshooting is documented
[ ] kubelet troubleshooting is documented
[ ] containerd troubleshooting is documented
[ ] Calico troubleshooting is documented
[ ] CoreDNS troubleshooting is documented
[ ] OpenEBS troubleshooting is documented
[ ] PV/PVC troubleshooting is documented
[ ] CronJob troubleshooting is documented
[ ] Backup troubleshooting is documented
[ ] Retention troubleshooting is documented
[ ] TLS troubleshooting is documented
[ ] Network troubleshooting is documented
[ ] Safe diagnostic procedures are documented
[ ] Destructive troubleshooting warnings are documented
[ ] Recovery decision trees are documented
```

---

# 929. Next Part

**Part 19 — Security**

The next part will document the security architecture for the complete cluster, including:

```text
Kubernetes RBAC
etcd TLS
Kubernetes PKI
Secrets
ServiceAccounts
HAProxy exposure
Network security
Calico NetworkPolicy
OpenEBS security
Backup protection
Admin Client security
SSH security
Tailscale security
Credential management
Least privilege
Audit considerations
Git repository security
```

# Part 19 — Security

## 930. Objective

Security is a foundational requirement for the Kubernetes cluster because the environment contains:

* Kubernetes control-plane state
* etcd data
* Kubernetes Secrets
* TLS private keys
* ServiceAccount credentials
* Administrative kubeconfig
* Persistent application data
* etcd backup snapshots

The security model follows:

```text id="z3h7px"
Least Privilege
      +
Authentication
      +
Authorization
      +
Encryption
      +
Network Segmentation
      +
Credential Protection
      +
Monitoring
      +
Controlled Recovery
```

The security architecture applies to all components:

```text id="y9y2dd"
Admin Client
     |
     v
HAProxy
     |
     v
Kubernetes API
     |
     +--> etcd
     |
     +--> Kubernetes workloads
     |
     +--> Calico
     |
     +--> OpenEBS
     |
     +--> Backup system
```

---

# 931. Security Zones

The infrastructure can be logically divided into several security zones.

```text id="3a0i5a"
+-------------------------------------------------------+
|                   External Network                    |
|                                                       |
|   Admin Client          HAProxy / Load Balancer       |
|        |                       |                      |
+--------+-----------------------+----------------------+
                         |
                         v
+-------------------------------------------------------+
|                Kubernetes Cluster                     |
|                                                       |
|  +-------------+  +-------------+  +-------------+   |
|  | Master 01   |  | Master 02   |  | Master 03   |   |
|  | etcd        |  | etcd        |  | etcd        |   |
|  +-------------+  +-------------+  +-------------+   |
|                                                       |
|  +-------------+  +-------------+  +-------------+   |
|  | Worker 01   |  | Worker 02   |  | Worker 03   |   |
|  +-------------+  +-------------+  +-------------+   |
|                                                       |
|        Calico                OpenEBS                  |
|                                                       |
+-------------------------------------------------------+
```

The external Admin Client and HAProxy are not Kubernetes nodes.

---

# 932. Security Responsibilities

Each component has a defined security responsibility.

| Component       | Primary Security Responsibility  |
| --------------- | -------------------------------- |
| Admin Client    | Administrative access control    |
| HAProxy         | Controlled API entry point       |
| kube-apiserver  | Authentication and authorization |
| etcd            | Protected cluster-state storage  |
| kubelet         | Node-level workload management   |
| containerd      | Container execution              |
| Calico          | Network connectivity and policy  |
| OpenEBS         | Persistent storage               |
| Backup workload | Protected etcd backup            |
| PVC             | Persistent backup storage        |
| Prometheus      | Monitoring                       |
| Grafana         | Monitoring visualization         |
| Tailscale       | Private connectivity where used  |
| Git repository  | Configuration/documentation only |

---

# 933. Principle of Least Privilege

Every component and identity should have only the permissions required to perform its function.

Examples:

```text id="xv10bd"
Backup workload
    |
    +--> Access etcd
    +--> Write backup PVC
    |
    X--> No unnecessary cluster-admin
```

Admin access:

```text id="w19z8c"
Administrator
    |
    +--> Required Kubernetes permissions
    |
    X--> Avoid unnecessary permanent credentials elsewhere
```

Applications should not automatically receive administrative permissions.

---

# 934. Kubernetes Authentication

The Kubernetes API server authenticates requests before authorization.

The Admin Client accesses:

```text id="c2y6zk"
Admin Client
     |
     v
HAProxy :6443
     |
     v
kube-apiserver
```

Authentication can involve mechanisms such as:

```text id="9id1f7"
Client certificates
ServiceAccount tokens
OIDC / external identity providers
Other configured authentication mechanisms
```

The actual authentication mechanisms used by this cluster should be documented separately if additional identity providers are introduced.

---

# 935. Kubernetes Authorization

After authentication, Kubernetes evaluates authorization.

The project should use:

```text id="8x6l9r"
Role
RoleBinding
ClusterRole
ClusterRoleBinding
```

where appropriate.

For namespace-specific permissions:

```yaml id="0h9x4y"
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: application-reader
  namespace: <NAMESPACE>
rules:
  - apiGroups: [""]
    resources:
      - pods
      - services
    verbs:
      - get
      - list
      - watch
```

Bind it only to the required identity.

---

# 936. Avoid Unnecessary Cluster-Admin

The following should not be the default approach:

```text id="3qmxoq"
kubectl create clusterrolebinding \
  <USER> \
  --clusterrole=cluster-admin
```

unless full administrative access is explicitly required.

Instead:

```text id="7ok4c7"
Required operation
       |
       v
Required resource
       |
       v
Required verb
       |
       v
Minimal RBAC permission
```

This reduces the impact of credential compromise.

---

# 937. Admin Client Security

The Admin Client is outside the Kubernetes cluster.

Its purpose is:

```text id="gl5t4y"
kubectl
helm
cluster administration
diagnostics
```

The Admin Client should be treated as a privileged management workstation.

Recommended controls:

```text id="xq9s5j"
[ ] OS kept patched
[ ] SSH protected
[ ] Disk encryption where appropriate
[ ] Strong local authentication
[ ] Administrative kubeconfig protected
[ ] Unnecessary software minimized
[ ] Credentials not committed to Git
```

---

# 938. Protect `admin.conf`

The kubeadm-generated administrator configuration is highly privileged.

Example location on a control-plane node:

```text id="8n4mry"
/etc/kubernetes/admin.conf
```

If copied to the Admin Client:

```bash id="x0d3gq"
mkdir -p ~/.kube
cp <SECURE-SOURCE>/admin.conf ~/.kube/config
chmod 600 ~/.kube/config
```

Verify:

```bash id="fdrd6c"
ls -l ~/.kube/config
```

Expected permissions should prevent other local users from reading the file.

Never commit:

```text id="bq0p3u"
admin.conf
```

to Git.

---

# 939. Kubeconfig Security

Check the API endpoint:

```bash id="cr7d1z"
kubectl config view --minify
```

The expected architecture is:

```text id="8c5iq8"
server: https://<HAProxy-ENDPOINT>:6443
```

The Admin Client should normally access the Kubernetes API through HAProxy rather than relying on a single master endpoint.

Protect kubeconfig because it may contain:

```text id="c8g7sa"
Client certificate
Client private key
Bearer token
Cluster CA
API endpoint
```

The exact contents depend on the authentication mechanism.

---

# 940. Kubernetes PKI

Kubernetes uses certificates for secure communication between components.

Typical kubeadm certificate material includes:

```text id="3o3tdv"
/etc/kubernetes/pki/
```

and etcd-related certificates under:

```text id="p6c1fw"
/etc/kubernetes/pki/etcd/
```

Do not expose private keys.

For example:

```text id="8f0wdu"
*.key
```

must be treated as sensitive credentials.

---

# 941. Certificate Expiration

Check kubeadm-managed certificate expiration:

```bash id="q9edj6"
sudo kubeadm certs check-expiration
```

Monitor certificate validity before expiration.

Certificate failure can cause:

```text id="4ld9jq"
API server unavailable
etcd client failure
etcd peer failure
kubectl TLS errors
kubelet authentication errors
```

Certificate management should therefore be part of routine cluster maintenance.

---

# 942. etcd Security

etcd contains critical Kubernetes state.

It must not be exposed unnecessarily.

Required communication channels include:

```text id="n6omqf"
Client:
2379

Peer:
2380
```

The intended architecture is:

```text id="r9qj0k"
Kubernetes components
       |
       v
   etcd :2379

etcd member
       |
       v
other etcd member :2380
```

Do not expose etcd ports to the public Internet.

---

# 943. etcd TLS

etcd communication should use TLS.

Typical components include:

```text id="o0a5yq"
CA certificate
Server certificate
Client certificate
Private key
```

Backup access should use appropriate etcd client certificates.

Example:

```bash id="w7k3r2"
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints="<ENDPOINT>" \
  --cacert=<CA-CERT> \
  --cert=<CLIENT-CERT> \
  --key=<CLIENT-KEY>
```

Never disable TLS verification simply to make troubleshooting easier.

---

# 944. etcd Peer Security

Peer communication occurs on:

```text id="ix2jse"
TCP 2380
```

Only the etcd members should require access to this port.

Conceptually:

```text id="9sm1yw"
Master 01 :2380
      |
      +---- Master 02 :2380
      |
      +---- Master 03 :2380
```

Worker nodes and the external Admin Client do not need general access to etcd peer traffic.

---

# 945. etcd Client Access

Client access on port `2379` should also be restricted.

The backup workload requires etcd client access.

Therefore:

```text id="b0j6mq"
Backup Pod
     |
     v
etcd :2379
```

should be allowed.

But unnecessary workloads should not receive the same access.

If network policy and infrastructure firewalls support the required controls, restrict access accordingly.

---

# 946. HAProxy Security

HAProxy exposes the Kubernetes API endpoint:

```text id="5wwtmi"
HAProxy :6443
```

The listener should not expose unnecessary services.

Check:

```bash id="iz12my"
sudo ss -lntp
```

Verify that only intended ports are listening.

Validate HAProxy:

```bash id="a0l9ly"
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

---

# 947. HAProxy Is Not an Authentication Boundary

HAProxy provides:

```text id="v8v6fl"
Load balancing
TCP forwarding
Health checks
```

Kubernetes authentication and authorization remain responsibilities of the Kubernetes API server.

Therefore:

```text id="67ed4g"
Admin Client
     |
     v
HAProxy
     |
     v
kube-apiserver
     |
     +--> Authentication
     |
     +--> Authorization
```

HAProxy should not be treated as a replacement for Kubernetes RBAC.

---

# 948. HAProxy Network Exposure

If HAProxy has an externally reachable address, restrict access to port `6443` wherever possible.

The desired model is:

```text id="3b0xjv"
Trusted Admin Network
        |
        v
HAProxy :6443
        |
        v
Kubernetes API
```

Avoid:

```text id="0xv9pb"
Internet
   |
   v
HAProxy :6443
   |
   v
Kubernetes API
```

unless the exposure is explicitly required and protected by an appropriate security architecture.

---

# 949. Firewall Strategy

The environment should implement a least-access firewall model.

Example conceptual requirements:

| Port         | Source                                | Destination   | Purpose           |
| ------------ | ------------------------------------- | ------------- | ----------------- |
| 22           | Admin/management network              | Nodes         | SSH               |
| 6443         | Admin Client / trusted network        | HAProxy       | Kubernetes API    |
| 6443         | HAProxy                               | Masters       | Kubernetes API    |
| 2379         | Required Kubernetes/backup components | Masters       | etcd client       |
| 2380         | Masters                               | Masters       | etcd peer         |
| 10250        | Required control-plane components     | Workers       | Kubelet           |
| CNI-specific | Cluster nodes                         | Cluster nodes | Calico networking |

The exact rules depend on the chosen network topology, firewall implementation, and Calico configuration.

Do not blindly apply this table without validating the cluster's actual communication requirements.

---

# 950. Calico Network Security

Calico provides the networking layer and can also enforce NetworkPolicy.

Without explicit NetworkPolicy, workloads may have broader connectivity than required by the application's security model.

A NetworkPolicy can restrict communication by:

```text id="2w3bqu"
Namespace
Pod labels
IP blocks
Ports
Ingress
Egress
```

---

# 951. Example NetworkPolicy

A basic example:

```yaml id="bqz7z3"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: <NAMESPACE>
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

This is only an example.

Network policies must be designed according to actual application communication requirements.

---

# 952. NetworkPolicy and etcd Backup

The backup workload requires network access to etcd.

Therefore, if NetworkPolicy is introduced for the `etcd-backup` namespace, its egress rules must permit the required etcd traffic.

Conceptually:

```text id="3c7vdy"
etcd-backup Pod
      |
      +---- TCP 2379 ----> Master 01
      +---- TCP 2379 ----> Master 02
      └---- TCP 2379 ----> Master 03
```

The backup Pod should not receive broad unrestricted network access simply because it needs etcd access.

---

# 953. Backup Credential Security

The backup workload requires credentials to authenticate to etcd.

These credentials should be provided through Kubernetes Secrets.

Example:

```yaml id="jyyi9k"
volumes:
  - name: etcd-tls
    secret:
      secretName: etcd-backup-tls
```

The private key should be mounted read-only:

```yaml id="yd7q87"
volumeMounts:
  - name: etcd-tls
    mountPath: /etc/etcd-tls
    readOnly: true
```

Do not embed private keys directly in:

```text id="e8kw40"
Dockerfiles
Shell scripts
ConfigMaps
Git repository
CronJob YAML
README.md
```

---

# 954. Kubernetes Secrets

Inspect Secret metadata without exposing its contents:

```bash id="1j1rkg"
kubectl describe secret etcd-backup-tls \
  -n etcd-backup
```

Do not use commands that unnecessarily print Secret values into logs or terminals.

Remember:

```text id="5azl6a"
Kubernetes Secret
      |
      v
Base64 encoding
```

Base64 is not encryption.

Secrets must therefore be protected through appropriate Kubernetes, API, storage, and access controls.

---

# 955. ServiceAccount Security

The backup workload should use a dedicated ServiceAccount:

```yaml id="7cv3z1"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: etcd-backup
  namespace: etcd-backup
```

This is preferable to reusing a broad administrative identity.

If the backup application does not need to call the Kubernetes API, unnecessary ServiceAccount token exposure should be avoided.

For example:

```yaml id="s0u0oz"
automountServiceAccountToken: false
```

can be considered when compatible with the application's implementation.

If the application needs Kubernetes API access for leader discovery or another function, grant only the required RBAC permissions.

---

# 956. Backup PVC Security

The backup PVC contains etcd snapshots.

Therefore, access to:

```text id="4qf6m3"
/backup
```

should be restricted to the backup and authorized recovery workflows.

Do not expose the backup PVC through:

```text id="3kj9aa"
NodePort
LoadBalancer
Ingress
Public file-sharing service
```

unless there is a specific, reviewed requirement.

---

# 957. Backup Data Sensitivity

An etcd snapshot may contain Kubernetes Secrets and other sensitive cluster state.

Therefore:

```text id="at9r8o"
etcd snapshot
      =
Sensitive recovery artifact
```

Treat the backup with the same seriousness as privileged cluster credentials.

Recommended controls:

```text id="s93vyo"
[ ] Restricted filesystem access
[ ] Restricted Kubernetes access
[ ] Protected storage
[ ] Protected transfer
[ ] Controlled restore access
[ ] Retention policy
[ ] Secure deletion according to organizational requirements
```

---

# 958. Git Repository Security

The repository should contain:

```text id="u7s1tm"
Documentation
Configuration templates
Example manifests
Scripts
Architecture diagrams
Troubleshooting procedures
```

It must not contain:

```text id="1g9p7m"
admin.conf
*.key
Private TLS keys
ServiceAccount tokens
Passwords
Cloud credentials
Tailscale auth keys
etcd snapshot files
Real secret values
```

---

# 959. `.gitignore`

A project-level `.gitignore` should protect common sensitive and generated files.

Example:

```gitignore id="h3v3pw"
# Kubernetes credentials
admin.conf
kubeconfig
*.kubeconfig

# TLS / private keys
*.key
*.pem
*.p12
*.pfx

# etcd backups
*.db
*.db.tmp

# Backup artifacts
backup/
snapshots/
checksums/
metadata/

# Secrets / environment files
.env
.env.*
secrets/
credentials/

# Terraform state
*.tfstate
*.tfstate.*

# Terraform variable files
*.tfvars
*.tfvars.json

# Local configuration
*.local
```

Review the ignore rules according to the actual repository structure.

Do not rely solely on `.gitignore` if a sensitive file has already been committed.

---

# 960. Secret Scanning

Before pushing changes:

```bash id="ezq1bf"
git status
```

Review:

```bash id="i6d2t7"
git diff
```

Search for obvious sensitive patterns:

```bash id="y3n3tg"
grep -RniE \
  'password|token|private.?key|secret|client.key' \
  .
```

This is only a basic check and does not replace dedicated secret-scanning tooling.

---

# 961. SSH Security

SSH access should use:

```text id="t6iz7p"
Key-based authentication
```

where supported.

Protect private keys:

```bash id="z3r7gl"
chmod 600 ~/.ssh/<PRIVATE-KEY>
```

Do not place SSH private keys inside the Git repository.

Limit SSH access through appropriate network controls.

---

# 962. Root Access

Administrative commands in this project often require:

```bash id="3b2njf"
sudo
```

Root-level access should be restricted to authorized operators.

Do not distribute root credentials through:

```text id="d9k9r8"
Git
README
Chat messages
ConfigMaps
Kubernetes Secrets without appropriate controls
```

---

# 963. Container Security

Backup and application containers should run with the minimum privileges required.

Avoid:

```yaml id="55o2lv"
privileged: true
```

unless there is a documented requirement.

Avoid unnecessary:

```yaml id="znjrr3"
hostPID: true
hostNetwork: true
hostIPC: true
```

Do not mount:

```text id="4p5k9m"
/var/lib/etcd
```

into the backup Pod simply to obtain a snapshot.

Use the supported etcd client/API mechanism.

---

# 964. Read-Only Filesystems

Where compatible with the application, consider:

```yaml id="c8tsla"
securityContext:
  readOnlyRootFilesystem: true
```

The backup directory remains writable through the mounted PVC:

```text id="ppqk2s"
/backup
```

The application should otherwise operate with minimal filesystem write access.

---

# 965. Container Capabilities

Where supported, drop unnecessary Linux capabilities.

Example:

```yaml id="6k1l6x"
securityContext:
  capabilities:
    drop:
      - ALL
```

Only add capabilities back when a documented application requirement exists.

---

# 966. Resource Limits

Backup workloads should have resource requests and limits.

Example:

```yaml id="7x4i3h"
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

The actual values should be adjusted after observing real snapshot performance.

Resource controls help prevent a backup process from consuming excessive node resources.

---

# 967. OpenEBS Security

OpenEBS provides the persistent storage layer for the backup PVC.

Security considerations include:

```text id="y6j2pm"
StorageClass access
PVC access
Node access
CSI components
Underlying storage
Storage replication
Filesystem permissions
```

Do not expose OpenEBS management components externally unless explicitly required.

---

# 968. Storage Engine Considerations

OpenEBS can use different storage engines and configurations.

Security and failure characteristics depend on:

```text id="f8qvcm"
Storage engine
Replication model
Node topology
Underlying disks
Network connectivity
Access controls
```

Therefore, the selected OpenEBS StorageClass should be documented.

Do not assume that all OpenEBS StorageClasses provide the same durability or replication characteristics.

---

# 969. Tailscale Security

Tailscale provides private connectivity between participating machines where configured.

The cluster should still apply normal security controls.

Tailscale does not eliminate the need for:

```text id="w9s1fj"
Kubernetes authentication
RBAC
TLS
Firewalls
NetworkPolicy
Credential protection
```

Check status:

```bash id="3cnd9a"
tailscale status
```

Use only authorized machines and identities in the tailnet.

---

# 970. Tailscale Credential Protection

Do not commit:

```text id="a1e2l6"
Tailscale auth keys
Reusable auth keys
Device credentials
```

to Git.

If an authentication key is exposed, follow the appropriate credential-revocation process.

---

# 971. Kubernetes API Security Flow

The intended access flow is:

```text id="m9w9m5"
Admin Client
      |
      | TLS
      v
HAProxy :6443
      |
      v
kube-apiserver
      |
      +--> Authenticate
      |
      +--> Authorize
      |
      +--> Admission
      |
      v
Kubernetes API
```

HAProxy distributes the connection among healthy API servers.

---

# 972. etcd Security Flow

The etcd architecture is:

```text id="5c84qt"
                 etcd Cluster
                      |
        +-------------+-------------+
        |             |             |
        v             v             v
    Master 01     Master 02     Master 03
       :2379         :2379         :2379
       :2380         :2380         :2380
```

Client access uses TLS.

Peer access uses the etcd peer security configuration.

---

# 973. Backup Security Flow

The backup architecture is:

```text id="l5ft4w"
Backup CronJob
      |
      v
Backup Pod
      |
      +---- TLS credentials
      |
      v
etcd :2379
      |
      v
Validated Snapshot
      |
      v
OpenEBS PVC
```

The backup Pod should not require access to unrelated Kubernetes resources.

---

# 974. Restore Security Flow

Restore is a privileged operation:

```text id="zq7k0e"
Authorized Operator
       |
       v
Select Snapshot
       |
       v
Verify Integrity
       |
       v
Restore etcd
       |
       v
Recover Cluster
```

Only authorized personnel should perform restore operations.

Restore snapshots should not be treated as ordinary application files.

---

# 975. Auditability

Important security-sensitive actions should be traceable where appropriate.

Examples:

```text id="m3q3cv"
Kubernetes API administrative actions
RBAC changes
Secret changes
Cluster configuration changes
Backup creation
Backup deletion
Restore operations
Certificate changes
```

Kubernetes audit logging can be considered if required by the operational or organizational security model.

---

# 976. Monitoring Security Events

Prometheus and Grafana can monitor operational security indicators such as:

```text id="u9f0dr"
Node availability
API server availability
Certificate expiration
Storage pressure
Backup failures
Backup age
CronJob failures
Pod restart rates
```

Monitoring does not replace security controls but provides visibility into abnormal behavior.

---

# 977. Backup Monitoring

At minimum, monitor:

```text id="2zcb8v"
Latest successful backup
Backup age
Backup duration
Backup size
Backup Job failures
PVC usage
Retention failures
```

A useful operational rule is:

```text id="i3l5n6"
Current Time - Last Successful Backup
```

If this exceeds the expected backup interval plus an operational tolerance, investigate immediately.

---

# 978. Security Incident Response

If a credential is suspected to be compromised:

```text id="h3r1ba"
1. Identify affected credential
2. Restrict access
3. Rotate/revoke credential
4. Review recent activity
5. Validate affected systems
6. Update dependent workloads
7. Remove exposed credential from repositories
8. Document incident
```

If a private key or privileged kubeconfig was committed to Git, deleting the file in a later commit is not sufficient.

The credential should be treated as exposed and rotated or revoked.

---

# 979. Security Hardening Checklist

## Infrastructure

```text id="m5e3na"
[ ] Hosts are patched
[ ] SSH access is restricted
[ ] Firewall is configured
[ ] Time synchronization is working
[ ] Unnecessary services are disabled
[ ] Disk encryption considered where appropriate
```

## HAProxy

```text id="7g1v9y"
[ ] Only required ports are exposed
[ ] API traffic uses TLS
[ ] Backend servers are explicitly configured
[ ] Configuration is validated
[ ] Administrative access is restricted
```

## Kubernetes

```text id="d3c2eq"
[ ] RBAC is enabled and used
[ ] Least privilege is followed
[ ] Admin kubeconfig is protected
[ ] Kubernetes certificates are monitored
[ ] Unnecessary privileged workloads are avoided
```

## etcd

```text id="0s7vzi"
[ ] Client TLS enabled
[ ] Peer TLS enabled where configured
[ ] Port 2379 restricted
[ ] Port 2380 restricted
[ ] etcd is not publicly exposed
[ ] Backup credentials are protected
```

## Calico

```text id="j2q3t1"
[ ] CNI is healthy
[ ] NetworkPolicy considered
[ ] Unnecessary pod communication restricted
[ ] Control-plane traffic protected
```

## OpenEBS

```text id="a4shf0"
[ ] StorageClass access controlled
[ ] PVC access controlled
[ ] Storage topology documented
[ ] Underlying storage protected
```

## Backup

```text id="c3q3s9"
[ ] Backup PVC protected
[ ] TLS credentials stored as Secrets
[ ] Snapshots treated as sensitive
[ ] Retention enabled
[ ] Backup integrity validated
[ ] Restore access restricted
```

## Git

```text id="g6p4fc"
[ ] No kubeconfig committed
[ ] No private keys committed
[ ] No passwords committed
[ ] No tokens committed
[ ] No etcd snapshots committed
[ ] `.gitignore` configured
[ ] Secret scanning performed
```

---

# 980. Security Validation Commands

Check listening ports:

```bash id="b1j8g7"
sudo ss -lntup
```

Check firewall:

```bash id="n4z5mp"
sudo ufw status
```

Check Kubernetes RBAC:

```bash id="9u4g5c"
kubectl auth can-i --list
```

Check node status:

```bash id="7n0z0n"
kubectl get nodes
```

Check privileged Pods:

```bash id="0m7t4v"
kubectl get pods -A -o yaml | grep -n "privileged:"
```

Check Secrets:

```bash id="b4x4yp"
kubectl get secrets -A
```

Do not dump Secret values unnecessarily.

Check certificates:

```bash id="q8h6z5"
sudo kubeadm certs check-expiration
```

Check etcd endpoints using TLS:

```bash id="x4j4pv"
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints="<ENDPOINT>" \
  --cacert=<CA-CERT> \
  --cert=<CLIENT-CERT> \
  --key=<CLIENT-KEY>
```

---

# 981. Security Review Before Production

Before considering the environment operationally ready, perform a security review.

### Identity

```text id="5e3mgo"
Who can access the Admin Client?
Who can access Kubernetes?
Who can access etcd?
Who can perform restore?
Who can modify OpenEBS?
```

### Network

```text id="4umj8j"
Which hosts can reach 6443?
Which hosts can reach 2379?
Which hosts can reach 2380?
Which hosts can reach kubelet ports?
Which workloads can communicate with each other?
```

### Credentials

```text id="m4g4d5"
Where are kubeconfigs stored?
Where are TLS private keys stored?
Where are backup credentials stored?
How are credentials rotated?
```

### Storage

```text id="x1r9gc"
Who can access backup PVC?
How long are snapshots retained?
How is backup storage protected?
How is an expired backup removed?
```

---

# 982. Security Boundaries

The final security boundaries are:

```text id="9wxw7q"
                External Management
                       |
                       v
                +-------------+
                | HAProxy     |
                | :6443       |
                +------+------+
                       |
                       v
              +-------------------+
              | Kubernetes API    |
              +---------+---------+
                        |
             +----------+----------+
             |                     |
             v                     v
           RBAC                  etcd
                                  |
                          TLS / restricted
                                  |
                                  v
                         Control-plane state

Backup path:

etcd
 |
 v
Backup Pod
 |
 | TLS
 v
Validated Snapshot
 |
 v
OpenEBS PVC
```

Each boundary should have an explicit access requirement.

---

# 983. Security Principles Used in This Project

The project follows these principles:

```text id="f8w0jv"
1. Least privilege
2. Defense in depth
3. Encryption in transit
4. Protected credentials
5. Restricted network access
6. Separation of management and workload functions
7. Protected backup storage
8. Controlled restore operations
9. Avoidance of unnecessary privileged containers
10. Secure repository practices
11. Operational monitoring
12. Documented recovery procedures
```

---

# 984. Security Responsibility Matrix

| Area                 | Primary Component  | Security Control                 |
| -------------------- | ------------------ | -------------------------------- |
| API access           | Kubernetes API     | Authentication + RBAC            |
| API routing          | HAProxy            | Restricted listener/backend      |
| etcd client traffic  | etcd               | TLS + network restriction        |
| etcd peer traffic    | etcd               | Peer TLS + network restriction   |
| Pod networking       | Calico             | NetworkPolicy                    |
| Persistent storage   | OpenEBS            | Storage access controls          |
| Backup credentials   | Kubernetes Secret  | Restricted Secret access         |
| Backup storage       | OpenEBS PVC        | Access control + retention       |
| Administration       | Admin Client       | Protected kubeconfig             |
| Host access          | SSH                | Key-based/restricted access      |
| Private connectivity | Tailscale          | Authorized devices/users         |
| Repository           | Git                | No secrets or recovery artifacts |
| Visibility           | Prometheus/Grafana | Operational monitoring           |

---

# 985. Final Security Validation

The environment should pass the following checks:

```text id="3i3p6r"
[ ] Admin Client access is controlled
[ ] HAProxy exposes only required services
[ ] Kubernetes API uses TLS
[ ] Kubernetes RBAC is configured
[ ] Admin kubeconfig is protected
[ ] Kubernetes private keys are protected
[ ] etcd client traffic is protected
[ ] etcd peer traffic is protected
[ ] etcd ports are not publicly exposed
[ ] Calico networking is operational
[ ] NetworkPolicy requirements are documented
[ ] OpenEBS access is controlled
[ ] Backup PVC is protected
[ ] Backup TLS credentials are stored securely
[ ] Backup snapshots are treated as sensitive
[ ] Retention policy is active
[ ] Restore access is restricted
[ ] SSH access is controlled
[ ] Tailscale credentials are protected
[ ] No secrets exist in Git
[ ] No etcd snapshots exist in Git
[ ] Certificate expiration is monitored
[ ] Backup health is monitored
[ ] Security-sensitive operations are documented
```

---

# 986. Part 19 Completion Criteria

Part 19 is complete when:

```text id="sjf2a8"
[ ] Kubernetes authentication and authorization are documented
[ ] RBAC least privilege is documented
[ ] Admin Client security is documented
[ ] HAProxy security is documented
[ ] etcd TLS security is documented
[ ] etcd network restrictions are documented
[ ] Calico NetworkPolicy considerations are documented
[ ] OpenEBS security is documented
[ ] Backup credential protection is documented
[ ] Backup PVC security is documented
[ ] Restore security is documented
[ ] SSH security is documented
[ ] Tailscale security is documented
[ ] Git repository security is documented
[ ] Secret-scanning considerations are documented
[ ] Container security is documented
[ ] Security monitoring is documented
[ ] Incident-response considerations are documented
[ ] Final security checklist is completed
```

---

# 987. Next Part

**Part 20 — Final Validation**

The next part will provide the complete end-to-end validation procedure for the project:

```text id="p4z2si"
Infrastructure
      |
      v
Network
      |
      v
HAProxy
      |
      v
Control Plane
      |
      v
Worker Nodes
      |
      v
Calico
      |
      v
OpenEBS
      |
      v
Persistent Storage
      |
      v
Monitoring
      |
      v
etcd
      |
      v
Backup
      |
      v
Retention
      |
      v
Restore
      |
      v
Security
      |
      v
Production Readiness
```

The final validation will consolidate the commands and acceptance criteria required to verify the complete six-node Kubernetes cluster and its supporting HAProxy, Admin Client, OpenEBS, monitoring, and etcd backup architecture.

# Part 20 — Final Validation

## 988. Objective

The purpose of this part is to perform the final end-to-end validation of the **Local Cluster Deployment on Intranet** environment.

All infrastructure and Kubernetes components must be validated together rather than independently.

The final environment consists of:

```text
External Infrastructure
├── Admin Client
└── HAProxy / Load Balancer

Kubernetes Cluster
├── Master 01
│   └── etcd member
├── Master 02
│   └── etcd member
├── Master 03
│   └── etcd member
├── Worker 01
├── Worker 02
└── Worker 03

Cluster Services
├── Kubernetes API Server
├── etcd
├── kube-controller-manager
├── kube-scheduler
├── kubelet
├── containerd
├── Calico
├── CoreDNS
├── OpenEBS
├── Prometheus
├── Grafana
└── etcd Backup
```

The final validation flow is:

```text
Infrastructure
      |
      v
Network
      |
      v
HAProxy
      |
      v
Control Plane
      |
      v
Worker Nodes
      |
      v
Calico
      |
      v
DNS
      |
      v
OpenEBS
      |
      v
Persistent Storage
      |
      v
Monitoring
      |
      v
etcd
      |
      v
Backup
      |
      v
Retention
      |
      v
Restore
      |
      v
Security
      |
      v
Production Readiness
```

---

# 989. Final Infrastructure Inventory

Before validating Kubernetes, confirm all eight machines.

```text
+----------------+
| Master 01      |
| Control Plane  |
| etcd           |
+----------------+

+----------------+
| Master 02      |
| Control Plane  |
| etcd           |
+----------------+

+----------------+
| Master 03      |
| Control Plane  |
| etcd           |
+----------------+

+----------------+
| Worker 01      |
| Worker         |
+----------------+

+----------------+
| Worker 02      |
| Worker         |
+----------------+

+----------------+
| Worker 03      |
| Worker         |
+----------------+

+----------------+
| HAProxy        |
| Load Balancer  |
+----------------+

+----------------+
| Admin Client   |
| Management     |
+----------------+
```

Verify hostnames:

```bash
hostname
```

On each Kubernetes node:

```bash
hostnamectl
```

Expected roles:

| Host         | Role                 | Kubernetes Node |
| ------------ | -------------------- | --------------- |
| Master 01    | Control Plane + etcd | Yes             |
| Master 02    | Control Plane + etcd | Yes             |
| Master 03    | Control Plane + etcd | Yes             |
| Worker 01    | Worker               | Yes             |
| Worker 02    | Worker               | Yes             |
| Worker 03    | Worker               | Yes             |
| HAProxy      | API Load Balancer    | No              |
| Admin Client | Administration       | No              |

---

# 990. Network Connectivity Validation

Validate network connectivity before validating Kubernetes.

From the required machines, test:

```bash
ping <TARGET-IP>
```

For TCP connectivity:

```bash
nc -vz -w 3 <TARGET-IP> <PORT>
```

Important ports include:

```text
22      SSH
6443    Kubernetes API
2379    etcd client
2380    etcd peer
```

Additional ports depend on:

```text
Calico configuration
Kubelet configuration
Monitoring configuration
OpenEBS storage engine
```

Do not assume that every port must be open between every machine.

---

# 991. Tailscale Validation

On machines using Tailscale:

```bash
tailscale status
```

Check local IP:

```bash
tailscale ip -4
```

Check interface:

```bash
ip addr show tailscale0
```

Check service:

```bash
sudo systemctl status tailscaled
```

Expected:

```text
[ ] Required nodes are reachable
[ ] No unexpected offline nodes
[ ] Tailscale interface is operational
[ ] Required ports are reachable
```

---

# 992. SSH Validation

From the Admin Client or management host:

```bash
ssh <USER>@<MASTER-01-IP>
ssh <USER>@<MASTER-02-IP>
ssh <USER>@<MASTER-03-IP>
ssh <USER>@<WORKER-01-IP>
ssh <USER>@<WORKER-02-IP>
ssh <USER>@<WORKER-03-IP>
```

If HAProxy administration is required:

```bash
ssh <USER>@<HAProxy-IP>
```

Verify that SSH access is restricted to authorized users.

---

# 993. Time Synchronization Validation

On all Kubernetes nodes:

```bash
timedatectl
```

Verify:

```text
System clock synchronized: yes
```

Check:

```bash
date
```

Consistent system time is important for:

```text
TLS certificates
Kubernetes operations
etcd
CronJobs
Backup timestamps
Retention
Monitoring
```

---

# 994. Resource Validation

On each Kubernetes node:

```bash
free -h
```

Check CPU:

```bash
nproc
```

Check disk:

```bash
df -h
```

Check inode availability:

```bash
df -i
```

There should be sufficient resources for:

```text
Kubernetes control plane
etcd
Calico
OpenEBS
Monitoring
Application workloads
Backup Jobs
```

---

# 995. Container Runtime Validation

On every Kubernetes node:

```bash
sudo systemctl status containerd
```

Check:

```bash
containerd --version
```

Verify CRI:

```bash
sudo crictl info
```

List containers:

```bash
sudo crictl ps
```

Expected:

```text
[ ] containerd active
[ ] CRI available
[ ] No unexpected runtime errors
```

---

# 996. kubelet Validation

On every Kubernetes node:

```bash
sudo systemctl status kubelet
```

Check logs:

```bash
sudo journalctl -u kubelet -n 100 --no-pager
```

Expected:

```text
[ ] kubelet active
[ ] No persistent errors
[ ] API server reachable
[ ] Container runtime reachable
```

---

# 997. HAProxy Validation

On the HAProxy node:

```bash
sudo systemctl status haproxy
```

Validate configuration:

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Check listener:

```bash
sudo ss -lntp | grep ':6443'
```

Expected:

```text
HAProxy
  |
  +--> Master 01 :6443
  +--> Master 02 :6443
  └--> Master 03 :6443
```

---

# 998. HAProxy Backend Validation

From HAProxy:

```bash
nc -vz -w 3 <MASTER-01-IP> 6443
nc -vz -w 3 <MASTER-02-IP> 6443
nc -vz -w 3 <MASTER-03-IP> 6443
```

All intended healthy API servers should be reachable.

If one server is unavailable, HAProxy should be able to route requests to the remaining healthy API servers.

---

# 999. Kubernetes API Endpoint Validation

From the Admin Client:

```bash
kubectl config view --minify
```

Verify the configured endpoint:

```text
https://<HAProxy-ENDPOINT>:6443
```

Then:

```bash
kubectl cluster-info
```

Expected:

```text
Kubernetes control plane is running
```

The exact output depends on the Kubernetes version and configuration.

---

# 1000. Kubernetes Version Validation

Check client version:

```bash
kubectl version --client
```

Check server version:

```bash
kubectl version
```

Check kubeadm:

```bash
kubeadm version
```

Check kubelet:

```bash
kubelet --version
```

The cluster should match the intended Kubernetes version:

```text
Kubernetes v1.34.11
```

Any version differences should be intentional and documented.

---

# 1001. Cluster Node Validation

Run:

```bash
kubectl get nodes -o wide
```

Expected architecture:

```text
NAME        ROLE
master-01   control-plane
master-02   control-plane
master-03   control-plane
worker-01   <worker>
worker-02   <worker>
worker-03   <worker>
```

All six Kubernetes nodes should normally report:

```text
STATUS
Ready
```

---

# 1002. Node Conditions

For each node:

```bash
kubectl describe node <NODE-NAME>
```

Check:

```text
MemoryPressure = False
DiskPressure   = False
PIDPressure    = False
Ready          = True
```

Also verify:

```bash
kubectl get nodes \
  -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[-1].type
```

Use `kubectl describe node` when detailed condition verification is required.

---

# 1003. Control-Plane Component Validation

Check:

```bash
kubectl get pods -n kube-system -o wide
```

Verify control-plane components:

```text
etcd
kube-apiserver
kube-controller-manager
kube-scheduler
```

On a kubeadm-managed cluster, these are commonly static Pods.

On each master:

```bash
sudo crictl ps | grep -E \
  'etcd|kube-apiserver|kube-controller-manager|kube-scheduler'
```

---

# 1004. etcd Cluster Validation

The cluster must contain three intended etcd members.

Check:

```bash
ETCDCTL_API=3 etcdctl member list \
  --endpoints="<ENDPOINT>" \
  --cacert=<CA-CERT> \
  --cert=<CLIENT-CERT> \
  --key=<CLIENT-KEY> \
  --write-out=table
```

Verify:

```text
[ ] Master 01 member
[ ] Master 02 member
[ ] Master 03 member
[ ] All members started
```

---

# 1005. etcd Health Validation

Run:

```bash
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints="<ENDPOINT-1>,<ENDPOINT-2>,<ENDPOINT-3>" \
  --cacert=<CA-CERT> \
  --cert=<CLIENT-CERT> \
  --key=<CLIENT-KEY>
```

All intended endpoints should report healthy.

Then:

```bash
ETCDCTL_API=3 etcdctl endpoint status \
  --endpoints="<ENDPOINT-1>,<ENDPOINT-2>,<ENDPOINT-3>" \
  --cacert=<CA-CERT> \
  --cert=<CLIENT-CERT> \
  --key=<CLIENT-KEY> \
  --write-out=table
```

Verify:

```text
[ ] Endpoints respond
[ ] One leader exists
[ ] Member IDs are correct
[ ] Revisions are consistent
```

---

# 1006. etcd Quorum Validation

For three etcd members:

```text
Members = 3
Quorum  = 2
```

The architecture can tolerate one member failure while maintaining quorum.

Test conceptually:

```text
3 members
   |
   +--> 1 unavailable
   |
   v
2 members
   |
   v
Quorum maintained
```

A failure test should only be performed in a controlled environment.

Do not intentionally stop an etcd member in production without an approved maintenance or resilience test.

---

# 1007. Calico Validation

Check:

```bash
kubectl get pods -n kube-system \
  -l k8s-app=calico-node \
  -o wide
```

Check:

```bash
kubectl get daemonset -n kube-system
```

Verify:

```text
[ ] Calico Pod on Master 01
[ ] Calico Pod on Master 02
[ ] Calico Pod on Master 03
[ ] Calico Pod on Worker 01
[ ] Calico Pod on Worker 02
[ ] Calico Pod on Worker 03
```

The exact DaemonSet labels may vary by Calico version.

---

# 1008. Pod CIDR Validation

Run:

```bash
kubectl get nodes \
  -o custom-columns=NAME:.metadata.name,PODCIDR:.spec.podCIDR
```

Verify that Pod CIDRs are assigned as expected.

Inspect Calico IPPool configuration where applicable:

```bash
kubectl get ippools.crd.projectcalico.org -o yaml
```

The Pod network design must remain consistent with the cluster's kubeadm and Calico configuration.

---

# 1009. CoreDNS Validation

Check:

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

Check Service:

```bash
kubectl get svc -n kube-system kube-dns
```

Test DNS:

```bash
kubectl run dns-test \
  --image=busybox:stable \
  --restart=Never \
  -- sleep 3600
```

Then:

```bash
kubectl exec dns-test -- \
  nslookup kubernetes.default
```

Clean up:

```bash
kubectl delete pod dns-test
```

Expected:

```text
DNS query succeeds
```

---

# 1010. Pod-to-Pod Network Validation

Create two test Pods:

```bash
kubectl run network-test-01 \
  --image=busybox:stable \
  --restart=Never \
  -- sleep 3600
```

```bash
kubectl run network-test-02 \
  --image=busybox:stable \
  --restart=Never \
  -- sleep 3600
```

Get IPs:

```bash
kubectl get pods -o wide
```

Test connectivity:

```bash
kubectl exec network-test-01 -- \
  ping <NETWORK-TEST-02-IP>
```

Clean up:

```bash
kubectl delete pod network-test-01 network-test-02
```

The exact test may need adjustment depending on the diagnostic image available in the intranet environment.

---

# 1011. Service Networking Validation

Create or use a test Service.

Check:

```bash
kubectl get svc
```

Check endpoints:

```bash
kubectl get endpoints
```

And:

```bash
kubectl get endpointslices
```

Verify:

```text
Service
   |
   v
EndpointSlice / Endpoints
   |
   v
Pod
```

A Service without endpoints should be investigated.

---

# 1012. OpenEBS Validation

Check namespace:

```bash
kubectl get pods -n openebs
```

Check StorageClasses:

```bash
kubectl get storageclass
```

Verify the intended OpenEBS StorageClass is available.

Then:

```bash
kubectl describe storageclass <OPENEBS-STORAGECLASS>
```

Verify:

```text
[ ] Provisioner correct
[ ] Reclaim policy documented
[ ] Volume binding mode understood
[ ] Storage engine documented
```

---

# 1013. PVC Validation

Check all PVCs:

```bash
kubectl get pvc -A
```

The backup PVC should show:

```text
STATUS
Bound
```

Check:

```bash
kubectl describe pvc \
  etcd-backup-pvc \
  -n etcd-backup
```

Verify:

```text
[ ] PVC Bound
[ ] Correct StorageClass
[ ] Correct requested capacity
[ ] Correct access mode
[ ] PV assigned
```

---

# 1014. PV Validation

Run:

```bash
kubectl get pv
```

Then:

```bash
kubectl describe pv <PV-NAME>
```

Verify:

```text
Capacity
Access Modes
Reclaim Policy
Status
StorageClass
CSI Driver
Node Affinity
```

The physical storage location must correspond to the selected OpenEBS storage architecture.

Do not assume that the Pod's node is necessarily the same as the physical storage host.

---

# 1015. Backup PVC Mount Validation

Identify the backup Pod:

```bash
kubectl get pods -n etcd-backup -o wide
```

Check:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  df -h /backup
```

Check mount:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  mount | grep /backup
```

Verify:

```text
[ ] /backup mounted
[ ] Writable
[ ] Correct capacity
[ ] Expected filesystem available
```

---

# 1016. Persistent Storage Test

Write a test file:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  sh -c 'echo "storage-test" > /backup/storage-test.txt'
```

Read it:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  cat /backup/storage-test.txt
```

After recreating the Pod, verify:

```bash
kubectl exec -n etcd-backup <NEW-BACKUP-POD> -- \
  cat /backup/storage-test.txt
```

Clean up:

```bash
kubectl exec -n etcd-backup <NEW-BACKUP-POD> -- \
  rm -f /backup/storage-test.txt
```

This validates persistence through the PVC.

---

# 1017. Monitoring Validation

Check monitoring namespaces:

```bash
kubectl get pods -A | grep -Ei \
  'prometheus|grafana|node-exporter'
```

Check Services:

```bash
kubectl get svc -A | grep -Ei \
  'prometheus|grafana'
```

Verify:

```text
[ ] Prometheus running
[ ] Grafana running
[ ] Node exporter running
[ ] Targets available
[ ] Metrics being collected
```

---

# 1018. Prometheus Validation

Check Prometheus Pods:

```bash
kubectl get pods -A | grep -i prometheus
```

Check Service:

```bash
kubectl get svc -A | grep -i prometheus
```

Verify that expected targets are being discovered.

At minimum, monitoring should cover:

```text
Nodes
Kubernetes components
Container metrics
Storage
Backup workload
```

The exact target list depends on the Prometheus deployment.

---

# 1019. Grafana Validation

Verify Grafana Pod:

```bash
kubectl get pods -A | grep -i grafana
```

Verify the Service:

```bash
kubectl get svc -A | grep -i grafana
```

Confirm that the Prometheus data source is configured and metrics can be queried.

---

# 1020. etcd Backup CronJob Validation

Check:

```bash
kubectl get cronjob -n etcd-backup
```

Expected:

```text
NAME          SUSPEND
etcd-backup   False
```

Check:

```bash
kubectl describe cronjob etcd-backup \
  -n etcd-backup
```

Verify:

```text
[ ] Schedule is correct
[ ] Time zone is correct
[ ] Concurrency policy is Forbid
[ ] Job history limits are configured
[ ] Backup image is correct
[ ] PVC is mounted
[ ] TLS Secret is mounted
```

---

# 1021. Manual Backup Validation

Trigger a manual Job:

```bash
kubectl create job \
  --from=cronjob/etcd-backup \
  etcd-backup-final-test-$(date +%s) \
  -n etcd-backup
```

Check:

```bash
kubectl get jobs -n etcd-backup
```

Then:

```bash
kubectl get pods -n etcd-backup -w
```

---

# 1022. Backup Log Validation

After the Job completes:

```bash
kubectl logs -n etcd-backup <BACKUP-POD>
```

The logs should show the expected sequence:

```text
Leader detection
      |
      v
Health check
      |
      v
Snapshot creation
      |
      v
Snapshot validation
      |
      v
Checksum
      |
      v
Metadata
      |
      v
Retention
      |
      v
Successful completion
```

The exact log messages depend on the implementation.

---

# 1023. Backup Artifact Validation

Check snapshots:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  find /backup/snapshots \
  -maxdepth 1 \
  -type f \
  -name '*.db' \
  -print | sort
```

Check checksums:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  find /backup/checksums \
  -maxdepth 1 \
  -type f \
  -name '*.sha256' \
  -print | sort
```

Check metadata:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  find /backup/metadata \
  -maxdepth 1 \
  -type f \
  -name '*.json' \
  -print | sort
```

Verify that each valid snapshot has its associated artifacts.

---

# 1024. Checksum Validation

For the newest backup:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  sha256sum -c \
  /backup/checksums/<SNAPSHOT-NAME>.sha256
```

Expected:

```text
<SNAPSHOT-NAME>.db: OK
```

---

# 1025. Snapshot Validation

Use the version-compatible tool:

```bash
etcdutl snapshot status <SNAPSHOT>
```

or the compatible `etcdctl` equivalent.

Verify:

```text
[ ] Snapshot is readable
[ ] Hash available
[ ] Revision available
[ ] Key count available
[ ] Database size available
```

The exact command must match the etcd version used by the project.

---

# 1026. Leader-Aware Backup Validation

The backup must not depend on a fixed master.

Verify manually:

```bash
ETCDCTL_API=3 etcdctl endpoint status \
  --endpoints="<ENDPOINT-1>,<ENDPOINT-2>,<ENDPOINT-3>" \
  --cacert=<CA-CERT> \
  --cert=<CLIENT-CERT> \
  --key=<CLIENT-KEY> \
  --write-out=table
```

Confirm that the backup logic identifies the endpoint whose:

```text
Member ID = Leader ID
```

The backup process should then perform the snapshot against the selected healthy endpoint according to the implementation from Part 13.

---

# 1027. Retention Validation

Check backup count:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  find /backup/snapshots \
  -maxdepth 1 \
  -type f \
  -name '*.db' \
  | wc -l
```

Verify that:

```text
[ ] Recent backups remain
[ ] Expired backups are removed
[ ] Newest valid backup remains
[ ] No incomplete .tmp files are treated as backups
[ ] Checksum files match retained snapshots
[ ] Metadata files match retained snapshots
```

---

# 1028. Backup Storage Capacity Validation

Run:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  df -h /backup
```

Then:

```bash
kubectl exec -n etcd-backup <BACKUP-POD> -- \
  du -sh /backup/*
```

Document:

```text
PVC Capacity
Current Usage
Available Space
Average Snapshot Size
Retention Period
Estimated Maximum Usage
```

---

# 1029. Backup Failure Test

In a controlled environment, verify that the backup process fails safely when a required dependency is unavailable.

Possible controlled tests include:

```text
etcd endpoint unavailable
PVC unavailable
TLS credential unavailable
Insufficient storage
Snapshot validation failure
```

The expected behavior is:

```text
Failure
  |
  +--> Job reports failure
  |
  +--> Existing valid backups preserved
  |
  +--> No corrupt backup marked valid
  |
  +--> Logs identify failure
```

Do not perform destructive failure tests on production infrastructure without an approved test plan.

---

# 1030. Restore Validation

The restore procedure from Part 17 should be tested in a controlled recovery environment.

Validate:

```text
[ ] Backup selected
[ ] Checksum verified
[ ] Snapshot validated
[ ] Snapshot restored
[ ] etcd starts
[ ] etcd cluster becomes healthy
[ ] Kubernetes API becomes available
[ ] Kubernetes objects are present
[ ] Calico becomes healthy
[ ] OpenEBS becomes healthy
[ ] Critical workloads recover
[ ] New backup succeeds
```

A documented restore procedure without a successful restore test should not be considered fully validated.

---

# 1031. Admin Client Validation

From the Admin Client:

```bash
kubectl cluster-info
```

Then:

```bash
kubectl get nodes -o wide
```

Check identity:

```bash
kubectl auth whoami
```

Check permissions:

```bash
kubectl auth can-i --list
```

Verify Helm:

```bash
helm version
```

Check Helm releases:

```bash
helm list -A
```

The Admin Client should be able to perform only the administrative actions required by the intended operator role.

---

# 1032. API Failover Validation

The HAProxy design should be validated by testing API server redundancy in a controlled environment.

Normal state:

```text
HAProxy
   |
   +--> Master 01 ✓
   +--> Master 02 ✓
   └--> Master 03 ✓
```

If one API server becomes unavailable:

```text
HAProxy
   |
   +--> Master 01 X
   +--> Master 02 ✓
   └--> Master 03 ✓
```

The Admin Client should continue to reach the Kubernetes API through the remaining healthy backend servers.

The test should be performed without intentionally causing unnecessary cluster disruption.

---

# 1033. Worker Scheduling Validation

Check:

```bash
kubectl get nodes
```

Deploy a test workload:

```bash
kubectl create deployment validation-nginx \
  --image=nginx
```

Check:

```bash
kubectl get pods -o wide
```

Scale:

```bash
kubectl scale deployment validation-nginx --replicas=3
```

Verify Pods are scheduled:

```bash
kubectl get pods -o wide
```

Clean up:

```bash
kubectl delete deployment validation-nginx
```

---

# 1034. Worker Distribution Validation

For three workers, verify that workloads can be scheduled across the worker pool.

```bash
kubectl get pods -A -o wide
```

Review:

```text
NODE
```

for application Pods.

The scheduler should use available worker resources according to:

```text
Taints
Labels
Affinity
Resources
Topology
Scheduling constraints
```

---

# 1035. Kubernetes Object Validation

Run:

```bash
kubectl get namespaces
```

Then:

```bash
kubectl get deployments -A
kubectl get daemonsets -A
kubectl get statefulsets -A
kubectl get jobs -A
kubectl get cronjobs -A
```

Check for unexpected failures:

```bash
kubectl get pods -A
```

Look for:

```text
CrashLoopBackOff
ImagePullBackOff
Pending
Error
Unknown
ContainerCreating
```

---

# 1036. Security Validation

Review:

```bash
kubectl auth can-i --list
```

Check Secrets:

```bash
kubectl get secrets -A
```

Do not print Secret contents.

Check privileged workloads:

```bash
kubectl get pods -A -o yaml | grep -n 'privileged:'
```

Check certificates:

```bash
sudo kubeadm certs check-expiration
```

Review Git repository:

```bash
git status
git diff
```

Confirm:

```text
[ ] No admin.conf
[ ] No private keys
[ ] No tokens
[ ] No passwords
[ ] No etcd snapshots
[ ] No sensitive environment files
```

---

# 1037. Backup Security Validation

Verify the backup Secret:

```bash
kubectl get secret etcd-backup-tls \
  -n etcd-backup
```

Verify the PVC:

```bash
kubectl get pvc etcd-backup-pvc \
  -n etcd-backup
```

Verify:

```text
[ ] TLS credentials mounted read-only
[ ] Backup PVC is not externally exposed
[ ] Backup Pod is not privileged unnecessarily
[ ] Backup files are protected
[ ] Retention is active
[ ] Restore access is restricted
```

---

# 1038. Resource and Stability Validation

Monitor the cluster after deployment.

Check:

```bash
kubectl get nodes
```

Check:

```bash
kubectl get pods -A
```

Check events:

```bash
kubectl get events -A \
  --sort-by=.lastTimestamp
```

Check node resources:

```bash
kubectl top nodes
```

If Metrics Server is installed.

Check Pods:

```bash
kubectl top pods -A
```

if supported by the monitoring configuration.

---

# 1039. Long-Running Stability Test

The environment should be observed over an appropriate period rather than validated only immediately after installation.

Monitor:

```text
Node readiness
Pod restarts
etcd health
API server availability
Calico health
OpenEBS health
PVC usage
Prometheus health
Grafana health
Backup success
Retention success
```

Record significant failures.

---

# 1040. Final End-to-End Test

The final functional test should follow this sequence:

```text
Admin Client
      |
      v
HAProxy
      |
      v
Kubernetes API
      |
      v
Create workload
      |
      v
Scheduler
      |
      v
Worker
      |
      v
Calico network
      |
      v
Service
      |
      v
OpenEBS storage
      |
      v
Application
```

Then validate:

```text
etcd
 |
 v
Backup
 |
 v
OpenEBS PVC
 |
 v
Retention
 |
 v
Restore test
```

---

# 1041. Final Acceptance Matrix

| Area           | Validation             | Expected Result                |
| -------------- | ---------------------- | ------------------------------ |
| Infrastructure | 8 machines available   | All required hosts reachable   |
| Network        | Node connectivity      | Required paths work            |
| Tailscale      | `tailscale status`     | Required nodes reachable       |
| SSH            | SSH tests              | Authorized access works        |
| HAProxy        | Config validation      | Configuration valid            |
| HAProxy        | Backend checks         | Healthy API backends available |
| Kubernetes     | `kubectl cluster-info` | API reachable                  |
| Nodes          | `kubectl get nodes`    | 6 Kubernetes nodes             |
| Control plane  | Static Pods            | Healthy                        |
| etcd           | Endpoint health        | Healthy                        |
| etcd           | Member list            | 3 members                      |
| etcd           | Leader                 | One leader                     |
| Calico         | DaemonSet              | Healthy across nodes           |
| CoreDNS        | DNS test               | Resolution succeeds            |
| OpenEBS        | Storage components     | Healthy                        |
| PVC            | Backup PVC             | Bound                          |
| PV             | Volume                 | Correctly provisioned          |
| Monitoring     | Prometheus/Grafana     | Operational                    |
| Backup         | Manual Job             | Successful                     |
| Snapshot       | Validation             | Valid                          |
| Checksum       | SHA-256                | Matches                        |
| Retention      | Cleanup                | Expired sets removed           |
| Restore        | Recovery test          | Successful                     |
| Security       | Credential review      | No exposed credentials         |

---

# 1042. Final Project Validation Commands

The following command set provides a quick final health check.

### Cluster

```bash
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A
kubectl get events -A --sort-by=.lastTimestamp
```

### Storage

```bash
kubectl get storageclass
kubectl get pv
kubectl get pvc -A
```

### OpenEBS

```bash
kubectl get pods -n openebs
```

### Backup

```bash
kubectl get cronjob -n etcd-backup
kubectl get jobs -n etcd-backup
kubectl get pods -n etcd-backup -o wide
```

### Monitoring

```bash
kubectl get pods -A | grep -Ei \
  'prometheus|grafana|node-exporter'
```

### Node services

On each Kubernetes node:

```bash
sudo systemctl status kubelet
sudo systemctl status containerd
```

### HAProxy

On the load-balancer:

```bash
sudo systemctl status haproxy
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo ss -lntp | grep ':6443'
```

---

# 1043. Final Architecture Validation

The final architecture should be represented as:

```text
                         +----------------+
                         |  Admin Client  |
                         +-------+--------+
                                 |
                                 | HTTPS / TLS
                                 | :6443
                                 v
                         +----------------+
                         |    HAProxy     |
                         | Load Balancer  |
                         +-------+--------+
                                 |
                 +---------------+---------------+
                 |               |               |
                 v               v               v
          +-------------+ +-------------+ +-------------+
          | Master 01   | | Master 02   | | Master 03   |
          | Control     | | Control     | | Control     |
          | Plane       | | Plane       | | Plane       |
          | etcd        | | etcd        | | etcd        |
          +------+------+ +------+------+ +------+------+
                 |               |               |
                 +---------------+---------------+
                         etcd Cluster
                         :2379/:2380
                                 |
                 +---------------+---------------+
                 |               |               |
                 v               v               v
          +-------------+ +-------------+ +-------------+
          | Worker 01   | | Worker 02   | | Worker 03   |
          +------+------+ +------+------+ +------+------+
                 |               |               |
                 +---------------+---------------+
                                 |
                              Calico
                                 |
                 +---------------+---------------+
                 |                               |
                 v                               v
             Workloads                       Services
                                                 |
                                                 v
                                             OpenEBS
                                                 |
                                                 v
                                              PV/PVC
                                                 |
                                                 v
                                         Backup Storage
                                                 ^
                                                 |
                                           etcd Backup
                                           CronJob
```

---

# 1044. Complete Backup Architecture Validation

The backup subsystem should follow:

```text
                  +------------------+
                  | etcd Cluster     |
                  | Master 01/02/03  |
                  +--------+---------+
                           |
                           | TLS :2379
                           v
                  +------------------+
                  | Backup CronJob   |
                  +--------+---------+
                           |
                           v
                  +------------------+
                  | Leader Detection |
                  +--------+---------+
                           |
                           v
                  +------------------+
                  | Snapshot         |
                  +--------+---------+
                           |
                           v
                  +------------------+
                  | Validation       |
                  +--------+---------+
                           |
                           v
                  +------------------+
                  | SHA-256          |
                  +--------+---------+
                           |
                           v
                  +------------------+
                  | Metadata         |
                  +--------+---------+
                           |
                           v
                  +------------------+
                  | Retention        |
                  +--------+---------+
                           |
                           v
                  +------------------+
                  | OpenEBS PVC      |
                  +------------------+
```

---

# 1045. Production Readiness Criteria

The cluster should not be considered ready until the following are satisfied.

## Infrastructure

```text
[ ] All required machines are available
[ ] Network connectivity is stable
[ ] Time synchronization is working
[ ] SSH access is controlled
[ ] Disk capacity is sufficient
[ ] Memory capacity is sufficient
```

## Control Plane

```text
[ ] Three control-plane nodes are Ready
[ ] Three etcd members are healthy
[ ] etcd leader is elected
[ ] API server is available
[ ] HAProxy backend failover is validated
```

## Worker Nodes

```text
[ ] Three workers are Ready
[ ] kubelet is healthy
[ ] containerd is healthy
[ ] Workloads can be scheduled
```

## Networking

```text
[ ] Calico is healthy
[ ] Pod-to-Pod connectivity works
[ ] Service connectivity works
[ ] DNS works
```

## Storage

```text
[ ] OpenEBS is healthy
[ ] StorageClass is configured
[ ] PV/PVC provisioning works
[ ] Backup PVC is Bound
[ ] Persistent write/read test succeeds
```

## Monitoring

```text
[ ] Prometheus is healthy
[ ] Grafana is healthy
[ ] Node metrics available
[ ] Cluster metrics available
[ ] Storage metrics available
```

## Backup

```text
[ ] Backup CronJob is enabled
[ ] Backup runs every 24 hours
[ ] Leader detection works
[ ] Snapshot creation succeeds
[ ] Snapshot validation succeeds
[ ] Checksum succeeds
[ ] Metadata succeeds
[ ] Backup stored on OpenEBS
[ ] Retention succeeds
```

## Restore

```text
[ ] Snapshot restore procedure documented
[ ] Checksum verification documented
[ ] Restore tooling version documented
[ ] Restore test completed
[ ] Kubernetes recovery validated
[ ] Post-restore backup succeeds
```

## Security

```text
[ ] RBAC configured
[ ] Admin kubeconfig protected
[ ] etcd TLS configured
[ ] Backup TLS credentials protected
[ ] Network access restricted
[ ] No secrets committed to Git
[ ] No private keys committed to Git
[ ] No etcd snapshots committed to Git
```

---

# 1046. Final Go-Live Checklist

Before declaring the project complete:

```text
+------------------------------------------------------+
|             FINAL GO-LIVE CHECKLIST                  |
+------------------------------------------------------+
| Infrastructure                                       |
| [ ] 3 Masters                                        |
| [ ] 3 Workers                                        |
| [ ] HAProxy                                           |
| [ ] Admin Client                                      |
|                                                      |
| Kubernetes                                           |
| [ ] All nodes Ready                                   |
| [ ] API available                                     |
| [ ] Control plane healthy                             |
|                                                      |
| etcd                                                 |
| [ ] 3 members                                         |
| [ ] Healthy                                            |
| [ ] Leader elected                                    |
|                                                      |
| Network                                               |
| [ ] Calico healthy                                    |
| [ ] DNS healthy                                       |
| [ ] Pod networking tested                             |
|                                                      |
| Storage                                               |
| [ ] OpenEBS healthy                                   |
| [ ] PVC Bound                                         |
| [ ] Persistence tested                                |
|                                                      |
| Monitoring                                            |
| [ ] Prometheus healthy                                |
| [ ] Grafana healthy                                   |
|                                                      |
| Backup                                                |
| [ ] CronJob enabled                                   |
| [ ] Snapshot validated                                |
| [ ] Checksum verified                                 |
| [ ] Retention working                                 |
|                                                      |
| Restore                                               |
| [ ] Restore tested                                    |
| [ ] Recovery documented                               |
|                                                      |
| Security                                              |
| [ ] RBAC reviewed                                     |
| [ ] TLS reviewed                                      |
| [ ] Credentials protected                             |
| [ ] Git repository clean                              |
+------------------------------------------------------+
```

---

# 1047. Final Validation Result

After all checks pass, record the final environment state.

Example:

```text
Project:
Local Cluster Deployment on Intranet

Kubernetes Version:
v1.34.11

Control Plane:
3 nodes

Worker Nodes:
3 nodes

etcd:
3-member cluster

Container Runtime:
containerd

CNI:
Calico

Storage:
OpenEBS

Load Balancer:
HAProxy

Administration:
External Admin Client

Monitoring:
Prometheus + Grafana

Backup:
Automated etcd snapshot every 24 hours

Backup Storage:
OpenEBS-backed PVC

Retention:
Configured backup lifecycle

Restore:
Documented and tested
```

Actual StorageClass, Pod CIDR, Service CIDR, IP addresses, hostnames, and other environment-specific values should be recorded according to the deployed configuration.

---

# 1048. Final Operational Validation

The project should transition from deployment mode to operational mode only after:

```text
Deployment
    |
    v
Validation
    |
    v
Monitoring
    |
    v
Backup
    |
    v
Restore Test
    |
    v
Security Review
    |
    v
Operational Handover
```

The operational handover should include:

```text
Architecture
Node inventory
Network design
HAProxy configuration
Kubernetes configuration
Calico configuration
OpenEBS configuration
Monitoring configuration
Backup procedure
Retention procedure
Restore procedure
Troubleshooting procedure
Security controls
```

---

# 1049. Documentation Completeness

The root `README.md` should now contain:

```text
Part 01 — Infrastructure and Node Provisioning
Part 02 — Kubernetes Node Preparation
Part 03 — HAProxy Load Balancer Configuration
Part 04 — Kubernetes Control Plane Initialization
Part 05 — Add Additional Control-Plane Nodes
Part 06 — Add Worker Nodes
Part 07 — Install and Configure Calico CNI
Part 08 — External Admin Client Configuration
Part 09 — OpenEBS Installation and Storage Foundation
Part 10 — Persistent Storage Configuration
Part 11 — Monitoring
Part 12 — etcd Architecture
Part 13 — etcd Backup
Part 14 — Backup Storage
Part 15 — CronJob
Part 16 — Backup Retention and Lifecycle Management
Part 17 — etcd Restore and Disaster Recovery
Part 18 — Troubleshooting
Part 19 — Security
Part 20 — Final Validation
```

All parts remain in the **single root `README.md`**.

---

# 1050. Part 20 Completion Criteria

Part 20 is complete when:

```text
[ ] Infrastructure validated
[ ] Network validated
[ ] Tailscale validated
[ ] SSH validated
[ ] HAProxy validated
[ ] Kubernetes API validated
[ ] Six Kubernetes nodes validated
[ ] Three-member etcd validated
[ ] etcd quorum validated
[ ] Calico validated
[ ] CoreDNS validated
[ ] Pod networking validated
[ ] Service networking validated
[ ] OpenEBS validated
[ ] PV/PVC validated
[ ] Persistent storage validated
[ ] Prometheus validated
[ ] Grafana validated
[ ] Backup CronJob validated
[ ] etcd snapshot validated
[ ] Checksum validated
[ ] Retention validated
[ ] Restore procedure validated
[ ] RBAC validated
[ ] TLS validated
[ ] Credential protection validated
[ ] Git repository reviewed
[ ] Final go-live checklist completed
```

---

# 1051. Project Completion Status

At this point, the complete deployment documentation covers the full lifecycle:

```text
                 LOCAL CLUSTER DEPLOYMENT
                        ON INTRANET
                             |
        +--------------------+--------------------+
        |                    |                    |
        v                    v                    v
 Infrastructure          Kubernetes          External Access
        |                    |                    |
        v                    v                    v
     3 Masters          Control Plane          HAProxy
     3 Workers          Worker Nodes           Admin Client
        |                    |
        +----------+---------+
                   |
                   v
                Calico
                   |
                   v
                OpenEBS
                   |
          +--------+--------+
          |                 |
          v                 v
      Monitoring         etcd Backup
          |                 |
          v                 v
    Prometheus/Grafana    PVC
                            |
                            v
                        Retention
                            |
                            v
                          Restore
                            |
                            v
                         Security
                            |
                            v
                      Final Validation
```

The project is therefore documented from **initial infrastructure provisioning through Kubernetes deployment, networking, storage, monitoring, automated etcd backup, retention, disaster recovery, troubleshooting, security, and final validation**.

---

# 1052. Final Project Acceptance

The project can be considered technically complete when all mandatory acceptance criteria from Parts 01–20 have been executed successfully in the target environment and the resulting configuration has been recorded.

The final operational objective is:

```text
                    +----------------------+
                    |      Admin Client     |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    |       HAProxy        |
                    +----------+-----------+
                               |
                 +-------------+-------------+
                 |             |             |
                 v             v             v
             Master 01     Master 02     Master 03
                etcd          etcd          etcd
                 |             |             |
                 +-------------+-------------+
                               |
                         etcd Cluster
                               |
                 +-------------+-------------+
                 |                           |
                 v                           v
              Workers                    Backup
                 |                           |
                 v                           v
              Calico                    OpenEBS
                 |                           |
                 v                           v
             Workloads                  PVC Storage
                                             |
                                             v
                                         Retention
                                             |
                                             v
                                           Restore
```

**End-to-end deployment, operation, backup, recovery, security, and validation are now documented in the single root `README.md`.**

---

# 1053. Next Part

**Part 21 — Final Architecture**

The final part will consolidate the complete project into a single architectural reference, including:

```text
Infrastructure Topology
Network Topology
Kubernetes Architecture
Control-Plane Architecture
etcd Architecture
HAProxy Architecture
Calico Architecture
OpenEBS Storage Architecture
Monitoring Architecture
Backup Architecture
Retention Architecture
Restore Architecture
Security Boundaries
Data Flow
Operational Flow
Port Matrix
Component Responsibilities
Final Architecture Diagram
```

# Part 21 — Final Architecture

## 1054. Objective

This section provides the final consolidated architecture for the **Local Cluster Deployment on Intranet** project.

It brings together all components documented in Parts 01–20:

```text
Infrastructure
Kubernetes
HAProxy
etcd
Calico
OpenEBS
Persistent Storage
Monitoring
Backup
Retention
Restore
Security
Administration
```

The architecture is designed around:

```text
High Availability
      +
Controlled Administration
      +
Network Isolation
      +
Persistent Storage
      +
Automated Backup
      +
Disaster Recovery
      +
Monitoring
      +
Security
```

---

# 1055. Final Infrastructure Topology

The project consists of **8 machines**.

```text id="4m6f0b"
                         INTRANET / PRIVATE NETWORK
                                  |
             +--------------------+--------------------+
             |                                         |
             v                                         v
      +--------------+                         +--------------+
      | Admin Client |                         |   HAProxy    |
      | Management   |                         | Load Balancer|
      +------+-------+                         +------+-------+
             |                                        |
             | kubectl / Helm                         | :6443
             |                                        |
             +--------------------+-------------------+
                                  |
                +-----------------+-----------------+
                |                 |                 |
                v                 v                 v
         +-------------+   +-------------+   +-------------+
         |  Master 01  |   |  Master 02  |   |  Master 03  |
         | Control     |   | Control     |   | Control     |
         | Plane + etcd|   | Plane + etcd|   | Plane + etcd|
         +------+------+   +------+------+   +------+------+
                |                 |                 |
                +-----------------+-----------------+
                                  |
                                  |
                +-----------------+-----------------+
                |                 |                 |
                v                 v                 v
         +-------------+   +-------------+   +-------------+
         |  Worker 01  |   |  Worker 02  |   |  Worker 03  |
         | Workloads   |   | Workloads   |   | Workloads   |
         +-------------+   +-------------+   +-------------+
```

The external machines are:

```text
HAProxy
Admin Client
```

They are **not Kubernetes nodes**.

The Kubernetes cluster contains:

```text
3 Control-Plane Nodes
3 Worker Nodes
```

---

# 1056. Node Role Matrix

| Node         | Role                   | etcd | kube-apiserver |        Workloads |
| ------------ | ---------------------- | ---: | -------------: | ---------------: |
| Master 01    | Control Plane          |  Yes |            Yes | System workloads |
| Master 02    | Control Plane          |  Yes |            Yes | System workloads |
| Master 03    | Control Plane          |  Yes |            Yes | System workloads |
| Worker 01    | Worker                 |   No |             No |              Yes |
| Worker 02    | Worker                 |   No |             No |              Yes |
| Worker 03    | Worker                 |   No |             No |              Yes |
| HAProxy      | External Load Balancer |   No |             No |               No |
| Admin Client | External Management    |   No |             No |               No |

This separation keeps management and load-balancing functions outside the Kubernetes node pool.

---

# 1057. Kubernetes Architecture

The Kubernetes cluster contains:

```text id="5t5y3g"
                    Kubernetes Cluster
                           |
             +-------------+-------------+
             |             |             |
             v             v             v
        Master 01      Master 02      Master 03
             |             |             |
       +-----+-----+ +-----+-----+ +-----+-----+
       |           | |           | |           |
       v           v v           v v           v
      etcd       API etcd      API etcd      API
       |           |   |         |   |         |
       +-----------+---+---------+---+---------+
                       |
                       v
                  Kubernetes API
                       |
             +---------+---------+
             |         |         |
             v         v         v
          Worker 01 Worker 02 Worker 03
```

The control plane is distributed across three masters.

---

# 1058. Control-Plane Components

Each control-plane node contains the required Kubernetes control-plane components.

Conceptually:

```text id="9e6ftw"
Master
 |
 +--> kube-apiserver
 |
 +--> kube-controller-manager
 |
 +--> kube-scheduler
 |
 +--> etcd
 |
 +--> kubelet
 |
 +--> containerd
 |
 └--> Calico
```

With kubeadm, control-plane components such as the API server, scheduler, controller-manager, and stacked etcd are commonly managed as static Pods.

---

# 1059. Kubernetes API Architecture

The Kubernetes API endpoint is provided through HAProxy.

```text id="h0b5h3"
                 Admin Client
                      |
                      | TLS :6443
                      v
                +-----------+
                |  HAProxy  |
                +-----+-----+
                      |
           +----------+----------+
           |          |          |
           v          v          v
       Master 01  Master 02  Master 03
          :6443      :6443      :6443
```

The Admin Client should use the HAProxy endpoint rather than depending on a single master.

---

# 1060. HAProxy Architecture

HAProxy performs TCP load balancing for the Kubernetes API.

Conceptual configuration:

```text id="i9m8k2"
frontend kubernetes-api
        |
        | TCP :6443
        v
backend kubernetes-masters
        |
        +--> Master 01 :6443
        +--> Master 02 :6443
        └--> Master 03 :6443
```

Backend health checks determine whether an API server is available.

HAProxy does not load-balance etcd traffic.

---

# 1061. HAProxy Responsibility

HAProxy is responsible for:

```text
API endpoint
TCP forwarding
Backend health checks
Load distribution
API-server failover
```

HAProxy is not responsible for:

```text
Kubernetes authentication
Kubernetes RBAC
etcd leadership
Pod networking
Persistent storage
Backup retention
```

---

# 1062. etcd Architecture

The cluster uses a three-member etcd cluster.

```text id="1b9uk0"
                 +----------------+
                 |   etcd Cluster |
                 +-------+--------+
                         |
          +--------------+--------------+
          |              |              |
          v              v              v
      Master 01      Master 02      Master 03
       Member 01      Member 02      Member 03
```

Ports:

```text
2379 → etcd client traffic
2380 → etcd peer traffic
```

---

# 1063. etcd Quorum

The cluster contains:

```text id="5j3z2f"
3 etcd members
```

The quorum is:

```text id="y2q6n1"
2 members
```

Therefore:

```text
3 healthy → normal operation
2 healthy → quorum maintained
1 healthy → no quorum
```

This provides tolerance for one member failure under normal quorum assumptions.

---

# 1064. etcd Leader Architecture

etcd dynamically elects a leader.

The project must not assume:

```text id="4y4r0m"
Master 01 = Leader
```

The leader can change during cluster operation.

The backup process therefore uses endpoint status to identify the current leader.

Conceptually:

```text id="v3w4e5"
Master 01
   |
   +--> Member ID A
   |
Master 02
   |
   +--> Member ID B ← Leader
   |
Master 03
   |
   +--> Member ID C
```

The backup logic compares:

```text
Member ID
```

with:

```text
Leader ID
```

to identify the current leader.

---

# 1065. etcd Communication

Normal etcd communication is:

```text id="8r8l8h"
Kubernetes components
       |
       | TLS
       v
Master 01 :2379
Master 02 :2379
Master 03 :2379
```

Peer communication:

```text id="i3d2v8"
Master 01 :2380
      ↕
Master 02 :2380
      ↕
Master 03 :2380
```

HAProxy is not part of this communication path.

---

# 1066. Calico Network Architecture

Calico provides Kubernetes Pod networking.

```text id="5b4j7d"
             Kubernetes Cluster
                    |
                  Calico
                    |
        +-----------+-----------+
        |           |           |
        v           v           v
    Worker 01   Worker 02   Worker 03
        |           |           |
        v           v           v
      Pods        Pods        Pods
```

Calico provides the network connectivity required for:

```text
Pod-to-Pod communication
Cross-node networking
Service connectivity
NetworkPolicy where configured
```

The exact Calico dataplane and routing mode depend on the deployed configuration.

---

# 1067. Pod Network

The cluster's Pod CIDR is defined during Kubernetes initialization and must be compatible with Calico.

The relationship is:

```text id="r3a4ti"
kubeadm Pod CIDR
       |
       v
Kubernetes node PodCIDRs
       |
       v
Calico IPPool
       |
       v
Pod IP addresses
```

The exact CIDR values should be recorded from the deployed configuration.

---

# 1068. DNS Architecture

CoreDNS provides Kubernetes cluster DNS.

```text id="1f0fby"
Application Pod
      |
      | DNS query
      v
kube-dns Service
      |
      v
CoreDNS
      |
      v
DNS resolution
```

The Admin Client is not required for normal Pod DNS resolution.

---

# 1069. OpenEBS Storage Architecture

OpenEBS provides persistent storage for workloads.

The abstraction is:

```text id="o9t8p1"
Pod
 |
 v
PVC
 |
 v
PV
 |
 v
StorageClass
 |
 v
OpenEBS
 |
 v
Underlying Storage
```

The actual physical location depends on the selected OpenEBS storage engine and topology.

---

# 1070. Backup Storage Architecture

The etcd backup uses a dedicated PVC.

```text id="i7n3g0"
etcd
 |
 v
Backup Pod
 |
 v
etcd-backup-pvc
 |
 v
PV
 |
 v
OpenEBS
 |
 v
Persistent Storage
```

The backup PVC is separate from the live etcd data directory.

---

# 1071. Live etcd Storage vs Backup Storage

The architecture intentionally separates:

```text id="u0q9gy"
Live etcd
    |
    +--> /var/lib/etcd
```

from:

```text id="9w2y1m"
Backup
    |
    +--> /backup
          |
          +--> OpenEBS PVC
```

This separation is important because the backup must remain available independently of the live etcd data path.

---

# 1072. Backup Architecture

The complete automated backup process is:

```text id="7v8w6f"
                    +----------------+
                    |   etcd Cluster |
                    +-------+--------+
                            |
                            v
                   +------------------+
                   | Leader Detection |
                   +--------+---------+
                            |
                            v
                   +------------------+
                   | Health Check     |
                   +--------+---------+
                            |
                            v
                   +------------------+
                   | Snapshot Save    |
                   +--------+---------+
                            |
                            v
                   +------------------+
                   | Snapshot Status  |
                   | Validation       |
                   +--------+---------+
                            |
                            v
                   +------------------+
                   | SHA-256          |
                   +--------+---------+
                            |
                            v
                   +------------------+
                   | Metadata         |
                   +--------+---------+
                            |
                            v
                   +------------------+
                   | Retention        |
                   +--------+---------+
                            |
                            v
                   +------------------+
                   | OpenEBS PVC      |
                   +------------------+
```

---

# 1073. Backup Schedule

The backup CronJob runs every 24 hours.

Example:

```yaml id="td1k4u"
schedule: "0 2 * * *"
timeZone: "Asia/Kolkata"
```

This means the backup is scheduled daily at 02:00 in the configured timezone.

The actual production schedule should be recorded according to the deployed CronJob.

---

# 1074. Backup CronJob Architecture

The Kubernetes workload hierarchy is:

```text id="j1b7gy"
CronJob
   |
   v
Job
   |
   v
Backup Pod
   |
   +---- etcd TLS Secret
   |
   +---- etcd endpoints
   |
   +---- etcd-backup-pvc
```

Recommended CronJob controls include:

```yaml id="0p5u3s"
concurrencyPolicy: Forbid
successfulJobsHistoryLimit: 3
failedJobsHistoryLimit: 3
```

The exact values should match the deployed configuration.

---

# 1075. Backup Data Layout

The backup PVC contains:

```text id="0q7vyo"
/backup/
├── snapshots/
│   ├── etcd-snapshot-<TIMESTAMP>.db
│   └── ...
│
├── checksums/
│   ├── etcd-snapshot-<TIMESTAMP>.sha256
│   └── ...
│
├── metadata/
│   ├── etcd-snapshot-<TIMESTAMP>.json
│   └── ...
│
└── tmp/
```

The `.db`, `.sha256`, and `.json` files form a logical backup set.

---

# 1076. Backup Integrity

The backup process uses multiple validation layers:

```text id="o5z1r7"
Snapshot creation
      |
      v
Snapshot validation
      |
      v
SHA-256 checksum
      |
      v
Metadata
```

This provides:

```text
Completeness
+
Integrity verification
+
Operational traceability
```

---

# 1077. Backup Retention Architecture

Retention occurs after successful backup creation.

```text id="8u5s6q"
New Snapshot
     |
     v
Validate
     |
     v
Checksum
     |
     v
Metadata
     |
     v
Commit Backup
     |
     v
Retention
     |
     +--> Keep recent backups
     |
     └--> Delete expired backup sets
```

Retention must never delete the newest valid backup.

---

# 1078. Backup Retention Model

For example:

```text id="3o0v3h"
Backup Frequency = 24 hours
Retention       = 14 days
```

Expected retention:

```text id="v3o4h0"
Approximately 14 daily backup sets
```

Actual storage consumption depends on snapshot size and temporary operational files.

---

# 1079. Restore Architecture

The recovery architecture is:

```text id="q8q7n0"
                 OpenEBS PVC
                     |
                     v
              Selected Snapshot
                     |
                     v
              SHA-256 Verify
                     |
                     v
              Snapshot Validate
                     |
                     v
              etcd Restore Tool
                     |
                     v
              Restored etcd
                     |
                     v
             Kubernetes API
                     |
                     v
              Cluster Recovery
```

The restore operation is separate from the normal backup process.

---

# 1080. Restore Safety

The architecture follows:

```text id="8o4h2d"
Never overwrite live etcd data blindly.
```

The restore process should initially use a separate restore directory:

```text id="r5y7t2"
/var/lib/etcd-restore/
```

rather than immediately replacing:

```text id="4s4y5x"
/var/lib/etcd/
```

The actual recovery procedure must account for the kubeadm-managed static etcd Pods and the three-member cluster configuration.

---

# 1081. Monitoring Architecture

The monitoring layer consists of:

```text id="f8v6o2"
                  Prometheus
                      |
          +-----------+-----------+
          |           |           |
          v           v           v
        Nodes      Kubernetes   Storage
          |         Metrics       |
          |                       |
          +-----------+-----------+
                      |
                      v
                  Grafana
```

The exact monitoring components depend on the deployed Prometheus/Grafana configuration.

---

# 1082. Monitoring Scope

The monitoring system should provide visibility into:

```text id="y0x4n5"
Node health
CPU
Memory
Disk
Pod status
Container restarts
Kubernetes components
etcd health
Storage
PVC capacity
Backup Jobs
CronJob status
Backup age
```

---

# 1083. Security Architecture

The security architecture is:

```text id="0x9h4j"
Admin Client
      |
      | TLS
      v
HAProxy
      |
      v
Kubernetes API
      |
      +--> Authentication
      |
      +--> Authorization / RBAC
      |
      v
Cluster Resources
```

etcd:

```text id="g8k1p3"
Kubernetes
      |
      | TLS
      v
etcd
      |
      +--> Client security
      |
      +--> Peer security
```

Backup:

```text id="8s2j4v"
Backup Pod
      |
      | TLS credentials
      v
etcd
      |
      v
OpenEBS PVC
```

---

# 1084. Security Boundaries

The principal security boundaries are:

```text id="q3z1d7"
External Management
        |
        v
     HAProxy
        |
        v
 Kubernetes API
        |
        +---- RBAC
        |
        +---- Admission
        |
        v
 Kubernetes Resources

Separate boundary:

Backup Pod
        |
        v
  etcd :2379
        |
        v
 Backup PVC
```

The backup workload should not receive unnecessary Kubernetes permissions.

---

# 1085. Network Flow Matrix

| Source                | Destination      |          Port | Purpose             |
| --------------------- | ---------------- | ------------: | ------------------- |
| Admin Client          | HAProxy          |          6443 | Kubernetes API      |
| HAProxy               | Master 01        |          6443 | API forwarding      |
| HAProxy               | Master 02        |          6443 | API forwarding      |
| HAProxy               | Master 03        |          6443 | API forwarding      |
| Kubernetes components | etcd             |          2379 | etcd client         |
| Backup Pod            | etcd             |          2379 | etcd snapshot       |
| Master 01             | Master 02/03     |          2380 | etcd peer           |
| Master 02             | Master 01/03     |          2380 | etcd peer           |
| Master 03             | Master 01/02     |          2380 | etcd peer           |
| Kubernetes nodes      | Kubernetes nodes |  CNI-specific | Pod networking      |
| Workloads             | CoreDNS          |            53 | DNS                 |
| Workloads             | Services         | Service ports | Application traffic |

Additional ports may be required depending on the exact Calico, OpenEBS, monitoring, and kubelet configurations.

---

# 1086. Component Responsibility Matrix

| Component               | Responsibility                                  |
| ----------------------- | ----------------------------------------------- |
| Admin Client            | Cluster administration                          |
| HAProxy                 | Kubernetes API load balancing                   |
| Master 01               | Control plane + etcd                            |
| Master 02               | Control plane + etcd                            |
| Master 03               | Control plane + etcd                            |
| Worker 01               | Application workloads                           |
| Worker 02               | Application workloads                           |
| Worker 03               | Application workloads                           |
| kube-apiserver          | Kubernetes API                                  |
| kube-controller-manager | Cluster reconciliation                          |
| kube-scheduler          | Pod scheduling                                  |
| etcd                    | Persistent Kubernetes state                     |
| kubelet                 | Node agent                                      |
| containerd              | Container runtime                               |
| Calico                  | Pod networking / NetworkPolicy where configured |
| CoreDNS                 | Cluster DNS                                     |
| OpenEBS                 | Persistent storage                              |
| Prometheus              | Metrics collection                              |
| Grafana                 | Metrics visualization                           |
| Backup CronJob          | Automated etcd backups                          |
| Retention logic         | Backup lifecycle                                |
| Restore process         | Disaster recovery                               |

---

# 1087. Data Flow — Kubernetes API

The administrative request flow is:

```text id="t0y3w7"
kubectl
  |
  v
Admin Client
  |
  | HTTPS/TLS
  v
HAProxy :6443
  |
  +----> Master 01 :6443
  |
  +----> Master 02 :6443
  |
  └----> Master 03 :6443
             |
             v
        kube-apiserver
             |
             v
            etcd
```

---

# 1088. Data Flow — Application

A typical application request flows through:

```text id="u5n3m4"
Client
  |
  v
Kubernetes Service
  |
  v
Pod
  |
  +--> Calico networking
  |
  +--> OpenEBS PVC
```

The exact ingress or external-service architecture depends on the application deployed.

---

# 1089. Data Flow — Backup

The backup data flow is:

```text id="r7j1x5"
CronJob
   |
   v
Backup Pod
   |
   | etcd TLS
   v
etcd Leader
   |
   | snapshot
   v
Temporary Snapshot
   |
   v
Validation
   |
   v
Checksum
   |
   v
Metadata
   |
   v
OpenEBS PVC
```

---

# 1090. Data Flow — Restore

The restore data flow is:

```text id="k8n3y6"
OpenEBS PVC
      |
      v
Selected Backup
      |
      v
Checksum Verification
      |
      v
Snapshot Validation
      |
      v
etcd Restore
      |
      v
Restored etcd Cluster
      |
      v
Kubernetes API
      |
      v
Cluster Resources
```

---

# 1091. Storage Data Flow

The persistent-storage abstraction is:

```text id="m8x6t1"
Application / Backup Pod
          |
          v
         PVC
          |
          v
          PV
          |
          v
     StorageClass
          |
          v
       OpenEBS
          |
          v
Underlying Storage
```

This abstraction separates applications from the physical storage implementation.

---

# 1092. Failure Domains

The architecture has several distinct failure domains.

### HAProxy failure

```text id="r4n2w8"
HAProxy unavailable
       |
       v
Admin Client cannot use the normal API endpoint
```

The Kubernetes control plane and etcd may still be running.

HAProxy itself is therefore a separate infrastructure availability dependency.

---

### One master failure

```text id="u6j3n8"
Master 01 unavailable
       |
       +--> Master 02
       +--> Master 03
       |
       v
etcd quorum can remain available
```

The API can continue through healthy HAProxy backends if the remaining control-plane nodes are healthy.

---

### One worker failure

```text id="d8q5y2"
Worker 01 unavailable
       |
       v
Workloads can potentially run on
Worker 02 / Worker 03
```

Actual behavior depends on replicas, scheduling constraints, and application design.

---

# 1093. Backup Failure Domain

The backup system is intentionally separate from live etcd storage.

```text id="y7v8w4"
Live etcd failure
       |
       v
Backup remains on OpenEBS
```

However, the actual resilience of backup storage depends on the OpenEBS storage engine, replication model, node topology, and underlying storage.

Therefore, backup durability must be validated against the actual OpenEBS configuration.

---

# 1094. Disaster Recovery Boundary

The disaster-recovery boundary is:

```text id="k2m6y7"
Live Kubernetes Cluster
          |
          X
          |
          v
Independent Backup Storage
          |
          v
Validated Snapshot
          |
          v
Recovery Environment
```

The backup must remain available even when the live etcd state is unavailable.

---

# 1095. Administrative Boundaries

The project separates:

```text id="n9j7p4"
Administration
    |
    +--> Admin Client
    |
    +--> HAProxy management

Cluster operations
    |
    +--> Kubernetes API

Node operations
    |
    +--> kubelet
    +--> containerd

Storage operations
    |
    +--> OpenEBS

Recovery operations
    |
    +--> etcd restore
```

Each administrative function should be granted only to authorized operators.

---

# 1096. Repository Architecture

The Git repository should contain the project documentation and reproducible configuration.

Recommended structure:

```text id="g8j3k2"
local-cluster-deployment-intranet/
│
├── README.md
│
├── manifests/
│   ├── calico/
│   ├── openebs/
│   ├── monitoring/
│   └── etcd-backup/
│
├── scripts/
│   ├── backup/
│   ├── retention/
│   ├── validation/
│   └── troubleshooting/
│
├── haproxy/
│   └── haproxy.cfg.example
│
├── docs/
│   └── architecture/
│
└── .gitignore
```

The exact repository structure can be adjusted to the actual implementation.

Sensitive environment-specific files must remain outside Git.

---

# 1097. Files That Must Not Be Committed

The following must not be stored in the repository:

```text id="e7v2p8"
admin.conf
Kubeconfig containing credentials
TLS private keys
*.key
Passwords
Tokens
Cloud credentials
Tailscale authentication keys
etcd snapshots
Backup databases
Private certificates
Secret values
Terraform state containing sensitive data
```

The README should contain placeholders instead.

---

# 1098. Complete Operational Flow

The complete operational lifecycle is:

```text id="n4c7y1"
                  Infrastructure
                       |
                       v
                  Kubernetes
                       |
                       v
                    Calico
                       |
                       v
                   OpenEBS
                       |
                       v
                  Monitoring
                       |
                       v
                     etcd
                       |
                       v
                  Backup Job
                       |
                       v
                  Validation
                       |
                       v
                   Retention
                       |
                       v
                 Backup Storage
                       |
                       v
                 Restore Testing
                       |
                       v
                   Security
                       |
                       v
                Final Validation
```

---

# 1099. Complete Component Relationship

```text id="q7m1d3"
                                  Admin Client
                                       |
                                       |
                                      TLS
                                       |
                                       v
                                +-------------+
                                |   HAProxy   |
                                |    :6443    |
                                +------+------+ 
                                       |
                    +------------------+------------------+
                    |                  |                  |
                    v                  v                  v
              +-----------+      +-----------+      +-----------+
              | Master 01 |      | Master 02 |      | Master 03 |
              |           |      |           |      |           |
              | API       |      | API       |      | API       |
              | etcd      |<---->| etcd      |<---->| etcd      |
              | Scheduler |      | Scheduler |      | Scheduler |
              | Controller|      | Controller|      | Controller|
              +-----+-----+      +-----+-----+      +-----+-----+
                    |                  |                  |
                    +------------------+------------------+
                                       |
                                  Kubernetes
                                       |
                    +------------------+------------------+
                    |                  |                  |
                    v                  v                  v
              +-----------+      +-----------+      +-----------+
              | Worker 01 |      | Worker 02 |      | Worker 03 |
              +-----+-----+      +-----+-----+      +-----+-----+
                    |                  |                  |
                    +------------------+------------------+
                                       |
                                     Calico
                                       |
                         +-------------+-------------+
                         |                           |
                         v                           v
                    Workloads                    Services
                         |
                         v
                      OpenEBS
                         |
                         v
                       PVC/PV
                         |
              +----------+----------+
              |                     |
              v                     v
         Application              Backup
                                  PVC
                                   |
                                   v
                               Snapshots
                                   |
                                   v
                                Retention
                                   |
                                   v
                                 Restore
```

---

# 1100. Final Architecture Principles

The final design follows these architectural principles:

```text id="w3n8k4"
1. Three control-plane nodes provide control-plane redundancy.
2. Three etcd members provide distributed cluster state.
3. HAProxy provides a stable Kubernetes API endpoint.
4. Admin Client remains outside the Kubernetes node pool.
5. Workers are separated from control-plane responsibilities.
6. Calico provides Pod networking.
7. OpenEBS provides persistent storage.
8. Backup storage is separated from live etcd storage.
9. Backup selection is leader-aware.
10. Snapshots are validated before retention.
11. Retention is performed only after a successful backup.
12. Restore uses supported etcd restore tooling.
13. RBAC controls Kubernetes authorization.
14. TLS protects sensitive communication.
15. Credentials are excluded from Git.
16. Monitoring provides operational visibility.
17. Troubleshooting follows dependency layers.
18. Restore is treated as a controlled disaster-recovery operation.
```

---

# 1101. Final Port Reference

|                Port | Component          | Purpose                    |
| ------------------: | ------------------ | -------------------------- |
|                  22 | SSH                | Node administration        |
|                6443 | kube-apiserver     | Kubernetes API             |
|                2379 | etcd               | Client traffic             |
|                2380 | etcd               | Peer traffic               |
|               10250 | kubelet            | Kubernetes node management |
|                  53 | CoreDNS            | DNS                        |
|        CNI-specific | Calico             | Pod networking             |
|    OpenEBS-specific | OpenEBS            | Storage operations         |
| Monitoring-specific | Prometheus/Grafana | Monitoring                 |

Only required communication paths should be permitted by the network security architecture.

---

# 1102. Final Technology Stack

The documented project uses:

```text id="u4p7c8"
Operating System
    Linux

Kubernetes
    v1.34.11

Container Runtime
    containerd

Cluster Bootstrap
    kubeadm

CNI
    Calico

Load Balancer
    HAProxy

Persistent Storage
    OpenEBS

Monitoring
    Prometheus
    Grafana

Backup
    etcd snapshot
    etcdctl / etcdutl
    Kubernetes CronJob

Connectivity
    Tailscale

Administration
    kubectl
    Helm
```

The exact component versions should be recorded from the deployed environment when this README is finalized.

---

# 1103. Final Architecture Validation

The final architecture is considered structurally correct when:

```text id="p9f4v7"
[ ] 3 control-plane nodes exist
[ ] 3 worker nodes exist
[ ] 3 etcd members exist
[ ] HAProxy fronts Kubernetes API
[ ] Admin Client uses HAProxy
[ ] Workers do not host etcd
[ ] etcd peer traffic uses 2380
[ ] etcd client traffic uses 2379
[ ] Kubernetes API uses 6443
[ ] Calico provides Pod networking
[ ] CoreDNS provides cluster DNS
[ ] OpenEBS provides persistent storage
[ ] Backup uses dedicated PVC
[ ] Backup is leader-aware
[ ] Backup is validated
[ ] Backup retention is configured
[ ] Restore procedure exists
[ ] Monitoring exists
[ ] RBAC and TLS are configured
[ ] Sensitive credentials are excluded from Git
```

---

# 1104. Final Project Lifecycle

The entire project can be summarized as:

```text id="c9v6h1"
+-------------------------------------------------------+
|        LOCAL CLUSTER DEPLOYMENT ON INTRANET          |
+-------------------------------------------------------+
                         |
                         v
              Infrastructure Provisioning
                         |
                         v
                 Node Preparation
                         |
                         v
                HAProxy Configuration
                         |
                         v
              Kubernetes Control Plane
                         |
                         v
                  Worker Nodes
                         |
                         v
                     Calico
                         |
                         v
                    OpenEBS
                         |
                         v
                   Monitoring
                         |
                         v
                      etcd
                         |
                         v
                   etcd Backup
                         |
                         v
                    Retention
                         |
                         v
                      Restore
                         |
                         v
                  Troubleshooting
                         |
                         v
                     Security
                         |
                         v
                Final Validation
                         |
                         v
                Operational Handover
+-------------------------------------------------------+
```

---

# 1105. Final Project Architecture Summary

The completed environment provides:

```text id="d5s6q8"
High-Availability Control Plane
        |
        +--> 3 Masters
        |
        +--> 3 etcd Members
        |
        +--> HAProxy API Endpoint

Worker Capacity
        |
        +--> 3 Workers

Networking
        |
        +--> Calico
        +--> CoreDNS

Storage
        |
        +--> OpenEBS
        +--> PV/PVC

Monitoring
        |
        +--> Prometheus
        +--> Grafana

Backup
        |
        +--> 24-hour CronJob
        +--> Leader Detection
        +--> Snapshot Validation
        +--> SHA-256
        +--> Metadata
        +--> OpenEBS PVC
        +--> Retention

Recovery
        |
        +--> Snapshot Selection
        +--> Integrity Verification
        +--> etcd Restore
        +--> Cluster Validation

Security
        |
        +--> RBAC
        +--> TLS
        +--> Network Controls
        +--> Credential Protection
        +--> Repository Security
```

---

# 1106. Final Architecture Diagram

```text id="7v1n5s"
                              +------------------+
                              |   ADMIN CLIENT   |
                              | kubectl / Helm   |
                              +--------+---------+
                                       |
                                       | TLS :6443
                                       v
                              +------------------+
                              |     HAProxy      |
                              |  Load Balancer   |
                              +--------+---------+
                                       |
                     +-----------------+-----------------+
                     |                 |                 |
                     v                 v                 v
              +-------------+   +-------------+   +-------------+
              |  MASTER 01  |   |  MASTER 02  |   |  MASTER 03  |
              |-------------|   |-------------|   |-------------|
              | API Server  |   | API Server  |   | API Server  |
              | Controller  |   | Controller  |   | Controller  |
              | Scheduler   |   | Scheduler   |   | Scheduler   |
              | etcd        |   | etcd        |   | etcd        |
              +------+------+   +------+------+   +------+------+
                     |                 |                 |
                     +-----------------+-----------------+
                                       |
                                  etcd Cluster
                                :2379 / :2380
                                       |
                     +-----------------+-----------------+
                     |                 |                 |
                     v                 v                 v
              +-------------+   +-------------+   +-------------+
              |  WORKER 01  |   |  WORKER 02  |   |  WORKER 03  |
              |-------------|   |-------------|   |-------------|
              | kubelet     |   | kubelet     |   | kubelet     |
              | containerd  |   | containerd  |   | containerd  |
              | Calico      |   | Calico      |   | Calico      |
              | Workloads   |   | Workloads   |   | Workloads   |
              +------+------+   +------+------+   +------+------+
                     |                 |                 |
                     +-----------------+-----------------+
                                       |
                                     Calico
                                       |
                    +------------------+------------------+
                    |                                     |
                    v                                     v
             +-------------+                       +-------------+
             | Application |                       |   OpenEBS   |
             | Workloads   |                       |   Storage   |
             +-------------+                       +------+------+
                                                         |
                                                         v
                                                  +-------------+
                                                  | Backup PVC  |
                                                  +------+------+
                                                         |
                                                         v
                                                  +-------------+
                                                  |   Snapshots |
                                                  |   Metadata  |
                                                  |   Checksums |
                                                  +------+------+
                                                         |
                                                         v
                                                     Retention
                                                         |
                                                         v
                                                      Restore
```

---

# 1107. Final Operational Model

The cluster operates according to the following model:

```text id="r8z2n5"
                   NORMAL OPERATION
                         |
             +-----------+-----------+
             |                       |
             v                       v
        Kubernetes                Monitoring
             |                       |
             v                       v
           etcd                  Prometheus
             |                       |
             v                       v
         Workloads                Grafana
             |
             v
          OpenEBS
             |
             v
        Persistent Data


                   BACKUP OPERATION
                         |
                         v
                    CronJob
                         |
                         v
                  Leader Detection
                         |
                         v
                   etcd Snapshot
                         |
                         v
                    Validation
                         |
                         v
                     Checksum
                         |
                         v
                      Metadata
                         |
                         v
                     Retention
                         |
                         v
                   OpenEBS PVC


                   RECOVERY OPERATION
                         |
                         v
                  Select Snapshot
                         |
                         v
                 Verify Checksum
                         |
                         v
                Validate Snapshot
                         |
                         v
                    Restore etcd
                         |
                         v
                Recover Kubernetes
                         |
                         v
                 Validate Workloads
                         |
                         v
                 Create New Backup
```

---

# 1108. Project Completion

Parts 01–21 now provide a complete documentation lifecycle:

```text id="4w1p5u"
Part 01  → Infrastructure
Part 02  → Node Preparation
Part 03  → HAProxy
Part 04  → First Control Plane
Part 05  → Additional Control Planes
Part 06  → Worker Nodes
Part 07  → Calico
Part 08  → Admin Client
Part 09  → OpenEBS
Part 10  → Persistent Storage
Part 11  → Monitoring
Part 12  → etcd Architecture
Part 13  → etcd Backup
Part 14  → Backup Storage
Part 15  → Backup CronJob
Part 16  → Backup Retention
Part 17  → Restore / Disaster Recovery
Part 18  → Troubleshooting
Part 19  → Security
Part 20  → Final Validation
Part 21  → Final Architecture
```

The documentation therefore covers the full lifecycle:

```text
Provision
   ↓
Configure
   ↓
Deploy
   ↓
Network
   ↓
Store
   ↓
Monitor
   ↓
Backup
   ↓
Retain
   ↓
Restore
   ↓
Troubleshoot
   ↓
Secure
   ↓
Validate
   ↓
Operate
```

---

# 1109. Final Project Statement

The **Local Cluster Deployment on Intranet** project implements a six-node Kubernetes cluster with three control-plane nodes and three worker nodes, an external HAProxy API load balancer, an external Admin Client, Calico networking, OpenEBS persistent storage, Prometheus/Grafana monitoring, and an automated leader-aware etcd backup and recovery workflow.

The architecture separates:

```text
Control Plane
Workload Nodes
API Load Balancing
Administration
Networking
Storage
Monitoring
Backup
Recovery
Security
```

This separation provides a clear operational model and establishes the foundation for maintaining the cluster as an internally managed Kubernetes platform.

---

# 1110. Root README Completion

The project documentation is maintained in a **single root `README.md`**.

No separate README is required for each part.

Final structure:

```text id="7s4m1k"
README.md
│
├── Project Overview
├── Architecture
├── Infrastructure
│
├── Part 01 — Infrastructure and Node Provisioning
├── Part 02 — Kubernetes Node Preparation
├── Part 03 — HAProxy Load Balancer Configuration
├── Part 04 — Kubernetes Control Plane Initialization
├── Part 05 — Add Additional Control-Plane Nodes
├── Part 06 — Add Worker Nodes
├── Part 07 — Install and Configure Calico CNI
├── Part 08 — External Admin Client Configuration
├── Part 09 — OpenEBS Installation and Storage Foundation
├── Part 10 — Persistent Storage Configuration
├── Part 11 — Monitoring
├── Part 12 — etcd Architecture
├── Part 13 — etcd Backup
├── Part 14 — Backup Storage
├── Part 15 — CronJob
├── Part 16 — Backup Retention and Lifecycle Management
├── Part 17 — etcd Restore and Disaster Recovery
├── Part 18 — Troubleshooting
├── Part 19 — Security
├── Part 20 — Final Validation
└── Part 21 — Final Architecture
```

---

# 1111. Final Architecture Acceptance Criteria

The architecture is complete when the following high-level conditions are satisfied:

```text id="b7v4x9"
[✓] 8-machine infrastructure defined
[✓] 3 control-plane nodes defined
[✓] 3 worker nodes defined
[✓] External HAProxy defined
[✓] External Admin Client defined
[✓] Kubernetes API endpoint defined
[✓] Three-member etcd architecture defined
[✓] etcd quorum model defined
[✓] Leader-aware backup defined
[✓] Calico networking defined
[✓] CoreDNS defined
[✓] OpenEBS storage defined
[✓] Persistent backup PVC defined
[✓] Prometheus/Grafana monitoring defined
[✓] Automated 24-hour backup defined
[✓] Snapshot validation defined
[✓] Checksum validation defined
[✓] Backup retention defined
[✓] Restore procedure defined
[✓] Troubleshooting procedures defined
[✓] Security controls defined
[✓] Final validation defined
[✓] Complete architecture documented
```

---

# 1112. End of Project Documentation

**Local Cluster Deployment on Intranet**

```text id="v6f1m2"
                  PROJECT COMPLETE

        Infrastructure → Kubernetes
                         ↓
                       Calico
                         ↓
                      OpenEBS
                         ↓
                     Monitoring
                         ↓
                        etcd
                         ↓
                       Backup
                         ↓
                     Retention
                         ↓
                       Restore
                         ↓
                    Troubleshooting
                         ↓
                      Security
                         ↓
                  Final Validation
                         ↓
                  Final Architecture
```
