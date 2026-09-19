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

section "STORAGE VALIDATION"

# ------------------------------------------------------------
# StorageClasses
# ------------------------------------------------------------

echo "StorageClasses:"
kubectl get storageclass || true

if kubectl get storageclass >/dev/null 2>&1; then
    pass "StorageClasses are available"
else
    fail "Unable to retrieve StorageClasses"
fi

# ------------------------------------------------------------
# OpenEBS namespace
# ------------------------------------------------------------

if kubectl get namespace openebs >/dev/null 2>&1; then
    pass "OpenEBS namespace exists"
else
    fail "OpenEBS namespace does not exist"
fi

# ------------------------------------------------------------
# OpenEBS pods
# ------------------------------------------------------------

echo
echo "OpenEBS pods:"
kubectl get pods -n openebs -o wide || true

if kubectl get pods -n openebs --no-headers 2>/dev/null |
    grep -E 'CrashLoopBackOff|ImagePullBackOff|ErrImagePull|Error' >/dev/null; then

    fail "OpenEBS has problematic pods"

else

    pass "No obvious OpenEBS pod failures detected"
fi

# ------------------------------------------------------------
# PVs and PVCs
# ------------------------------------------------------------

echo
echo "PersistentVolumes:"
kubectl get pv || true

echo
echo "PersistentVolumeClaims:"
kubectl get pvc -A || true

if kubectl get pvc -A --no-headers 2>/dev/null |
    awk '$3 != "Bound" {found=1} END {exit !found}'; then

    fail "One or more PVCs are not Bound"

else

    pass "PVCs are Bound"
fi

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

section "STORAGE VALIDATION SUMMARY"

echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"

if [[ "${FAIL}" -gt 0 ]]; then
    exit 1
fi

echo
echo "Storage validation completed successfully."
