#!/usr/bin/env bash

set -euo pipefail

echo "=========================================="
echo " Kubernetes Node Prerequisites"
echo "=========================================="

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: Run this script with sudo or as root."
    exit 1
fi

echo
echo "== Updating package index =="
apt-get update

echo
echo "== Installing required packages =="
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gpg \
    jq \
    net-tools \
    socat \
    conntrack \
    iptables \
    ethtool \
    chrony

echo
echo "== Disabling swap =="
swapoff -a

sed -ri '/\sswap\s/s/^/#/' /etc/fstab

echo
echo "== Loading required kernel modules =="

cat > /etc/modules-load.d/kubernetes.conf <<'EOF'
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

echo
echo "== Configuring Kubernetes sysctl settings =="

cat > /etc/sysctl.d/99-kubernetes.conf <<'EOF'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

echo
echo "== Enabling time synchronization =="

systemctl enable --now chrony

echo
echo "== Checking swap =="

if swapon --show | grep -q .; then
    echo "ERROR: Swap is still enabled."
    exit 1
else
    echo "Swap disabled successfully."
fi

echo
echo "== Checking kernel modules =="

lsmod | grep -E 'overlay|br_netfilter' || true

echo
echo "== Checking IP forwarding =="

sysctl net.ipv4.ip_forward

echo
echo "=========================================="
echo " Prerequisites completed successfully"
echo "=========================================="
