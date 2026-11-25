---
title: "Milestone M3 GCP-to-local ARM64 handoff"
sub-title: "Session resume guide, validation runbook, diagnostics, and next-session plan"
author: "Coding agent"
date: "2026-11-25"
---

# Milestone M3 Handoff (`GCP Authoring -> Local ARM64 Session`)

Prepared per [../.agents/skills/release_validation/SKILL.md](../.agents/skills/release_validation/SKILL.md) and [../.agents/skills/session-resume/SKILL.md](../.agents/skills/session-resume/SKILL.md). Canonical tables live in linked documents rather than being duplicated here.

## 1. Repository and Milestone Status

* **Completed on GCP (`2026-11-25`)**:
  * `M0` (`Bootstrap`): Committed on `main` at `58be40c`.
  * `M1` (`Infrastructure`): Committed on `main` at `4647b70`.
  * `M3` (`Handoff`): Prepared in working tree above `4647b70` (uncommitted pending owner approval).
* **Deferred to Local ARM64 Session (`2026-11-26`, MacBook Pro M5, 16 GiB RAM)**:
  * `M4` Phase 1: Native `linux/arm64` Docker image build and toolchain smoke validation (`AC2`).
  * `M2` (`Implementation`): Deferred until `G1`--`G5` are approved by planner/owner (informed by `M4` Phase 1 toolchain findings).
  * `M4` Phase 2 & `M5` (`Evaluation`): `exp001` RTL compilation, oracle co-simulation, generic synthesis, and cycle/resource evaluation (`AC1`, `AC3`--`AC7`).
* **Live Acceptance Matrix (`AC1`--`AC7`)**: See [STATUS.md](STATUS.md). No container build, simulation, or synthesis has been executed (`NOT_RUN` locally / `BLOCKED` on GCP).

### Source Inventory Summary

| Path Group | Contents | GCP Verification State | Local ARM64 State |
| :--- | :--- | :--- | :--- |
| [../AGENTS.md](../AGENTS.md), [../START_PROMPT.md](../START_PROMPT.md), `.agents/`, `context/` | 35 protected planner-owned files | `PASS` (`make verify` SHA-256 check) | Re-verify first on host |
| [../Makefile](../Makefile), `scripts/` | Host/container CLI controllers & digest verifier | `PASS` (`make help`, `make verify`, `bash -n`, `py_compile`) | `NOT_RUN` for Docker targets |
| `docker/Dockerfile`, `docker/requirements.txt` | Candidate native `linux/arm64` `sim` & `full` stages | `PASS` (static/hygiene review only) | `NOT_RUN` (`make build`) |
| `docker/smoke/` | Spec-neutral `smoke_reg` & `smoke_fp32_add` (`ieee.float_pkg`) | `PASS` (`py_compile` + IEEE-754 vector check) | `NOT_RUN` (`make smoke`) |
| [../experiments/exp001/tb/conftest.py](../experiments/exp001/tb/conftest.py) | `AC1` pre/post-session `pytest` digest guard | `PASS` (`py_compile`) | `NOT_RUN` |
| `experiments/exp001/rtl/`, `experiments/exp001/reference/` | `exp001` RTL and planner golden reference | *Not created* (`M2` deferred; `G1`--`G5` open) | Pending `G1`--`G5` + `M2` |

## 2. Exact Commands to Validate the Local ARM64 Environment

Run in order from repository root on MacBook Pro M5 (candidate versions and log paths documented in [../experiments/exp001/docs/INFRASTRUCTURE.md](../experiments/exp001/docs/INFRASTRUCTURE.md)):

```bash
# Step 1: Confirm clean transfer and unmodified protected files on host
git status
make verify

# Step 2: Build native linux/arm64 toolchain image (default stage: full)
#         If synthesis apt packages fail, run `make build-sim` to unblock simulation.
make build

# Step 3: Validate VHDL-2008 + ieee.float_pkg + cocotb/pytest/NumPy simulation
make smoke-sim

# Step 4: Validate generic synthesis independently (smoke_reg, then smoke_fp32_add)
make smoke-synth

# Step 5: Inspect recorded versions, summaries, and exit codes
cat experiments/exp001/results/m1_smoke/exit_codes.log
cat experiments/exp001/results/m1_smoke/sim_summary.txt
cat experiments/exp001/results/m1_smoke/synth_summary.txt
```

*(Optional interactive shell inside container: `make shell`.)*

## 3. Outstanding Specification Gates (`G1`--`G5`)

Full gate definitions and `R1`--`R7` mappings live in [../experiments/exp001/docs/SPECIFICATION_REVIEW.md](../experiments/exp001/docs/SPECIFICATION_REVIEW.md). **Do not start `M2` RTL or oracle tests until all five gates are planner/owner-approved**:

1. **`G1`**: Protected, immutable Python golden reference module + recorded SHA-256 manifest (`AC1`).
2. **`G2`**: Exact time-domain equation (`x[0..N-1]`, `h[0..P-1]` -> `y[0..N-1]`): conjugation, reversal, padding, and crop/alignment across `N < P`, `N == P`, `N > P`.
3. **`G3`**: IEEE-754 `binary32` rounding, subnormal, `NaN`/`+/-Inf`/`-0.0`, parallel summation associativity, and comparison tolerance policy.
4. **`G4`**: Clock/reset polarity, single-transaction handshake/backpressure, coefficient loading protocol, and `AC6` cycle-count start/stop boundaries.
5. **`G5`**: Compile-time parallelism generic(s), microarchitecture, and `(N, P, PARALLELISM)` fixture matrix.

## 4. Toolchain Risks (`R-ENV-1`..`3`) and Diagnostic Procedures

Baseline risk descriptions are in [ENVIRONMENT_CAPABILITY.md](ENVIRONMENT_CAPABILITY.md). Execute these diagnostics if any step in Section 2 fails:

* **If `make build` fails**:
  * Inspect `experiments/exp001/results/m1_smoke/docker_build_full.log`.
  * Verify host Docker targets native ARM64 (`docker info --format '{{.Architecture}}'` should report `aarch64` / `arm64`).
  * If failure occurs in Stage 2 (`full` / `yosys`), run `make build-sim` immediately so `make smoke-sim` can proceed while synthesis packaging is diagnosed.
  * If `pip install` fails on candidate pins in [../docker/requirements.txt](../docker/requirements.txt), test inside `docker run --rm -it --platform linux/arm64 ubuntu:24.04 bash`, record exact compatible `aarch64` wheel versions, and propose a bounded `requirements.txt` update for approval.
* **If `make smoke-sim` fails (`R-ENV-1`)**:
  * Check `sim_summary.txt` to separate pure-GHDL failures (`sim_ghdl_*`) from `cocotb` VPI/VHPI failures (`sim_cocotb_*`).
  * Inside `make shell`, inspect `ghdl --version` (verify backend) and `cocotb-config --lib-name-path vpi ghdl`. If the default `ghdl` apt backend lacks VPI stability on `arm64`, test rebuilding with `--build-arg GHDL_APT_PKGS="ghdl ghdl-llvm"` or `"ghdl ghdl-gcc"`.
* **If `make smoke-synth` fails on `smoke_reg` (`R-ENV-2`)**:
  * Check `synth_versions.log` (`selected_synth_frontend_mode`: `plugin` vs. `ghdl-verilog`) and `synth_smoke_reg.log`.
  * Inside `make shell`, test each frontend path explicitly:
    * `SYNTH_FRONTEND_MODE=ghdl-verilog bash scripts/smoke_synth.sh`
    * `SYNTH_FRONTEND_MODE=plugin bash scripts/smoke_synth.sh`
* **If `smoke_reg` synthesizes (`PASS`) but `smoke_fp32_add` fails (`R-ENV-3`)**:
  * Inspect `synth_smoke_fp32_add.log` for unsupported `ieee.float_pkg` constructs or unresolved cells in `hierarchy -check`.
  * Preserve the log as empirical evidence and report to planner/owner before `M2`: if open-source synthesis rejects `ieee.float_pkg`, `M2` architecture (`G5`) will require vendor-independent synthesizable `binary32` RTL operator modules (`ieee.std_logic_1164` / `ieee.numeric_std` only; no third-party IP).

## 5. Resuming Work with Another LLM (Agentic or Chat-Only)

### Option A: Agentic Coding Tool (Filesystem + Terminal Access)

1. Point workspace root to `fpga_ai/` and instruct the agent:
   > *"Read `AGENTS.md`, `context/STATUS.md`, `research/STATUS.md`, `research/HANDOFF_M3.md`, `research/TODO.md`, and all `.agents/rules/*.md`. Run `make verify` and `git status` read-only. Do not modify protected files or resolve `G1`--`G5`. Propose a bounded plan for the next task in `research/TODO.md` and wait for explicit approval."*
2. Enforce one approved milestone/fix at a time, recording actual `PASS` / `FAIL` / `BLOCKED` / `NOT_RUN` outcomes and raw log paths.

### Option B: Chat-Only LLM (No Direct Repository Access)

Keep prompts compact by uploading/pasting only the minimal file set for the active step:

1. **Core Governance Pack (attach in first message)**: [../AGENTS.md](../AGENTS.md), [../context/PROJECT_DECISIONS.md](../context/PROJECT_DECISIONS.md), [../context/experiments/exp001/REQUIREMENTS.md](../context/experiments/exp001/REQUIREMENTS.md), [../context/experiments/exp001/ACCEPTANCE_CRITERIA.md](../context/experiments/exp001/ACCEPTANCE_CRITERIA.md), [HANDOFF_M3.md](HANDOFF_M3.md), and [STATUS.md](STATUS.md).
2. **Step-Specific Attachments**:
   * *Toolchain / smoke fix (`M4` Phase 1)*: Attach [../docker/Dockerfile](../docker/Dockerfile), [../scripts/smoke_sim.sh](../scripts/smoke_sim.sh) or [../scripts/smoke_synth.sh](../scripts/smoke_synth.sh), and the failing `.log` file.
   * *`M2` plan & RTL authoring*: Attach approved `G1`--`G5` contract + golden oracle + `synth_smoke_fp32_add.log` (`R-ENV-3` result) + [../experiments/exp001/tb/conftest.py](../experiments/exp001/tb/conftest.py). Request a file-level `M2` plan first; apply approved files locally and run `make verify` + container checks yourself.

## 6. Next-Session Prioritized Task Order (`2026-11-26`)

Canonical task definitions live in [TODO.md](TODO.md). Execute in this order tomorrow:

1. **`TODO-005` (`P0`, `M4` Phase 1 -- Toolchain Smoke Gate)**: Run Section 2 commands (`make verify`, `make build`, `make smoke-sim`, `make smoke-synth`), resolve `R-ENV-1`..`3`, pin verified container/pip versions, and record `AC2` evidence.
2. **`TODO-002` (`P0`, Pre-`M2` Spec Gate)**: Finalize planner/owner approval of `G1`--`G5` (incorporating `R-ENV-3` `float_pkg` synthesis findings), add protected Python golden reference, and generate its SHA-256 manifest (`AC1`).
3. **`TODO-003` (`P0`, `M2` Implementation)**: Propose bounded `M2` plan, obtain approval, and implement generic VHDL-2008 `binary32` filter RTL, `cocotb`/`pytest` test suite, and synthesis script.
4. **`TODO-007` (`P0`, `M4` Phase 2 -- `exp001` Verification & Synthesis)**: Run compilation (`AC3`), oracle numerical verification across approved fixtures (`AC1`, `AC4`), and generic synthesis (`AC5`), logging all failures and bounded fixes.
5. **`TODO-006` (`P1`, `M5` Evaluation & Expert Review Package)**: Measure transaction cycle latency and sample throughput (`AC6`), evaluate approved parallelism configurations, and assemble Amir's review package (`AC7`).
