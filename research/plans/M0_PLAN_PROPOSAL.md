---
title: "EXP001 Milestone M0 implementation plan proposal"
sub-title: "Bootstrap plan, GCP capability report, traceability, and blockers"
author: "Coding agent"
date: "2026-11-25"
---

# EXP001 Milestone M0 Implementation Plan Proposal

This document is submitted by the coding agent for review and explicit approval by the project owner and planning assistant before executing Milestone `M0` (`Bootstrap`), in accordance with [AGENTS.md](../../AGENTS.md), [context/experiments/exp001/IMPLEMENTATION_PLAN.md](../../context/experiments/exp001/IMPLEMENTATION_PLAN.md), and [.agents/rules/plan_and_approval_workflow.md](../../.agents/rules/plan_and_approval_workflow.md).

---

## 1. Current Repository Baseline

* **Workspace Path**: `/workspace/projects/fpga_ai`
* **Git Branch and Base Revision**: `main` at root commit `a373f4b` (`chore: bootstrap fpga_ai context, rules, README, and .gitignore`)
* **Tracked Baseline Files**: 37 files total:
  * 35 protected planner-owned bootstrap files ([AGENTS.md](../../AGENTS.md), [START_PROMPT.md](../../START_PROMPT.md), `.agents/**`, `context/**`) -- verified unmodified via SHA-256 digest (`0` edits).
  * 2 owner-approved bootstrap root files: [README.md](../../README.md) and [.gitignore](../../.gitignore).
* **Coding Agent Model**: Gemini 4 Carbon (High) running in Antigravity on GCP sandboxed Linux (`x86_64`).
* **Project Execution State**: `M0 PROPOSED` (awaiting owner/planner approval; no RTL, Dockerfile, test harness, simulation, or synthesis has been authored or executed).

---

## 2. Environment Capability Report (GCP Sandbox -- Observed Read-Only)

All capability data below was collected strictly via read-only commands per [context/DEVELOPMENT_ENVIRONMENTS.md](../../context/DEVELOPMENT_ENVIRONMENTS.md) and [.agents/rules/system_environments_and_deployment_workflow.md](../../.agents/rules/system_environments_and_deployment_workflow.md).

### 2.1 Host Comparison (Today vs. Tomorrow)

| Property | GCP Authoring Environment (2026-11-25) | Local Execution Environment (2026-11-26) |
| :--- | :--- | :--- |
| **Role** | Plan, scaffold, author portable code/docs, run static/stdlib checks | Build ARM64 container, run smoke checks, simulate, verify, synthesize |
| **OS / Kernel** | Ubuntu 24.04 container (`Linux 6.12.114+`, `glibc 2.39`) | macOS host (MacBook Pro M5, 16 GiB RAM) running Docker Linux |
| **CPU Architecture** | `x86_64` | `linux/arm64` (`aarch64`) |
| **Docker Execution** | **Unavailable and prohibited** (`BLOCKED`) | Required (`docker build --platform linux/arm64`) |
| **Package Installation** | **Prohibited** (read-only probing only) | Permitted inside reproducible `Dockerfile` |

### 2.2 Observed GCP Tool and Python Package Matrix

| Category | Observed `PRESENT` (with version) | Observed `ABSENT` / Unavailable |
| :--- | :--- | :--- |
| **Core / VCS / Shell** | `bash 5.2.21`, `git 2.43.0`, `jq 1.7`, `sha256sum`, `tar`, `zip` | -- |
| **Build / C and C++** | `make 4.3`, `cmake 3.28.3`, `gcc 13.3.0`, `clang 18.1.3` | -- |
| **Python Runtime** | `python3 3.12.3` (stdlib + `PyYAML 6.0.1`), `pip3`, `uv 0.13.10` *(installs prohibited)* | `numpy`, `scipy`, `pytest`, `cocotb`, `cocotb-bus`, `cocotb-test`, `jsonschema` |
| **Python Static Linters** | `python3 -m py_compile`, `ast` (stdlib) | `ruff`, `flake8`, `mypy`, `black` |
| **Containers** | `/usr/bin/docker` CLI client binary on `PATH` *(daemon/execution prohibited)* | Docker daemon / build / run (`BLOCKED` on GCP), `podman` |
| **HDL Sim and Synthesis** | *None* | `ghdl`, `nvc`, `iverilog`, `verilator`, `yosys`, `vivado`, `quartus` |

### 2.3 Practical Verification Split

* **Runnable on GCP (M0--M3, within approved scope)**:
  * SHA-256 digest verification of all protected files and future golden reference files (`sha256sum`, Python `hashlib`).
  * Markdown YAML frontmatter, pure-ASCII compliance, and repo-relative link resolution checks (`python3` + `PyYAML`).
  * Shell script syntax validation (`bash -n`) and Python 3.12 syntax/stdlib unit tests (`python3 -m py_compile`, `unittest`, `struct` binary32 helpers).
  * Static structural/coding-rule checks on authored VHDL-2008 and Dockerfile sources (clearly labeled as *static review checks*, never compilation or synthesis).
* **Blocked on GCP until Local ARM64 Execution (`M4`)**:
  * Docker `linux/arm64` image build and package version pinning (`AC2`).
  * VHDL-2008 analysis, elaboration, and cycle-accurate simulation via `ghdl` (`AC2`, `AC3`, `AC6`).
  * Co-simulation numerical verification against the approved Python oracle via `cocotb` + `pytest` + `numpy` (`AC4`).
  * Generic RTL synthesis and cell/black-box inspection via `yosys` + VHDL-2008 frontend (`AC5`).

---

## 3. Scope Boundaries and Governance

1. **Protected / Planner-Owned Paths (Zero Edits Without Separate Explicit Approval)** per [.agents/rules/code_ownership.md](../../.agents/rules/code_ownership.md):
   * [AGENTS.md](../../AGENTS.md)
   * [START_PROMPT.md](../../START_PROMPT.md)
   * `.agents/**` (all rules, skills, and workflows)
   * `context/**` (all project decisions, vision, environments, methodology, reuse manifest, [context/STATUS.md](../../context/STATUS.md), and `context/experiments/exp001/**`)
   * Future planner-approved functional contract and Python golden reference files (`AC1`).
2. **Execution and Portability Rules**:
   * Work strictly one approved milestone at a time; stop at every milestone gate with diffs, observed evidence, unresolved blockers, and the next milestone plan.
   * No autonomous `git commit` or `git push` without explicit owner command ([.agents/rules/agent_permissions_and_scope.md](../../.agents/rules/agent_permissions_and_scope.md)).
   * No package installations, privilege escalation, Docker execution, external credentials, or sandbox workarounds on GCP.
   * Public synthetic generic DSP material only; zero internal endpoints, corporate registry URLs, operational parameters, or secrets in repository files (`R6`, `R7`).
   * Honest verification states (`PASS` / `FAIL` / `BLOCKED` / `NOT_RUN`) backed by observed logs; no fabricated outcomes, hardware timing/Fmax claims, or unsupported professional parity claims ([.agents/rules/verification.md](../../.agents/rules/verification.md), [.agents/rules/research_integrity.md](../../.agents/rules/research_integrity.md)).

---

## 4. Requirement-to-Acceptance Traceability and Baseline Status

Per [.agents/skills/specification_review/SKILL.md](../../.agents/skills/specification_review/SKILL.md), each requirement in [context/experiments/exp001/REQUIREMENTS.md](../../context/experiments/exp001/REQUIREMENTS.md) is traced to [context/experiments/exp001/ACCEPTANCE_CRITERIA.md](../../context/experiments/exp001/ACCEPTANCE_CRITERIA.md):

| Req | Summary | Mapped Criteria | Verification Method | Current Status | Blocker / Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **R1** | Equal input/output length `N`, reference length `P` (`N, P > 0` generics), single transaction in V1 | `AC1`, `AC3`, `AC4`, `AC6` | Elaboration across `(N, P)` fixtures; shape/length check; transaction cycle count | `BLOCKED` | Open contract gate (crop/alignment so `len(y) == N`, handshake protocol, fixtures); no `ghdl` on GCP |
| **R2** | Complex samples as two IEEE-754 `binary32` values; `binary32` arithmetic | `AC1`, `AC3`, `AC4`, `AC5` | Bit/float comparison vs. Python oracle under approved rounding/special-value/tolerance policy; synthesis check | `BLOCKED` | Numerical policy (rounding, subnormals, `NaN`/`Inf`/`-0.0`, tolerances) pending planner approval; no sim/syn tools on GCP |
| **R3** | Direct time-domain linear filtering (no FFT); external coeff prep; unambiguous conj/reversal/pad/crop in independent oracle | `AC1`, `AC4` | Protected Python golden reference SHA-256 check before/after `cocotb`/`pytest` test suite | `BLOCKED` | Independent Python golden reference and mathematical definition pending planner approval |
| **R4** | Vendor-independent VHDL-2008; standard IEEE packages only; no third-party IP | `AC3`, `AC5`, `AC7` | Static source audit + `ghdl --std=08` compile/elaborate + generic `yosys` synthesis without black boxes | `BLOCKED` | Blocked on M2 spec gate and local ARM64 `ghdl`/`yosys` toolchain |
| **R5** | Compile-time configurable computational parallelism | `AC3`, `AC4`, `AC5`, `AC6` | Multi-configuration elaboration, numerical equivalence, resource/cycle scaling across parallelism settings | `BLOCKED` | Parallelism architecture, generic parameter contract, and physical transfer interface pending planner approval |
| **R6** | Reproducible Docker `linux/arm64` environment, automated tests, documented execution | `AC2`, `AC7` | Local ARM64 `docker build`, simulator/Python/synthesis smoke test, end-to-end scripted test run | `BLOCKED` | M1 files not yet authored; Docker unavailable on GCP (runs locally in M4 on 2026-11-26) |
| **R7** | No application-specific operational parameters, internal code, datasets, or hardware interfaces | `AC1`, `AC7` | Static repository audit + diff review at every milestone gate | `NOT_RUN` | Enforced continuously; formal release validation check at M3/M5 |

### Baseline Acceptance Criteria Rollup (`M0 Pre-Execution`)

* **AC1**: `BLOCKED` -- 35 protected bootstrap files hashed; planner-approved functional contract and Python golden reference not yet supplied.
* **AC2**: `BLOCKED` -- Docker unavailable on GCP; M1 container/smoke-test definitions pending M1 approval and M4 local ARM64 execution.
* **AC3**: `BLOCKED` -- Pending pre-M2 specification approval and local `ghdl` toolchain.
* **AC4**: `BLOCKED` -- Pending golden oracle, numerical tolerances, special-value policy, and local `ghdl`/`cocotb`/`pytest`/`numpy`.
* **AC5**: `BLOCKED` -- Pending M2 RTL and local `yosys` + VHDL-2008 synthesis frontend.
* **AC6**: `BLOCKED` -- Pending approved transaction boundary contract and local cycle-accurate simulation.
* **AC7**: `NOT_RUN` -- Scheduled across M3 (GCP handoff today) and M4/M5 (local execution and evaluation tomorrow).

---

## 5. Proposed Portable Repository Directory Tree (M0--M5 Target)

```text
fpga_ai/
|-- AGENTS.md                                     # [Protected] Agent entry point
|-- START_PROMPT.md                               # [Protected] Initial session prompt
|-- README.md                                     # [M0] Portable repo overview, directory map & workflow
|-- .gitignore                                    # [M0] Portable ignores (sim_build/, .env*, .DS_Store, etc.)
|-- .agents/                                      # [Protected] Rules, skills, workflows
|-- context/                                      # [Protected] Vision, decisions, specs, initial status
|-- docker/                                       # [M1] Portable Linux ARM64 Dockerfile & smoke tests
|-- scripts/                                      # [M1] Portable container/test/synthesis runner & digest scripts
|-- experiments/
|   `-- exp001/
|       |-- docs/
|       |   `-- SPECIFICATION_REVIEW.md           # [M0] R1-R7 -> AC1-AC7 trace, open gates & dependencies
|       |-- reference/                            # [Pre-M2 Gate] Planner-owned immutable Python golden oracle
|       |-- rtl/                                  # [M2] Synthesizable vendor-independent VHDL-2008 RTL
|       |-- tb/                                   # [M1/M2] VHDL testbench & cocotb/pytest harness
|       |-- syn/                                  # [M1/M2/M4] Generic synthesis scripts (Yosys + VHDL frontend)
|       `-- results/                              # [M4/M5] Raw simulation, synthesis & cycle-count evidence
`-- research/                                     # [M0-M5] Durable engineering & research records
    |-- STATUS.md                                 # [M0] Live milestone state, AC1-AC7 matrix & blockers
    |-- ENVIRONMENT_CAPABILITY.md                 # [M0] Observed GCP probe + 35-file SHA-256 baseline manifest
    |-- TODO.md                                   # [M0] Prioritized backlog (TODO-001.., P0/P1/P2)
    |-- plans/
    |   `-- M0_PLAN_PROPOSAL.md                   # [M0] This milestone plan proposal
    |-- daily_notes/
    |   `-- 2026-11-25.md                         # [M0] Chronological engineering session log
    |-- changelog/
    |   `-- log_YYYYMMDD_HHMMSS.md                # [M0] Milestone M0 changelog anchored to commit a373f4b
    `-- lessons_learned/                          # [M4+] Evidence-backed transferable lessons (when observed)
```

---

## 6. Bounded M0 File-Level Implementation Plan

Upon explicit approval of M0, the coding agent will execute **only** the following file operations inside `/workspace/projects/fpga_ai`:

| Action | Repo-Relative Path | Purpose and Content Summary |
| :--- | :--- | :--- |
| **UPDATE** | [README.md](../../README.md) | Add the approved directory layout map and repo-relative links to `research/STATUS.md`, `research/ENVIRONMENT_CAPABILITY.md`, and `experiments/exp001/docs/SPECIFICATION_REVIEW.md`. |
| **CREATE** | `research/STATUS.md` | Live session/milestone status (`M0 COMPLETE` at gate), `AC1`--`AC7` table (`BLOCKED`/`NOT_RUN`), active blockers, and readiness for M1 plan proposal. |
| **CREATE** | `research/ENVIRONMENT_CAPABILITY.md` | Complete read-only GCP tool/package report, ARM64 portability constraints, and full 35-file SHA-256 digest manifest of protected files. |
| **CREATE** | `experiments/exp001/docs/SPECIFICATION_REVIEW.md` | Detailed `R1`--`R7` -> `AC1`--`AC7` traceability matrix, ambiguity inventory, open specification gate checklist, and M0->M5 dependency chain. |
| **CREATE** | `research/TODO.md` | Prioritized backlog (`TODO-001` through `TODO-006`, `P0`/`P1`/`P2`) with affected paths, acceptance criteria, and blockers per [.agents/skills/todo-tracking/SKILL.md](../../.agents/skills/todo-tracking/SKILL.md). |
| **CREATE** | `research/daily_notes/2026-11-25.md` | Concise chronological engineering note recording environment, model, observed checks, interventions, and M0 summary per [.agents/skills/daily-notes/SKILL.md](../../.agents/skills/daily-notes/SKILL.md). |
| **CREATE** | `research/changelog/log_YYYYMMDD_HHMMSS.md` | Milestone M0 changelog referencing base commit `a373f4b`, file diffs, verification outputs, and open items per [.agents/skills/changelog-logging/SKILL.md](../../.agents/skills/changelog-logging/SKILL.md). |
| **UPDATE** | `research/plans/M0_PLAN_PROPOSAL.md` | Record owner/planner approval timestamp and decisions in Section 8. |

### 6.1 M0 Verification Checks (Executed on GCP)

1. **Protected File Integrity (`safe-editing`)**: Verify SHA-256 digests of all 35 protected files match the root commit `a373f4b` (`git diff a373f4b -- AGENTS.md START_PROMPT.md .agents context` must be empty).
2. **Document Metadata, ASCII, and Link Check**: Run a Python 3.12 + `PyYAML` check across all created/updated `.md` files verifying:
   * Required YAML frontmatter keys (`title`, `sub-title`, `author`, `date`) are non-empty.
   * Pure ASCII characters (`ord(c) < 128`).
   * All markdown links are repo-relative and resolve to existing files on disk.
   * Zero corporate/internal URLs, hostnames, or credentials appear anywhere in repository files.
3. **Git Working Tree Inspection**: Run `git status` and `git diff --stat` (no `git commit` unless explicitly instructed).

### 6.2 Fallback Plan

If any protected file digest mismatches or any metadata/link validation fails, halt immediately, report the exact discrepancy, and restore/fix only the agent-owned M0 file within approved scope.

---

## 7. Downstream Blockers and Risks Flagged for Planner Review

### 7.1 Open Specification Gates Required Before `M2` (`Implementation`)

While `M0` (`Bootstrap`) and `M1` (`Infrastructure`) can proceed today on GCP, **`M2` is strictly blocked** until the planner and owner supply and approve the following five items ([context/PROJECT_DECISIONS.md](../../context/PROJECT_DECISIONS.md), [context/experiments/exp001/REQUIREMENTS.md](../../context/experiments/exp001/REQUIREMENTS.md)):

1. **Protected Python Golden Reference (`R3`, `AC1`, Decision 9)**:
   * Independent immutable Python module placed under `experiments/exp001/reference/` (or planner-designated protected path) with documented function signature and SHA-256 digest.
2. **Exact Mathematical Filtering Contract (`R1`, `R3`, Decision 8)**:
   * Explicit equation defining how input `x[0..N-1]` (`complex64` / two `binary32` values) and reference `h[0..P-1]` produce output `y[0..N-1]` of equal length `N`:
     * Correlation vs. convolution.
     * Conjugation (`h*` vs. `h`) and index reversal (`h[k]` vs. `h[P-1-k]`).
     * Boundary zero-padding and output crop/alignment indices (e.g., causal `y[n] = sum_{k=0}^{P-1} ...`, `same`, or `valid` with explicit padding) including behavior when `N < P`, `N == P`, and `N > P`.
3. **IEEE-754 `binary32` Numerical Policy (`R2`, `AC4`, Decision 7)**:
   * Rounding mode (e.g., round-to-nearest-even).
   * Subnormal/denormal policy (IEEE gradual underflow vs. flush-to-zero).
   * Exceptional-value policy (`NaN`, `+/-Inf`, `-0.0` inputs/intermediates, or restricted finite-domain input contract with explicit bounds).
   * Permitted floating-point summation/accumulation order across parallel lanes (`PARALLELISM > 1` changes non-associative `binary32` addition order unless fixed or accounted for in tolerance).
   * Exact pass/fail numerical comparison tolerances (absolute/relative/ULP) for `AC4`.
4. **Physical Transaction and Handshake Interface (`R1`, `R5`, `AC6`, Decision 4)**:
   * Clock and synchronous/asynchronous reset polarity.
   * Port list, signal widths/types, single-transaction packet framing, `valid`/`ready` backpressure rules, and how `P` reference coefficients are supplied (dedicated load phase, parallel port, or transaction header).
   * Exact start-cycle and end-cycle event definitions for `AC6` latency and throughput measurement.
5. **Parallelism Architecture and Fixture Matrix (`R1`, `R5`, `AC3`, Decision 10)**:
   * Approved compile-time parallelism generic(s) (e.g., `G_LANES` / `G_PARALLELISM` MACs per cycle), baseline vs. parallel microarchitecture, and concrete `(N, P, PARALLELISM)` synthesis/simulation test fixtures.

### 7.2 ARM64 Toolchain Portability Risks (To Address in `M1` Design)

1. **GHDL Backend on `linux/arm64`**:
   * On Debian/Ubuntu `arm64`, `ghdl-llvm` or `ghdl-gcc` must be selected (`ghdl-mcode` is traditionally `x86`-only) and verified for VPI/VHPI compatibility with `cocotb`.
2. **Yosys VHDL-2008 + `binary32` Synthesis Path on `linux/arm64`**:
   * Open-source generic synthesis requires `yosys` paired with a VHDL-2008 frontend (`ghdl-yosys-plugin`).
   * Synthesizability of VHDL-2008 `ieee.float_pkg` operators through `ghdl` + `ghdl-yosys-plugin` is a known open-source toolchain risk; M1's smoke test should explicitly test both basic VHDL-2008 synthesis and `binary32` arithmetic synthesis feasibility on the 16 GiB MacBook Pro M5 so M2 does not rely on unsupported library constructs.

---

## 8. Approval Record and Owner / Planner Decisions

* **Status**: `APPROVED` (`2026-11-25`)
* **Approved Decisions**:
  1. **D-M0-A (M0 Scope)**: Approved. Execute the bounded M0 file-level plan in Section 6.
  2. **D-M0-B (Future Milestone Directories)**: Create future milestone directories on demand; do not create empty directories or `.gitkeep` files.
  3. **D-M0-C (Git Commit at M0 Gate)**: Leave M0 changes uncommitted for owner review.
* **Planner Clarifications Applied in Canonical M0 Outputs**:
  * Kept canonical records concise and non-overlapping across [../STATUS.md](../STATUS.md), [../ENVIRONMENT_CAPABILITY.md](../ENVIRONMENT_CAPABILITY.md), [../../experiments/exp001/docs/SPECIFICATION_REVIEW.md](../../experiments/exp001/docs/SPECIFICATION_REVIEW.md), [../TODO.md](../TODO.md), [../daily_notes/2026-11-25.md](../daily_notes/2026-11-25.md), and [../changelog/log_20261125_122300.md](../changelog/log_20261125_122300.md).
  * Distinguished `NOT_RUN` (verification milestone not yet reached) from `BLOCKED` (actively prevented by missing external input or absent host capability).
  * Framed unverified `linux/arm64` toolchain behavior strictly as risks (`R-ENV-1`..`3`) rather than established facts.
