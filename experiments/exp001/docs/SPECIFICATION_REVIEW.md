---
title: "EXP001 specification review and traceability"
sub-title: "Requirements-to-acceptance mapping, open gates, and milestone dependencies"
author: "Coding agent"
date: "2026-11-25"
---

# EXP001 Specification Review

Traces [../../../context/experiments/exp001/REQUIREMENTS.md](../../../context/experiments/exp001/REQUIREMENTS.md) (`R1`--`R7`) to [../../../context/experiments/exp001/ACCEPTANCE_CRITERIA.md](../../../context/experiments/exp001/ACCEPTANCE_CRITERIA.md) (`AC1`--`AC7`) per [../../../.agents/skills/specification_review/SKILL.md](../../../.agents/skills/specification_review/SKILL.md). No open functional, numerical, or architectural decisions are resolved here.

## 1. Requirement-to-Acceptance Traceability Matrix

Status distinguishes `NOT_RUN` (verification milestone not yet reached) from `BLOCKED` (gate cannot proceed without an external prerequisite or absent environment capability).

| Req | Requirement Scope | Mapped Criteria | Target Milestone | Verification Status | Dependencies and Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **R1** | Complex input/output length `N`, reference length `P` (`N, P > 0` generics); single transaction in V1 | `AC1`, `AC3`, `AC4`, `AC6` | Impl `M2`; Exec `M4` | `NOT_RUN` | Requires Gates `G2`, `G4`, `G5` before `M2`; simulation requires `M4` local ARM64 Docker |
| **R2** | Two IEEE-754 `binary32` values per complex sample; `binary32` arithmetic | `AC1`, `AC3`, `AC4`, `AC5` | Impl `M2`; Exec `M4` | `NOT_RUN` | Requires Gate `G3` (rounding, special values, tolerances) before `M2` |
| **R3** | Direct time-domain linear filtering (no FFT); external coeff prep; independent oracle | `AC1`, `AC4` | Gate pre-`M2`; Exec `M4` | `NOT_RUN` | `AC1` oracle presence is `BLOCKED` on Gates `G1` and `G2` from planner |
| **R4** | Vendor-independent VHDL-2008; standard IEEE packages only; no third-party IP | `AC3`, `AC5`, `AC7` | Impl `M2`; Exec `M4` | `NOT_RUN` | Subject to ARM64 synthesis frontend risk `R-ENV-3` in [../../../research/ENVIRONMENT_CAPABILITY.md](../../../research/ENVIRONMENT_CAPABILITY.md) |
| **R5** | Configurable compile-time computational parallelism | `AC3`, `AC4`, `AC5`, `AC6` | Impl `M2`; Exec `M4`/`M5` | `NOT_RUN` | Requires Gates `G4` and `G5` (parallelism contract and architecture) before `M2` |
| **R6** | Reproducible Docker `linux/arm64` environment, automated tests, documented execution | `AC2`, `AC7` | Authored `M1`/`M3`; Exec `M4` | `NOT_RUN` | `M1` authors container/harness; Docker execution on GCP is `BLOCKED` until `M4` |
| **R7** | No operational parameters, internal code, datasets, or proprietary hardware interfaces | `AC1`, `AC7` | Continuous (`M0`--`M5`) | `NOT_RUN` | Checked statically at each gate; formal release validation in `M3`/`M5` |

## 2. Open Planner Specification Gates (Blocking `M2` Only)

Per [../../../context/PROJECT_DECISIONS.md](../../../context/PROJECT_DECISIONS.md), the coding agent must not invent defaults for the items below. `M1` (`Infrastructure`) may proceed without them using generic component-independent smoke tests; `M2` (`Implementation`) is `BLOCKED` until all five gates are approved:

* **G1 -- Protected Golden Reference (`R3`, `AC1`)**: Independent, immutable Python reference module placed in a protected path with recorded SHA-256 digest.
* **G2 -- Mathematical Contract (`R1`, `R3`)**: Exact time-domain formula mapping `x[0..N-1]` and `h[0..P-1]` to `y[0..N-1]` of length `N`, including conjugation, index reversal, boundary padding, and crop/alignment across `N < P`, `N == P`, and `N > P`.
* **G3 -- Numerical Policy (`R2`, `AC4`)**: IEEE-754 `binary32` rounding mode, subnormal handling, exceptional-value policy (`NaN`, `+/-Inf`, `-0.0`), permitted summation order across parallel lanes, and pass/fail comparison tolerances.
* **G4 -- Physical Transaction Interface (`R1`, `R5`, `AC6`)**: Clock/reset semantics, port definitions, single-transaction handshake/backpressure rules, coefficient load contract, and cycle-count start/stop events.
* **G5 -- Parallelism Architecture and Fixtures (`R1`, `R5`, `AC3`)**: Approved compile-time parallelism generic(s), architectural structure, and `(N, P, PARALLELISM)` test/synthesis fixture matrix.

## 3. Milestone Dependency Chain

* `M0` (`Bootstrap`, GCP) -> `M1` (`Infrastructure` authoring, GCP; no DSP spec assumptions) -> `M3` (`Handoff`, GCP, if `G1`--`G5` remain open) **or** `M2` (`Implementation`, GCP, only after `G1`--`G5` approval) -> `M4` (`Local ARM64 Execution`) -> `M5` (`Evaluation`).
* Live milestone and acceptance status is tracked in [../../../research/STATUS.md](../../../research/STATUS.md).
