# Part 04 — High-Availability Control Plane

This document describes the high-availability architecture for the Kubernetes control plane.

The cluster uses:

* 1 HAProxy load balancer
* 3 control-plane nodes
* 3 etcd members
* Kubernetes API endpoint exposed through HAProxy
* Stacked etcd topology

## 1. Architecture

The control plane consists of three Kubernetes control-plane nodes.

Each control-plane node runs:

* kube-apiserver
* kube-controller-manager
* kube-scheduler
* kubelet
* containerd
* etcd

Architecture:

```text
                         Kubernetes Clients
                                |
                                |
                         k8s-api:6443
                                |
                                v
                     ┌────────────────────┐
                     │      HAProxy       │
                     │    Load Balancer   │
                     │       :6443        │
                     └─────────┬──────────┘
                               |
              ┌────────────────┼────────────────┐
              |                |                |
              v                v                v
       ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
       │  Master 01  │  │  Master 02  │  │  Master 03  │
       │             │  │             │  │             │
       │ API Server  │  │ API Server  │  │ API Server  │
       │ Controller  │  │ Controller  │  │ Controller  │
       │ Scheduler   │  │ Scheduler   │  │ Scheduler   │
       │ etcd-1      │  │ etcd-2      │  │ etcd-3      │
       └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
              |                 |                 |
              +-----------------+-----------------+
                         etcd Cluster
```

## 2. Why HAProxy Is Required

Clients should not depend directly on a single control-plane node.

Without a load balancer:

```text
Client
  |
  +----> Master 01
```

If Master 01 becomes unavailable, clients cannot reach the Kubernetes API through that endpoint.

With HAProxy:

```text
                  HAProxy
                     |
        +------------+------------+
        |            |            |
        v            v            v
    Master 01    Master 02    Master 03
```

If one API server becomes unavailable, HAProxy can direct traffic to another available API server.

## 3. HAProxy Node

The HAProxy machine is separate from the Kubernetes control-plane nodes.

Example:

```text
Hostname: haproxy
IP:       <HAPROXY-IP>
Port:     6443
```

Verify the hostname:

```bash
hostname
```

Verify the IP:

```bash
ip addr
```

## 4. Install HAProxy

On the HAProxy node:

```bash
sudo apt update
```

Install HAProxy:

```bash
sudo apt install -y haproxy
```

Check the version:

```bash
haproxy -v
```

Enable the service:

```bash
sudo systemctl enable haproxy
```

## 5. HAProxy Configuration

The configuration file is:

```text
/etc/haproxy/haproxy.cfg
```

Back up the original configuration:

```bash
sudo cp /etc/haproxy/haproxy.cfg \
        /etc/haproxy/haproxy.cfg.backup
```

Edit:

```bash
sudo nano /etc/haproxy/haproxy.cfg
```

Example configuration:

```text
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon
    maxconn 4096

defaults
    log global
    mode tcp
    option tcplog
    timeout connect 10s
    timeout client  1m
    timeout server  1m

frontend kubernetes-api
    bind *:6443
    mode tcp
    default_backend kubernetes-masters

backend kubernetes-masters
    mode tcp
    balance roundrobin

    option tcp-check

    server master01 <MASTER01-IP>:6443 check
    server master02 <MASTER02-IP>:6443 check
    server master03 <MASTER03-IP>:6443 check
```

Replace:

```text
<MASTER01-IP>
<MASTER02-IP>
<MASTER03-IP>
```

with the actual control-plane IP addresses.

## 6. Validate HAProxy Configuration

Before restarting HAProxy:

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Expected:

```text
Configuration file is valid
```

If validation fails, do not restart HAProxy until the configuration is corrected.

## 7. Start HAProxy

Restart:

```bash
sudo systemctl restart haproxy
```

Enable at boot:

```bash
sudo systemctl enable haproxy
```

Check:

```bash
sudo systemctl status haproxy
```

Expected:

```text
active (running)
```

## 8. Verify HAProxy Listener

Check port 6443:

```bash
sudo ss -lntp | grep 6443
```

Expected:

```text
LISTEN ... :6443
```

From another machine:

```bash
nc -vz <HAPROXY-IP> 6443
```

## 9. Verify HAProxy Backend Connectivity

From the HAProxy node:

```bash
nc -vz <MASTER01-IP> 6443
nc -vz <MASTER02-IP> 6443
nc -vz <MASTER03-IP> 6443
```

All three control-plane API servers should be reachable.

If a backend is unavailable, HAProxy should mark it as unavailable.

Check HAProxy logs:

```bash
sudo journalctl -u haproxy -n 100 --no-pager
```

## 10. Configure Kubernetes API Endpoint

The Kubernetes API endpoint should use the HAProxy address.

Example:

```text
k8s-api:6443
```

If DNS is unavailable, use an IP address:

```text
192.168.1.120:6443
```

The endpoint configured in kubeadm must remain stable.

Example:

```yaml
controlPlaneEndpoint: "k8s-api:6443"
```

## 11. Configure Host Resolution

If internal DNS is not available, add the API endpoint and node addresses to `/etc/hosts`.

Example:

```text
192.168.1.120 k8s-api

192.168.1.101 master01
192.168.1.102 master02
192.168.1.103 master03

192.168.1.111 worker01
192.168.1.112 worker02
192.168.1.113 worker03
```

Verify:

```bash
getent hosts k8s-api
```

Expected:

```text
192.168.1.120 k8s-api
```

## 12. Control-Plane Components

Each control-plane node runs the Kubernetes control-plane components.

Check:

```bash
kubectl get pods -n kube-system -o wide
```

Expected components include:

```text
kube-apiserver-master01
kube-controller-manager-master01
kube-scheduler-master01

kube-apiserver-master02
kube-controller-manager-master02
kube-scheduler-master02

kube-apiserver-master03
kube-controller-manager-master03
kube-scheduler-master03
```

The exact pod names depend on the node hostnames.

## 13. Verify Control-Plane Nodes

Run:

```bash
kubectl get nodes -o wide
```

Expected:

```text
NAME       STATUS     ROLES           AGE
master01   NotReady   control-plane   ...
master02   NotReady   control-plane   ...
master03   NotReady   control-plane   ...
```

`NotReady` may occur before Calico is installed.

After the CNI is installed, the nodes should transition to `Ready`.

## 14. Stacked etcd Architecture

This project uses stacked etcd.

That means each control-plane node hosts one etcd member.

```text
Master 01
   |
   +---- etcd member 1

Master 02
   |
   +---- etcd member 2

Master 03
   |
   +---- etcd member 3
```

The three members form one etcd cluster.

```text
             etcd Cluster
                  |
       +----------+----------+
       |          |          |
       v          v          v
    etcd-1     etcd-2     etcd-3
   Master01   Master02   Master03
```

## 15. etcd Ports

etcd uses:

```text
2379 - Client communication
2380 - Peer communication
```

Verify the listeners on each control-plane node:

```bash
sudo ss -lntp | grep -E '2379|2380'
```

Expected ports:

```text
:2379
:2380
```

## 16. Verify etcd Pods

Run:

```bash
kubectl get pods -n kube-system -o wide | grep etcd
```

Expected:

```text
etcd-master01
etcd-master02
etcd-master03
```

All members should eventually show:

```text
1/1 Running
```

## 17. Verify etcd Cluster Membership

Install `etcdctl` if required.

Set the API version:

```bash
export ETCDCTL_API=3
```

On a control-plane node, etcd certificates are normally located under:

```text
/etc/kubernetes/pki/etcd/
```

Example command:

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  endpoint status \
  --cluster
```

The command should return the members of the etcd cluster.

## 18. Verify etcd Health

Run:

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  endpoint health
```

Expected output should indicate that the endpoint is healthy.

If the certificate names differ in your Kubernetes installation, inspect:

```bash
sudo ls -l /etc/kubernetes/pki/etcd/
```

## 19. Check etcd Member List

Run:

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  member list
```

A three-member cluster should contain three etcd members.

## 20. Leader and Follower

etcd uses a leader-based consensus mechanism.

One member acts as the leader while the other members follow the leader.

```text
                 etcd Cluster
                      |
                 ┌────┴────┐
                 | Leader  |
                 └────┬────┘
                      |
             +--------+--------+
             |                 |
             v                 v
          Follower          Follower
```

The leader can change if the current leader becomes unavailable.

This is important for the automated backup design because the backup process should determine the current cluster state rather than permanently assuming that one particular node is always the leader.

## 21. HAProxy Failure Testing

The HA design should be tested.

First verify all backends:

```bash
nc -vz <MASTER01-IP> 6443
nc -vz <MASTER02-IP> 6443
nc -vz <MASTER03-IP> 6443
```

Then stop the API server on one control-plane node only in a controlled test environment.

For example, identify the API server container:

```bash
sudo crictl ps | grep kube-apiserver
```

Monitor the HAProxy backend:

```bash
sudo journalctl -u haproxy -f
```

From a client, continue checking:

```bash
kubectl get nodes
```

HAProxy should remove the unavailable backend from active service and continue forwarding traffic to healthy API servers.

## 22. Restore the Failed Backend

After testing, restore the affected control-plane node.

Check kubelet:

```bash
sudo systemctl status kubelet
```

Check the API server:

```bash
sudo crictl ps | grep kube-apiserver
```

Check port 6443:

```bash
sudo ss -lntp | grep 6443
```

Then verify from HAProxy:

```bash
nc -vz <MASTER-IP> 6443
```

HAProxy should detect the backend again.

## 23. HAProxy Troubleshooting

### HAProxy service fails

Check:

```bash
sudo systemctl status haproxy
```

Validate the configuration:

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Check logs:

```bash
sudo journalctl -u haproxy -n 100 --no-pager
```

### Backend has no available server

Check:

```bash
sudo journalctl -u haproxy -n 100 --no-pager
```

Test every master directly:

```bash
nc -vz <MASTER01-IP> 6443
nc -vz <MASTER02-IP> 6443
nc -vz <MASTER03-IP> 6443
```

Check the API server on each master:

```bash
sudo crictl ps | grep kube-apiserver
```

### Kubernetes API cannot be reached through HAProxy

Test:

```bash
nc -vz <HAPROXY-IP> 6443
```

Then:

```bash
kubectl cluster-info
```

Check the endpoint:

```bash
kubectl config view --minify
```

Check HAProxy:

```bash
sudo ss -lntp | grep 6443
```

## 24. HA Validation

Verify the complete traffic path:

```text
kubectl
   |
   v
k8s-api:6443
   |
   v
HAProxy
   |
   +----> Master 01:6443
   |
   +----> Master 02:6443
   |
   +----> Master 03:6443
```

Run:

```bash
kubectl cluster-info
```

```bash
kubectl get nodes -o wide
```

```bash
kubectl get pods -n kube-system -o wide
```

## 25. Validation Checklist

Before moving forward:

* [ ] HAProxy is installed.
* [ ] HAProxy service is running.
* [ ] HAProxy listens on port 6443.
* [ ] Master 01 API server is reachable.
* [ ] Master 02 API server is reachable.
* [ ] Master 03 API server is reachable.
* [ ] Kubernetes uses the HAProxy endpoint.
* [ ] Three control-plane nodes are joined.
* [ ] Three etcd members exist.
* [ ] etcd client port 2379 is available.
* [ ] etcd peer port 2380 is available.
* [ ] etcd cluster health is verified.
* [ ] HAProxy backend health is verified.
* [ ] API access through HAProxy is working.

## 26. Result

At the end of this stage, the project has a highly available Kubernetes control plane:

```text
                         Client
                           |
                           v
                    ┌─────────────┐
                    │   HAProxy   │
                    │    :6443    │
                    └──────┬──────┘
                           |
             +-------------+-------------+
             |             |             |
             v             v             v
         Master 01     Master 02     Master 03
         API + etcd    API + etcd    API + etcd
             |             |             |
             +-------------+-------------+
                       etcd Cluster
```

The next stage is to install the cluster networking layer using Calico.

Continue with:

`docs/05-calico.md`
