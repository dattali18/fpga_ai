---
title: "EXP001 M2c validation"
sub-title: "DPC parallel lanes (G_LANES > 1)"
author: "Claude Code (implementer)"
date: "2026-11-26"
---

# EXP001 M2c validation - DPC parallel lanes

Prompt: [M2C_PROMPT.md](prompts/M2C_PROMPT.md). Contract:
[DPC_SPECIFICATION.md](docs/DPC_SPECIFICATION.md), G5. Baseline: M2b
([VALIDATION_M2B.md](VALIDATION_M2B.md)).

Runs:
- **Accepted candidate:** [m2c_20261126T114754Z](evidence/m2c_20261126T114754Z/summary.txt),
  OVERALL PASS.
- **Superseded first run:**
  [m2c_20261126T113151Z](evidence/m2c_20261126T113151Z/CORRECTION.md), OVERALL FAIL
  (DPC-DEFECT-002).

Scope of the claims: simulation (GHDL 4.1.0), numerical verification against the frozen
golden reference, and generic structural synthesis (GHDL `--synth` to Verilog, Yosys
0.33). Not established (M4, D-075): Series 7 mapping and LUTRAM inference,
post-synthesis equivalence, timing (Fmax), power, behaviour on hardware.

## Command

```sh
bash experiments/exp001/tb/run_dpc.sh
```

The runner works on the host (bash 3.2) and runs every tool step in
`fpga_ai-toolchain:m1-arm64`. The accepted run took about 12.4 minutes: 2026-11-26
11:47:54Z to 12:00:16Z. Its source state was `6cc35c0` plus the uncommitted M2c
changes; their SHA-256 values are in
[source_sha256.txt](evidence/m2c_20261126T114754Z/source_sha256.txt).

## Files changed

| Path | Change |
|---|---|
| [rtl/dpc.vhd](rtl/dpc.vhd) | Lane architecture: groups, sliding window, `L` MAC lanes, `S_FILL`, lane output mux, new elaboration check. Entity unchanged |
| [rtl/dpc_pkg.vhd](rtl/dpc_pkg.vhd) | Unchanged |
| [tb/tb_dpc.vhd](tb/tb_dpc.vhd) | **Unchanged** (already generic in `G_LANES`) |
| [tb/run_dpc.sh](tb/run_dpc.sh) | Fixtures as `N:P:L:synth`; closed-form cycle check (C6); NC3; `$mul = 4L` and tri-state `= 32L` checks |

## Closed-form cycle formula (D-076)

With `out_ready = 1`, `G = ceil(N_RG / L)` groups, `v_g = min(L, N_RG - n0)` valid
lanes per group:

```text
latency = N_RG                                  input transfers
        + sum_g [ (L - 1) + P + v_g ]           fill + compute + output, per group
        = 2*N_RG + ceil(N_RG / L) * (P + L - 1)

period  = latency                               next block accepted the cycle after its last output
period  = latency + P                           when the next block starts with a pulse load (t=4 -> 5)
```

- For `L = 1` the formula reduces to `N_RG + N_RG*(P+1)`, the M2b result.
- `ceil(N_RG/L)*(P+L-1)` is the compute model of spec G5.
- The runner checks every `CYCLES` line of every fixture against this formula: 7 lines
  per fixture, including the `+P` reload line and `NA` for the last period.

## Acceptance (C1-C8)

| ID | Criterion | Result | Evidence |
|---|---|---|---|
| C1 | Every fixture, stress (30 %) and timing (0 %): 0 mismatches, 0 protocol errors | **PASS**: 13 fixtures x 2 modes (+13 timing repeats), 0 errors | `sim/sim_*.log` |
| C2 | `--check` on every dump: 0 gate failures, 0 bit-exact mismatches | **PASS**: 39/39 dumps, 0 and 0 | `sim/check_*.log` |
| C3 | NC1, NC2 and the lane-specific control fail as intended | **PASS**: NC1 `--check` exits 1; NC2 TB FAIL; NC3 TB FAIL, with exactly 1 mismatch at tx 0, `n = 7` (the corrupted last output; (8,8,3), last group lanes 6 and 7, lane 8 inactive) | `neg/` |
| C4 | Synthesis rows: 0 problems; `$mul = 4L`; tri-state `= 32L`; memories recorded | **PASS**: 9/9 rows | `syn/synthesis_summary.csv` |
| C5 | Protected and oracle digests before and after; oracle manifest = D-068 | **PASS**: 35 + 1 files both times; digest unchanged | `protected_*.txt`, `oracle_manifest_sha256_*.txt` |
| C6 | Measured latency and period equal the formula, identical on a repeat | **PASS**: 13/13 formula, 13/13 repeat | `sim/cycles_*` |
| C7 | `L = 1` regression passes C1/C2; cycles against M2b | **PASS**: all 6 bit exact; cycles identical to M2b (table below) | `sim/` |
| C8 | Validation, records, staged, not committed | **PASS**: see the planner report | this file, `research/` |

## Cycles per fixture (timing mode, measured = formula)

| `(N_RG, P, L)` | Latency = period | Formula | Period with reload (*) | Speed-up vs `L = 1` | Throughput (samples/cycle) |
|---|---|---|---|---|---|
| (1, 1, 1) | 3 | 3 | 4 | 1 (M2b: 3) | 0.333 |
| (5, 8, 1) | 50 | 50 | 58 | 1 (M2b: 50) | 0.100 |
| (8, 3, 1) | 40 | 40 | 43 | 1 (M2b: 40) | 0.200 |
| (8, 8, 1) | 80 | 80 | 88 | 1 (M2b: 80) | 0.100 |
| (64, 16, 1) | 1152 | 1152 | 1168 | 1 (M2b: 1152) | 0.0556 |
| (256, 64, 1) | 16896 | 16896 | 16960 | 1 (M2b: 16896) | 0.0152 |
| (64, 16, 3) | 524 | 524 | 540 | 2.20 | 0.122 |
| (64, 16, 4) | 432 | 432 | 448 | 2.67 | 0.148 |
| (256, 64, 8) | 2784 | 2784 | 2848 | 6.07 | 0.0920 |
| (64, 16, 64) | 207 | 207 | 223 | 5.57 | 0.309 |
| (8, 3, 8) | 26 | 26 | 29 | 1.54 | 0.308 |
| (5, 8, 2) | 37 | 37 | 45 | 1.35 | 0.135 |
| (8, 8, 3) | 46 | 46 | 54 | 1.74 | 0.174 |

How to read the table:
- **(\*)** Measured periods from transaction 4 to 5 include the pulse reload. They
  equal latency + P (D-070).
- **Speed-up:** latency at `L = 1` divided by latency at `L`, for the same
  `(N_RG, P)`.
- The speed-up stays below `L` because input and output remain serial (`2*N_RG`
  cycles) and each group pays `L - 1` fill cycles. Overlapping output with the next
  group was allowed but not built (D-076).
- Clock cycles in simulation only; no time or frequency claim.

## Simulation and numerical checks (accepted run)

| `(N_RG, P, L)` | Outputs | Checks stress / timing | Errors | Worst err/tol |
|---|---|---|---|---|
| (1,1,1) | 7 | 62 / 53 | 0 | 0.2569 |
| (5,8,1) | 35 | 774 / 711 | 0 | 0.1372 |
| (8,3,1) | 56 | 625 / 571 | 0 | 0.2490 |
| (8,8,1) | 56 | 1200 / 1131 | 0 | 0.1415 |
| (64,16,1) | 448 | 16802 / 16139 | 0 | 0.1490 |
| (256,64,1) | 1792 | 238562 / 236555 | 0 | 0.0637 |
| (64,16,3) | 448 | 7896 / 7347 | 0 | 0.1490 |
| (64,16,4) | 448 | 6689 / 6059 | 0 | 0.1490 |
| (256,64,8) | 1792 | 41240 / 38987 | 0 | 0.0637 |
| (64,16,64) | 448 | 3485 / 2909 | 0 | 0.1490 |
| (8,3,8) | 56 | 450 / 375 | 0 | 0.2490 |
| (5,8,2) | 35 | 565 / 529 | 0 | 0.1372 |
| (8,8,3) | 56 | 718 / 655 | 0 | 0.1415 |

- **Same worst err/tol for every lane count:** for each `(N_RG, P)`, the value is
  identical across lane counts. This is expected: the outputs are bit-identical to
  the `L = 1` design and to `seq32`.
- **Check counts:** these fall as `L` grows, because the testbench checks the
  `in_ready = 0` and `ref_ready = 0` protocol on every processing cycle, and there
  are fewer of those cycles.

## Generic structural synthesis (accepted run)

| `(N_RG, P, L)` | Problems | Cells | `$mul` | Memories | Memory bits | Tri-state warnings |
|---|---|---|---|---|---|---|
| (1,1,1) | 0 | 3283 | 4 | 4 | 256 | 32 |
| (5,8,1) | 0 | 3373 | 4 | 4 | 1024 | 32 |
| (8,3,1) | 0 | 3344 | 4 | 4 | 768 | 32 |
| (8,8,1) | 0 | 3373 | 4 | 4 | 1024 | 32 |
| (64,16,1) | 0 | 3785 | 4 | 4 | 5120 | 32 |
| (256,64,1) | 0 | 5269 | 4 | 4 | 20480 | 32 |
| (64,16,3) | 0 | 9753 | 12 | 4 | 5120 | 96 |
| (64,16,4) | 0 | 12733 | 16 | 4 | 5120 | 128 |
| (256,64,8) | 0 | 26137 | 32 | 4 | 20480 | 256 |

- **Flows:** the acceptance flow (`... memory; opt; check -assert; stat`) is unchanged.
  Memory figures come from the count-only flow (`memory -nomap; opt; memory_unpack;
  stat`).
- **Warnings:** all are tri-state warnings, 8 float_pkg operations x 4 x `L`
  (CA-OBS-001).
- **Memories:** there are still exactly 4, one sample read and one pulse read per
  cycle for every `L`. Memory bits depend only on `(N_RG, P)`.
- **Cells:** generic Yosys cells (often multi-bit), not a resource estimate. They grow
  by about 3,000 per lane, mostly the lane arithmetic. The `L = 1` rows are 5-6 cells
  larger than M2b (extra `S_FILL` state and lane counters).

## Design summary (D-076, D-077)

- **Groups and window:**
  - Groups start at `n0 = 0, L, 2L, ...`. The window has `L-1` registers plus the
    sample read in the current cycle.
  - `S_FILL` reads `x[n0..n0+L-2]` in `L-1` cycles. `S_COMPUTE` runs `P` cycles,
    shifting the window by one each cycle.
  - The sample index `idx` and `n0` have `addr_width(N_RG + P + L)` bits. `idx` is
    compared with `N_RG` before it is truncated to an address; past the block the
    zero word is used.
- **Accumulators:** each lane's accumulator input is `+0` at `k = 0`. The
  accumulators are the result buffer: `S_OUT` sends `acc(j_out)` through a bounded
  mux. Lanes past `N_RG - 1` are never sent.
- **Handshake:** unchanged from M2b, including the D-069 priority rule.
- **Elaboration check:** `1 <= G_LANES <= G_N_RG`.

## Defects

| ID | Where | Root cause | Fix | Status |
|---|---|---|---|---|
| DPC-DEFECT-002 | `rtl/dpc.vhd`, run `m2c_20261126T113151Z` | Window arrays had `L` entries but only `L-1` were written. GHDL synthesis turned the unwritten entry into a `'bZ` constant: +2 tri-state warnings for every `L > 1`. Not functional (the entry was never read) | Window type with exactly `L-1` entries (at least 1); then 32L warnings and no `'bZ` in any netlist | Fixed (attempt 1 of 3) |

Preventive measure before the first run: the lane output select is an explicit bounded
mux (`select_lane`), because `j_out` has `2^addr_width(L)` codes for `L` lanes. This is
the FIFO-DEFECT-001 lesson.

The reference, the vectors, the testbench and the acceptance criteria were not changed.

## Limitations and observations

- **Long logic paths:** the arithmetic is one long combinational path per lane, as in
  M2b; pipelining is a later milestone. No Fmax is claimed.
- **Memory read on the MAC path:** in `S_COMPUTE`, lane `L-1` takes its operand directly
  from the asynchronous memory read. That puts the memory read on the MAC path, as
  in M2b.
- **Serial input and output:** the `2*N_RG` term dominates for large `L`. Overlapping
  output with compute, or input with compute, is the obvious next cycle optimisation
  and needs its own milestone.
- **Synthesis cost:** the (64,16,64) fixture was simulated only (per the prompt). Its
  synthesis cost would be about 64 lanes x 3,000 generic cells.
