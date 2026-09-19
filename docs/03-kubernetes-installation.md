# Part 03 — Kubernetes Installation

This document describes the installation and initial configuration of Kubernetes using `kubeadm`, `kubelet`, and `kubectl`.

The cluster uses:

* Kubernetes control-plane nodes: 3
* Worker nodes: 3
* Container runtime: containerd
* Cluster bootstrap tool: kubeadm
* API endpoint: HAProxy
* CNI: Calico

## 1. Kubernetes Components

The Kubernetes installation consists of three primary packages.

### kubeadm

`kubeadm` is used to bootstrap the Kubernetes cluster.

### kubelet

`kubelet` runs on every Kubernetes node and manages the containers and pods assigned to that node.

### kubectl

`kubectl` is the command-line client used to communicate with the Kubernetes API server.

The architecture is:

```text
kubectl
   |
   v
HAProxy :6443
   |
   +----------------+----------------+
   |                |                |
   v                v                v
Master 01        Master 02        Master 03
   |                |                |
 kubelet          kubelet          kubelet
```

## 2. Kubernetes Version

This project uses:

```text
Kubernetes v1.34.11
```

Check the installed package versions:

```bash
kubeadm version
kubelet --version
kubectl version --client
```

All Kubernetes nodes should use compatible Kubernetes package versions.

## 3. Configure the Kubernetes Package Repository

Install the packages required to configure the repository:

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

Create the keyring directory:

```bash
sudo mkdir -p -m 755 /etc/apt/keyrings
```

Download the Kubernetes repository signing key:

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

Set appropriate permissions:

```bash
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

Add the Kubernetes repository:

```bash
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Set permissions:

```bash
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
```

Update the package index:

```bash
sudo apt-get update
```

## 4. Install Kubernetes Packages

Install:

```bash
sudo apt-get install -y kubelet kubeadm kubectl
```

Prevent automatic upgrades:

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

Expected Kubernetes version:

```text
v1.34.x
```

The exact patch version depends on the repository state when the packages are installed.

## 5. Enable kubelet

Enable kubelet:

```bash
sudo systemctl enable kubelet
```

Start it:

```bash
sudo systemctl start kubelet
```

Check status:

```bash
sudo systemctl status kubelet
```

The kubelet may repeatedly restart before the node has been initialized with `kubeadm`. This is normal during the pre-initialization stage.

Check logs:

```bash
sudo journalctl -u kubelet -n 100 --no-pager
```

## 6. Verify containerd

Before initializing Kubernetes, verify that containerd is running:

```bash
sudo systemctl is-active containerd
```

Expected:

```text
active
```

Verify the CRI:

```bash
sudo crictl info
```

Verify the socket:

```bash
sudo ls -l /run/containerd/containerd.sock
```

## 7. Configure the Kubernetes API Endpoint

The cluster uses HAProxy as the stable Kubernetes API endpoint.

Example:

```text
k8s-api.example.local:6443
```

or:

```text
192.168.1.120:6443
```

The API endpoint must point to the HAProxy load balancer rather than directly to one control-plane node.

Architecture:

```text
                         Kubernetes API Endpoint
                                  |
                                  v
                           HAProxy :6443
                                  |
                +-----------------+-----------------+
                |                 |                 |
                v                 v                 v
           Master 01         Master 02         Master 03
             :6443             :6443             :6443
```

The API endpoint must remain stable if a control-plane node becomes unavailable.

## 8. Verify HAProxy Connectivity

From the first control-plane node:

```bash
nc -vz <HAProxy-IP> 6443
```

Example:

```bash
nc -vz 192.168.1.120 6443
```

If DNS is configured:

```bash
nc -vz k8s-api.example.local 6443
```

A successful connection should show:

```text
Connection to <address> 6443 port [tcp/*] succeeded!
```

If the connection fails, do not continue with `kubeadm init`.

Check HAProxy first.

## 9. Configure `/etc/hosts`

If internal DNS is not available, configure name resolution.

Example:

```text
192.168.1.120  k8s-api
192.168.1.101  master01
192.168.1.102  master02
192.168.1.103  master03
192.168.1.111  worker01
192.168.1.112  worker02
192.168.1.113  worker03
```

Test:

```bash
ping -c 3 master01
ping -c 3 master02
ping -c 3 master03
```

Test the API endpoint:

```bash
ping -c 3 k8s-api
```

## 10. Create kubeadm Configuration

Create a configuration directory:

```bash
sudo mkdir -p /etc/kubernetes
```

Create a kubeadm configuration file:

```bash
sudo nano /etc/kubernetes/kubeadm-config.yaml
```

Example:

```yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: <MASTER01-IP>
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///run/containerd/containerd.sock
  kubeletExtraArgs:
    node-ip: <MASTER01-IP>

---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
clusterName: local-kubernetes
kubernetesVersion: v1.34.11
controlPlaneEndpoint: "k8s-api:6443"
networking:
  serviceSubnet: "10.96.0.0/12"
  podSubnet: "192.168.0.0/16"
  dnsDomain: "cluster.local"
```

Replace:

```text
<MASTER01-IP>
```

with the actual IP address of Master 01.

Replace:

```text
k8s-api:6443
```

with the actual HAProxy endpoint.

## 11. Important Configuration Values

### controlPlaneEndpoint

```yaml
controlPlaneEndpoint: "k8s-api:6443"
```

This is the stable endpoint used by the cluster to access the Kubernetes API.

It should point to HAProxy.

### criSocket

```yaml
criSocket: unix:///run/containerd/containerd.sock
```

This tells kubeadm to use containerd as the container runtime.

### kubernetesVersion

```yaml
kubernetesVersion: v1.34.11
```

This ensures that kubeadm initializes the requested Kubernetes version.

### podSubnet

```yaml
podSubnet: "192.168.0.0/16"
```

The Pod CIDR must be compatible with the selected CNI.

For this project, Calico will be configured to use the same Pod network.

## 12. Validate kubeadm Configuration

Before initialization:

```bash
sudo kubeadm config validate --config /etc/kubernetes/kubeadm-config.yaml
```

If the command reports configuration errors, fix them before continuing.

## 13. Initialize the First Control Plane

Run this command only on Master 01:

```bash
sudo kubeadm init \
  --config /etc/kubernetes/kubeadm-config.yaml \
  --upload-certs
```

The initialization process creates:

* Kubernetes API server
* kube-controller-manager
* kube-scheduler
* etcd
* kubelet configuration
* admin kubeconfig
* control-plane certificates

## 14. Configure kubectl for the Administrator

After successful initialization:

```bash
mkdir -p $HOME/.kube
```

Copy the administrator configuration:

```bash
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
```

Change ownership:

```bash
sudo chown "$(id -u)":"$(id -g)" $HOME/.kube/config
```

Verify:

```bash
kubectl cluster-info
```

Check nodes:

```bash
kubectl get nodes
```

Initially, the first control-plane node may show:

```text
NotReady
```

This is expected until the CNI is installed.

## 15. Verify Control-Plane Pods

Run:

```bash
kubectl get pods -n kube-system
```

The following components should be present:

```text
etcd-master01
kube-apiserver-master01
kube-controller-manager-master01
kube-scheduler-master01
```

The exact pod names depend on the hostname.

## 16. Verify etcd

Check etcd:

```bash
kubectl get pods -n kube-system | grep etcd
```

Expected:

```text
etcd-master01
```

At this stage, only the first etcd member exists.

The remaining etcd members will be added when Master 02 and Master 03 join the control plane.

## 17. Generate the Worker Join Command

After initialization, kubeadm provides a worker join command.

Example:

```bash
kubeadm join k8s-api:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

Save this command securely.

If the join command is lost, generate a new one:

```bash
kubeadm token create --print-join-command
```

## 18. Generate the Control-Plane Join Command

Because this is a multi-control-plane cluster, the additional control-plane nodes require a control-plane join command.

Generate a new certificate key if required:

```bash
sudo kubeadm init phase upload-certs --upload-certs
```

The command returns a certificate key.

Then generate the join command:

```bash
kubeadm token create --print-join-command
```

The resulting command can be extended with:

```text
--control-plane
--certificate-key <certificate-key>
```

Example:

```bash
sudo kubeadm join k8s-api:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <certificate-key>
```

Do not reuse an expired token.

## 19. Join Master 02

On Master 02:

```bash
sudo kubeadm join k8s-api:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <certificate-key>
```

After successful joining:

```bash
kubectl get nodes
```

Expected:

```text
master01
master02
```

Check etcd:

```bash
kubectl get pods -n kube-system | grep etcd
```

Expected:

```text
etcd-master01
etcd-master02
```

## 20. Join Master 03

On Master 03:

```bash
sudo kubeadm join k8s-api:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <certificate-key>
```

Verify:

```bash
kubectl get nodes
```

Expected:

```text
master01
master02
master03
```

Verify etcd:

```bash
kubectl get pods -n kube-system | grep etcd
```

Expected:

```text
etcd-master01
etcd-master02
etcd-master03
```

## 21. Verify Control-Plane Components

Run:

```bash
kubectl get pods -n kube-system -o wide
```

Verify:

```text
kube-apiserver
kube-controller-manager
kube-scheduler
etcd
```

are running on all three control-plane nodes.

## 22. Verify Node Roles

Run:

```bash
kubectl get nodes -o wide
```

Expected structure:

```text
NAME       STATUS     ROLES           AGE
master01   NotReady   control-plane   ...
master02   NotReady   control-plane   ...
master03   NotReady   control-plane   ...
```

The nodes may remain `NotReady` until Calico is installed.

## 23. Verify Kubernetes API Through HAProxy

Verify the API server endpoint:

```bash
kubectl cluster-info
```

Check the Kubernetes service:

```bash
kubectl get svc kubernetes
```

Check the endpoint:

```bash
kubectl get endpoints kubernetes
```

The control-plane API servers should be reachable through the configured HAProxy endpoint.

## 24. Verify kubelet

On each node:

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

## 25. Verify Certificates

Kubeadm manages Kubernetes certificates under:

```text
/etc/kubernetes/pki/
```

Check:

```bash
sudo ls -l /etc/kubernetes/pki/
```

Important certificates include:

```text
ca.crt
ca.key
apiserver.crt
apiserver.key
front-proxy-ca.crt
front-proxy-client.crt
```

The etcd certificates are located under:

```text
/etc/kubernetes/pki/etcd/
```

Check:

```bash
sudo ls -l /etc/kubernetes/pki/etcd/
```

## 26. Verify kubeconfig

Check the current context:

```bash
kubectl config current-context
```

List contexts:

```bash
kubectl config get-contexts
```

Verify the API server:

```bash
kubectl config view --minify
```

## 27. Common Problems

### kubeadm init fails

Check:

```bash
sudo journalctl -u kubelet -n 100 --no-pager
```

Check containerd:

```bash
sudo systemctl status containerd
```

Check CRI:

```bash
sudo crictl info
```

Check API endpoint:

```bash
nc -vz k8s-api 6443
```

### API endpoint connection refused

Check HAProxy:

```bash
sudo systemctl status haproxy
```

Check HAProxy logs:

```bash
sudo journalctl -u haproxy -n 100 --no-pager
```

Check the control-plane API server:

```bash
sudo crictl ps | grep kube-apiserver
```

Check port 6443:

```bash
sudo ss -lntp | grep 6443
```

### Node remains NotReady

At this stage, the most common reason is that the CNI has not yet been installed.

Check:

```bash
kubectl get pods -n kube-system
```

After the control plane is validated, continue with the Calico installation.

## 28. Resetting a Failed Initialization

If `kubeadm init` must be completely restarted on a node:

```bash
sudo kubeadm reset -f
```

Remove the kubeconfig:

```bash
rm -rf $HOME/.kube
```

Restart kubelet:

```bash
sudo systemctl restart kubelet
```

Restart containerd:

```bash
sudo systemctl restart containerd
```

> Do not run `kubeadm reset` on an existing production control-plane node without understanding the impact. It removes local Kubernetes configuration and can affect the cluster.

## 29. Validation Checklist

Before continuing to the networking stage:

* [ ] kubeadm installed.
* [ ] kubelet installed.
* [ ] kubectl installed.
* [ ] Kubernetes version is compatible across nodes.
* [ ] containerd is running.
* [ ] CRI is working.
* [ ] HAProxy API endpoint is reachable.
* [ ] Master 01 initialized successfully.
* [ ] Master 02 joined successfully.
* [ ] Master 03 joined successfully.
* [ ] Three etcd members are running.
* [ ] Three control-plane nodes are visible.
* [ ] Kubernetes API is accessible.
* [ ] kubeconfig is configured.
* [ ] Control-plane components are running.

At this point, the control plane is established but the cluster still requires a CNI.

Continue with:

`docs/04-ha-control-plane.md`

After the HA control-plane configuration is documented, the next implementation component will be:

`docs/05-calico.md`
