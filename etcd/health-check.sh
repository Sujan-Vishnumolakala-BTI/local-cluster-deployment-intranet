#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# etcd Health Check
# ============================================================
#
# Required:
#
#   ETCD_ENDPOINTS
#
# Optional:
#
#   ETCD_CACERT
#   ETCD_CERT
#   ETCD_KEY
#
# ============================================================

ETCD_ENDPOINTS="${ETCD_ENDPOINTS:?ETCD_ENDPOINTS must be set}"

ETCD_CACERT="${ETCD_CACERT:-/etc/kubernetes/pki/etcd/ca.crt}"
ETCD_CERT="${ETCD_CERT:-/etc/kubernetes/pki/etcd/server.crt}"
ETCD_KEY="${ETCD_KEY:-/etc/kubernetes/pki/etcd/server.key}"

log() {
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"
}

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

# ------------------------------------------------------------
# Validate etcdctl
# ------------------------------------------------------------

command -v etcdctl >/dev/null 2>&1 || \
    fail "etcdctl is not installed"

# ------------------------------------------------------------
# Validate certificates
# ------------------------------------------------------------

[[ -f "${ETCD_CACERT}" ]] || \
    fail "CA certificate not found: ${ETCD_CACERT}"

[[ -f "${ETCD_CERT}" ]] || \
    fail "Client certificate not found: ${ETCD_CERT}"

[[ -f "${ETCD_KEY}" ]] || \
    fail "Client key not found: ${ETCD_KEY}"

# ------------------------------------------------------------
# Configure etcdctl API
# ------------------------------------------------------------

export ETCDCTL_API=3

ETCDCTL_ARGS=(
    "--endpoints=${ETCD_ENDPOINTS}"
    "--cacert=${ETCD_CACERT}"
    "--cert=${ETCD_CERT}"
    "--key=${ETCD_KEY}"
)

# ------------------------------------------------------------
# Cluster health
# ------------------------------------------------------------

echo
echo "=============================================="
echo " ETCD CLUSTER HEALTH"
echo "=============================================="

log "Checking endpoint health"

etcdctl \
    "${ETCDCTL_ARGS[@]}" \
    endpoint health \
    --cluster

# ------------------------------------------------------------
# Endpoint status
# ------------------------------------------------------------

echo
echo "=============================================="
echo " ETCD ENDPOINT STATUS"
echo "=============================================="

etcdctl \
    "${ETCDCTL_ARGS[@]}" \
    endpoint status \
    --cluster \
    --write-out=table

# ------------------------------------------------------------
# Member list
# ------------------------------------------------------------

echo
echo "=============================================="
echo " ETCD MEMBER LIST"
echo "=============================================="

etcdctl \
    "${ETCDCTL_ARGS[@]}" \
    member list \
    --write-out=table

# ------------------------------------------------------------
# Final result
# ------------------------------------------------------------

echo
echo "=============================================="
echo " ETCD HEALTH CHECK PASSED"
echo "=============================================="
