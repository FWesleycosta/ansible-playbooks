# Test host for Molecule and the local lab: Ubuntu with systemd as PID 1.
# It stands in for a virtual machine and is never deployed anywhere.
# It runs as root on purpose: systemd must be PID 1 to manage services like on a real host.
#
# BASE_IMAGE is pinned by digest (multi-arch index with amd64 and arm64).
# The default is Ubuntu 24.04; the Makefile passes the Ubuntu 26.04 digest for the second image.
ARG BASE_IMAGE=ubuntu:24.04@sha256:fe81560990fae86dc4743202b2cb4d3df98d0bcf949173cecef15ce1127ef852
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.title="ansible-playbooks test host" \
      org.opencontainers.image.description="Ubuntu with systemd for Ansible tests. Not for production." \
      org.opencontainers.image.source="https://github.com/FWesleycosta/ansible-playbooks" \
      org.opencontainers.image.licenses="MIT"

# Tells systemd that it runs inside a container.
ENV container=docker

# Package versions follow the pinned base image; pinning each apt package is not worth it for a test fixture.
# hadolint ignore=DL3008
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        python3 \
        python3-apt \
        sudo \
        systemd \
        systemd-sysv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Signal that makes systemd shut down cleanly.
STOPSIGNAL SIGRTMIN+3

CMD ["/lib/systemd/systemd"]
