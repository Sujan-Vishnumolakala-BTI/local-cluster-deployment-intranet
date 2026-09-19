#!/usr/bin/env bash

set -euo pipefail

KUBERNETES_MINOR="${KUBERNETES_MINOR:-v1.34}"

echo "=========================================="
echo " Kubernetes Package Installation"
echo "=========================================="

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: Run this script with sudo or as root."
    exit 1
fi

echo
echo "Kubernetes repository:"
echo "https://pkgs.k8s.io/core:/stable:/${KUBERNETES_MINOR}/deb/"

echo
echo "== Installing repository signing key =="

install -m 0755 -d /etc/apt/keyrings

curl -fsSL \
    "https://pkgs.k8s.io/core:/stable:/${KUBERNETES_MINOR}/deb/Release.key" \
    | gpg --dearmor \
    -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

chmod 0644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo
echo "== Adding Kubernetes repository =="

cat > /etc/apt/sources.list.d/kubernetes.list <<EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_MINOR}/deb/ /
EOF

echo
echo "== Updating package index =="

apt-get update

echo
echo "== Installing Kubernetes packages =="

apt-get install -y \
    kubelet \
    kubeadm \
    kubectl

echo
echo "== Holding Kubernetes package versions =="

apt-mark hold kubelet kubeadm kubectl

echo
echo "== Enabling kubelet =="

systemctl enable kubelet

echo
echo "== Installed versions =="

kubeadm version
kubectl version --client
kubelet --version

echo
echo "=========================================="
echo " Kubernetes packages installed"
echo "=========================================="

echo
echo "Next steps:"
echo "1. Configure containerd."
echo "2. Initialize the first control-plane node with kubeadm."
echo "3. Join additional control-plane nodes."
echo "4. Join worker nodes."
