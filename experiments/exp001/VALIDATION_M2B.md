---
title: "EXP001 M2b validation"
sub-title: "DPC RTL baseline with G_LANES = 1"
author: "Claude Code (implementer)"
date: "2026-11-26"
---

# EXP001 M2b validation - DPC RTL baseline (`G_LANES = 1`)

Prompt: [M2B_PROMPT.md](prompts/M2B_PROMPT.md). Contract:
[DPC_SPECIFICATION.md](docs/DPC_SPECIFICATION.md). Accepted run:
[m2b_20261126T111903Z](evidence/m2b_20261126T111903Z/summary.txt). Superseded first
run: [m2b_20261126T111341Z](evidence/m2b_20261126T111341Z/CORRECTION.md)
(DPC-DEFECT-001).

Scope of the claims: simulation (GHDL 4.1.0), numerical verification against the frozen
golden reference, and generic structural synthesis (GHDL `--synth` to Verilog, Yosys
0.33). Not established: Series 7 mapping, post-synthesis equivalence, timing (Fmax),
power, behaviour on hardware.

## Command

```sh
bash experiments/exp001/tb/run_dpc.sh
```

The runner works on the host (bash 3.2) and runs every tool step in
`fpga_ai-toolchain:m1-arm64` (image `sha256:cfa652b2...`). The run took about 4
minutes: 2026-11-26 11:19:03Z to 11:23:11Z. Its source state was `a272393` plus the
uncommitted M2b files; their SHA-256 values are in
[source_sha256.txt](evidence/m2b_20261126T111903Z/source_sha256.txt).

## Files

| Path | Content |
|---|---|
| [rtl/dpc_pkg.vhd](rtl/dpc_pkg.vhd) | `clog2`, `addr_width`, `negate`, `cmac` (one multiply-accumulate step with the `edu_complex_mul` float_pkg settings) |
| [rtl/dpc.vhd](rtl/dpc.vhd) | Entity `dpc`, 5-state control, 4 memories, one MAC per cycle |
| [tb/tb_dpc.vhd](tb/tb_dpc.vhd) | Vector-driven self-checking testbench, output dump, protocol checks, cycle report |
| [tb/run_dpc.sh](tb/run_dpc.sh) | Runner, steps 1-9 of the prompt |

## Acceptance (B1-B7)

| ID | Criterion | Result | Evidence |
|---|---|---|---|
| B1 | 12 simulation runs (6 fixtures x stress/timing): 0 mismatches, 0 protocol errors | **PASS**: 12/12, 0 errors (plus 6 determinism repeats, also 0 errors) | `sim/sim_*.log` |
| B2 | `--check` on all dumps: 0 gate failures, 0 bit-exact mismatches | **PASS**: 18/18 dumps, 0 and 0 | `sim/check_*.log` |
| B3 | Both negative controls fail as intended | **PASS**: NC1 `--check` exits 1 (1 bit-exact mismatch); NC2 testbench ends in FAIL (1 error) | `neg/` |
| B4 | Synthesis of 6 fixtures: 0 structural problems; metrics recorded | **PASS**: 6/6, `check -assert` 0 problems | `syn/synthesis_summary.csv` |
| B5 | Protected and oracle digests before and after | **PASS**: 35 + 1 files both times; `ORACLE_MANIFEST.sha256` equals the D-068 value | `protected_*.txt`, `oracle_manifest_sha256_*.txt` |
| B6 | Cycle counts for all 6 fixtures, identical between two timing runs | **PASS**: 6/6 identical | `sim/cycles_*.txt` |
| B7 | Validation, research records, staged, not committed | **PASS**: see the planner report | this file, `research/` |

### Simulation and numerical checks

| Fixture `(N_RG, P)` | Outputs | Checks (stress / timing) | Errors | Worst err/tol (`--check`) |
|---|---|---|---|---|
| (1, 1) | 7 | 62 / 53 | 0 | 0.2569 |
| (5, 8) | 35 | 774 / 711 | 0 | 0.1372 |
| (8, 3) | 56 | 625 / 571 | 0 | 0.2490 |
| (8, 8) | 56 | 1200 / 1131 | 0 | 0.1415 |
| (64, 16) | 448 | 16802 / 16139 | 0 | 0.1490 |
| (256, 64) | 1792 | 238562 / 236555 | 0 | 0.0637 |

- Every output was bit-exact against the reference's binary32 sequential model and
  inside the error bound.
- Stress mode uses 30 % random idle cycles on `ref_valid` and `in_valid` and random
  `out_ready = 0` cycles, with seed 20261126.
- Zero padding (`n + k >= N_RG`) is exercised by every fixture with `P > 1`, and
  heavily by (5,8) (`P > N_RG`) and (8,8) (`P = N_RG`). The sample index reaches
  `N_RG + P - 2` there.

Protocol checks included in the counts:
- output stability under `out_ready = 0`;
- `out_last` on exactly the last output of each block;
- no input accepted before the first pulse (5 cycles);
- `in_ready = 0` and `ref_ready = 0` from the last input to the last output of every
  block;
- the directed ref/in priority cycle after the first pulse load (D-069);
- reset forgets the pulse.

### Cycle counts (timing mode, `out_ready = 1`, back-to-back blocks)

| Fixture | Latency (cycles) | Period (cycles) | Period with pulse reload, t=4 to 5 | Throughput (samples/cycle) |
|---|---|---|---|---|
| (1, 1) | 3 | 3 | 4 (*) | 0.333 |
| (5, 8) | 50 | 50 | 58 (*) | 0.100 |
| (8, 3) | 40 | 40 | 43 (*) | 0.200 |
| (8, 8) | 80 | 80 | 88 (*) | 0.100 |
| (64, 16) | 1152 | 1152 | 1168 (*) | 0.0556 |
| (256, 64) | 16896 | 16896 | 16960 (*) | 0.0152 |

How to read the table:
- Latency and period are the same for all 7 transactions of a fixture.
- **(*) Measured periods that include a pulse reload**: transaction 5 loads a new pulse
  before its block, which adds exactly `P` cycles (D-070).
- **Latency** = `N_RG + N_RG * (P + 1)`: `N_RG` input cycles, then for each output `P`
  MAC cycles plus 1 cycle in the output register (transfer).
- This equals the G5 model `ceil(N_RG/L) * (P + L - 1) + N_RG + N_RG` at `L = 1`. With
  one lane, output and compute are interleaved rather than separate phases.
- **Period** = latency, because the next block is accepted in the cycle after the last
  output transfer.
- Throughput = `N_RG / period` = `1 / (P + 2)`.
- These are clock cycles in simulation only; no time or frequency claim is made.

### Generic structural synthesis

| Fixture | Problems | Cells | `$mul` | Memories | Memory bits | Warnings (all tri-state) |
|---|---|---|---|---|---|---|
| (1, 1) | 0 | 3278 | 4 | 4 | 256 | 32 |
| (5, 8) | 0 | 3367 | 4 | 4 | 1024 | 32 |
| (8, 3) | 0 | 3338 | 4 | 4 | 768 | 32 |
| (8, 8) | 0 | 3367 | 4 | 4 | 1024 | 32 |
| (64, 16) | 0 | 3779 | 4 | 4 | 5120 | 32 |
| (256, 64) | 0 | 5263 | 4 | 4 | 20480 | 32 |

- **Problems and cells:** from the acceptance flow
  `proc; opt; memory; opt; check -assert; stat`. Cells are generic Yosys cells (often
  multi-bit), not LUTs or flip-flops, so they are not a resource estimate. Series 7
  mapping is M4.
- **Memories and bits:** from the count-only flow
  `proc; opt; memory -nomap; opt; memory_unpack; stat` (D-070, DPC-DEFECT-001).
  - There are four memories: sample re/im with `2^addr_width(N_RG)` words, and pulse
    re/im with `2^addr_width(P)` words, all 32 bits wide. The power-of-two padding is
    the FIFO-DEFECT-001 lesson.
  - Example (1,1): `addr_width = 1`, so 4 x 2 x 32 = 256 bits.
- **`$mul` = 4:** the four mantissa multipliers of one complex product. The datapath is
  shared by all `k` and `n`.
- **Warnings = 32:** 8 float_pkg operations per MAC (4 multiplies, 1 subtraction, 3
  additions) x 4 = 32. This is the known CA-OBS-001 pattern, not hidden. Counted as
  `^Warning:` lines (CA-DEFECT-001).

## Design summary (implementer decisions D-069 to D-072)

- **States:** `S_IDLE`, `S_LOAD_REF`, `S_LOAD_IN`, `S_COMPUTE`, `S_OUT`. Sample 0 of a
  pulse or block is accepted in `S_IDLE`.
- **Priority / combinational path (D-069):**
  - In `S_IDLE`, `in_ready = pulse_loaded and not ref_valid`, so a pulse load wins
    over a block offered in the same cycle. This is the only combinational
    valid-to-ready path.
  - No valid depends on any ready. The output signals come from registers only.
- **Counter widths (D-071):**
  - `idx = n + k` has `addr_width(N_RG + P)` bits, enough for `N_RG + P - 1`.
  - It is compared with `N_RG` before it is truncated to a memory address. When
    `idx >= N_RG` the all-zero sample is used and the MAC still runs.
- **Arithmetic:** `acc = +0` at the start of each output, then `acc = add(acc, t_k)`
  for `k = 0..P-1`.
  - `t_k` uses the `edu_complex_mul` operation order on `conj(r[k])`; the conjugate is
    a sign-bit flip.
  - One MAC per clock, combinational between registers (no pipelining in M2b).

## Defects

| ID | Where | Root cause | Fix | Status |
|---|---|---|---|---|
| DPC-DEFECT-001 | Runner, memory metric (run `m2b_20261126T111341Z`) | Yosys `stat` counts only unpacked memories; after `memory -nomap` the memories are `$mem_v2` cells, so "Number of memories" read 0 | `memory_unpack` before `stat` in the count-only flow, plus a positive control that fails on a count of 0. Re-run `m2b_20261126T111903Z` | Fixed (1 attempt) |

No RTL or testbench defect was found: both full runs passed every simulation and
numerical check. The reference, the vectors and the acceptance criteria were not
changed.

## Limitations and observations

- The combinational path from the memory read through 4 multiplies, a
  subtraction/addition and the accumulate add is very long. This is intended in M2b;
  pipelining is a later milestone. No Fmax is claimed.
- The memories use asynchronous reads (as in edu_fifo V2). Whether they map to
  LUTRAM is an M4 question.
- In timing mode the testbench offers each sample as early as possible. Measured
  cycles are for that schedule only.
- The directed priority cycle withdraws the `in_valid` offer after the ref transfer.
  This is the only place the testbench withdraws a valid (D-072).
- The cell counts of the first, superseded run are identical to the accepted run; only
  its memory metric was wrong.
