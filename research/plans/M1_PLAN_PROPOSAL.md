---
title: "EXP001 Milestone M1 implementation plan"
sub-title: "Approved native linux/arm64 infrastructure, smoke tests, and Makefile interface"
author: "Coding agent"
date: "2026-11-25"
---

# EXP001 Milestone M1 Implementation Plan (`Infrastructure`)

Recorded per owner and planner approval (`M0 ACCEPTED -- M1 APPROVED WITH ADDITIONS`, `2026-11-25`). Base Git revision on `main`: `58be40c` (`chore: complete M0 project bootstrap`).

## 1. Approval Status and Governing Additions

* **Status**: `APPROVED` (`2026-11-25`)
* **Key Planner and Owner Additions Applied**:
  1. Independent IEEE-754 `binary32` smoke test (`docker/smoke/smoke_fp32_add.vhd`) using VHDL-2008 `ieee.float_pkg`, exercised separately in simulation and synthesis, with zero `exp001` functional assumptions.
  2. Strict separation between simulation and synthesis toolchains at both image-build time (`sim` vs. `full` stages in `docker/Dockerfile`) and runtime (`smoke-sim` vs. `smoke-synth`) so synthesis frontend issues never block functional simulation.
  3. Separate commands and root [../../Makefile](../../Makefile) targets for `build` (plus `build-sim`), `smoke`, `smoke-sim`, `smoke-synth`, `shell`, and `verify`.
  4. Explicit candidate tool and Python package versions in `docker/Dockerfile`, `docker/requirements.txt`, and [../../experiments/exp001/docs/INFRASTRUCTURE.md](../../experiments/exp001/docs/INFRASTRUCTURE.md), clearly distinguished from locally verified versions (`NOT_RUN` until `M4`).
  5. Full capture of tool versions, exit codes, and execution logs during local runs without suppressing failures.
  6. Native `linux/arm64` execution without `x86` emulation.
  7. Preservation of all 35 protected planner-owned files; zero resolution of `G1`--`G5`; zero package installs or Docker invocations on GCP; M1 changes left uncommitted for review.

## 2. Approved M1 File-Level Scope

| Action | Repo-Relative Path | Purpose |
| :--- | :--- | :--- |
| **CREATE** | `research/plans/M1_PLAN_PROPOSAL.md` | Record this approved `M1` plan and additions. |
| **CREATE** | `Makefile` | Root command interface (`build`, `build-sim`, `smoke`, `smoke-sim`, `smoke-synth`, `shell`, `verify`). |
| **CREATE** | `docker/Dockerfile` | Native `linux/arm64` multi-stage image (`sim` and `full` targets) on `ubuntu:24.04`. |
| **CREATE** | `docker/requirements.txt` | Candidate Python dependency pins (`numpy==2.1.3`, `pytest==8.3.3`, `cocotb==1.9.2`). |
| **CREATE** | `docker/smoke/smoke_reg.vhd` | Minimal VHDL-2008 registered `std_logic_vector` entity. |
| **CREATE** | `docker/smoke/tb_smoke_reg.vhd` | Standalone VHDL-2008 testbench for `smoke_reg`. |
| **CREATE** | `docker/smoke/smoke_fp32_add.vhd` | Minimal VHDL-2008 `ieee.float_pkg` (`binary32`) registered adder, independent of `exp001`. |
| **CREATE** | `docker/smoke/tb_smoke_fp32_add.vhd` | Standalone VHDL-2008 testbench for `smoke_fp32_add`. |
| **CREATE** | `docker/smoke/cocotb_smoke_reg.py` | `cocotb` coroutine test module for `smoke_reg`. |
| **CREATE** | `docker/smoke/cocotb_smoke_fp32.py` | `cocotb` + `numpy.float32` coroutine test module for `smoke_fp32_add`. |
| **CREATE** | `docker/smoke/test_smoke_cocotb.py` | `pytest` runner invoking GHDL co-simulation independently for `smoke_reg` and `smoke_fp32_add`. |
| **CREATE** | `scripts/verify_protected_digests.py` | Host/container Python 3.12 stdlib SHA-256 verifier for protected files and future `AC1` oracle manifests. |
| **CREATE** | `scripts/docker_ctl.sh` | Host-side native `linux/arm64` Docker wrapper for `build`, `smoke-sim`, `smoke-synth`, `smoke`, and `shell`. |
| **CREATE** | `scripts/smoke_sim.sh` | In-container simulation smoke runner capturing versions, logs, and exit codes. |
| **CREATE** | `scripts/smoke_synth.sh` | In-container generic synthesis smoke runner exercising `smoke_reg` and `smoke_fp32_add` separately. |
| **CREATE** | `experiments/exp001/tb/conftest.py` | Spec-neutral `pytest` harness skeleton enforcing pre/post-test protected digest checks (`AC1` hook). |
| **CREATE** | `experiments/exp001/docs/INFRASTRUCTURE.md` | Concise `M1` guide covering candidate versions, local `M4` commands, log layout, and `R-ENV-1`..`3` diagnostics. |
| **UPDATE** | `README.md`, `research/STATUS.md`, `research/TODO.md`, `research/daily_notes/2026-11-25.md`, `research/changelog/` | Update command orientation and record `M1` completion and verification evidence. |

## 3. GCP Verification vs. Local M4 Execution

* **Executed on GCP in `M1`**: `make help`, `make verify` (`scripts/verify_protected_digests.py`), `bash -n` on all shell scripts, `python3 -m py_compile` on all Python modules, and YAML/ASCII/relative-link/hygiene validation across all Markdown files.
* **Deferred to Local ARM64 `M4` (`NOT_RUN` locally / `BLOCKED` on GCP)**: `make build`, `make smoke-sim`, `make smoke-synth`, `make smoke`, and `make shell`.
