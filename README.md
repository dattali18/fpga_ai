---
title: "FPGA AI research repository"
sub-title: "LLM-assisted FPGA component engineering study (EXP001)"
author: "Coding agent"
date: "2026-11-25"
---

# fpga_ai

Empirical research repository studying whether an experienced software engineer aided by LLM planning and coding workflows can produce vendor-independent FPGA components comparable to professionally engineered RTL, evaluated under explicit functional, verification, and synthesis criteria.

## Current Experiment (`exp001`)

`exp001` targets a generic synthetic complex-valued IEEE-754 `binary32` direct time-domain linear DSP filter implemented in vendor-independent VHDL-2008 (`N`-sample complex input/output per transaction, `P`-tap reference vector, compile-time configurable parallelism, no third-party hardware IP).

## Key Documents

* Agent entry point: [AGENTS.md](AGENTS.md)
* Project vision: [context/PROJECT_VISION.md](context/PROJECT_VISION.md)
* Approved architectural and workflow decisions: [context/PROJECT_DECISIONS.md](context/PROJECT_DECISIONS.md)
* Execution environments (GCP authoring + local Linux ARM64 Docker): [context/DEVELOPMENT_ENVIRONMENTS.md](context/DEVELOPMENT_ENVIRONMENTS.md)
* Research methodology: [context/RESEARCH_METHODOLOGY.md](context/RESEARCH_METHODOLOGY.md)
* Initial bootstrap status: [context/STATUS.md](context/STATUS.md)
* `exp001` requirements: [context/experiments/exp001/REQUIREMENTS.md](context/experiments/exp001/REQUIREMENTS.md)
* `exp001` acceptance criteria: [context/experiments/exp001/ACCEPTANCE_CRITERIA.md](context/experiments/exp001/ACCEPTANCE_CRITERIA.md)
* `exp001` milestone plan: [context/experiments/exp001/IMPLEMENTATION_PLAN.md](context/experiments/exp001/IMPLEMENTATION_PLAN.md)

## Repository Ownership Boundaries

* Planner-owned (protected, read-only without separate explicit approval): [AGENTS.md](AGENTS.md), [START_PROMPT.md](START_PROMPT.md), `.agents/`, `context/`, and future planner-approved golden reference files.
* Milestone-gated engineering and research outputs: created incrementally under explicit milestone approval (`M0` through `M5`), with live tracking maintained under `research/`.

## Portability and Data Policy

* Public synthetic DSP inputs and vendor-independent VHDL-2008 only.
* No proprietary specifications, operational parameters, internal endpoints, or credentials.
* Designed for portable execution inside a reproducible Linux ARM64 (`linux/arm64`) Docker toolchain (GHDL, cocotb, pytest, NumPy, Yosys + VHDL frontend).
