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

section "LOGGING VALIDATION"

# ------------------------------------------------------------
# Namespace
# ------------------------------------------------------------

if kubectl get namespace logging >/dev/null 2>&1; then
    pass "Logging namespace exists"
else
    fail "Logging namespace does not exist"
fi

# ------------------------------------------------------------
# Loki
# ------------------------------------------------------------

if helm status loki -n logging >/dev/null 2>&1; then
    pass "Loki Helm release exists"
else
    fail "Loki Helm release not found"
fi

# ------------------------------------------------------------
# Loki pods
# ------------------------------------------------------------

echo
echo "Loki pods:"
kubectl get pods -n logging -o wide || true

if kubectl get pods -n logging --no-headers 2>/dev/null |
    grep -E 'CrashLoopBackOff|ImagePullBackOff|ErrImagePull|Error' >/dev/null; then

    fail "Loki has problematic pods"

else

    pass "No obvious Loki pod failures detected"
fi

# ------------------------------------------------------------
# Fluentd
# ------------------------------------------------------------

echo
echo "Fluentd pods:"
kubectl get pods -n logging -l app=fluentd -o wide || true

if kubectl get daemonset fluentd -n logging >/dev/null 2>&1; then

    DESIRED="$(kubectl get daemonset fluentd \
        -n logging \
        -o jsonpath='{.status.desiredNumberScheduled}')"

    READY="$(kubectl get daemonset fluentd \
        -n logging \
        -o jsonpath='{.status.numberReady}')"

    if [[ "${DESIRED}" == "${READY}" ]]; then
        pass "Fluentd is Ready on all scheduled nodes"
    else
        fail "Fluentd is not fully Ready"
    fi

else

    fail "Fluentd DaemonSet not found"
fi

# ------------------------------------------------------------
# Loki service
# ------------------------------------------------------------

if kubectl get service loki -n logging >/dev/null 2>&1; then
    pass "Loki service exists"
else
    fail "Loki service not found"
fi

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

section "LOGGING VALIDATION SUMMARY"

echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"

if [[ "${FAIL}" -gt 0 ]]; then
    exit 1
fi

echo
echo "Logging validation completed successfully."
