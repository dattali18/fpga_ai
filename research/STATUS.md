---
title: "Project live status"
sub-title: "EXP001 milestone and acceptance criteria tracker"
author: "Coding agent"
date: "2026-11-25"
---

# Project Status

* **Current Milestone State**: `M1 COMPLETE` (uncommitted at M1 review gate; `M0` committed at `58be40c`; awaiting owner review and `M2`/`M3` decision).
* **Base Git Revision**: `58be40c` (`chore: complete M0 project bootstrap`) on `main`.
* **Active Environment**: GCP Ubuntu 24.04 `x86_64` container (see [ENVIRONMENT_CAPABILITY.md](ENVIRONMENT_CAPABILITY.md)).
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
| **AC7** | Code, instructions, evidence, limitations, and review handoff complete | `M3` / `M4` / `M5` | `NOT_RUN` | Handoff and evaluation milestones not yet reached |

## Active Blockers and Next Action

* **Current Gate (`M2` vs. `M3`)**:
  * **`M2` (`Implementation`) is `BLOCKED`** until planner/owner supply and approve specification gates `G1`--`G5` (see [../experiments/exp001/docs/SPECIFICATION_REVIEW.md](../experiments/exp001/docs/SPECIFICATION_REVIEW.md)).
  * If `G1`--`G5` are supplied next, propose bounded `M2` plan; otherwise proceed to `M3` (`Handoff`) upon owner approval.
* **Environment Blocker**: Container build, HDL simulation, numerical co-simulation, and synthesis execution remain `BLOCKED` on GCP and deferred to `M4` local `linux/arm64` execution.
* **Prioritized Backlog**: Tracked in [TODO.md](TODO.md).
