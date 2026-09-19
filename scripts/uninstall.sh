#!/usr/bin/env bash

set -euo pipefail

echo "=========================================="
echo " Kubernetes Node Cleanup"
echo "=========================================="

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: Run this script with sudo or as root."
    exit 1
fi

echo
echo "WARNING:"
echo "This script removes Kubernetes packages and"
echo "resets the local kubeadm configuration."
echo
read -r -p "Continue? [yes/no]: " CONFIRM

if [[ "${CONFIRM}" != "yes" ]]; then
    echo "Aborted."
    exit 0
fi

echo
echo "== Resetting kubeadm configuration =="

if command -v kubeadm >/dev/null 2>&1; then
    kubeadm reset -f || true
fi

echo
echo "== Removing Kubernetes packages =="

apt-mark unhold kubelet kubeadm kubectl 2>/dev/null || true

apt-get purge -y \
    kubelet \
    kubeadm \
    kubectl || true

echo
echo "== Removing Kubernetes package repository =="

rm -f /etc/apt/sources.list.d/kubernetes.list
rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo
echo "== Removing kubeconfig =="

rm -rf /root/.kube

echo
echo "== Removing kubeadm configuration =="

rm -rf /etc/kubernetes

echo
echo "== Removing CNI configuration =="

rm -rf /etc/cni/net.d

echo
echo "== Removing kubelet state =="

rm -rf /var/lib/kubelet

echo
echo "== Updating package index =="

apt-get update

echo
echo "=========================================="
echo " Kubernetes node cleanup completed"
echo "=========================================="

echo
echo "NOTE:"
echo "containerd was intentionally not removed."
echo "OpenEBS data was not removed."
echo "Manual cleanup may be required depending on"
echo "your environment."
