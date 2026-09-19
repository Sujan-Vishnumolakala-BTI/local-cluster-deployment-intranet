#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# etcd Snapshot Restore Script
# ============================================================
#
# Usage:
#
#   ./restore.sh <snapshot-file> [restore-directory]
#
# Example:
#
#   ./restore.sh /backup/etcd-snapshot-20260918-020000.db \
#       /var/lib/etcd-restore
#
# IMPORTANT:
#
# This script does NOT overwrite the live etcd data directory.
# It prepares a restored data directory for a controlled restore.
#
# ============================================================

SNAPSHOT_FILE="${1:-}"
RESTORE_DIR="${2:-/var/lib/etcd-restore}"

log() {
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"
}

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

usage() {
    echo
    echo "Usage:"
    echo "  $0 <snapshot-file> [restore-directory]"
    echo
    echo "Example:"
    echo "  $0 /backup/etcd-snapshot-20260918-020000.db /var/lib/etcd-restore"
    echo
    exit 1
}

# ------------------------------------------------------------
# Validate arguments
# ------------------------------------------------------------

if [[ -z "${SNAPSHOT_FILE}" ]]; then
    usage
fi

# ------------------------------------------------------------
# Validate commands
# ------------------------------------------------------------

if command -v etcdutl >/dev/null 2>&1; then
    ETCD_RESTORE_TOOL="etcdutl"
elif command -v etcdctl >/dev/null 2>&1; then
    ETCD_RESTORE_TOOL="etcdctl"
else
    fail "Neither etcdutl nor etcdctl is installed"
fi

# ------------------------------------------------------------
# Validate snapshot
# ------------------------------------------------------------

[[ -f "${SNAPSHOT_FILE}" ]] || \
    fail "Snapshot file does not exist: ${SNAPSHOT_FILE}"

[[ -s "${SNAPSHOT_FILE}" ]] || \
    fail "Snapshot file is empty: ${SNAPSHOT_FILE}"

# ------------------------------------------------------------
# Prevent accidental live etcd overwrite
# ------------------------------------------------------------

if [[ "${RESTORE_DIR}" == "/var/lib/etcd" ]]; then
    fail "Refusing to restore directly into /var/lib/etcd"
fi

if [[ "${RESTORE_DIR}" == "/" ]]; then
    fail "Refusing to restore into /"
fi

# ------------------------------------------------------------
# Verify snapshot
# ------------------------------------------------------------

log "Verifying etcd snapshot"

if [[ "${ETCD_RESTORE_TOOL}" == "etcdutl" ]]; then

    etcdutl snapshot status \
        "${SNAPSHOT_FILE}" \
        --write-out=table

else

    export ETCDCTL_API=3

    etcdctl snapshot status \
        "${SNAPSHOT_FILE}" \
        --write-out=table

fi

# ------------------------------------------------------------
# Check restore directory
# ------------------------------------------------------------

if [[ -e "${RESTORE_DIR}" ]]; then

    if [[ -n "$(find "${RESTORE_DIR}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
        fail "Restore directory is not empty: ${RESTORE_DIR}"
    fi

else

    mkdir -p "${RESTORE_DIR}"

fi

# ------------------------------------------------------------
# Restore snapshot
# ------------------------------------------------------------

log "Restoring snapshot"

if [[ "${ETCD_RESTORE_TOOL}" == "etcdutl" ]]; then

    etcdutl snapshot restore \
        "${SNAPSHOT_FILE}" \
        --data-dir "${RESTORE_DIR}"

else

    export ETCDCTL_API=3

    etcdctl snapshot restore \
        "${SNAPSHOT_FILE}" \
        --data-dir "${RESTORE_DIR}"

fi

# ------------------------------------------------------------
# Verify restored data
# ------------------------------------------------------------

if [[ ! -d "${RESTORE_DIR}" ]]; then
    fail "Restore directory was not created"
fi

if [[ -z "$(find "${RESTORE_DIR}" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
    fail "Restore directory is empty"
fi

echo
echo "=============================================="
echo " ETCD SNAPSHOT RESTORE PREPARED"
echo "=============================================="
echo "Snapshot      : ${SNAPSHOT_FILE}"
echo "Restore dir   : ${RESTORE_DIR}"
echo "Restore tool  : ${ETCD_RESTORE_TOOL}"
echo "=============================================="
echo
echo "The restored data directory must be used with"
echo "the appropriate etcd cluster configuration."
echo "Do NOT replace a live etcd data directory"
echo "without a controlled recovery procedure."
echo

log "Snapshot restore completed successfully"
