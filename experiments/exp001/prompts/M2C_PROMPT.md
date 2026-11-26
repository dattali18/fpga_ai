---
title: "EXP001 M2c milestone prompt"
sub-title: "DPC parallel lanes (G_LANES > 1)"
author: "Claude (planner)"
date: "2026-11-26"
---

# EXP001 M2c - DPC parallel lanes (`G_LANES > 1`)

Implementer: Claude Code (D-064). Contract:
[DPC_SPECIFICATION.md](../docs/DPC_SPECIFICATION.md), G5. Baseline: the accepted M2b
design (run `m2b_20261126T111903Z`). Where this prompt and the specification
disagree, the specification wins; stop and report.

Start with a short plan (files, design, checks, risks), then wait for Daniel's "go".

## 1. Goal

Make `G_LANES` work for any value with `1 <= G_LANES <= G_N_RG`. The `G_LANES`
multiply-add lanes work on neighbouring outputs at the same time, and the results
must stay bit-identical to the reference for every lane count.

Out of scope: pipelining the arithmetic, Series 7 mapping, post-synthesis checks
(these belong to M4). The reference, the vectors and the M2b acceptance criteria are
unchanged.

## 2. Architecture (spec G5)

- **Groups:** outputs are computed in groups `n0 = 0, L, 2L, ...`. In a group, lane
  `j` computes `y[n0 + j]`.
- **Sliding window:**
  - At step `k`, every lane uses the same `conj(r[k])`.
  - Lane `j` uses `x[n0 + j + k]`. These samples form a window of `L` consecutive
    samples, which moves one place per step.
  - Keep the window in `L` registers. Fill it once per group, then at each step shift
    it by one and read one new sample from memory.
  - So there is one sample read and one pulse read per cycle, whatever `L` is.
- **Per-lane arithmetic:** exactly the M2b rules. Set `acc = +0`, then add terms in
  the order `k = 0..P-1` using the same `float_pkg` calls. This keeps every lane
  bit-exact with `seq32`.
- **Zero padding:** apply the M2b rule to the window. Any sample index
  `>= G_N_RG` enters the window as the all-zero word. The index is computed in a
  counter wide enough for `G_N_RG + G_P + G_LANES`, and compared before it is
  truncated to a memory address.
- **Last group:** when `L` does not divide `N_RG`, the lanes with
  `n0 + j >= N_RG` are inactive. They may compute, but their results are never
  output.
- **Output:** after a group finishes, transfer its valid results in order through
  the `out` stream, honouring `out_ready`. Use a small result buffer of `L` entries
  or an equivalent design. `out_last` marks `n = N_RG - 1`.
- **Elaboration check:** assert `1 <= G_LANES <= G_N_RG` with `severity failure`,
  replacing the M2b assertion.
- **Optional:** overlapping output with the next group's computation. It is
  allowed, but only if it is simple. Correctness comes before cycles.

Derive the **exact closed-form cycle formula** of your design for latency and
period as a function of `N_RG`, `P` and `L`, with `out_ready = 1`. Write it in the
plan and in `VALIDATION_M2C.md`.

## 3. Files

| Path | Change |
|---|---|
| `experiments/exp001/rtl/dpc.vhd`, `dpc_pkg.vhd` | Lane architecture; the entity stays as specified |
| `experiments/exp001/tb/tb_dpc.vhd` | Change only if needed. Document any change |
| `experiments/exp001/tb/run_dpc.sh` | Fixture list with `G_LANES`; everything else as in M2b |
| `experiments/exp001/VALIDATION_M2C.md`, `evidence/m2c_<run>/` | Results |
| Research records | Decisions from the next free ID, STATUS, TODO, changelog, daily note |

## 4. Fixtures `(N_RG, P, G_LANES)`

| Group | Fixtures | Synthesis |
|---|---|---|
| Regression | all six M2b fixtures with `L = 1` | yes |
| Specification | (64,16,3), (64,16,4), (256,64,8) | yes |
| Specification, simulation only | (64,16,64) | no |
| Lane edge cases | (8,3,8) (`L = N_RG`), (5,8,2) (`P > N_RG`), (8,8,3) (`L` does not divide `N_RG`), (1,1,1) is already in the regression set | no |

Vectors depend only on `(N_RG, P)`: use the existing generated files.

## 5. Acceptance criteria

| ID | Criterion |
|---|---|
| C1 | Every fixture, stress (30 %) and timing (0 %): 0 mismatches, 0 protocol errors |
| C2 | `dpc_ref.py --check` on every dump: 0 gate failures, 0 bit-exact mismatches |
| C3 | Negative controls as in M2b fail as intended, plus one lane-specific control: corrupt the expected value of the **last** output of a block where `L` does not divide `N_RG`. The testbench must FAIL |
| C4 | Synthesis rows: 0 structural problems. Record cells, `$mul` (expect `4L`), memory objects and bits, and tri-state warnings (expect `32L`, CA-OBS-001) |
| C5 | Protected and oracle digests PASS before and after; the oracle manifest SHA-256 equals D-068 |
| C6 | Measured latency and period in timing mode **equal the closed-form formula** for every fixture, and are identical on a repeat run |
| C7 | Regression: the `L = 1` fixtures still pass C1 and C2. Report their cycle counts against M2b |
| C8 | `VALIDATION_M2C.md`, records written, changes staged, not committed |

Defect handling as in M2b: give each defect an ID (`DPC-DEFECT-nnn`), state the root
cause, fix within scope, never touch the reference, vectors or criteria, and stop
after three failed attempts on one issue. Write `MANIFEST.sha256` last.

## 6. Report

End with the `PLANNER REPORT` block. Include:
- the C1 to C8 table;
- per fixture: latency, period, formula value, and speed-up against `L = 1` for the
  same `(N_RG, P)`;
- synthesis metrics;
- defects;
- the runner command.

Explain the results to Daniel in at most 10 plain-language lines.
