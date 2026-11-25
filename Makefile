# Root interface for fpga_ai toolchain, smoke checks, and integrity verification.
# Docker targets require local Linux ARM64 Docker (M4); `make verify` runs anywhere with Python 3.

SHELL := /bin/bash

IMAGE_NAME      ?= fpga_ai-toolchain:m1-arm64
DOCKER_PLATFORM ?= linux/arm64
DOCKER_TARGET   ?= full
LOG_DIR         ?= experiments/exp001/results/m1_smoke

.PHONY: help build build-sim smoke smoke-sim smoke-synth shell verify

help:
	@echo "fpga_ai Makefile targets:"
	@echo "  make verify       Verify SHA-256 digests of all protected planner-owned files"
	@echo "  make build        Build native $(DOCKER_PLATFORM) Docker image (target=$(DOCKER_TARGET))"
	@echo "  make build-sim    Build simulation-only Docker image stage (target=sim)"
	@echo "  make smoke        Run simulation and synthesis smoke suites sequentially"
	@echo "  make smoke-sim    Run VHDL-2008 + float_pkg simulation smoke tests in container"
	@echo "  make smoke-synth  Run generic VHDL-2008 + float_pkg synthesis smoke tests in container"
	@echo "  make shell        Start an interactive bash session inside the container"
	@echo ""
	@echo "Configurable variables: IMAGE_NAME=$(IMAGE_NAME) DOCKER_PLATFORM=$(DOCKER_PLATFORM) DOCKER_TARGET=$(DOCKER_TARGET) LOG_DIR=$(LOG_DIR)"

verify:
	python3 scripts/verify_protected_digests.py

build:
	IMAGE_NAME="$(IMAGE_NAME)" DOCKER_PLATFORM="$(DOCKER_PLATFORM)" DOCKER_TARGET="$(DOCKER_TARGET)" LOG_DIR="$(LOG_DIR)" bash scripts/docker_ctl.sh build

build-sim:
	IMAGE_NAME="$(IMAGE_NAME)" DOCKER_PLATFORM="$(DOCKER_PLATFORM)" DOCKER_TARGET="sim" LOG_DIR="$(LOG_DIR)" bash scripts/docker_ctl.sh build

smoke:
	IMAGE_NAME="$(IMAGE_NAME)" DOCKER_PLATFORM="$(DOCKER_PLATFORM)" LOG_DIR="$(LOG_DIR)" bash scripts/docker_ctl.sh smoke

smoke-sim:
	IMAGE_NAME="$(IMAGE_NAME)" DOCKER_PLATFORM="$(DOCKER_PLATFORM)" LOG_DIR="$(LOG_DIR)" bash scripts/docker_ctl.sh smoke-sim

smoke-synth:
	IMAGE_NAME="$(IMAGE_NAME)" DOCKER_PLATFORM="$(DOCKER_PLATFORM)" LOG_DIR="$(LOG_DIR)" bash scripts/docker_ctl.sh smoke-synth

shell:
	IMAGE_NAME="$(IMAGE_NAME)" DOCKER_PLATFORM="$(DOCKER_PLATFORM)" LOG_DIR="$(LOG_DIR)" bash scripts/docker_ctl.sh shell
