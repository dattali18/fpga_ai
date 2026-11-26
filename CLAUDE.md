# CLAUDE.md - fpga_ai project memory for Claude Code

Read this file completely at the start of every session. It complements, and never
overrides, `AGENTS.md`, `.agents/rules/*.md` and `context/`.

## 1. What this project is

Research question (`context/PROJECT_VISION.md`): can an experienced software
engineer **without FPGA training**, aided by LLM planning and coding, produce FPGA
components comparable to professionally engineered ones?

- Current experiment `exp001`: a **digital pulse compression (DPC)** component in
  vendor-independent VHDL-2008.
- Input: `N_RG` complex binary32 samples plus a pulse reference of `P` samples.
- Output: `N_RG` compressed samples:
  `y[n] = sum_{k=0}^{P-1} conj(r[k]) * x[n+k]`, with `x[m] = 0` for `m >= N_RG`.
- The deliverable is the VHDL component plus a review document for **Amir**, the
  senior FPGA engineer and the project's point of contact.
- All data are synthetic and public. Nothing operational or proprietary may enter
  this repository.
- **There is no FPGA device.** Evidence is limited to:
  - simulation;
  - generic synthesis;
  - Xilinx Series 7 resource mapping in Docker.
- Never claim Fmax, timing, power or on-hardware behaviour.

## 2. Roles (D-064, which supersedes the coder part of D-055)

| Who | Role |
|---|---|
| Daniel (owner) | Requirements, approvals, Git commits/pushes. **Not an FPGA engineer**: explain hardware terms in plain language |
| Claude chat (planner, reviewer) | Specifications, milestone prompts, review of reported results. Delivers prompts through Daniel |
| Claude Code (you) | Implementation: RTL, testbenches, scripts, running the toolchain, evidence, research records |
| Docker toolchain | Verification authority. Only tool output counts as evidence |
| Amir | Final professional review |

You do not change requirements, the approved specification or the golden reference.
If a milestone prompt is ambiguous or conflicts with the specification, stop and ask.

## 3. Read first, in this order

1. `AGENTS.md`, `.agents/rules/*.md`, `.agents/workflows/*.md`
2. `context/PROJECT_DECISIONS.md`, `context/PROJECT_VISION.md`,
   `context/DEVELOPMENT_ENVIRONMENTS.md`,
   `context/experiments/exp001/{REQUIREMENTS,ACCEPTANCE_CRITERIA,IMPLEMENTATION_PLAN}.md`
   (all required by `AGENTS.md`). `context/STATUS.md` is a protected bootstrap
   snapshot and is out of date by design.
3. `experiments/exp001/docs/DPC_SPECIFICATION.md` (the approved contract, G1-G5)
4. `research/STATUS.md`, `research/TODO.md`, the tail of `research/DECISION_LOG.md`.
   In STATUS and TODO, the dated "Current status" block right after the YAML header
   is current; the tables below it are a historical M3 snapshot of 2026-11-25 (D-067)
5. As needed, the validated building blocks: `experiments/edu_complex_arithmetic/`
   (binary32 complex add/mul) and `experiments/edu_fifo/` (memory, valid/ready).

## 4. Hard rules

- **Protected, never edit:** `AGENTS.md`, `START_PROMPT.md`, `.agents/`, `context/`,
  `experiments/exp001/reference/` (golden reference and its manifest). Check them
  before and after every test run:
  `python3 scripts/verify_protected_digests.py --extra-manifest experiments/exp001/reference/ORACLE_MANIFEST.sha256`
  - That script checks `dpc_ref.py` against the oracle manifest but does not
    fingerprint `ORACLE_MANIFEST.sha256` itself. Its SHA-256 is recorded in D-068
    (`1f26c582...4bb294`); check it with `shasum -a 256` when it matters.
  - `make verify` runs the same script **without** the oracle manifest. Do not use
    it as the AC1 check.
- **No `git commit`/`git push` unless Daniel explicitly says so in this session.**
  Staging is fine.
- No dependency installation, no `sudo`, no edits outside the repository.
- Never weaken tests, tolerances or acceptance criteria. Never overwrite raw evidence.
- Status words: PASS / FAIL / BLOCKED / NOT_RUN. PASS requires observed tool output.
  Separate what is authored, statically reviewed, compiled, simulated, numerically
  verified and synthesized.
- Markdown project documents start with a YAML header (`title`, `sub-title`,
  `author`, `date`). Use repo-relative links.
- `research/DECISION_LOG.md` is append-only. Continue the ID sequence; never
  rewrite earlier entries, only supersede them.

## 5. Toolchain (everything runs in Docker)

Host: macOS, Apple Silicon, Colima. The host `bash` is 3.2, so host scripts must not
use bash 4 features (`mapfile`, associative arrays, `${x,,}`).

```sh
docker run --rm --platform linux/arm64 -v "$PWD:/workspace" -w /workspace \
  fpga_ai-toolchain:m1-arm64 bash -c '<commands>'
```

| Tool | Version | Notes |
|---|---|---|
| GHDL | 4.1.0 (GCC backend) | `ghdl -a/-e/-r --std=08`. Top-level generics via `-gNAME=value` at `-r` |
| Yosys | 0.33 | No GHDL plugin. Flow: `ghdl --synth --std=08 --no-formal --out=verilog <top> > top.v`, then `yosys -p "read_verilog top.v; hierarchy -check -top <top>; proc; opt; memory; opt; check -assert; stat"` |
| Python / NumPy | 3.12.3 / 2.1.3 | Available in the container only |
| cocotb | 1.9.2 | Installed but **not used** for exp001 (D-065) |

Absent from the image: iverilog, verilator, sby. `yosys-abc` is present.

- If Docker is not running: `colima start`.
- Build products go under the experiment's `build/` folder, which is ignored by
  Git. Compact evidence (logs, manifests, provenance) goes under
  `experiments/<exp>/evidence/<run_id>/` and is committed.
- Existing scripts show the conventions: `scripts/verify_edu_fifo.sh`,
  `scripts/benchmark_edu_fifo_xc7.sh` (Series 7 mapping). The closest template for
  exp001 runners is `experiments/edu_complex_arithmetic/tb/run_ghdl.sh` (it has no
  `scripts/verify_*` wrapper); mind CA-DEFECT-001 when reusing it.
- `Makefile` targets: `make verify` (bootstrap digests only, see section 4),
  `make build`, `make smoke`, `make smoke-sim`, `make smoke-synth`, `make shell`.
- Testbenches for exp001 are plain GHDL VHDL-2008 testbenches that read vector files;
  `dpc_ref.py --check` judges the output dumps afterwards. cocotb and
  `experiments/exp001/tb/conftest.py` are not used (D-065).

## 6. Engineering lessons already learned (do not repeat these mistakes)

- **FIFO-DEFECT-001:** indexing an array of `D` words with a pointer wide enough for
  `2^ceil(log2 D)` addresses leaves unallocated address branches when `D` is not a
  power of two. Yosys then reports undriven bits. The fix kept in V2 is to pad
  storage to a power of two and use fixed-width `unsigned` pointers with explicit
  wrap. A plain indexed asynchronous read is then kept as a memory and maps to
  LUTRAM on Series 7.
- **binary32 arithmetic:** use `ieee.float_pkg` with explicit parameters
  (`round_style => round_nearest, guard => 3, check_error => true, denormalize => true`)
  and `use ieee.fixed_float_types.all`. This combination matched an independent
  reference bit for bit on 8124 vectors (`edu_complex_arithmetic`, D-059).
- **Known, not fixed:** Yosys reports 4 "limited tri-state support" warnings per
  float_pkg operation (CA-OBS-001). Report the count; do not hide it.
- **CA-DEFECT-001:** the edu_complex_arithmetic runner's warning count is off by
  one (it counts the summary line). Count `Warning:` lines instead.
- **GHDL synthesis** needs `--no-formal`; otherwise Yosys rejects the generated
  `$fatal`.
- **Testbenches:**
  - drive inputs on the falling edge and check after the rising edge;
  - read stimulus and expected results from vector files;
  - count mismatches and end with a `severity failure` if any occurred;
  - finish with `std.env.finish`;
  - never import or reimplement the golden reference inside the testbench.
- **Verification harnesses can be wrong too.** The formal-equivalence harness had
  two defects (EQ-DEFECT-001/002). Every harness needs a positive control and a
  deliberately failing control.
- **M2A-DEFECT-001:** the M2a install script computed `MANIFEST.sha256` while its
  `tee`'d log was still being written and included its own `.tmp` file (D-066,
  `experiments/exp001/evidence/m2a_20261126T105320Z/CORRECTION.md`). In every
  script, write manifests last, after all logs are closed, excluding the manifest
  itself and temporary files.

## 7. exp001 DPC: where things stand

- The specification is approved (D-060, D-061). The golden reference
  `experiments/exp001/reference/dpc_ref.py` is frozen (D-062):
  - `--selftest` runs its own checks;
  - `--output DIR` writes vector files `dpc_n<N>_p<P>.txt`, with tags `T`/`R`/`X`/`Y`
    and binary32 hex words;
  - `--check VECTORS DUMP` scores a hardware output dump (lines `O <re> <im>`) with
    the error-bound gate and the bit-exact check.
- **M2a is complete** (D-063, commit `fe26c25`). Its evidence manifest has a known
  defect, corrected without editing it (M2A-DEFECT-001, D-066).
- Milestones:
  - **M2b:** RTL with `G_LANES = 1`, testbench, runner. Prompt:
    `experiments/exp001/prompts/M2B_PROMPT.md`. Milestone prompts live in
    `experiments/exp001/prompts/`.
  - **M2c:** `G_LANES > 1`.
  - **M4/M5:** Series 7 mapping, cycle measurements, review document for Amir.
  - Each milestone starts only on a planner prompt approved by Daniel.

## 8. How to work a milestone

1. Read the milestone prompt. Restate scope, the files you will touch, checks and
   risks in a short plan, then wait for Daniel's "go".
2. Implement, then run every check in Docker. On failure, diagnose; fix only within
   scope. Record the defect with an ID; never edit the reference or tests to pass.
3. Write evidence and research records:
   - an experiment `VALIDATION.md` or `RESULTS.md`;
   - `research/DECISION_LOG.md`, `STATUS.md`, `TODO.md`;
   - a changelog file and today's daily note.
4. Stage the changes. Do not commit until Daniel says so.
5. End with a **planner report** that Daniel can paste to the planner:

```text
PLANNER REPORT - <milestone> - <date>
Scope done: ...
Files changed: ...
Checks (command -> PASS/FAIL/BLOCKED/NOT_RUN, key numbers): ...
Defects / deviations from the prompt: ...
Open questions for the planner: ...
Git state: staged / committed (hash) / not pushed
```

Keep explanations for Daniel short and in plain language.
