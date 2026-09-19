# Part 02 — containerd Installation and Configuration

This document describes the installation and configuration of `containerd` as the container runtime for the Kubernetes cluster.

The configuration is applied to:

* Master 01
* Master 02
* Master 03
* Worker 01
* Worker 02
* Worker 03

## 1. Why containerd

Kubernetes requires a Container Runtime Interface (CRI) compatible runtime to run containers.

This project uses:

```text
containerd
```

The runtime architecture is:

```text
Kubernetes
    |
    v
  kubelet
    |
    v
   CRI
    |
    v
 containerd
    |
    v
  runc
    |
    v
Containers
```

## 2. Remove Conflicting Packages

If Docker or an incompatible container runtime is already installed, remove packages that could conflict with the Kubernetes container runtime.

Check installed packages:

```bash
dpkg -l | grep -E 'docker|containerd|runc'
```

If an old containerd installation exists:

```bash
sudo apt remove -y containerd containerd.io
```

Clean unused packages:

```bash
sudo apt autoremove -y
```

> Do not remove an existing working container runtime from a production system without verifying its dependencies first.

## 3. Update the System

Update the package index:

```bash
sudo apt update
```

Upgrade installed packages:

```bash
sudo apt upgrade -y
```

Install required packages:

```bash
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    apt-transport-https
```

## 4. Install containerd

Install the Ubuntu containerd package:

```bash
sudo apt install -y containerd
```

Verify the installation:

```bash
containerd --version
```

Example:

```text
containerd containerd.io 2.x
```

The exact version may vary depending on the Ubuntu repository and installation date.

## 5. Generate containerd Configuration

Create the configuration directory:

```bash
sudo mkdir -p /etc/containerd
```

Generate the default configuration:

```bash
containerd config default | sudo tee /etc/containerd/config.toml
```

Verify the file:

```bash
sudo ls -l /etc/containerd/config.toml
```

## 6. Configure systemd cgroups

Kubernetes should use the same cgroup driver consistently between kubelet and the container runtime.

For this project, configure containerd to use:

```text
SystemdCgroup = true
```

Open the configuration:

```bash
sudo nano /etc/containerd/config.toml
```

Find:

```text
SystemdCgroup = false
```

Change it to:

```text
SystemdCgroup = true
```

Depending on the containerd version, the setting is located under the CRI runtime configuration.

For example:

```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
```

## 7. Verify the CRI Configuration

Search for the setting:

```bash
sudo grep -n "SystemdCgroup" /etc/containerd/config.toml
```

Expected:

```text
SystemdCgroup = true
```

Verify the CRI plugin:

```bash
sudo ctr plugins ls | grep cri
```

The CRI plugin should be available.

## 8. Restart containerd

Restart the service:

```bash
sudo systemctl restart containerd
```

Enable containerd at boot:

```bash
sudo systemctl enable containerd
```

Check the service:

```bash
sudo systemctl status containerd
```

Expected state:

```text
active (running)
```

## 9. Verify containerd

Check the version:

```bash
containerd --version
```

Check the service:

```bash
systemctl is-active containerd
```

Expected:

```text
active
```

Check whether it starts automatically:

```bash
systemctl is-enabled containerd
```

Expected:

```text
enabled
```

## 10. Verify containerd Socket

The Kubernetes CRI socket should be available at:

```text
/run/containerd/containerd.sock
```

Check:

```bash
sudo ls -l /run/containerd/containerd.sock
```

The socket is used by kubelet through the CRI.

## 11. Verify CRI with crictl

`crictl` can be used to inspect containers and pods through the CRI.

If `crictl` is installed, configure it:

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

Check running containers:

```bash
sudo crictl ps
```

Check all containers:

```bash
sudo crictl ps -a
```

Check images:

```bash
sudo crictl images
```

## 12. Verify containerd with ctr

List namespaces:

```bash
sudo ctr namespaces list
```

Kubernetes normally uses the:

```text
k8s.io
```

namespace after Kubernetes workloads are running.

Before Kubernetes is initialized, this namespace may not exist yet.

## 13. Configure Kernel Modules

Ensure the required modules are loaded:

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

Persist them:

```bash
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
```

## 14. Configure Networking Parameters

Configure the required kernel parameters:

```bash
sudo tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
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

## 15. Restart containerd After Kernel Configuration

Restart containerd:

```bash
sudo systemctl restart containerd
```

Verify:

```bash
sudo systemctl status containerd --no-pager
```

## 16. Containerd Configuration Validation

Run the following checks:

```bash
containerd --version
```

```bash
sudo systemctl is-active containerd
```

```bash
sudo systemctl is-enabled containerd
```

```bash
sudo grep -n "SystemdCgroup" /etc/containerd/config.toml
```

```bash
sudo crictl info
```

```bash
sudo crictl images
```

## 17. Troubleshooting

### containerd is not running

Check the service:

```bash
sudo systemctl status containerd
```

Check the logs:

```bash
sudo journalctl -u containerd -n 100 --no-pager
```

Follow logs:

```bash
sudo journalctl -u containerd -f
```

### CRI is unavailable

Check plugins:

```bash
sudo ctr plugins ls
```

Look for:

```text
io.containerd.grpc.v1.cri
```

Check containerd configuration:

```bash
sudo grep -n "cri" /etc/containerd/config.toml
```

Restart:

```bash
sudo systemctl restart containerd
```

### crictl cannot connect

Check the socket:

```bash
sudo ls -l /run/containerd/containerd.sock
```

Check `/etc/crictl.yaml`:

```bash
sudo cat /etc/crictl.yaml
```

The endpoint should be:

```text
unix:///run/containerd/containerd.sock
```

### SystemdCgroup is incorrect

Check:

```bash
sudo grep -n "SystemdCgroup" /etc/containerd/config.toml
```

It should be:

```text
SystemdCgroup = true
```

Restart:

```bash
sudo systemctl restart containerd
```

## 18. Apply to All Nodes

The same containerd configuration must be applied to:

```text
Master 01
Master 02
Master 03

Worker 01
Worker 02
Worker 03
```

Each node should independently pass:

```bash
sudo systemctl is-active containerd
```

and:

```bash
sudo crictl info
```

## 19. Final Validation Checklist

Before continuing to Kubernetes installation:

* [ ] containerd is installed.
* [ ] containerd starts successfully.
* [ ] containerd is enabled at boot.
* [ ] `/etc/containerd/config.toml` exists.
* [ ] `SystemdCgroup = true` is configured.
* [ ] CRI plugin is available.
* [ ] containerd socket exists.
* [ ] `crictl info` works.
* [ ] `overlay` module is loaded.
* [ ] `br_netfilter` module is loaded.
* [ ] IPv4 forwarding is enabled.
* [ ] Configuration is applied to every Kubernetes node.

Once containerd is working on all nodes, continue with:

`docs/03-kubernetes-installation.md`
