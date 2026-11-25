---
title: "Project live status"
sub-title: "EXP001 milestone and acceptance criteria tracker"
author: "Coding agent"
date: "2026-11-25"
---

# Project Status

* **Current Milestone State**: `M0 COMPLETE` (uncommitted at M0 review gate; awaiting owner review and `M1` approval).
* **Base Git Revision**: `a373f4b` on `main`.
* **Active Environment**: GCP Ubuntu 24.04 `x86_64` container (see [ENVIRONMENT_CAPABILITY.md](ENVIRONMENT_CAPABILITY.md)).
* **Protected Files**: 35 planner-owned files verified intact (`PASS`, zero modifications).

## Acceptance Criteria Matrix (`exp001`)

Definitions follow [../context/experiments/exp001/ACCEPTANCE_CRITERIA.md](../context/experiments/exp001/ACCEPTANCE_CRITERIA.md). Criteria whose implementation/execution milestone has not yet been reached are recorded as `NOT_RUN`; criteria actively prevented by an unmet external input or current-host restriction are noted accordingly.

| ID | Criterion Summary | Target Milestone | Status | Status Basis |
| :--- | :--- | :--- | :--- | :--- |
| **AC1** | Approved contract & protected golden reference present; digest verified pre/post tests | Gate pre-`M2` / Exec `M4` | `BLOCKED` | 35 bootstrap files verified (`PASS`), but planner functional contract & Python golden oracle (`G1`--`G5`) are not yet supplied; test-time check `NOT_RUN` |
| **AC2** | Local Docker `linux/arm64` build & VHDL simulator smoke test succeed | Authored `M1` / Exec `M4` | `NOT_RUN` | `M1` files not yet authored; note that Docker execution on GCP is `BLOCKED` |
| **AC3** | RTL compiles and elaborates for approved configurations | Impl `M2` / Exec `M4` | `NOT_RUN` | `M2` and `M4` not yet reached (`M2` awaits `G1`--`G5`; `ghdl` absent on GCP) |
| **AC4** | Independent numerical comparisons pass all approved fixtures & tolerances | Impl `M2` / Exec `M4` | `NOT_RUN` | `M2` and `M4` not yet reached (`M2` awaits `G1`--`G3`, `G5`; sim/NumPy absent on GCP) |
| **AC5** | Generic synthesis succeeds without black boxes or unsynthesizable constructs | Impl `M2` / Exec `M4` | `NOT_RUN` | `M2` and `M4` not yet reached (`yosys` + VHDL frontend absent on GCP) |
| **AC6** | Measured transaction cycles and sample counts with explicit boundaries | Impl `M2` / Exec `M4`--`M5` | `NOT_RUN` | `M2` and `M4` not yet reached (awaits `G4` boundary contract and local simulation) |
| **AC7** | Code, instructions, evidence, limitations, and review handoff complete | `M3` / `M4` / `M5` | `NOT_RUN` | Handoff and evaluation milestones not yet reached |

## Active Blockers and Next Action

* **Current Gate (`M1` entry)**: Not blocked by `G1`--`G5`; awaits explicit owner/planner approval of the `M1` implementation plan.
* **Downstream Blockers**:
  1. `M2` (`Implementation`) is `BLOCKED` on planner/owner approval of specification gates `G1`--`G5` (see [../experiments/exp001/docs/SPECIFICATION_REVIEW.md](../experiments/exp001/docs/SPECIFICATION_REVIEW.md)).
  2. Container build, HDL simulation, numerical co-simulation, and synthesis execution are `BLOCKED` on GCP and deferred to `M4` local ARM64 execution.
* **Prioritized Backlog**: Tracked in [TODO.md](TODO.md).
