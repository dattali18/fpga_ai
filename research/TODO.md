---
title: "Prioritized engineering backlog"
sub-title: "EXP001 milestone tasks and blockers"
author: "Coding agent"
date: "2026-11-25"
---

# Prioritized Backlog (`TODO`)

Maintained per [../.agents/skills/todo-tracking/SKILL.md](../.agents/skills/todo-tracking/SKILL.md). Details on gates `G1`--`G5` live in [../experiments/exp001/docs/SPECIFICATION_REVIEW.md](../experiments/exp001/docs/SPECIFICATION_REVIEW.md); environment risks `R-ENV-1`..`3` live in [ENVIRONMENT_CAPABILITY.md](ENVIRONMENT_CAPABILITY.md).

| ID | Pri | Milestone | Status | Affected Paths | Summary and Acceptance Check | Blocker |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `TODO-001` | `P0` | `M1` | `DONE` (GCP) | `Makefile`, `docker/`, `scripts/`, `experiments/exp001/tb/`, `experiments/exp001/docs/INFRASTRUCTURE.md` | Authored native `linux/arm64` multi-stage `Dockerfile`, `Makefile`, runner/digest scripts, and independent `smoke_reg` + `smoke_fp32_add` (`ieee.float_pkg`) sim/synth smoke tests; GCP checks `PASS` | Local execution deferred to `TODO-005` (`M4`) |
| `TODO-002` | `P0` | Pre-`M2` | `BLOCKED` | `experiments/exp001/reference/`, `context/experiments/exp001/` | Obtain planner-approved Python golden oracle and contract gates `G1`--`G5`; record protected SHA-256 digest (`AC1`) | External planner/owner deliverable |
| `TODO-003` | `P0` | `M2` | `NOT_STARTED` | `experiments/exp001/rtl/`, `experiments/exp001/tb/`, `experiments/exp001/syn/` | Propose and implement approved generic VHDL-2008 binary32 filter RTL, cocotb/pytest tests, and synthesis scripts | `TODO-002` (`G1`--`G5`) + `M2` plan approval |
| `TODO-004` | `P1` | `M3` | `NOT_STARTED` | `README.md`, `research/STATUS.md`, `experiments/exp001/docs/` | Prepare GCP-to-local ARM64 handoff guide, exact local command checklist, and verified status audit (`AC7` partial) | Completion of approved GCP milestones (`M1` and, if unblocked, `M2`) |
| `TODO-005` | `P0` | `M4` | `NOT_STARTED` | `docker/`, `experiments/exp001/results/`, `research/` | Build `linux/arm64` image on M5 host, resolve `R-ENV-1`..`3`, pin tool versions, and run smoke/RTL/synthesis checks (`AC2`--`AC5`) | Requires local MacBook Pro M5 Docker environment (2026-11-26) |
| `TODO-006` | `P1` | `M5` | `NOT_STARTED` | `experiments/exp001/results/`, `research/` | Measure cycle/throughput/resource metrics across approved parallelism configs and assemble expert review package (`AC6`, `AC7`) | `TODO-005` correctness baseline |
