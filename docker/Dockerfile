# Portable native linux/arm64 toolchain image for fpga_ai (EXP001).
# STATUS: PROPOSED CANDIDATE CONFIGURATION -- NOT YET VERIFIED ON LOCAL ARM64 DOCKER.
#
# Two build targets keep simulation independent of synthesis frontend packaging:
#   --target sim  : Ubuntu 24.04 arm64 + GHDL + Python 3.12 venv (numpy, pytest, cocotb)
#   --target full : Extends `sim` with Yosys and optional GHDL-Yosys plugin check (default)

ARG BASE_IMAGE=ubuntu:24.04

# -----------------------------------------------------------------------------
# Stage 1: Native linux/arm64 VHDL-2008 simulation + Python verification stage
# -----------------------------------------------------------------------------
FROM --platform=linux/arm64 ${BASE_IMAGE} AS sim

ARG GHDL_APT_PKGS="ghdl"

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:${PATH}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        g++ \
        gcc \
        git \
        jq \
        make \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        ${GHDL_APT_PKGS} \
    && rm -rf /var/lib/apt/lists/*

COPY docker/requirements.txt /tmp/requirements.txt

RUN python3 -m venv "${VIRTUAL_ENV}" \
    && pip install --no-cache-dir --upgrade "pip==24.3.1" \
    && pip install --no-cache-dir -r /tmp/requirements.txt \
    && mkdir -p /opt/fpga_ai \
    && { \
        echo "stage=sim"; \
        uname -srmo; \
        python3 --version; \
        ghdl --version | head -n 3; \
        pip freeze; \
    } > /opt/fpga_ai/sim_versions.txt

WORKDIR /workspace
CMD ["/bin/bash"]

# -----------------------------------------------------------------------------
# Stage 2: Generic synthesis stage (adds Yosys + probes optional VHDL plugin)
# -----------------------------------------------------------------------------
FROM sim AS full

ARG YOSYS_APT_PKGS="yosys"
ARG OPTIONAL_YOSYS_PLUGIN_PKG="ghdl-yosys-plugin"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ${YOSYS_APT_PKGS} \
    && if [ -n "${OPTIONAL_YOSYS_PLUGIN_PKG}" ] && apt-cache show "${OPTIONAL_YOSYS_PLUGIN_PKG}" >/dev/null 2>&1; then \
        apt-get install -y --no-install-recommends "${OPTIONAL_YOSYS_PLUGIN_PKG}" \
        && echo "yosys_vhdl_plugin_apt=${OPTIONAL_YOSYS_PLUGIN_PKG}:INSTALLED" > /opt/fpga_ai/synth_plugin_status.txt; \
    else \
        echo "yosys_vhdl_plugin_apt=${OPTIONAL_YOSYS_PLUGIN_PKG}:NOT_IN_APT_ARCHIVE" > /opt/fpga_ai/synth_plugin_status.txt; \
    fi \
    && rm -rf /var/lib/apt/lists/* \
    && { \
        echo "stage=full"; \
        yosys -V; \
        cat /opt/fpga_ai/synth_plugin_status.txt; \
    } > /opt/fpga_ai/synth_versions.txt

WORKDIR /workspace
CMD ["/bin/bash"]
