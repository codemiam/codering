ARG NUCLIO_LABEL=0.4.0
ARG NUCLIO_ARCH=amd64
ARG NUCLIO_PROCESSOR_IMAGE=nuclio/processor-shell-alpine:${NUCLIO_LABEL}-${NUCLIO_ARCH}
ARG NUCLIO_RUNTIME_IMAGE=php:7-alpine

# Supplies processor uhttpc, used for healthcheck
FROM nuclio/uhttpc:0.0.1-amd64 as uhttpc

# Builds source, supplies processor script and handler plugin
FROM ${NUCLIO_PROCESSOR_IMAGE} as processor

# From the base image
FROM ${NUCLIO_RUNTIME_IMAGE}

# Copy required objects from the suppliers
COPY --from=processor /usr/local/bin/processor /usr/local/bin/processor
COPY --from=processor /etc/nuclio/version_info.json /etc/nuclio/version_info.json
# COPY --from=uhttpc /home/nuclio/bin/uhttpc /usr/local/bin/uhttpc
# COPY function.yaml /opt/nuclio/
COPY proxy-function.sh /opt/nuclio/

# Readiness probe
HEALTHCHECK --interval=1s --timeout=30s CMD /usr/local/bin/uhttpc --url http://127.0.0.1:8082/ready || exit 1

# Run processor with configuration and platform configuration
#CMD [ "processor", "--config", "/etc/nuclio/config/processor/processor.yaml", "--platform-config", "/etc/nuclio/config/platform/platform.yaml" ]
CMD ["processor"]