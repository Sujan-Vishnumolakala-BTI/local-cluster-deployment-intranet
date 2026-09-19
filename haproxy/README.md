# HAProxy — Kubernetes API Load Balancer

This directory contains the HAProxy configuration used as the external load balancer for the Kubernetes control plane.

## Architecture

```text
                    Kubernetes Clients
                           |
                           | TCP :6443
                           v
                  +------------------+
                  |     HAProxy      |
                  |  Load Balancer   |
                  +--------+---------+
                           |
              +------------+------------+
              |            |            |
              v            v            v
          Master 01    Master 02    Master 03
            :6443        :6443        :6443
              |            |            |
              +------------+------------+
                           |
                          etcd
```

## Requirements

The HAProxy server requires:

* Ubuntu/Debian-based operating system
* Network connectivity to all control-plane nodes
* TCP port `6443` reachable from Kubernetes clients
* TCP port `6443` reachable from HAProxy to each control-plane node
* HAProxy installed and enabled

## Install HAProxy

```bash
sudo apt-get update
sudo apt-get install -y haproxy
```

Check the installed version:

```bash
haproxy -v
```

## Configure HAProxy

Copy the project configuration:

```bash
sudo cp haproxy.cfg /etc/haproxy/haproxy.cfg
```

Edit the configuration:

```bash
sudo nano /etc/haproxy/haproxy.cfg
```

Replace:

```text
<MASTER01-IP>
<MASTER02-IP>
<MASTER03-IP>
```

with the actual control-plane IP addresses.

Example:

```text
backend kubernetes-masters
    mode tcp
    balance roundrobin
    option tcp-check

    server master01 10.0.0.11:6443 check
    server master02 10.0.0.12:6443 check
    server master03 10.0.0.13:6443 check
```

## Validate Configuration

Before restarting HAProxy:

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Expected result:

```text
Configuration file is valid
```

If the configuration is invalid, do not restart HAProxy until the problem is corrected.

## Start HAProxy

```bash
sudo systemctl enable haproxy
sudo systemctl restart haproxy
```

Check status:

```bash
sudo systemctl status haproxy
```

Check logs:

```bash
sudo journalctl -u haproxy -f
```

## Verify Port 6443

On the HAProxy server:

```bash
sudo ss -lntp | grep 6443
```

Expected:

```text
LISTEN ... 0.0.0.0:6443
```

From a Kubernetes client:

```bash
nc -vz <LB-IP> 6443
```

Expected:

```text
Connection to <LB-IP> 6443 port [tcp/*] succeeded!
```

## Test Kubernetes API

From a machine with the Kubernetes configuration:

```bash
kubectl cluster-info
```

Also verify:

```bash
kubectl get nodes
```

## Test Individual Control-Plane Nodes

From the HAProxy server:

```bash
nc -vz <MASTER01-IP> 6443
nc -vz <MASTER02-IP> 6443
nc -vz <MASTER03-IP> 6443
```

All three control-plane API endpoints should be reachable.

## Backend Failure Test

HAProxy should continue serving the Kubernetes API when one control-plane API server becomes unavailable.

For example, temporarily stop the API server on one control-plane node only in a controlled test environment.

Then check HAProxy logs:

```bash
sudo journalctl -u haproxy --since "5 minutes ago"
```

Verify that the remaining control-plane nodes are still available:

```bash
kubectl get nodes
```

After the test, restore the affected control-plane node and verify:

```bash
kubectl get nodes
```

## HAProxy Statistics

The optional statistics interface can be enabled in `haproxy.cfg`:

```text
frontend haproxy-stats
    bind *:8404
    mode http
    stats enable
    stats uri /stats
    stats refresh 10s
```

Then access:

```text
http://<LB-IP>:8404/stats
```

Only expose the statistics port where appropriate. If it is not required, keep the section disabled.

## Kubernetes API Endpoint

The Kubernetes cluster should use the HAProxy address as its API endpoint.

Example:

```text
k8s-api:6443
```

or:

```text
<LB-IP>:6443
```

The same endpoint should be used consistently by Kubernetes components that depend on the control-plane endpoint.

## Troubleshooting

### HAProxy service fails

Check:

```bash
sudo systemctl status haproxy
```

Validate configuration:

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Check logs:

```bash
sudo journalctl -u haproxy -n 100 --no-pager
```

### Backend has no available server

Check all control-plane nodes:

```bash
nc -vz <MASTER01-IP> 6443
nc -vz <MASTER02-IP> 6443
nc -vz <MASTER03-IP> 6443
```

On each control-plane node:

```bash
sudo ss -lntp | grep 6443
```

Check the API server:

```bash
sudo crictl ps | grep kube-apiserver
```

### Connection refused

Check:

```bash
sudo systemctl status kubelet
```

and:

```bash
sudo crictl ps | grep kube-apiserver
```

Then inspect:

```bash
sudo crictl logs <API-SERVER-CONTAINER-ID>
```

### Kubernetes client cannot connect through HAProxy

Verify:

```bash
nc -vz <LB-IP> 6443
```

Then:

```bash
kubectl cluster-info
```

Also check that the Kubernetes client configuration points to the HAProxy endpoint.

## Validate the configuration

### After creating the file:
```bash
sudo haproxy -c -f haproxy/haproxy.cfg
sudo cp haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
sudo systemctl restart haproxy
sudo systemctl status haproxy
```
## Security Considerations

HAProxy is forwarding Kubernetes API traffic as TCP.

The Kubernetes API server remains responsible for:

* TLS termination
* Authentication
* Authorization
* Kubernetes API security

HAProxy should not be exposed unnecessarily to the public Internet.

Recommended network controls include:

* Restrict inbound TCP `6443`
* Allow only trusted Kubernetes clients
* Restrict access to HAProxy management interfaces
* Use host firewall rules
* Keep HAProxy updated
* Monitor HAProxy logs

## Verification Checklist

```text
[ ] HAProxy installed
[ ] haproxy.cfg copied to /etc/haproxy/
[ ] Control-plane IPs configured
[ ] Configuration validation passed
[ ] HAProxy service enabled
[ ] HAProxy service running
[ ] Port 6443 listening
[ ] Master 01 reachable
[ ] Master 02 reachable
[ ] Master 03 reachable
[ ] Kubernetes API reachable through LB
[ ] kubectl get nodes works
```
