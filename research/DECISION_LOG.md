# Research decision ledger

Created: 2026-11-26. Scope: AI-assisted standalone educational FPGA experiments and supporting development workflow. This is a retrospective reconstruction up to commit c884ca9, followed by prospective entries. It is not a verbatim transcript or a complete historical audit.

## Recording policy (D-001)

Owner: user; explicitly requested 2026-11-26. Every material decision is recorded before implementation, or immediately after discovery for corrective actions. Record the decision ID, date, owner (user, planner, coder, reviewer), approval status, alternatives, rationale, expected trade-offs, affected artifacts, and validation evidence. Separate observations from decisions. Never silently rewrite earlier decisions: append a superseding entry referencing its ID. Record rejected alternatives, failures and uncertainties, not only successes. The user approves functional scope and application constraints; the planner chooses engineering defaults under delegated authority; the coder owns implementation details within the approved contract. A coder decision is not a user approval. Update this ledger at every handoff and before milestone commit. Preserve exact commands, versions, source hashes and run identifiers with experiment evidence. Do not infer missing historical dates or approvals.

## Retrospective decisions (2026-11-25 to 2026-11-26)

| ID | Owner / status | Decision and alternatives | Rationale / evidence |
|---|---|---|---|
| D-002 | User / approved | Separate planner, coder and reviewer; milestone-based development rather than unrestricted edits. | Research measures productivity with review; protected bootstrap integrity checks. |
| D-003 | User / approved | Local ARM64 Docker/Colima environment, rather than native HDL installations or GCP execution for today's runs. | Portable toolchain; GCP execution constraints; M1_LOCAL_VALIDATION.md, bba647a. |
| D-004 | Planner / corrective | Explicit initial clock low and start_high=False in cocotb; no masking unknown logic. | M1 simulation failure resolved; DEFECT-001. |
| D-005 | Planner / corrective | GHDL-to-Verilog fallback with --no-formal, preserve simulation assertions and strict structural checks. | GHDL-Yosys plugin unavailable; Verilog $fatal parsing failure resolved; DEFECT-002. |
| D-006 | User / approved | Chat-based Claude coder with bounded context ZIP and prompt, ChatGPT planner/reviewer, manual local execution. | No local coding agent; token budget limited. |
| D-007 | User / approved | Prioritize productive engineering with necessary explanations, rather than prerequisite FPGA education or repeated low-level approval questions. | User clarified intended junior-EE workflow; planner delegated engineering defaults. |
| D-008 | User / approved | Scripts write only inside project; no automatic commits/pushes or installations. | Local execution and review remain user controlled. |
| D-009 | Planner / chosen | Standalone educational register with synchronous active-high reset and clock enable. | Small initial exercise to test the chat workflow. See edu_register specification and prompt. |
| D-010 | Coder / reviewed | Clocked register process, reset priority over enable. | First submission accepted; synthesis inferred one eight-bit $sdffe. |
| D-011 | Reviewer / corrective | Add pre-edge assertion to distinguish synchronous from asynchronous reset. | Original testbench coverage gap; final 21 checks passed. |
| D-012 | User / approved | Keep reusable scripts and prompts, remove stale one-time scripts, ignore local build artifacts. | Clean Git baseline and reproducibility. |
| D-013 | User / approved scope | Standalone parameterizable synchronous FIFO; width/depth generics, single clock, ready/valid, simultaneous transfers, arbitrary positive depth. | More demanding control and verification exercise than register. |
| D-014 | Planner / delegated | First-word-fall-through, no empty bypass, full replacement, synchronous state reset with combinational reset gating, no physical memory clearing. | Explicit cycle contract; simpler initial architecture. See edu_fifo/SPECIFICATION.md. |
| D-015 | Planner / delegated | Independent deque oracle and deterministic vector generation, directed plus randomized checks at six configurations. | Avoid coder-owned expected outputs; TEST_CONTRACT.md and golden.py. |
| D-016 | Coder / reviewed | Circular storage, occupancy counter and explicit pointer wrap; dynamic memory head read. | Straightforward baseline; original RTL simulation passed reached cases. |
| D-017 | Reviewer / corrective | Fix directed reset test expectation for depth two; strict runner exit propagation, full Yosys logs and --no-formal. | Generic verification correctness and useful diagnostics. |
| D-018 | Planner / corrective | Replace dynamic head read with explicit bounded read mux and default output. | FIFO-DEFECT-001: eight undriven bits at W8 D3 in memory mapping. Root cause consistent with unused address branch; full regression after patch passed. No oracle or interface changes. Potential inference/scaling cost. |
| D-019 | User / approved | Accept and publish FIFO V1 within tested functional and generic structural scope. | 6 configurations, 12,262 oracle cycles, zero reported structural issues; c884ca9. Physical timing, equivalence, BRAM inference not established. |
| D-020 | User / approved | Preserve V1 and evaluate architecture optimization against a controlled baseline rather than immediately introducing a new component. | Same observable contract and independent oracle for comparison. V2 design not yet approved or implemented. |

Earlier EXP001 planning decisions are outside this ledger's educational experiment scope; no implementation acceptance is implied. Existing research notes remain authoritative for their own scope. Historical coder choices not visible in returned artifacts cannot be reconstructed reliably.

## Prospective benchmark decisions (2026-11-26)

### D-021 — Controlled V1 baseline
Owner: planner; delegated. User approved the benchmark direction.

- Sweep depth at width 32: 1, 4, 8, 16, 32, 64, 128, 256.
- Sweep width at depth 32: 8, 16, 32, 64, 128.
- Non-power-of-two depths at width 32: 3, 15, 31, 63, 127.
- Include the original six acceptance configurations as regressions. Deduplicate overlapping points: 22 unique configurations; 50,626 deterministic oracle cycles expected.
- Alternatives: change width and depth together, or test only the original six. Rejected because trends would be confounded or too narrow.
- Preserve source RTL, testbench and oracle. Generate vectors by calling existing golden.vectors; no change to the reference or seed.
- Evidence: benchmark.csv, cell_types.csv, per-configuration simulation/synthesis logs, configuration manifest, source SHA-256, Git HEAD/status, image ID and tool versions. New run directory per invocation.
- Status: planned; local execution pending.

### D-022 — Two synthesis views
Owner: planner; delegated.

- Use Yosys memory -nomap to inspect retained memory objects; use memory to obtain generic logic-mapped statistics, as in V1 acceptance. Keep strict check -assert in both views. Report memory objects and capacity from retained memory cells, not just stat num_memories (which can be zero after memory_collect).
- Alternatives: only compare mapped cells, or immediately choose an FPGA family. Rejected because the former hides memory inference and the latter introduces an unapproved target.
- Capture cell types, wire bits, phase wall times and raw logs. Wall times are single-run tool measurements, not hardware latency or robust performance estimates.
- Do not interpret generic cells as LUTs/physical FFs or retained memory as actual BRAM usage. Technology-specific mapping and timing deferred until a device is selected.
- Continue across individual configuration failures, record them explicitly, return nonzero if any fail. No suppression of structural errors.
- Status: planned; actual Yosys JSON compatibility and local execution pending.

### D-023 — Evidence retention
Owner: planner; delegated under existing user repository policy.

- Keep raw output in ignored experiments/edu_fifo/build/benchmark.* directories. Track runner and this ledger. On completion, archive compact benchmark CSV and summarized provenance in tracked experiment documentation if approved; do not commit raw build artifacts.
- No changes to protected files; no automatic Git commit/push. Do not launch V2 coding task until baseline is reviewed.
- Status: planned.

## Entry template

### D-NNN — Title
Date / owner / approval status:
Decision and scope:
Alternatives considered:
Rationale and expected trade-offs:
Affected artifacts / baseline:
Validation criteria and observed evidence:
Limitations / unresolved questions:
Supersedes (if applicable):

## Benchmark completion and V2 handoff (2026-11-26)

### D-024 - Accept V1 benchmark evidence
Owner: planner; delegated. D-021 and D-022 completed, not superseded.
Evidence: benchmark.uMRVDG9y, 22/22 configurations, 50,626 oracle cycles, 44/44 synthesis views; no retained memory objects. Alternatives: repeat the same run before any design work (not necessary for functional baseline; timing repeatability remains untested). Limitations: generic RTLIL only; runner and ledger untracked at run time. See benchmarks/v1/RESULTS.md.

### D-025 - Preserve compact evidence
Owner: planner; delegated under user-approved research provenance policy. D-023 completed on installation. Track exact CSVs, run log, hashes, tool versions, image ID and configuration manifest; retain bulky logs/netlists locally. Alternative: commit all raw artifacts, rejected to avoid repository bloat. Archive hash recorded for provenance. No automatic commit/push.

### D-026 - V2 scope and acceptance
Owner: user approved optimization direction; planner delegated engineering criteria. Standalone educational FIFO only. Preserve cycle-level interface, capacity, reset and ordering exactly, including depth 1 and non-power-of-two depths. Preserve V1, oracle and testbench. Alternative: relax latency or full replacement semantics, rejected because comparison would no longer be equivalent. V2 should retain inferred memory objects for larger depths, but functional and structural correctness are mandatory; failure to infer memory is a measured outcome, not grounds to weaken checks. Physical mapping deferred. Status: proposed to coder; no results yet.

### D-027 - V2 implementation autonomy
Owner: planner; delegated. Ask coder for a separate VHDL implementation and explicit rationale, alternatives and risks. Memory-oriented implementation is the objective; no prescribed internal buffering microarchitecture. No modifications to oracle, testbench or protected context. Compare with identical 22 configurations and both synthesis views after review. Candidate must be separately integrated and verified. Status: awaiting coder submission.

## V2 candidate review and integration (2026-11-26)

### D-028 - Coder architecture choices
Owner: Claude (coder); submitted, reviewer accepted for testing only. See experiments/edu_fifo/v2/DESIGN.md, V2-D1 through V2-D5, for detailed alternatives and risks. Padded power-of-two storage, fixed-width unsigned pointers with logical-depth wrap, special depth-one register, unchanged occupancy/handshake logic, reset-free synchronous write and asynchronous read. Rejected synchronous prefetch architecture in favor of simpler cycle-equivalent behavior. Potential cost: padding and no guarantee of BRAM mapping. Candidate ZIP SHA-256: 1966ba5e46d541b818818127a4224683744a226c466a72dfaeefa5a396f7708c. Claude reports a scratch Python cross-check, not independently reproduced; HDL execution NOT RUN by coder.

### D-029 - Reviewer acceptance for integration
Owner: planner/reviewer; delegated. Static review finds interface, reset gating, logical capacity, full replacement, no empty bypass and stall stability consistent with V1. Preserve candidate RTL unchanged; no corrections requested before execution. Alternative: mandate synchronous read or prefetch, rejected for this candidate to preserve coder autonomy and avoid unnecessary changes. Limits: asynchronous read may not map to BRAM; padding may waste capacity; elaboration integer limits apply; physical mapping and equivalence not established. Acceptance pending 22-config local regression and synthesis.

### D-030 - Shared benchmark runner variant selection
Owner: planner; delegated. Extend existing runner with optional v1/v2 selector (default v1), compile only selected RTL, use unchanged oracle, testbench, configurations and strict synthesis passes. Separate run directories and record variant and runner hash. Alternative: duplicate runner, rejected to avoid benchmark drift. V1 source remains immutable; previous runner remains in Git history. Local execution pending.

## Paired V1/V2 benchmark acceptance (2026-11-26)

### D-031 - Repeat V1 with V2 benchmark runner
Owner: user; observed action. Rationale: control runner and environment differences. Alternative: compare against historical V1 run alone. Evidence: 22 identical stimuli, same tools and image. Single timing repetition; dirty tree documented.

### D-032 - Accept V2 within generic synthesis scope
Owner: planner; delegated. All 22 configurations pass both views and simulation; no candidate RTL corrections. Memory retained in 19 depth>1 cases. At W32 D256 mapped cells 1824 to 1110; W16 D5 worsens from 64 to 69. Preserve V1 rather than replace it. See benchmarks/COMPARISON.md. Physical implementation and equivalence remain unverified.

### D-033 - Retain paired evidence and defer physical claims
Owner: planner; delegated. Track both compact paired datasets and provenance without replacing historical V1 data. Raw build artifacts remain local. Next proposed investigation: device-specific mapping as a distinct experiment, target selection pending. Alternative: immediately develop V3, deferred until physical resource evidence is available.
