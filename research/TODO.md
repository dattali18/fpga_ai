---
title: "Prioritized engineering backlog"
sub-title: "EXP001 milestone tasks and blockers"
author: "Coding agent"
date: "2026-11-25"
---

## Current status (2026-11-26)

- `TODO-002` (golden reference and G1-G5): **DONE** in M2a (D-060 to D-063).
- `TODO-003` (M2 RTL): **SUPERSEDED** by M2b
  ([M2B_PROMPT.md](../experiments/exp001/prompts/M2B_PROMPT.md)), with plain GHDL
  testbenches instead of cocotb/pytest (D-065).
- `TODO-005` (local Docker smoke): done in the M1 local validation.
- Next: M2b plan approval, then M2b implementation; then M2c (`G_LANES > 1`), Series 7
  mapping and the review document for Amir.
- The table below is a historical M3 snapshot of 2026-11-25 (D-067); later dated
  sections remain valid.

# Prioritized Backlog (`TODO`)

Maintained per [../.agents/skills/todo-tracking/SKILL.md](../.agents/skills/todo-tracking/SKILL.md). Details on gates `G1`--`G5` live in [../experiments/exp001/docs/SPECIFICATION_REVIEW.md](../experiments/exp001/docs/SPECIFICATION_REVIEW.md); environment risks `R-ENV-1`..`3` live in [ENVIRONMENT_CAPABILITY.md](ENVIRONMENT_CAPABILITY.md).

| ID | Pri | Milestone | Status | Affected Paths | Summary and Acceptance Check | Blocker |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `TODO-001` | `P0` | `M1` | `DONE` (GCP) | `Makefile`, `docker/`, `scripts/`, `experiments/exp001/tb/`, `experiments/exp001/docs/INFRASTRUCTURE.md` | Authored native `linux/arm64` multi-stage `Dockerfile`, `Makefile`, runner/digest scripts, and independent `smoke_reg` + `smoke_fp32_add` (`ieee.float_pkg`) sim/synth smoke tests (`4647b70`) | Local execution tracked in `TODO-005` |
| `TODO-004` | `P1` | `M3` | `DONE` (GCP) | `research/HANDOFF_M3.md`, `research/STATUS.md`, `research/TODO.md`, `README.md` | Prepared bounded GCP-to-local ARM64 handoff, validation runbook, `R-ENV-1`..`3` diagnostics, and LLM resume instructions | Pending owner review/commit |
| `TODO-005` | `P0` | `M4` (Ph.1) | `READY` (Local) | `docker/`, `experiments/exp001/results/m1_smoke/`, `research/` | Run `make build`, `make smoke-sim`, and `make smoke-synth` on MacBook Pro M5 (`linux/arm64`); resolve `R-ENV-1`..`3` and pin verified versions (`AC2`) | Requires local M5 Docker host (2026-11-26) |
| `TODO-002` | `P0` | Pre-`M2` | `BLOCKED` | `experiments/exp001/reference/`, `context/experiments/exp001/` | Supply planner-approved Python golden oracle and contract gates `G1`--`G5` (informed by `R-ENV-3` smoke result); record `AC1` SHA-256 manifest | External planner/owner deliverable |
| `TODO-003` | `P0` | `M2` | `DEFERRED` | `experiments/exp001/rtl/`, `experiments/exp001/tb/`, `experiments/exp001/syn/` | Propose bounded `M2` plan, obtain approval, and implement generic VHDL-2008 `binary32` filter RTL, `cocotb`/`pytest` tests, and synthesis script | `TODO-002` (`G1`--`G5`) + `M2` plan approval |
| `TODO-007` | `P0` | `M4` (Ph.2) | `NOT_STARTED` | `experiments/exp001/results/`, `research/` | Compile `exp001` RTL (`AC3`), run protected-oracle numerical verification across fixtures (`AC1`, `AC4`), and run generic synthesis (`AC5`) | `TODO-005` + `TODO-003` |
| `TODO-006` | `P1` | `M5` | `NOT_STARTED` | `experiments/exp001/results/`, `research/` | Measure cycle/throughput/resource metrics across approved parallelism configs and assemble Amir's expert review package (`AC6`, `AC7`) | `TODO-007` correctness baseline |


## 2026-11-26 - M1 local validation

- [ ] Verify post-synthesis numerical equivalence and investigate the four tri-state warnings before claiming arithmetic netlist correctness.
- [ ] Validate binary32 multiplication independently if required by a future approved generic arithmetic experiment.
- [ ] Move container pytest temporary build artifacts into the project results tree.
- [ ] Review proposed reusable skill updates separately; do not edit protected files without approval.
- [ ] Review infrastructure changes and commit explicitly if approved.

## 2026-11-26 - Educational complex arithmetic

- [ ] Explain the tri-state warnings from the generated Verilog (CA-OBS-001).
- [ ] Fix the warning count in experiments/edu_complex_arithmetic/tb/run_ghdl.sh (CA-DEFECT-001).
- [ ] Post-synthesis equivalence for the complex arithmetic blocks before reuse claims.
- [ ] Propose exp001 G1-G5 specification for the DPC component and obtain approval.

## 2026-11-26 - EXP001 M2a

- [ ] M2b: plan, then RTL with G_LANES = 1, testbench with output dump, runner (edge and baseline fixtures).
- [ ] M2c: G_LANES > 1 and cycle measurements.
- [ ] Series 7 mapping and review document for Amir.
