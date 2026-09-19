#!/usr/bin/env bash

set -u

echo "=================================================="
echo " Local Kubernetes Cluster Health Check"
echo "=================================================="

echo
echo "== Date =="
date

echo
echo "== Host =="
hostname

echo
echo "== Kubernetes Client =="
kubectl version --client 2>/dev/null || true

echo
echo "== Cluster Info =="
kubectl cluster-info 2>/dev/null || true

echo
echo "== Nodes =="
kubectl get nodes -o wide 2>/dev/null || true

echo
echo "== Node Conditions =="
kubectl get nodes \
    -o custom-columns='NAME:.metadata.name,READY:.status.conditions[-1].status,KUBELET:.status.nodeInfo.kubeletVersion' \
    2>/dev/null || true

echo
echo "== All Pods =="
kubectl get pods -A -o wide 2>/dev/null || true

echo
echo "== Storage Classes =="
kubectl get storageclass 2>/dev/null || true

echo
echo "== Persistent Volumes =="
kubectl get pv 2>/dev/null || true

echo
echo "== Persistent Volume Claims =="
kubectl get pvc -A 2>/dev/null || true

echo
echo "== Monitoring =="
kubectl get pods -n monitoring 2>/dev/null || true

echo
echo "== Logging =="
kubectl get pods -n logging 2>/dev/null || true

echo
echo "== Backup =="
kubectl get cronjob -n backup 2>/dev/null || true
kubectl get jobs -n backup 2>/dev/null || true

echo
echo "== Recent Events =="
kubectl get events -A \
    --sort-by=.lastTimestamp \
    2>/dev/null | tail -50 || true

echo
echo "=================================================="
echo " Health check completed"
echo "=================================================="
