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

## EXP001 DPC specification and golden reference (2026-11-26)

### D-060 - Approve the DPC specification (gates G1-G5)
Owner: user; approved ("I trust you"). Proposal items P-01 to P-09 accepted: simulation and generic synthesis demonstration with Series 7 mapping, no FPGA device (Docker toolchain only); correlation contract with output length N_RG; binary32, round to nearest even, fixed summation order, finite inputs; error-bound gate plus bit-exact check; frozen Python reference; valid/ready streams, one block at a time; output-parallel lanes with sliding window; fixture matrix; M2a next. Contract: experiments/exp001/docs/DPC_SPECIFICATION.md.

### D-061 - Component conjugates the pulse reference
Owner: Claude as planner, at approval; revises P-02. The owner described the deliverable as taking N_RG samples and a pulse reference. The component therefore receives the pulse r as supplied and computes y[n] = sum conj(r[k]) x[n+k]; windowing and scaling remain external (PROJECT_DECISIONS item 8). Conjugation is an exact sign change, so the numerical contract is unaffected. Generics named G_N_RG, G_P, G_LANES; pulse port ref_*.

### D-062 - Golden reference design and freeze
Owner: Claude as planner. experiments/exp001/reference/dpc_ref.py, standard library only: exact rational model, binary32 sequential model, error bound, seeded stimuli, judge for output dumps. Frozen by ORACLE_MANIFEST.sha256 before any RTL; verified with --extra-manifest before and after test runs. Vectors are regenerated, not committed. NumPy used only for cross-checks. Independence caveat (D-055) mitigated by freezing first, numpy.correlate and float32 cross-checks, and file-only coupling to RTL.

### D-063 - Accept M2a
Owner: user via this run (20261126T105320Z). Self-test PASS in the container (worst seq32 err/tol = 0.2569; numpy 2.1.3 cross-checks (42 transactions)). Vectors IDENTICAL to the authoring sandbox (x86_64). Oracle digest verified before and after. No RTL exists yet; M2b (G_LANES = 1 RTL) requires approval of its plan.

## Claude Code workflow and M2a evidence correction (2026-11-26)

### D-064 - Claude Code as implementer
Owner: user; approved (planner decision 1 on the session-start audit). Claude Code writes RTL, tests and scripts, runs the Docker toolchain and keeps the research records. Claude chat is planner and reviewer; the user approves milestones and decides commits; Amir performs the final review. Supersedes the coder part of D-055. Project memory for Claude Code: CLAUDE.md.

### D-065 - Plain GHDL testbenches for exp001
Owner: user; approved (planner decision 2). exp001 testbenches are plain VHDL-2008 GHDL testbenches that read vector files (edu_complex_arithmetic pattern); dpc_ref.py judges output dumps after simulation. cocotb and experiments/exp001/tb/conftest.py are not used for M2b. Supersedes "cocotb/pytest" in TODO-003. Rationale: keeps the reference/RTL boundary file-only (D-062).

### D-066 - M2A-DEFECT-001 handling
Owner: user; approved (planner decision 3). Observation M2A-OBS-001 reclassified as M2A-DEFECT-001, a defect in the planner's install script: MANIFEST.sha256 was computed while the tee'd log was still being written, and the listing included the script's own .tmp file. MANIFEST.sha256 is not edited; install_and_verify.log is committed as it is now (it only grew, 30 to 53 lines); experiments/exp001/evidence/m2a_20261126T105320Z/CORRECTION.md records the defect, root causes and fresh digests. M2a results are unaffected. Lesson: write manifests last, after logs are closed, excluding the manifest itself and temporary files.

### D-067 - Current-status blocks in STATUS and TODO
Owner: user; approved (planner decision 4). research/STATUS.md and research/TODO.md get a dated "Current status (2026-11-26)" block right after the YAML header. The original tables remain as a historical M3 snapshot of 2026-11-25; nothing is deleted. TODO-002 DONE (M2a); TODO-003 superseded by M2b.

### D-068 - Fingerprint of the oracle manifest
Owner: user; approved (planner decision 5). verify_protected_digests.py checks dpc_ref.py against ORACLE_MANIFEST.sha256 but not the manifest itself. Recorded digest:
SHA-256(experiments/exp001/reference/ORACLE_MANIFEST.sha256) = 1f26c582f6507d2b742d24bc8d658fdc0043fa06be674c5cdc261e94294bb294
(manifest content: dpc_ref.py = 4389871a1b857349fbd8f0600e207e36f1cf2a98d017e6be629792af8dd8c1eb). Check with `shasum -a 256 experiments/exp001/reference/ORACLE_MANIFEST.sha256`.

## EXP001 M2b - DPC RTL baseline, G_LANES = 1 (2026-11-26)

### D-069 - Pulse load priority and the combinational in_ready path
Owner: planner; approved (M2b plan review, answer 4); implemented by Claude Code. In S_IDLE, in_ready = pulse_loaded and not ref_valid, so a pulse load wins when ref and in are offered in the same cycle and exactly one transfer (the ref one) happens. Ready may depend on valid; no valid depends on any ready; out_valid, out_last and out data come only from registers. Documented in experiments/exp001/rtl/dpc.vhd; covered by a directed testbench check after the first pulse load. Alternative rejected: registered mutually exclusive ready signals (adds a cycle and a second idle state for no functional gain).

### D-070 - M2b verification additions
Owner: planner; approved (answers 1-3). Timing mode runs a third time per fixture and its CYCLES lines must be identical to the second run (18 simulation runs; B1 counts 12). Memory objects and bits are counted with a separate "memory -nomap; stat" pass; the acceptance flow (proc; opt; memory; opt; check -assert; stat) is unchanged and must report 0 problems. Periods that include a pulse reload (transaction 4 to 5) are reported as measured and labelled.

### D-071 - DPC control structure and counter widths
Owner: Claude Code (implementer), within the approved contract. Five states: S_IDLE, S_LOAD_REF, S_LOAD_IN, S_COMPUTE (P cycles, one multiply-accumulate per cycle), S_OUT (hold y[n] until transferred). Sample 0 of a pulse or block is accepted in S_IDLE. Widths: sample address addr_width(N_RG), pulse address and k addr_width(P), output index n and sample index idx = n + k addr_width(N_RG + P) bits (holds N_RG + P - 1, planner addition 5); addr_width(x) = max(1, ceil(log2 x)) so N_RG = 1 or P = 1 never gives a null range. idx is compared with N_RG before truncation to a memory address; for idx >= N_RG the all-zero sample is used and the MAC still runs. Memories padded to powers of two, write pointers wrap explicitly. acc reset to +0 at the start of each output. Expected cost at out_ready = 1: N_RG input cycles plus N_RG * (P + 1) cycles.

### D-072 - Testbench conventions for tb_dpc
Owner: Claude Code (implementer). A raised valid is held, with stable data, until its transfer; the only exception is the directed priority cycle, where the in offer is withdrawn after the ref transfer. The priority check reloads the same pulse (k = 0 offered again), so expected outputs are unchanged. Random stalls use ieee.math_real.uniform seeded from G_SEED (runner: 20261126); timing mode draws no random numbers. Per-transaction watchdog. Output dump lines "O <re> <im>" in uppercase hex, consumed only by dpc_ref.py --check.

### D-073 - DPC-DEFECT-001 and the accepted M2b run
Owner: Claude Code (implementer); for planner review. Run m2b_20261126T111341Z passed every check but reported memories=0 because Yosys stat counts only unpacked memories and the count-only flow left them packed as $mem_v2 cells (runner defect, not RTL). Fix: memory_unpack before stat, plus a positive control failing the run on a zero memory count. Re-run m2b_20261126T111903Z: OVERALL PASS (B1-B6); 18/18 simulations and dumps 0 errors, bit exact; NC1 and NC2 fail as intended; 6/6 syntheses 0 problems, 4 $mul, 4 memories, 32 tri-state warnings each; latency N_RG + N_RG(P+1) cycles, equal to the G5 model at L = 1. The first run is kept unchanged with CORRECTION.md (D-066 precedent). Evidence: experiments/exp001/VALIDATION_M2B.md. M2b acceptance is the owner's decision.

### D-074 - Accept M2b
Owner: user; approved (planner review of M2b). M2b accepted on run m2b_20261126T111903Z (completes D-073) within the simulation and generic structural synthesis scope. Post-synthesis equivalence, technology mapping and timing are not established. The superseded run m2b_20261126T111341Z is kept with its CORRECTION.md (D-053 policy).

### D-075 - Order of the next milestones
Owner: planner; approved by the user. M2c (G_LANES > 1) is next. Post-synthesis checks and Series 7 mapping move to M4 and apply to the final design. M4 checks LUTRAM mapping for all configurations, including (256,64). BRAM would need a synchronous-read architecture and is out of scope for now.

## EXP001 M2c - DPC parallel lanes (2026-11-26)

### D-076 - Lane architecture and closed-form cycle formula
Owner: Claude Code (implementer), within G5 and the approved M2c plan. Groups n0 = 0, L, 2L, ...; lane j computes y[n0 + j]. Sliding window of L-1 registers plus the sample read in the current cycle (lane L-1); one sample read and one pulse read per cycle. States S_IDLE, S_LOAD_REF, S_LOAD_IN, S_FILL (L-1 cycles, skipped for L = 1), S_COMPUTE (P cycles, one MAC per lane), S_OUT (v = min(L, N_RG - n0) cycles). n0 and the sample index idx use addr_width(N_RG + P + L) bits; idx is compared with N_RG before truncation. Lanes with n0 + j >= N_RG compute but are never output. No output/compute overlap (owner "go" on the plan, question 1 left at the proposed default). Closed form at out_ready = 1: latency = 2*N_RG + ceil(N_RG/L)*(P + L - 1); period = latency, + P when the next block starts with a pulse load. For L = 1 it equals the M2b result N_RG + N_RG(P + 1). Elaboration check 1 <= G_LANES <= G_N_RG replaces the M2b check.

### D-077 - Lane accumulators as the result buffer
Owner: Claude Code (implementer); plan question 2 left at the proposed default. The accumulator input is +0 at k = 0 (no clear cycle, M2b rule acc = +0 preserved), and in S_OUT the output data are acc(j_out) through an explicit bounded lane mux (select_lane, FIFO-DEFECT-001 lesson: j_out has 2**addr_width(L) codes for L lanes). Outputs depend only on registers. Alternative: a separate output register (one more cycle per group, latency 2*N_RG + G*(P + L)).

### D-078 - DPC-DEFECT-002 and the M2c candidate run
Owner: Claude Code (implementer); for planner review and owner acceptance. First M2c run m2c_20261126T113151Z: all simulation, numerical, formula and negative-control checks PASS, but tri-state warnings were 32L + 2 for L > 1 (OVERALL FAIL). Root cause: window arrays sized L with only L-1 entries written; GHDL synthesis emitted a 'bZ constant for the unwritten entry (structural, not functional). Fix: window type of exactly L-1 entries (at least 1). Re-run m2c_20261126T114754Z: OVERALL PASS (C1-C7); 39 simulations and dumps bit exact; NC1-NC3 fail as intended; 9/9 syntheses 0 problems, $mul = 4L, tri-state = 32L; measured cycles equal 2*N_RG + ceil(N_RG/L)*(P + L - 1) on all 13 fixtures and repeat identically; L = 1 cycles identical to M2b. First run kept with CORRECTION.md (D-053 policy). Evidence: experiments/exp001/VALIDATION_M2C.md.

### D-079 - Accept M2c
Owner: user; approved (planner review of M2c). M2c accepted on run m2c_20261126T114754Z (completes D-078) within the simulation and generic structural synthesis scope. Mapping, post-synthesis equivalence and timing are not established. The superseded run m2c_20261126T113151Z is kept with its CORRECTION.md (D-053 policy).

### D-080 - M4 before optimisation; M4 mapping set
Owner: planner; approved by the user. M4 (post-synthesis simulation and Series 7 mapping of the final M2c design) comes before any cycle or pipelining optimisation. Optimisation becomes M6, after Amir's review. M4 mapping set: (256,64) with L = 1, 2, 4, 8 and (64,16) with L = 1, 4.

## EXP001 M4 - post-synthesis simulation and Series 7 mapping (2026-11-26)

### D-081 - Series 7 flow without the share step (M4-TOOL-001)
Owner: planner; approved with conditions (M4 plan review, F1). Probe: the D-035 flow (synth_xilinx -family xc7 -top dpc -noiopad -noclkbuf) was killed for lack of memory (exit 137, Colima VM 10 GB) in the coarse-step share pass (SAT-based resource sharing) on the smallest design (8,3,1); share -fast was also killed. Yosys 0.33 has no -noshare option (help synth_xilinx checked; share appears once, in coarse). Flow used: synth_xilinx ... -run :coarse; techmap -map +/cmp2lut.v -map +/cmp2lcu.v -D LUT_WIDTH=6; alumacc; opt; memory -nomap; opt_clean; synth_xilinx ... -run map_memory:; then check -assert; stat -tech xilinx; write_json; ltp -noff. The runner checks this sequence against the help listing (equal to the standard coarse step minus share) and keeps the listing as evidence. Resource counts are a likely upper bound (no resource sharing). A mapping killed for lack of memory is BLOCKED, with no further flow change; VM memory is the planner's decision.

### D-082 - Saturated shift amounts in GHDL netlist simulation (M4-TOOL-002)
Owner: planner; approved (N1). ghdl --synth --out=vhdl writes float_pkg normalisation shifts as shift_left/shift_right(unsigned(a), to_integer(unsigned(s))) with 32-bit s; values >= 2**31 fail the to_integer bound check. Only that exact pattern inside shift calls is rewritten to sat_shift(s) = min(s, 2**30) (experiments/exp001/tb/m4_sat_pkg.vhd); metavalue inputs keep the original path. Meaning unchanged: numeric_std shifts of a length-W vector give the same result for every amount >= W, and all vectors are far shorter than 2**30 bits. Replacement counts, diffs and netlist hashes are recorded.

### D-083 - Constant-Z selects resolved as in Yosys (M4-TOOL-003)
Owner: planner; approved (N2). float_pkg's classfp tests its input for metavalues (to_01(x,'X') = 'X' -> isx). That test has no hardware meaning; GHDL synthesis writes it as a mux with a constant 'Z' select (VHDL: "n <= normal when std_logic'('Z') = '0' else isx"; Verilog: "1'bZ ? isx : normal"). VHDL simulation resolves 'Z' = '0' as false, so every operation classifies its inputs as isx and all outputs are X (diagnostic control, (8,3,1) N1-only: 56/56 outputs X). IEEE 1076.6 treats comparisons with metalogical values as false in synthesis, and Yosys resolves the select to the normal path (three-line test: 1'bZ ? 4'b1010 : a -> y = a, kept as evidence). N2 applies the same reading in simulation: the exact text "std_logic'('Z') = '0'" becomes "true"; the count must equal 32*L or the fixture stops. Part A wording: "GHDL netlist simulation with saturated shift amounts (M4-TOOL-002) and constant-Z selects resolved as in Yosys (M4-TOOL-003); mapped netlist simulation BLOCKED (no Verilog simulator)".

### D-084 - CA-OBS-001 explained; float_pkg portability finding
Owner: planner; approved. CA-OBS-001 (4 Yosys tri-state warnings per float_pkg operation, 32 per DPC lane) is explained: each warning is one constant-Z select from the classfp metavalue test (D-083); explained, not fixed. Finding for the Amir review: synthesis of ieee.float_pkg depends on each tool treating the metavalue test as false. Yosys does; Vivado is untested here. Portability risk.

### D-085 - M4 run results and M4-TOOL-004
Owner: Claude Code (implementer); for planner review and owner acceptance. Run m4_20261126T123436Z (4628 s), runner OVERALL FAIL on one row only.
- Part A (GHDL netlist simulation, N1 and N2 rewrites): for (8,3,1), (5,8,2), (8,8,3), (64,16,1) and (64,16,4), stress and timing modes are bit exact (0 gate failures, 0 mismatches) and the cycles equal the D-076 formula. N1 and N2 counts are exact for all 6 fixtures (N2 = 32*L). The netlist negative control and the N1-only diagnostic control (56/56 outputs X) behave as intended.
- M4-TOOL-004: the 8.1 MB (256,64,8) netlist could not be compiled by GHDL 4.1.0 (GCC back end), "exec error". A diagnostic re-run (evidence DIAGNOSIS_M4_TOOL_004.md, written after the run, not in the manifest) reproduced it: ghdl1 peaked at 9.43 GB, VM MemAvailable fell to 0.33 GB of 10 GB, and the same truncated .s file was left. This is a tool resource limit; reclassification to BLOCKED is proposed and not applied.
- Part B: 8/8 mappings PASS, 0 problems. Memories map to LUTRAM (110 RAM64M for (256,64); 22 RAM64M + 12 RAM32M for (64,16)), 0 BRAM. DSP48E1 = 8*L (2 per binary32 multiplication). Per added lane for (256,64): about 8000 logic LUTs, 129 FFs, 1322 CARRY4, 8 DSP48E1, near-linear within 3 %. (256,64,8): 64982 logic LUTs, 1006 FFs, 64 DSP48E1, peak memory 8.56 GB. Sensitivity for (64,16,4): -nodsp gives +23570 LUTs; -nolutram gives +5120 FFs and +1463 LUTs. Logic depth (cells on the longest combinational path) is 712 to 781. These are likely upper bounds (no share), not Vivado, not placed, and not timing.
- Mapped netlist simulation BLOCKED (no Verilog simulator); Part C NOT_RUN.
- Results: experiments/exp001/RESULTS_M4.md.
