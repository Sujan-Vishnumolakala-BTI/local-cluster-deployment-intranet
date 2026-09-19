#!/usr/bin/env bash

set -u

PASS=0
FAIL=0

pass() {
    echo "[PASS] $*"
    PASS=$((PASS + 1))
}

fail() {
    echo "[FAIL] $*"
    FAIL=$((FAIL + 1))
}

section() {
    echo
    echo "============================================================"
    echo "$*"
    echo "============================================================"
}

section "KUBERNETES CLUSTER VALIDATION"

# ------------------------------------------------------------
# kubectl
# ------------------------------------------------------------

if ! command -v kubectl >/dev/null 2>&1; then
    fail "kubectl is not installed"
    exit 1
fi

pass "kubectl is available"

# ------------------------------------------------------------
# API server
# ------------------------------------------------------------

if kubectl cluster-info >/dev/null 2>&1; then
    pass "Kubernetes API server is reachable"
else
    fail "Kubernetes API server is not reachable"
fi

# ------------------------------------------------------------
# Nodes
# ------------------------------------------------------------

echo
echo "Node status:"
kubectl get nodes -o wide || true

if kubectl get nodes --no-headers 2>/dev/null |
    awk '{print $2}' |
    grep -q '^NotReady$'; then

    fail "One or more nodes are NotReady"

else

    if kubectl get nodes --no-headers >/dev/null 2>&1; then
        pass "All registered nodes are Ready"
    else
        fail "Unable to retrieve nodes"
    fi
fi

# ------------------------------------------------------------
# Kubernetes system pods
# ------------------------------------------------------------

echo
echo "System pods:"
kubectl get pods -n kube-system -o wide || true

if kubectl get pods -n kube-system --no-headers 2>/dev/null |
    grep -E 'CrashLoopBackOff|ImagePullBackOff|ErrImagePull|Error' >/dev/null; then

    fail "Problematic kube-system pod detected"

else

    pass "No obvious kube-system pod failures detected"
fi

# ------------------------------------------------------------
# Calico
# ------------------------------------------------------------

if kubectl get daemonset -n kube-system calico-node >/dev/null 2>&1; then

    DESIRED="$(kubectl get daemonset calico-node \
        -n kube-system \
        -o jsonpath='{.status.desiredNumberScheduled}')"

    READY="$(kubectl get daemonset calico-node \
        -n kube-system \
        -o jsonpath='{.status.numberReady}')"

    if [[ "${DESIRED}" == "${READY}" ]]; then
        pass "Calico nodes are Ready"
    else
        fail "Calico is not fully Ready"
    fi

else

    fail "Calico DaemonSet not found"
fi

# ------------------------------------------------------------
# CoreDNS
# ------------------------------------------------------------

if kubectl get deployment coredns -n kube-system >/dev/null 2>&1; then

    AVAILABLE="$(kubectl get deployment coredns \
        -n kube-system \
        -o jsonpath='{.status.availableReplicas}')"

    DESIRED="$(kubectl get deployment coredns \
        -n kube-system \
        -o jsonpath='{.spec.replicas}')"

    if [[ "${AVAILABLE:-0}" == "${DESIRED}" ]]; then
        pass "CoreDNS is Ready"
    else
        fail "CoreDNS is not fully Ready"
    fi

else

    fail "CoreDNS deployment not found"
fi

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

section "CLUSTER VALIDATION SUMMARY"

echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"

if [[ "${FAIL}" -gt 0 ]]; then
    exit 1
fi

echo
echo "Cluster validation completed successfully."
