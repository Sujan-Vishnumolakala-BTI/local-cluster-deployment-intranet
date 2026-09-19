FROM fluent/fluentd:v1.18-debian-1

USER root

# ------------------------------------------------------------
# Install dependencies required by the Loki output plugin
# ------------------------------------------------------------

RUN gem install fluent-plugin-grafana-loki --no-document

# ------------------------------------------------------------
# Create Fluentd configuration directory
# ------------------------------------------------------------

RUN mkdir -p /fluentd/etc

# ------------------------------------------------------------
# Copy Fluentd configuration
# ------------------------------------------------------------

COPY fluent.conf /fluentd/etc/fluent.conf

# ------------------------------------------------------------
# Set permissions
# ------------------------------------------------------------

RUN chown -R fluent:fluent /fluentd

USER fluent

# ------------------------------------------------------------
# Start Fluentd
# ------------------------------------------------------------

CMD ["fluentd", "-c", "/fluentd/etc/fluent.conf", "-v"]
