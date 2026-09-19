# Part 06 — Worker Nodes

This document describes how to prepare, join, configure, and validate the three Kubernetes worker nodes.

The cluster contains:

```text
Control Plane
├── Master 01
├── Master 02
└── Master 03

Worker Nodes
├── Worker 01
├── Worker 02
└── Worker 03
```

## 1. Worker Node Architecture

Worker nodes execute application workloads.

```text
                         HAProxy
                            |
                            v
                     Control Plane
                            |
             +--------------+--------------+
             |              |              |
             v              v              v
          Worker 01      Worker 02      Worker 03
             |              |              |
             v              v              v
           Pods            Pods            Pods
```

A worker node normally runs:

* kubelet
* containerd
* kube-proxy
* Calico
* application Pods

## 2. Worker Node Requirements

Each worker node must have:

* Supported Ubuntu installation
* Unique hostname
* Stable IP address
* Network connectivity to the control plane
* containerd
* kubeadm
* kubelet
* Required kernel modules
* Swap disabled
* Required firewall ports
* Access to the Kubernetes API endpoint

Example:

| Node     | IP              | Role   |
| -------- | --------------- | ------ |
| worker01 | `<WORKER01-IP>` | Worker |
| worker02 | `<WORKER02-IP>` | Worker |
| worker03 | `<WORKER03-IP>` | Worker |

## 3. Set Worker Hostnames

On Worker 01:

```bash
sudo hostnamectl set-hostname worker01
```

On Worker 02:

```bash
sudo hostnamectl set-hostname worker02
```

On Worker 03:

```bash
sudo hostnamectl set-hostname worker03
```

Verify:

```bash
hostname
```

## 4. Configure Host Resolution

If internal DNS is not available, configure `/etc/hosts`.

Example:

```text
<HAProxy-IP>  k8s-api

<MASTER01-IP> master01
<MASTER02-IP> master02
<MASTER03-IP> master03

<WORKER01-IP> worker01
<WORKER02-IP> worker02
<WORKER03-IP> worker03
```

Apply the same mapping to all Kubernetes nodes.

Verify:

```bash
getent hosts k8s-api
getent hosts master01
getent hosts master02
getent hosts master03
```

## 5. Disable Swap

Check:

```bash
free -h
```

Check active swap:

```bash
swapon --show
```

Disable:

```bash
sudo swapoff -a
```

Disable it permanently by editing:

```bash
sudo nano /etc/fstab
```

Comment out the swap entry.

Verify:

```bash
free -h
```

Swap should be zero.

## 6. Configure Kernel Modules

Load:

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

Persist:

```bash
sudo tee /etc/modules-load.d/kubernetes.conf <<EOF
overlay
br_netfilter
EOF
```

Verify:

```bash
lsmod | grep overlay
lsmod | grep br_netfilter
```

## 7. Configure Kernel Parameters

Create:

```bash
sudo tee /etc/sysctl.d/99-kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
```

Apply:

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

## 8. Verify Network Connectivity

Test the HAProxy API endpoint:

```bash
nc -vz <HAProxy-IP> 6443
```

Example:

```bash
nc -vz k8s-api 6443
```

The connection must succeed before joining the worker.

Test the control-plane nodes:

```bash
nc -vz <MASTER01-IP> 6443
nc -vz <MASTER02-IP> 6443
nc -vz <MASTER03-IP> 6443
```

## 9. Install containerd

Update packages:

```bash
sudo apt update
```

Install containerd:

```bash
sudo apt install -y containerd
```

Create configuration:

```bash
sudo mkdir -p /etc/containerd
```

Generate the default configuration:

```bash
containerd config default | sudo tee /etc/containerd/config.toml
```

## 10. Configure SystemdCgroup

Edit:

```bash
sudo nano /etc/containerd/config.toml
```

Set:

```text
SystemdCgroup = true
```

The relevant section should look similar to:

```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
```

Verify:

```bash
sudo grep -n "SystemdCgroup" /etc/containerd/config.toml
```

## 11. Start containerd

Restart:

```bash
sudo systemctl restart containerd
```

Enable:

```bash
sudo systemctl enable containerd
```

Verify:

```bash
sudo systemctl status containerd
```

Expected:

```text
active (running)
```

## 12. Verify CRI

Install or configure `crictl` if required.

Create:

```bash
sudo tee /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
```

Verify:

```bash
sudo crictl info
```

The command should return container runtime information.

## 13. Install Kubernetes Packages

Configure the Kubernetes package repository as described in:

`docs/03-kubernetes-installation.md`

Then install:

```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
```

Hold the packages:

```bash
sudo apt-mark hold kubelet kubeadm kubectl
```

Verify:

```bash
kubeadm version
```

```bash
kubelet --version
```

```bash
kubectl version --client
```

## 14. Enable kubelet

Enable:

```bash
sudo systemctl enable kubelet
```

Start:

```bash
sudo systemctl start kubelet
```

Check:

```bash
sudo systemctl status kubelet
```

Before the node joins the cluster, kubelet may restart repeatedly. This is expected.

## 15. Generate Worker Join Command

On a control-plane node, generate a new join command:

```bash
kubeadm token create --print-join-command
```

Example:

```text
kubeadm join k8s-api:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

The actual token and hash will be generated by your cluster.

Do not copy the example values literally.

## 16. Join Worker 01

On Worker 01, run the generated command:

```bash
sudo kubeadm join k8s-api:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

A successful join should report that the node has joined the cluster.

## 17. Join Worker 02

On Worker 02:

```bash
sudo kubeadm join k8s-api:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

## 18. Join Worker 03

On Worker 03:

```bash
sudo kubeadm join k8s-api:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

## 19. Verify Worker Nodes

From a control-plane node:

```bash
kubectl get nodes
```

Expected:

```text
NAME       STATUS   ROLES           AGE
master01   Ready    control-plane   ...
master02   Ready    control-plane   ...
master03   Ready    control-plane   ...
worker01   Ready    <none>          ...
worker02   Ready    <none>          ...
worker03   Ready    <none>          ...
```

The worker nodes may briefly appear as `NotReady` while Calico initializes.

## 20. Verify Node Details

Run:

```bash
kubectl get nodes -o wide
```

This displays:

* Internal IP
* Kubernetes version
* OS
* Kernel version
* Container runtime

Example:

```text
NAME       STATUS   ROLES           INTERNAL-IP
master01   Ready    control-plane   <MASTER01-IP>
master02   Ready    control-plane   <MASTER02-IP>
master03   Ready    control-plane   <MASTER03-IP>
worker01   Ready    <none>          <WORKER01-IP>
worker02   Ready    <none>          <WORKER02-IP>
worker03   Ready    <none>          <WORKER03-IP>
```

## 21. Verify Worker kubelet

On each worker:

```bash
sudo systemctl status kubelet
```

Check whether it is enabled:

```bash
systemctl is-enabled kubelet
```

Expected:

```text
enabled
```

Check logs:

```bash
sudo journalctl -u kubelet -n 100 --no-pager
```

Follow logs:

```bash
sudo journalctl -u kubelet -f
```

## 22. Verify containerd on Workers

Run on every worker:

```bash
sudo systemctl status containerd
```

Check:

```bash
sudo crictl info
```

Check running containers:

```bash
sudo crictl ps
```

After workloads are scheduled, Kubernetes containers should appear here.

## 23. Verify Calico on Workers

Calico runs on worker nodes as a DaemonSet.

Check:

```bash
kubectl get pods -A -o wide | grep calico
```

Each worker should have an appropriate Calico node pod.

Example:

```text
calico-node-xxxxx    1/1   Running   ...   worker01
calico-node-yyyyy    1/1   Running   ...   worker02
calico-node-zzzzz    1/1   Running   ...   worker03
```

## 24. Verify kube-proxy

Check:

```bash
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide
```

There should be one kube-proxy Pod on each Kubernetes node.

## 25. Verify Node Conditions

Inspect Worker 01:

```bash
kubectl describe node worker01
```

Look at:

```text
Conditions:
```

Important conditions include:

```text
Ready
MemoryPressure
DiskPressure
PIDPressure
NetworkUnavailable
```

A healthy worker should have:

```text
Ready              True
MemoryPressure     False
DiskPressure       False
PIDPressure        False
```

## 26. Verify Allocatable Resources

Run:

```bash
kubectl describe node worker01
```

Look for:

```text
Capacity:
Allocatable:
```

Or use:

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory
```

This verifies that Kubernetes can see the worker's resources.

## 27. Test Workload Scheduling

Create a test deployment:

```bash
kubectl create deployment nginx \
  --image=nginx:stable
```

Check:

```bash
kubectl get deployment nginx
```

Check the Pod:

```bash
kubectl get pods -o wide
```

The Pod should be scheduled onto a worker node.

Example:

```text
NAME                     READY   STATUS    NODE
nginx-xxxxxxxxxx         1/1     Running   worker01
```

## 28. Scale the Test Workload

Scale to six replicas:

```bash
kubectl scale deployment nginx --replicas=6
```

Check:

```bash
kubectl get pods -o wide
```

Kubernetes should distribute Pods according to its scheduling decisions and available resources.

Example:

```text
nginx-xxxxx   1/1   Running   worker01
nginx-yyyyy   1/1   Running   worker01
nginx-zzzzz   1/1   Running   worker02
nginx-aaaaa   1/1   Running   worker02
nginx-bbbbb   1/1   Running   worker03
nginx-ccccc   1/1   Running   worker03
```

Exact placement is controlled by the Kubernetes scheduler and is not guaranteed to match this example.

## 29. Add Worker Labels

Labels can be used to identify node roles or hardware.

Example:

```bash
kubectl label node worker01 node-role.kubernetes.io/worker=""
```

```bash
kubectl label node worker02 node-role.kubernetes.io/worker=""
```

```bash
kubectl label node worker03 node-role.kubernetes.io/worker=""
```

Verify:

```bash
kubectl get nodes --show-labels
```

## 30. Add Application-Specific Labels

For example:

```bash
kubectl label node worker01 workload=application
```

```bash
kubectl label node worker02 workload=application
```

```bash
kubectl label node worker03 workload=application
```

Verify:

```bash
kubectl get nodes -L workload
```

These labels can later be used with:

* nodeSelector
* nodeAffinity
* podAffinity
* topology constraints

## 31. Worker Node Taints

By default, worker nodes do not have the control-plane taint.

Check:

```bash
kubectl describe node worker01 | grep -i taint
```

For standard application workers, no control-plane taint should be present.

Do not remove control-plane taints from masters unless there is a deliberate scheduling requirement.

## 32. Test Node Failure Handling

A controlled failure test can be used to verify workload rescheduling.

First check:

```bash
kubectl get pods -o wide
```

Identify a worker hosting test workloads.

In a lab environment, temporarily stop kubelet:

```bash
sudo systemctl stop kubelet
```

Monitor:

```bash
kubectl get nodes -w
```

The node may eventually become:

```text
NotReady
```

Kubernetes can reschedule eligible workloads depending on their controller, readiness, termination behavior, and configured tolerations.

Restart kubelet:

```bash
sudo systemctl start kubelet
```

Verify:

```bash
kubectl get nodes
```

> Perform failure testing only in a controlled environment.

## 33. Worker Node Troubleshooting

### Worker cannot join

Test API connectivity:

```bash
nc -vz k8s-api 6443
```

Check kubelet:

```bash
sudo systemctl status kubelet
```

Check containerd:

```bash
sudo systemctl status containerd
```

Check logs:

```bash
sudo journalctl -u kubelet -n 100 --no-pager
```

### Token expired

Generate a new token on a control-plane node:

```bash
kubeadm token create --print-join-command
```

Then run the new command on the worker.

### Worker is NotReady

Check:

```bash
kubectl describe node worker01
```

Check Calico:

```bash
kubectl get pods -A -o wide | grep worker01
```

Check kubelet:

```bash
sudo journalctl -u kubelet -n 100 --no-pager
```

Check containerd:

```bash
sudo crictl info
```

### NetworkUnavailable

Check Calico:

```bash
kubectl get pods -A | grep -i calico
```

Check node:

```bash
kubectl describe node worker01
```

Check interfaces:

```bash
ip link
```

Check routes:

```bash
ip route
```

## 34. Reset a Worker Node

If a worker must be removed from the cluster:

On the control plane:

```bash
kubectl drain worker01 \
  --ignore-daemonsets \
  --delete-emptydir-data
```

Then:

```bash
kubectl delete node worker01
```

On the worker:

```bash
sudo kubeadm reset -f
```

Restart the runtime:

```bash
sudo systemctl restart containerd
```

Restart kubelet:

```bash
sudo systemctl restart kubelet
```

The worker can then be joined again using a new join command.

## 35. Remove Test Workload

Delete nginx:

```bash
kubectl delete deployment nginx
```

Verify:

```bash
kubectl get pods
```

## 36. Final Cluster Validation

Check all nodes:

```bash
kubectl get nodes -o wide
```

Check all Pods:

```bash
kubectl get pods -A -o wide
```

Check system components:

```bash
kubectl get pods -n kube-system
```

Check Calico:

```bash
kubectl get pods -A | grep -i calico
```

Check kube-proxy:

```bash
kubectl get pods -n kube-system -l k8s-app=kube-proxy
```

Check container runtime on a worker:

```bash
sudo crictl info
```

Check kubelet:

```bash
sudo systemctl is-active kubelet
```

## 37. Validation Checklist

* [ ] Worker 01 is prepared.
* [ ] Worker 02 is prepared.
* [ ] Worker 03 is prepared.
* [ ] Swap is disabled.
* [ ] containerd is running.
* [ ] CRI is working.
* [ ] kubeadm is installed.
* [ ] kubelet is installed.
* [ ] Kubernetes API endpoint is reachable.
* [ ] Worker 01 joined successfully.
* [ ] Worker 02 joined successfully.
* [ ] Worker 03 joined successfully.
* [ ] All workers are `Ready`.
* [ ] Calico is running on workers.
* [ ] kube-proxy is running.
* [ ] Pods can be scheduled on workers.
* [ ] Test workloads can communicate over the cluster network.

## 38. Result

The cluster now has three control-plane nodes and three worker nodes:

```text
                         HAProxy
                            |
                            v
                  ┌───────────────────┐
                  │   Control Plane   │
                  │                   │
                  │ Master 01 + etcd  │
                  │ Master 02 + etcd  │
                  │ Master 03 + etcd  │
                  └─────────┬─────────┘
                            |
             ┌──────────────┼──────────────┐
             |              |              |
             v              v              v
        Worker 01      Worker 02      Worker 03
             |              |              |
             v              v              v
           Pods            Pods            Pods
```

The basic Kubernetes cluster is now established.

The next stage is persistent storage using OpenEBS.

Continue with:

`docs/07-openebs.md`
