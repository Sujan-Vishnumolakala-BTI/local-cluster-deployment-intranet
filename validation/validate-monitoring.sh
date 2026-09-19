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

section "MONITORING VALIDATION"

# ------------------------------------------------------------
# Namespace
# ------------------------------------------------------------

if kubectl get namespace monitoring >/dev/null 2>&1; then
    pass "Monitoring namespace exists"
else
    fail "Monitoring namespace does not exist"
fi

# ------------------------------------------------------------
# Helm release
# ------------------------------------------------------------

if helm status monitoring -n monitoring >/dev/null 2>&1; then
    pass "Monitoring Helm release exists"
else
    fail "Monitoring Helm release not found"
fi

# ------------------------------------------------------------
# Pods
# ------------------------------------------------------------

echo
echo "Monitoring pods:"
kubectl get pods -n monitoring -o wide || true

if kubectl get pods -n monitoring --no-headers 2>/dev/null |
    grep -E 'CrashLoopBackOff|ImagePullBackOff|ErrImagePull|Error' >/dev/null; then

    fail "Monitoring has problematic pods"

else

    pass "No obvious monitoring pod failures detected"
fi

# ------------------------------------------------------------
# Prometheus
# ------------------------------------------------------------

if kubectl get statefulset -n monitoring \
    -l app.kubernetes.io/name=prometheus >/dev/null 2>&1; then

    pass "Prometheus StatefulSet detected"

else

    if kubectl get prometheus -n monitoring >/dev/null 2>&1; then
        pass "Prometheus resource detected"
    else
        fail "Prometheus resource not detected"
    fi
fi

# ------------------------------------------------------------
# Grafana
# ------------------------------------------------------------

if kubectl get deployment -n monitoring \
    -l app.kubernetes.io/name=grafana >/dev/null 2>&1; then

    pass "Grafana deployment detected"
else
    fail "Grafana deployment not detected"
fi

# ------------------------------------------------------------
# Alertmanager
# ------------------------------------------------------------

if kubectl get alertmanager -n monitoring >/dev/null 2>&1; then
    pass "Alertmanager resource detected"
else
    fail "Alertmanager resource not detected"
fi

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

section "MONITORING VALIDATION SUMMARY"

echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"

if [[ "${FAIL}" -gt 0 ]]; then
    exit 1
fi

echo
echo "Monitoring validation completed successfully."