---
title: "EXP001 toolchain infrastructure and smoke-test guide"
sub-title: "Native linux/arm64 container design, candidate versions, and M4 execution commands"
author: "Coding agent"
date: "2026-11-25"
---

# EXP001 Toolchain Infrastructure (`M1`)

Documents the `M1` container, smoke tests, and command interface for local MacBook Pro M5 (`linux/arm64`) execution in `M4`. No Docker or HDL commands were executed on GCP.

## 1. Candidate vs. Locally Verified Versions

All container and package versions below are **proposed candidate versions** (`NOT_RUN` on `linux/arm64` until `M4`). Actual installed versions are captured automatically into `LOG_DIR` (`sim_versions.log`, `synth_versions.log`) during `M4`.

| Component | Candidate Specification | Local ARM64 Verification State |
| :--- | :--- | :--- |
| **Base OS Image** | `ubuntu:24.04` (`--platform=linux/arm64`) | `NOT_RUN` (probed in `M4`) |
| **Python Runtime** | Ubuntu `python3` (`3.12.x`) + `pip==24.3.1` in `/opt/venv` | `NOT_RUN` (probed in `M4`) |
| **Python Packages** | `numpy==2.1.3`, `pytest==8.3.3`, `cocotb==1.9.2` ([../../../docker/requirements.txt](../../../docker/requirements.txt)) | `NOT_RUN` (probed in `M4`) |
| **VHDL Simulator** | Ubuntu `ghdl` (`4.x` series in Ubuntu 24.04 `arm64` archive) | `NOT_RUN` (`R-ENV-1`) |
| **Generic Synthesis** | Ubuntu `yosys` (`0.33` series) + `ghdl-yosys-plugin` if in `apt`, else `ghdl --synth --out=verilog` -> `yosys` | `NOT_RUN` (`R-ENV-2`, `R-ENV-3`) |

## 2. Independent Toolchain Architecture

1. **Image Build Independence** ([../../../docker/Dockerfile](../../../docker/Dockerfile)):
   * Stage `sim`: Installs `ghdl`, C/C++ build tools, and `/opt/venv` (`numpy`, `pytest`, `cocotb`). Zero Yosys dependencies.
   * Stage `full` *(default)*: Extends `sim` with `yosys` and checks `ghdl-yosys-plugin` availability in `apt`. If synthesis packaging fails on `arm64`, `make build-sim` still builds a functional simulation container.
2. **Smoke-Test Independence** (`docker/smoke/`):
   * `smoke_reg.vhd`: Registered `std_logic_vector` pass-through verifying baseline VHDL-2008 compilation, `cocotb` VPI/VHPI co-simulation, and basic synthesis.
   * `smoke_fp32_add.vhd`: Minimal registered IEEE-754 `binary32` scalar adder using `ieee.float_pkg`, testing `binary32` simulation and synthesis separately with zero `exp001` DSP assumptions.

## 3. Exact Local Commands for Tomorrow (`M4` on MacBook Pro M5)

Run from repository root (`fpga_ai/`):

```bash
# 1. Verify protected-file SHA-256 digests on host (also runnable on GCP)
make verify

# 2. Build full native linux/arm64 toolchain image (fallback if synth apt fails: `make build-sim`)
make build

# 3. Run simulation smoke tests only (GHDL + cocotb/pytest/NumPy on smoke_reg & smoke_fp32_add)
make smoke-sim

# 4. Run generic synthesis smoke tests only (smoke_reg & smoke_fp32_add separately)
make smoke-synth

# 5. Or run both smoke suites sequentially (records independent logs & exit codes)
make smoke

# 6. Open an interactive development shell inside the linux/arm64 container
make shell
```

Equivalent direct script invocations without `make`:
* `python3 scripts/verify_protected_digests.py`
* `bash scripts/docker_ctl.sh build` (or `DOCKER_TARGET=sim bash scripts/docker_ctl.sh build`)
* `bash scripts/docker_ctl.sh smoke-sim`
* `bash scripts/docker_ctl.sh smoke-synth`
* `bash scripts/docker_ctl.sh shell`

## 4. Evidence Logs and Failure Diagnostics

All local logs and exit codes are written to `experiments/exp001/results/m1_smoke/` (override with `LOG_DIR=...`):
* `docker_build_full.log` / `exit_codes.log`: Image build log and step exit codes.
* `sim_versions.log`, `sim_summary.txt`, `sim_*.log`: Simulator/Python versions and per-test logs for pure-GHDL and `cocotb` runs.
* `synth_versions.log`, `synth_summary.txt`, `synth_smoke_reg.log`, `synth_smoke_fp32_add.log`: Synthesis frontend mode (`plugin` vs. `ghdl-verilog`), cell statistics, and separate `smoke_reg` vs. `ieee.float_pkg` (`R-ENV-3`) synthesis outcomes.
