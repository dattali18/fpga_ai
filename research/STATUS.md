---
title: "Project live status"
sub-title: "EXP001 milestone and acceptance criteria tracker"
author: "Coding agent"
date: "2026-11-25"
---

## Current status (2026-11-26)

- **Milestone:** M4 CANDIDATE for planner review (D-085), run `m4_20261126T123436Z`
  ([results](../experiments/exp001/RESULTS_M4.md)); runner OVERALL FAIL on one row only
  (Part A (256,64,8) netlist did not compile, M4-TOOL-004; BLOCKED proposed). M2c ACCEPTED
  (D-079, [validation](../experiments/exp001/VALIDATION_M2C.md)). Optimisation is M6,
  after Amir's review (D-080). M2b ACCEPTED (D-074). M2a COMPLETE (D-063, `fe26c25`).
- **Workflow:** Claude Code implements, Claude chat plans and reviews, the owner approves
  and commits (D-064). exp001 testbenches are plain GHDL (D-065).
- **AC1:** PASS. Protected and oracle digests verified before and after every run through M4;
  the oracle manifest digest equals D-068.
- **AC3:** PASS for all 13 specification and edge configurations (compiled and
  elaborated; 9 synthesized, (64,16,64) and the lane edge cases simulation only).
- **AC4:** PASS for every fixture and lane count (bit exact and error bound, 39 dumps in
  M2c).
- **AC5:** generic structural synthesis PASS (0 problems; 32 tri-state warnings per
  lane, CA-OBS-001, explained in D-084, not fixed). Series 7 mapping (M4, Yosys
  `synth_xilinx` without `share`, likely upper bounds): 8/8 PASS, 0 problems; LUTRAM, no
  BRAM; 8 DSP48E1 and about 8000 logic LUTs per lane. Not Vivado, not placed.
- **AC6:** cycles measured for all configurations; equal to the closed form
  `2*N_RG + ceil(N_RG/L)*(P+L-1)` (D-076), in RTL and (M4) in the generic netlist for
  5 fixtures up to L = 4. Simulation cycles only; no timing.
- **Post-synthesis:** generic GHDL netlist simulation with N1/N2 rewrites
  (M4-TOOL-002/003) bit exact for 5 of 6 fixtures; mapped netlist simulation BLOCKED
  (no Verilog simulator); equivalence NOT_RUN.
- **AC7:** NOT_RUN (review package M5).
- **Defects:** M2A-DEFECT-001 (D-066); DPC-DEFECT-001 (runner memory metric, fixed,
  D-073); DPC-DEFECT-002 (partly written window array, fixed, D-078). Tool limits:
  M4-TOOL-001 to M4-TOOL-004 (D-081 to D-085).
- The tables and sections below are a historical M3 snapshot of 2026-11-25 plus dated
  updates; this block supersedes them (D-067).

# Project Status

* **Current Milestone State**: `M3 COMPLETE (GCP HANDOFF)` (uncommitted above `4647b70`; `M0` committed at `58be40c`, `M1` committed at `4647b70`; `M2` deferred to 2026-11-26 local ARM64 session pending `G1`--`G5`).
* **Base Git Revision**: `4647b70` (`chore: complete M1 development infrastructure`) on `main`.
* **Active Environment**: GCP Ubuntu 24.04 `x86_64` container (see [ENVIRONMENT_CAPABILITY.md](ENVIRONMENT_CAPABILITY.md)); ready for export to local MacBook Pro M5 (`linux/arm64`) per [HANDOFF_M3.md](HANDOFF_M3.md).
* **Protected Files**: 35 planner-owned files verified intact via `make verify` (`PASS`, zero modifications).

## Acceptance Criteria Matrix (`exp001`)

Definitions follow [../context/experiments/exp001/ACCEPTANCE_CRITERIA.md](../context/experiments/exp001/ACCEPTANCE_CRITERIA.md). Criteria whose implementation/execution milestone has not yet been reached are recorded as `NOT_RUN`; criteria actively prevented by an unmet external input or current-host restriction are noted accordingly.

| ID | Criterion Summary | Target Milestone | Status | Status Basis |
| :--- | :--- | :--- | :--- | :--- |
| **AC1** | Approved contract & protected golden reference present; digest verified pre/post tests | Gate pre-`M2` / Exec `M4` | `BLOCKED` | 35 bootstrap files verified (`PASS`) & `conftest.py` hook ready, but planner contract & golden oracle (`G1`--`G5`) are not yet supplied |
| **AC2** | Local Docker `linux/arm64` build & VHDL simulator smoke test succeed | Authored `M1` / Exec `M4` | `NOT_RUN` | `M1` container & smoke suite (`smoke_reg`, `smoke_fp32_add`) authored and static-checked on GCP; execution is `BLOCKED` on GCP and scheduled for `M4` (see [../experiments/exp001/docs/INFRASTRUCTURE.md](../experiments/exp001/docs/INFRASTRUCTURE.md)) |
| **AC3** | RTL compiles and elaborates for approved configurations | Impl `M2` / Exec `M4` | `NOT_RUN` | `M2` and `M4` not yet reached (`M2` awaits `G1`--`G5`; `ghdl` absent on GCP) |
| **AC4** | Independent numerical comparisons pass all approved fixtures & tolerances | Impl `M2` / Exec `M4` | `NOT_RUN` | `M2` and `M4` not yet reached (`M2` awaits `G1`--`G3`, `G5`; sim/NumPy absent on GCP) |
| **AC5** | Generic synthesis succeeds without black boxes or unsynthesizable constructs | Impl `M2` / Exec `M4` | `NOT_RUN` | `M2` and `M4` not yet reached (`yosys` + VHDL frontend absent on GCP) |
| **AC6** | Measured transaction cycles and sample counts with explicit boundaries | Impl `M2` / Exec `M4`--`M5` | `NOT_RUN` | `M2` and `M4` not yet reached (awaits `G4` boundary contract and local simulation) |
| **AC7** | Code, instructions, evidence, limitations, and review handoff complete | `M3` / `M4` / `M5` | `NOT_RUN` | `M3` GCP-to-local handoff prepared ([HANDOFF_M3.md](HANDOFF_M3.md)); final `exp001` code, evidence, and expert review package await `M2`/`M4`/`M5` |

## Active Blockers and Next Action

* **Immediate Next Action (`2026-11-26` Local Session)**: Follow [HANDOFF_M3.md](HANDOFF_M3.md) -- run `M4` Phase 1 (`make verify`, `make build`, `make smoke-sim`, `make smoke-synth`) on MacBook Pro M5, resolve `R-ENV-1`..`3`, and supply approved `G1`--`G5` before starting `M2`.
* **Hard `M2` Blocker**: `M2` (`Implementation`) remains `BLOCKED` until planner/owner approve `G1`--`G5` ([../experiments/exp001/docs/SPECIFICATION_REVIEW.md](../experiments/exp001/docs/SPECIFICATION_REVIEW.md)).
* **Prioritized Backlog**: Tracked in [TODO.md](TODO.md).


## 2026-11-26 - M1 local validation

M1 local infrastructure validation: COMPLETE (individual simulation and structural synthesis smoke suites passed after two fixes). See [M1 local validation](M1_LOCAL_VALIDATION.md). AC2 infrastructure smoke evidence is available; full experimental acceptance, post-synthesis equivalence and physical mapping are not established. This does not complete M2 or M4. Existing specification gates remain unchanged.

## 2026-11-26 - Educational complex arithmetic

edu_complex_add and edu_complex_mul (binary32) ACCEPTED within simulation and generic structural synthesis scope (D-059). See [validation](../experiments/edu_complex_arithmetic/VALIDATION.md). Claude now acts as planner and coder (D-055). exp001 gates G1-G5 remain open; next proposed step is a plain-language G1-G5 specification proposal for the DPC component.

## 2026-11-26 - EXP001 M2a

DPC specification approved (D-060, D-061): [specification](../experiments/exp001/docs/DPC_SPECIFICATION.md). Golden reference frozen and self-tested in the container (D-062, D-063). AC1: contract approved and reference present with digest; before/after digest checks around RTL tests start in M2b. AC3-AC7 NOT_RUN. Next: M2b plan (RTL with G_LANES = 1).
