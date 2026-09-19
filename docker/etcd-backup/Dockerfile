FROM quay.io/coreos/etcd:v3.6.5

USER root

# ------------------------------------------------------------
# Install required utilities
# ------------------------------------------------------------

RUN microdnf install -y \
        bash \
        jq \
        coreutils \
        findutils \
        ca-certificates \
    && microdnf clean all

# ------------------------------------------------------------
# Create backup directory
# ------------------------------------------------------------

RUN mkdir -p /backup

# ------------------------------------------------------------
# Copy etcd operational scripts
# ------------------------------------------------------------

COPY backup.sh /usr/local/bin/etcd-backup.sh
COPY restore.sh /usr/local/bin/etcd-restore.sh
COPY health-check.sh /usr/local/bin/etcd-health-check.sh

RUN chmod +x \
        /usr/local/bin/etcd-backup.sh \
        /usr/local/bin/etcd-restore.sh \
        /usr/local/bin/etcd-health-check.sh

# ------------------------------------------------------------
# Default working directory
# ------------------------------------------------------------

WORKDIR /backup

# ------------------------------------------------------------
# Default command
# ------------------------------------------------------------

ENTRYPOINT ["/usr/local/bin/etcd-backup.sh"]
