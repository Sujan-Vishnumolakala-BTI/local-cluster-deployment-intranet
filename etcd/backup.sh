#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# etcd Leader-Aware Backup Script
# ============================================================
#
# Required environment variables:
#
#   ETCD_ENDPOINTS
#       Comma-separated etcd client endpoints.
#
#       Example:
#       https://10.0.0.11:2379,https://10.0.0.12:2379,https://10.0.0.13:2379
#
# Optional environment variables:
#
#   BACKUP_DIR
#   ETCD_CACERT
#   ETCD_CERT
#   ETCD_KEY
#   RETENTION_DAYS
#
# ============================================================

BACKUP_DIR="${BACKUP_DIR:-/backup}"

ETCD_ENDPOINTS="${ETCD_ENDPOINTS:?ETCD_ENDPOINTS must be set}"

ETCD_CACERT="${ETCD_CACERT:-/etc/kubernetes/pki/etcd/ca.crt}"
ETCD_CERT="${ETCD_CERT:-/etc/kubernetes/pki/etcd/server.crt}"
ETCD_KEY="${ETCD_KEY:-/etc/kubernetes/pki/etcd/server.key}"

RETENTION_DAYS="${RETENTION_DAYS:-7}"

TIMESTAMP="$(date -u '+%Y%m%d-%H%M%S')"
HOSTNAME_VALUE="$(hostname)"

SNAPSHOT_FILE="${BACKUP_DIR}/etcd-snapshot-${TIMESTAMP}.db"
TEMP_SNAPSHOT="${SNAPSHOT_FILE}.tmp"
CHECKSUM_FILE="${SNAPSHOT_FILE}.sha256"

log() {
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"
}

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

cleanup() {
    rm -f "${TEMP_SNAPSHOT}"
}

trap cleanup EXIT

log "Starting etcd backup"
log "Backup host: ${HOSTNAME_VALUE}"
log "Backup directory: ${BACKUP_DIR}"

# ------------------------------------------------------------
# Validate required commands
# ------------------------------------------------------------

command -v etcdctl >/dev/null 2>&1 || \
    fail "etcdctl is not installed"

command -v jq >/dev/null 2>&1 || \
    fail "jq is not installed"

command -v sha256sum >/dev/null 2>&1 || \
    fail "sha256sum is not installed"

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
# Prepare backup directory
# ------------------------------------------------------------

mkdir -p "${BACKUP_DIR}"

[[ -w "${BACKUP_DIR}" ]] || \
    fail "Backup directory is not writable: ${BACKUP_DIR}"

# ------------------------------------------------------------
# etcdctl configuration
# ------------------------------------------------------------

export ETCDCTL_API=3

ETCDCTL_COMMON_ARGS=(
    "--endpoints=${ETCD_ENDPOINTS}"
    "--cacert=${ETCD_CACERT}"
    "--cert=${ETCD_CERT}"
    "--key=${ETCD_KEY}"
)

# ------------------------------------------------------------
# Check cluster health
# ------------------------------------------------------------

log "Checking etcd cluster health"

if ! etcdctl \
    "${ETCDCTL_COMMON_ARGS[@]}" \
    endpoint health \
    --cluster; then

    fail "etcd cluster health check failed"
fi

# ------------------------------------------------------------
# Retrieve endpoint status
# ------------------------------------------------------------

log "Retrieving etcd endpoint status"

STATUS_JSON="$(
    etcdctl \
        "${ETCDCTL_COMMON_ARGS[@]}" \
        endpoint status \
        --cluster \
        --write-out=json
)"

echo "${STATUS_JSON}" | jq empty >/dev/null 2>&1 || \
    fail "Unable to parse etcd endpoint status"

# ------------------------------------------------------------
# Identify the current etcd leader
# ------------------------------------------------------------

LEADER_ENDPOINT="$(
    echo "${STATUS_JSON}" |
        jq -r '
            .[] |
            select(
                (.Status.header.member_id == .Status.leader)
            ) |
            .Endpoint
        ' |
        head -n 1
)"

if [[ -z "${LEADER_ENDPOINT}" || "${LEADER_ENDPOINT}" == "null" ]]; then
    fail "Unable to identify the current etcd leader"
fi

log "Current etcd leader: ${LEADER_ENDPOINT}"

# ------------------------------------------------------------
# Verify the leader is healthy
# ------------------------------------------------------------

log "Checking leader health"

if ! etcdctl \
    "--endpoints=${LEADER_ENDPOINT}" \
    "--cacert=${ETCD_CACERT}" \
    "--cert=${ETCD_CERT}" \
    "--key=${ETCD_KEY}" \
    endpoint health; then

    fail "The current etcd leader is not healthy"
fi

# ------------------------------------------------------------
# Display cluster status
# ------------------------------------------------------------

log "Current etcd cluster status"

etcdctl \
    "${ETCDCTL_COMMON_ARGS[@]}" \
    endpoint status \
    --cluster \
    --write-out=table

# ------------------------------------------------------------
# Take snapshot from leader
# ------------------------------------------------------------

log "Creating snapshot from leader"

etcdctl \
    "--endpoints=${LEADER_ENDPOINT}" \
    "--cacert=${ETCD_CACERT}" \
    "--cert=${ETCD_CERT}" \
    "--key=${ETCD_KEY}" \
    snapshot save "${TEMP_SNAPSHOT}"

# ------------------------------------------------------------
# Validate snapshot
# ------------------------------------------------------------

log "Validating snapshot"

etcdctl snapshot status \
    "${TEMP_SNAPSHOT}" \
    --write-out=table

# ------------------------------------------------------------
# Verify snapshot size
# ------------------------------------------------------------

SNAPSHOT_SIZE="$(stat -c '%s' "${TEMP_SNAPSHOT}")"

if [[ "${SNAPSHOT_SIZE}" -le 0 ]]; then
    fail "Snapshot file is empty"
fi

log "Snapshot size: ${SNAPSHOT_SIZE} bytes"

# ------------------------------------------------------------
# Move verified snapshot into final location
# ------------------------------------------------------------

mv "${TEMP_SNAPSHOT}" "${SNAPSHOT_FILE}"

# ------------------------------------------------------------
# Generate checksum
# ------------------------------------------------------------

sha256sum "${SNAPSHOT_FILE}" > "${CHECKSUM_FILE}"

log "Snapshot checksum:"
cat "${CHECKSUM_FILE}"

# ------------------------------------------------------------
# Retention cleanup
# ------------------------------------------------------------

if [[ "${RETENTION_DAYS}" =~ ^[0-9]+$ ]]; then

    log "Removing backups older than ${RETENTION_DAYS} days"

    find "${BACKUP_DIR}" \
        -type f \
        -name 'etcd-snapshot-*.db' \
        -mtime "+${RETENTION_DAYS}" \
        -delete

    find "${BACKUP_DIR}" \
        -type f \
        -name 'etcd-snapshot-*.db.sha256' \
        -mtime "+${RETENTION_DAYS}" \
        -delete

else

    fail "RETENTION_DAYS must be a positive integer"

fi

# ------------------------------------------------------------
# Final output
# ------------------------------------------------------------

log "etcd backup completed successfully"

echo
echo "=============================================="
echo " ETCD BACKUP COMPLETED"
echo "=============================================="
echo "Leader       : ${LEADER_ENDPOINT}"
echo "Snapshot     : ${SNAPSHOT_FILE}"
echo "Checksum     : ${CHECKSUM_FILE}"
echo "Size         : ${SNAPSHOT_SIZE} bytes"
echo "Retention    : ${RETENTION_DAYS} days"
echo "=============================================="
