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

## FPGA-family mapping experiment (2026-11-26)

### D-034 - Reference architecture
Owner: planner; user approved mapping experiment. Select Xilinx Series 7 (xc7) as a reference family because installed Yosys exposes LUT, distributed RAM and block RAM mappings. Alternatives: iCE40, ECP5, UltraScale. No specific part or board selected. Evidence: local Yosys help probe. Physical timing and fit remain unknown.

### D-035 - Out-of-context mapping
Owner: planner; delegated. Use synth_xilinx -family xc7 -top edu_fifo -noiopad -noclkbuf for both versions. Exclude top-level I/O and clock buffer insertion to compare internal component resources. Retain check -assert. No RTL changes or retiming. Mapped primitives are estimates, not routed utilization.

### D-036 - Controlled mapping strategies
Owner: planner; user approved direction. Reuse all 22 paired configurations for both RTL versions. Compare default, -nobram, and -nobram -nolutram -nosrl (132 mappings). Record exact primitive types and counts, netlists, commands, wall times and failures. Keep distributed RAM and SRL primitives distinct from logic LUTs; do not equate primitive counts with occupied slices. No new functional simulation in this mapping-only run; existing oracle regression is prior evidence, not netlist equivalence. Continue individual failures and return nonzero if any fail.

### D-037 - Defer physical implementation
Owner: planner; delegated. No nextpnr executable was found in the local probe. Use existing Docker image, no installations. Defer part selection, placement, routing, timing closure and mapped functional equivalence. Raw evidence stays in ignored build directory; compact results to be archived after review. Status: planned; actual mapping pending.

## XC7 mapping acceptance (2026-11-26)

### D-038 - Accept V2 resource-mapping improvement
Owner: planner; delegated decision, user approved proceeding with archival. Evidence: F-FIFO-014 through F-FIFO-020, benchmarks/xc7/RESULTS.md. All 132 runs passed; V2 uses distributed RAM and fewer ordinary LUT/FF cells in aggregate. No claim of physical timing or total LUT utilization.

### D-039 - Retain compact mapping evidence
Owner: planner. Archive CSVs, commands, configuration list, logs summary and provenance; leave large raw mapped netlists and individual logs in local ignored build directory. Alternative: commit entire 162 MB transfer archive; rejected to avoid repository bloat. Raw archive retention outside Git remains user responsibility.

### D-040 - Prioritize mapped functional equivalence
Owner: planner; user approved sequence. Preserve V1/V2 and evaluate mapped behavior before considering BRAM-oriented V3. Neither structural checks nor resource mapping establish equivalence.

## Generic formal verification (2026-11-26)

### D-041 - Solver selection
Owner: planner; user approved direction. Use installed Yosys internal SAT; no new dependencies. External SMT solvers unavailable in probe. EQ4 deferred.

### D-042 - Observable equivalence
Owner: planner; delegated. Compare ready and valid exactly and valid read data only. Compare GHDL-generated Verilog before generic optimization (normalized for SAT) against generic synthesis and compare V1/V2. This does not independently prove VHDL translation correctness.

### D-043 - Invalid data masking
Owner: planner; delegated. Ignore read data only when both outputs are invalid; do not ignore valid mismatches. Binary-valued input model, no restrictions on subsequent request sequences. No unknown-cell skipping.

### D-044 - Reset semantics
Owner: planner; delegated. Harness forces reset during first modeled cycle via initialized armed flag; all subsequent resets arbitrary. Compare after first reset edge. No forced zero initialization of data storage.

### D-045 - Proof classification
Owner: planner; delegated. Run bounded SAT and independent combined base/induction proof. PROVEN requires explicit induction success; BOUNDED means bounded pass but no complete proof; FAILED requires reachable bounded counterexample; other failures INCONCLUSIVE. Keep logs and counterexamples; induction-step counterexamples alone are not reachable defects.

### D-046 - Progressive proof sweep
Owner: planner; delegated. Pilot widths/depths (1,1), (2,2), (2,3), (2,4), (8,3), (8,4). Bounded horizon 2D+8 cycles including reset; induction max 8 steps; SAT instance timeout 15 seconds, wall timeout 90 seconds per invocation. Larger configurations and XC7 mapping deferred. No RTL or oracle changes. Status: planned.

## Invariant-strengthened formal verification (2026-11-26)

### D-047 - Preserve initial proof evidence
Owner: planner; user approved direction. Initial experiment: 3 complete proofs, 15 bounded, no reachable counterexamples. Induction reached maximum depth for the 15 cases; no timeout observed. Preserve original runner and logs.

### D-048 - Strengthen induction property
Owner: planner; delegated. Expose existing netlist state as verification-only ports; prove pointer bounds, equal occupancy and pointers, circular pointer/occupancy relation, and equality of occupied words. Unoccupied words are unconstrained. Prove conjunction from reset and by induction, never assume these invariants externally. Preserve observable property. This is a sufficient state relation for these architectures, not a general FIFO equivalence method.

### D-049 - Controlled proof pilot
Owner: planner; delegated. Repeat six configurations and three comparisons with original horizons and time limits. Audit state aliases against prior generated Verilog and JSON; fail closed on missing or unexpected widths. No source RTL changes. Classify incomplete induction as bounded only if observable bounded proof previously established or current strengthened bounded proof passes; strengthened-property failure is not automatically an observable defect. XC7 equivalence deferred.

## Formal verification harness audit (2026-11-26)

### D-050 - Correct verification harness elaboration (EQ-DEFECT-001)
Owner: planner/reviewer; delegated. Both initial and invariant-strengthened proof logs contain the warning that compare_fifo contains unlowered processes. The SAT logs do not show the expected armed initialization constraint. The earlier 3/18 and 18/18 proof completion results are provisional and cannot establish reset-aware equivalence until rerun. Preserve historical evidence; supersede its acceptance claims rather than erase it.

Correction: lower the comparison harness with proc before flattening and SAT. For every problem, prove armed=0 initially and armed=1 after the first transition; require an intentionally false armed=0 property across two cycles to produce a counterexample. Fail closed if any harness control fails. Retain original configurations, time horizons, solver limits, RTL and oracle. No changes to functional requirements. Corrected proof results pending.

### D-051 - Correct Yosys SAT result parsing (EQ-DEFECT-002)
Owner: planner/reviewer; delegated. Audit of both corrected runs found 36/36 initial activation proofs and 36/36 next-state activation proofs succeeded. All 36 deliberately false properties emitted the Yosys 0.33 -verify failure diagnostic and produced counterexample traces. The runner expected a different diagnostic, so all actual equivalence checks were NOT_RUN. Preserve the historical runs as infrastructure evidence.

Correction: recognize the actual -verify failure diagnostic as well as the previous format, require exit status 1 and a counterexample VCD for negative controls and bounded failures. Retain strict positive-proof checks, proc lowering, solver limits and all original RTL and oracle files. No equivalence acceptance until corrected runs are audited.

### D-052 - Accept corrected formal equivalence pilot
Owner: planner/reviewer; delegated, user approved milestone closure. Accept only corrected runs equiv.VFD9H4vr and equiv_invariants.Uu1w69q7. All 36 bounded checks passed; strengthened 18/18 proofs completed with one-step induction. No general parameter or XC7 proof claim. Findings F-FIFO-026 through F-FIFO-031.

### D-053 - Preserve invalidated and parser-blocked experiments
Owner: planner; delegated. Retain historical evidence separately with explicit invalidation labels; do not overwrite or count earlier results as proofs. Record original hashes and exclude compiled objects from tracked evidence.

### D-054 - Scale only after pilot closure
Owner: planner; delegated. Next investigate broader fixed-parameter proofs using corrected harness and controls; keep XC7 mapped equivalence separate. A timeout remains inconclusive. No RTL changes authorized by this archival step.

## Educational complex arithmetic (2026-11-26)

### D-055 - Claude as planner and coder
Owner: user; approved. ChatGPT planner role discontinued for subsequent work. Claude (chat) plans, specifies and implements; the user executes scripts locally and approves milestones; local tools are the verification authority; senior engineer review remains the final assessment. Trade-off: planner/coder/reviewer independence is reduced. Mitigations: plan and acceptance criteria stated before code, independent reference models with a second cross-check, only tool evidence counts as PASS.

### D-056 - Binary32 representation for complex arithmetic
Owner: Claude as planner; delegated by an open assignment. IEEE-754 binary32 parts, round to nearest even, subnormals, IEEE special values, fixed evaluation order (four rounded products, then one rounded subtraction/addition), no FMA or three-multiplier form, bit-exact pass criterion with NaN compared by class. Alternative rejected: fixed point (simpler to verify, but conflicts with PROJECT_DECISIONS item 7 and is unusable for the DPC). Does not resolve exp001 gate G3.

### D-057 - Interface and implementation
Owner: Claude as coder. Identical ports for both entities, one registered output stage (latency 1, one input per cycle), synchronous active-high reset clears out_valid only, data registers not reset and hold when in_valid is low. float_pkg calls state round_nearest, guard 3, check_error and denormalize explicitly.

### D-058 - Independent reference and vectors
Owner: Claude as planner. Exact rational (Fraction) reference with one rounding per operation, standard library only; NumPy float32 cross-check as a second model. Five categories per operation (directed, edge, special, random_normal, random_bits), 8124 vectors, seed 20261126.

### D-059 - Accept edu_complex_arithmetic
Owner: user; approved after review of run 20261126T103335Z. Accepted within simulation and generic structural synthesis scope: 24,462 checks, 0 errors; 0 structural problems. Observations CA-OBS-001 (tri-state warnings, 4 per float operation) and CA-DEFECT-001 (runner warning count off by one) recorded, not corrected. Post-synthesis equivalence, technology mapping and timing not established. Evidence: experiments/edu_complex_arithmetic/VALIDATION.md.
