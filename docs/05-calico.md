# Part 05 — Calico CNI

This document describes the installation and validation of Calico as the Container Network Interface (CNI) for the Kubernetes cluster.

Calico provides:

* Pod-to-pod networking
* Node-to-node networking
* Network policy
* Pod IP allocation
* Kubernetes network connectivity

## 1. Network Architecture

After Kubernetes control-plane initialization, the nodes may initially show `NotReady`.

The primary reason is that no CNI has been installed yet.

The network architecture is:

```text
                    Kubernetes Cluster
                           |
                    ┌──────┴──────┐
                    │    Calico   │
                    │     CNI     │
                    └──────┬──────┘
                           |
          +----------------+----------------+
          |                |                |
          v                v                v
      Master 01        Master 02        Master 03
          |                |                |
          +----------------+----------------+
                           |
          +----------------+----------------+
          |                |                |
          v                v                v
      Worker 01        Worker 02        Worker 03
          |                |                |
       Pods              Pods              Pods
```

## 2. Pod Network CIDR

The cluster was configured with:

```text
192.168.0.0/16
```

This must match the Calico configuration.

Check the Kubernetes configuration:

```bash
kubectl cluster-info dump | grep -m 1 cluster-cidr
```

You can also inspect the kubeadm configuration:

```bash
sudo cat /etc/kubernetes/kubeadm-config.yaml
```

The configuration should contain:

```yaml
networking:
  podSubnet: "192.168.0.0/16"
```

## 3. Verify Nodes Before Calico

Run:

```bash
kubectl get nodes -o wide
```

Before the CNI is installed, nodes may appear as:

```text
NAME       STATUS     ROLES           AGE
master01   NotReady   control-plane   ...
master02   NotReady   control-plane   ...
master03   NotReady   control-plane   ...
```

This is expected.

Check system pods:

```bash
kubectl get pods -n kube-system
```

The CoreDNS pods may also be pending because the cluster network is not available.

## 4. Install Calico

Calico can be installed using the official manifest.

Download the manifest:

```bash
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.31.0/manifests/calico.yaml
```

Before applying it, verify the configured Pod CIDR.

Search for the Calico IP pool configuration:

```bash
grep -n "CALICO_IPV4POOL_CIDR" calico.yaml
```

The value should correspond to:

```text
192.168.0.0/16
```

If the manifest uses a different CIDR, update it before deployment.

Example:

```yaml
- name: CALICO_IPV4POOL_CIDR
  value: "192.168.0.0/16"
```

Apply Calico:

```bash
kubectl apply -f calico.yaml
```

## 5. Verify Calico Namespace

Check the namespace:

```bash
kubectl get namespace
```

Calico components are normally deployed in:

```text
calico-system
```

Depending on the installation method and Calico version, additional Calico resources may exist in other namespaces.

Check:

```bash
kubectl get pods -A | grep -i calico
```

## 6. Verify Calico Pods

Run:

```bash
kubectl get pods -A -o wide | grep -i calico
```

Typical components include:

```text
calico-node
calico-kube-controllers
```

The exact components depend on the Calico version and installation method.

Check the DaemonSet:

```bash
kubectl get daemonset -A | grep -i calico
```

## 7. Verify Calico Nodes

Run:

```bash
kubectl get nodes -o wide
```

The nodes should transition to:

```text
NAME       STATUS   ROLES           AGE
master01   Ready    control-plane   ...
master02   Ready    control-plane   ...
master03   Ready    control-plane   ...
```

Worker nodes will become `Ready` after they are joined and Calico is running on them.

## 8. Check Calico Node Status

For installations using the Calico node DaemonSet:

```bash
kubectl get pods -A -l k8s-app=calico-node -o wide
```

Check all pods:

```bash
kubectl get pods -A -o wide | grep calico-node
```

All expected Calico node pods should be:

```text
Running
```

## 9. Inspect Calico Logs

Get the Calico pods:

```bash
kubectl get pods -A | grep calico-node
```

Inspect logs:

```bash
kubectl logs -n calico-system <calico-node-pod>
```

If the Calico installation uses the `kube-system` namespace instead:

```bash
kubectl logs -n kube-system <calico-node-pod>
```

Follow logs:

```bash
kubectl logs -n calico-system <calico-node-pod> -f
```

## 10. Check Calico Configuration

Inspect the Calico ConfigMap:

```bash
kubectl get configmap -A | grep -i calico
```

For a known ConfigMap:

```bash
kubectl get configmap <configmap-name> -n <namespace> -o yaml
```

Inspect the Calico DaemonSet:

```bash
kubectl get daemonset -A | grep -i calico
```

Then:

```bash
kubectl describe daemonset <daemonset-name> -n <namespace>
```

## 11. Check Pod CIDRs

Verify node Pod CIDRs:

```bash
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.podCIDR}{"\n"}{end}'
```

Example:

```text
master01    192.168.x.0/24
master02    192.168.x.0/24
master03    192.168.x.0/24
worker01    192.168.x.0/24
worker02    192.168.x.0/24
worker03    192.168.x.0/24
```

The exact ranges are allocated by Kubernetes and the CNI configuration.

## 12. Verify CoreDNS

After Calico is working:

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

Expected:

```text
READY   STATUS
1/1     Running
```

Check all system pods:

```bash
kubectl get pods -n kube-system -o wide
```

CoreDNS should eventually become `Running`.

## 13. Verify Pod Networking

Create a temporary test pod:

```bash
kubectl run network-test \
  --image=busybox:1.36 \
  --restart=Never \
  --command -- sleep 3600
```

Check:

```bash
kubectl get pod network-test -o wide
```

The pod should receive a Pod IP.

Example:

```text
NAME           READY   STATUS    IP             NODE
network-test   1/1     Running   192.168.x.x    worker01
```

## 14. Test DNS

Execute a DNS lookup from the test pod:

```bash
kubectl exec network-test -- nslookup kubernetes.default
```

If `nslookup` is not available in the selected image, use a suitable DNS testing image.

Successful DNS resolution indicates that:

```text
Pod
 |
 v
Calico
 |
 v
Kubernetes Service
 |
 v
CoreDNS
```

is functioning.

## 15. Test Service Connectivity

Create an nginx deployment:

```bash
kubectl create deployment nginx \
  --image=nginx:stable
```

Expose it:

```bash
kubectl expose deployment nginx \
  --port=80 \
  --target-port=80
```

Check:

```bash
kubectl get deployment nginx
```

```bash
kubectl get pods -o wide
```

```bash
kubectl get service nginx
```

## 16. Test Service DNS

Run:

```bash
kubectl exec network-test -- nslookup nginx.default.svc.cluster.local
```

The service should resolve to its ClusterIP.

Check the ClusterIP:

```bash
kubectl get service nginx
```

## 17. Test Service Connectivity

Run:

```bash
kubectl exec network-test -- wget -qO- http://nginx
```

Expected output should contain the nginx welcome page.

This verifies:

```text
network-test Pod
      |
      v
Calico
      |
      v
Kubernetes Service
      |
      v
nginx Pod
```

## 18. Test Pod-to-Pod Connectivity

Get Pod IPs:

```bash
kubectl get pods -o wide
```

Create another test pod:

```bash
kubectl run network-test-2 \
  --image=busybox:1.36 \
  --restart=Never \
  --command -- sleep 3600
```

Check:

```bash
kubectl get pods -o wide
```

Test connectivity:

```bash
kubectl exec network-test-2 -- ping -c 3 <POD-IP>
```

If ICMP is not supported or is restricted, test using the application's TCP port instead.

## 19. Test Cross-Node Networking

First identify the node where each test pod is running:

```bash
kubectl get pods -o wide
```

Create additional test pods if required:

```bash
kubectl run network-test-3 \
  --image=busybox:1.36 \
  --restart=Never \
  --command -- sleep 3600
```

Check:

```bash
kubectl get pods -o wide
```

Ensure the test pods are distributed across different nodes.

Then test communication between their Pod IPs.

This validates:

```text
Worker 01
   |
   v
Calico
   |
   +----------------------+
                          |
                          v
                       Worker 02
                          |
                          v
                         Pod
```

## 20. Check Calico Interfaces

On a Kubernetes node:

```bash
ip link
```

Depending on the Calico configuration, interfaces associated with Calico networking may include:

```text
cali*
tunl0
```

The exact interface configuration depends on the selected Calico dataplane and version.

Check routes:

```bash
ip route
```

Look for Pod network routes.

## 21. Check BGP Status

If Calico is configured to use BGP, inspect the node configuration.

For modern Calico installations, use the Calico tooling appropriate to the deployed version rather than assuming a specific command-line flag.

If `calicoctl` is installed:

```bash
calicoctl node status
```

For installations without `calicoctl`, inspect the Calico resources and node logs:

```bash
kubectl get nodes.crd.projectcalico.org -o wide
```

and:

```bash
kubectl get bgppeers.crd.projectcalico.org
```

Only use BGP-specific checks when the selected Calico deployment actually uses BGP.

## 22. Network Policies

Calico supports Kubernetes NetworkPolicy resources.

Example:

```yaml id="r7mlh1"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

Apply:

```bash
kubectl apply -f network-policy.yaml
```

Check:

```bash
kubectl get networkpolicy
```

Network policies should be introduced deliberately because an overly restrictive policy can block required cluster or application traffic.

## 23. Calico Troubleshooting

### Calico pods are not running

Check:

```bash
kubectl get pods -A | grep -i calico
```

Describe the pod:

```bash
kubectl describe pod <calico-pod> -n <namespace>
```

Check logs:

```bash
kubectl logs <calico-pod> -n <namespace>
```

### Nodes remain NotReady

Check:

```bash
kubectl get nodes
```

Then:

```bash
kubectl describe node <node-name>
```

Look for:

```text
NetworkPluginNotReady
```

Check Calico:

```bash
kubectl get pods -A | grep -i calico
```

### CoreDNS remains Pending

Check:

```bash
kubectl get pods -n kube-system
```

Describe CoreDNS:

```bash
kubectl describe pod <coredns-pod> -n kube-system
```

Check Calico first because CoreDNS depends on functional cluster networking.

### Pods cannot communicate

Check:

```bash
kubectl get pods -o wide
```

Check routes:

```bash
ip route
```

Check Calico pods:

```bash
kubectl get pods -A | grep -i calico
```

Check Calico logs:

```bash
kubectl logs <calico-node-pod> -n <namespace>
```

### DNS does not work

Check CoreDNS:

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

Check the DNS service:

```bash
kubectl get service kube-dns -n kube-system
```

Check DNS endpoints:

```bash
kubectl get endpoints kube-dns -n kube-system
```

Test:

```bash
kubectl exec network-test -- nslookup kubernetes.default
```

## 24. Remove Test Resources

Delete the test pods:

```bash
kubectl delete pod network-test network-test-2 network-test-3 \
  --ignore-not-found
```

Delete nginx:

```bash
kubectl delete service nginx --ignore-not-found
kubectl delete deployment nginx --ignore-not-found
```

## 25. Validation

Run:

```bash
kubectl get nodes -o wide
```

All currently configured Kubernetes nodes should eventually show:

```text
Ready
```

Check system pods:

```bash
kubectl get pods -A -o wide
```

Check Calico:

```bash
kubectl get pods -A | grep -i calico
```

Check CoreDNS:

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

Test DNS:

```bash
kubectl run dns-test \
  --image=busybox:1.36 \
  --restart=Never \
  --rm -it \
  -- nslookup kubernetes.default
```

## 26. Validation Checklist

* [ ] Calico is installed.
* [ ] Calico node components are running.
* [ ] Calico controllers are running where applicable.
* [ ] All Kubernetes nodes become `Ready`.
* [ ] CoreDNS pods are `Running`.
* [ ] Pods receive Pod IP addresses.
* [ ] Kubernetes service DNS works.
* [ ] Pod-to-pod connectivity works.
* [ ] Cross-node Pod networking works.
* [ ] Service connectivity works.
* [ ] Calico logs show no persistent errors.
* [ ] Pod CIDR matches the cluster networking design.

## 27. Result

After this stage, the cluster has functional Kubernetes networking:

```text
                       Kubernetes Cluster
                              |
                           Calico
                              |
          +-------------------+-------------------+
          |                   |                   |
          v                   v                   v
      Master 01           Master 02           Master 03
          |                   |                   |
          +-------------------+-------------------+
                              |
          +-------------------+-------------------+
          |                   |                   |
          v                   v                   v
      Worker 01           Worker 02           Worker 03
          |                   |                   |
        Pods                Pods                Pods
```

The next stage is to join and validate the worker nodes.

Continue with:

`docs/06-worker-nodes.md`
