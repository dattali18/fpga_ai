---
title: "EXP001 DPC functional specification"
sub-title: "Approved contract for gates G1-G5"
author: "Claude (planner); approved by the project owner"
date: "2026-11-26"
---

# EXP001 DPC functional specification

Status: APPROVED by the owner on 2026-11-26 (D-060), with the revision of P-02 in
D-061. This is the exp001 functional contract. Requirements R1-R7 and acceptance
criteria AC1-AC7 in `context/experiments/exp001/` are unchanged.

## Scope

- Deliverable: a vendor-independent VHDL-2008 digital pulse compression (DPC)
  component that takes `N_RG` received complex samples and a pulse reference of `P`
  complex samples and returns `N_RG` compressed complex samples. A review document
  for the senior FPGA engineer accompanies it.
- Verification environment: the project Docker toolchain only (GHDL, Yosys,
  Python/NumPy). **No FPGA device is available.** Evidence is limited to
  simulation, generic synthesis and technology mapping (Xilinx Series 7 resource
  counts). No timing (Fmax), power or on-hardware claims.
- All data are synthetic and public: textbook linear FM chirps, impulses and random
  values.

## What the component does

A radar transmits a known pulse; the echo returns weak and spread out. Pulse
compression slides the conjugated pulse along the received samples, multiplies
sample by sample and sums. Where the echo aligns with the pulse the products add in
phase and a sharp peak appears at the echo delay.

## G2 - Mathematical contract

```text
y[n] = sum_{k=0}^{P-1} conj(r[k]) * x[n + k]      n = 0 .. N_RG-1
x[m] = 0 for m >= N_RG
```

| Symbol | Meaning |
|---|---|
| `x[0..N_RG-1]` | received samples (range samples) |
| `r[0..P-1]` | pulse reference as supplied by the user. Any window or scaling is applied by the user beforehand |
| `y[0..N_RG-1]` | compressed output |

- **The hardware conjugates the reference** (negates the imaginary part, which is
  exact) and performs no reversal. The user supplies the transmitted pulse as is.
- **Alignment:** an echo of the pulse starting at sample `d` peaks at `y[d]`.
- **End of block:** for `n > N_RG-P` some samples fall after the block and count as
  zero, so those outputs are partial sums. They are computed and checked. The fully
  valid region is `n = 0 .. N_RG-P`.
- `N_RG < P`, `N_RG = P` and `N_RG > P` all follow from the same formula.

## G3 - Numerical policy

| Item | Decision |
|---|---|
| Format | IEEE-754 binary32 for every real and imaginary part |
| Rounding | Round to nearest, ties to even, on every operation |
| Product | `conj(r[k]) * x[n+k]` evaluated as the validated `edu_complex_mul`: four rounded products, one rounded subtraction (real), one rounded addition (imaginary) |
| Sum order | For each `n`, `acc = +0`, then `acc = acc + t_k` for `k = 0, 1, ..., P-1`, each addition rounded, per part |
| Subnormals | Supported |
| Inputs in scope | Finite values. Test data have magnitudes of about 1 or less, so overflow does not occur. NaN/Inf inputs follow IEEE propagation but are not tested |
| Exception flags | None |

Acceptance, two levels, both required:

1. **Error-bound gate.** For every output part:

   ```text
   |y_hw[n] - y_exact[n]| <= g * S[n] + (P+2) * 2^-149
   g = (P+2) u / (1 - (P+2) u),   u = 2^-24
   S_re[n] = sum_k |Re(c_k) Re(x_{n+k})| + |Im(c_k) Im(x_{n+k})|,   c_k = conj(r[k])
   S_im[n] = sum_k |Re(c_k) Im(x_{n+k})| + |Im(c_k) Re(x_{n+k})|
   ```

   `y_exact` is computed with exact rational arithmetic. Each term passes through at
   most `P+2` roundings whatever the summation order, so the bound does not depend on
   the architecture.
2. **Bit-exact check.** The output must equal the binary32 result computed in the
   order above, bit for bit.

## G1 - Golden reference

- `experiments/exp001/reference/dpc_ref.py`, standard library only. It contains:
  - the exact and the binary32 (`seq32`) models;
  - the error bound;
  - stimulus and vector generation (seed 20261126);
  - a judge for hardware output dumps (`--check`).
- Frozen by `experiments/exp001/reference/ORACLE_MANIFEST.sha256` and verified with
  `python3 scripts/verify_protected_digests.py --extra-manifest experiments/exp001/reference/ORACLE_MANIFEST.sha256`
  before and after every test run (AC1). Any change requires a new decision entry.
- `--selftest` covers:
  - hand examples and zero padding;
  - exact impulse alignment for every fixture;
  - the bound holding for `seq32`, without being vacuous;
  - detection of a dropped term;
  - NumPy cross-checks: `numpy.correlate` against the exact model, and a float32
    loop against `seq32` bit for bit.
- RTL and testbenches never import it. Only vector files and output dumps cross the
  boundary.

### Vector files

The files are generated into a build directory and are not committed (they are
reproducible). Format: one file per fixture, `dpc_n<N_RG>_p<P>.txt`, with tagged
lines:

```text
T <i>          start of transaction i
R <re> <im>    P pulse samples, present only when the pulse is (re)loaded
X <re> <im>    N_RG input samples
Y <re> <im>    N_RG expected outputs (bit exact)
```

Words are binary32 bit patterns written as 8 hex digits. Each fixture runs 7
back-to-back transactions:

| # | Transaction | Pulse |
|---|---|---|
| 0 | impulse at the first sample | chirp loaded |
| 1 | impulse at the last sample | kept |
| 2 | impulse in the middle | kept |
| 3 | chirp echo (delays `N_RG/5` and `N_RG/2`, amplitudes 1 and 0.3) plus noise | kept |
| 4 | uniform random | kept |
| 5 | wide-range random | random pulse loaded |
| 6 | uniform random | kept |

## G4 - Interface

| Group | Signals | Meaning |
|---|---|---|
| Clock, reset | `clk`, `rst` | Rising edge. Synchronous active-high reset returns to idle and forgets the pulse |
| Pulse load | `ref_valid`, `ref_ready`, `ref_re`, `ref_im` | `P` samples in order `k = 0..P-1`. Accepted only when idle. Kept until reset or the next load |
| Input block | `in_valid`, `in_ready`, `in_re`, `in_im` | `N_RG` samples in order. `in_ready` stays 0 until a pulse has been loaded |
| Output block | `out_valid`, `out_ready`, `out_re`, `out_im`, `out_last` | `N_RG` outputs in order. `out_last` marks `n = N_RG-1`. `out_ready = 0` pauses output |

- Generics: `G_N_RG`, `G_P`, `G_LANES`.
- Data ports are `std_logic_vector(31 downto 0)` binary32 bit patterns.
- A transfer happens at a rising edge with `valid = ready = 1`.
- One block at a time: the next block is accepted only after the previous block's
  last output has been transferred.
- **Cycle measurement (AC6):**
  - *Latency* = cycles from the first input transfer to the last output transfer
    inclusive, with `out_ready = 1`.
  - *Throughput* = `N_RG` divided by the cycles between the first input transfers
    of consecutive back-to-back blocks.
  - Both are reported in cycles only.

## G5 - Architecture and fixtures

The design works in three phases:
1. Store the block in an internal memory of `N_RG` words.
2. Compute outputs in groups of `G_LANES` neighbouring outputs. All lanes use the
   same `conj(r[k])` at the same time, and their samples form a sliding window, so
   each step reads one new sample and one pulse value whatever the lane count.
3. Stream the results out.

Each lane sums in the fixed `k` order, so results are identical for every
`G_LANES`.

- Expected compute time is about `ceil(N_RG/L) * (P + L - 1)` cycles, plus `N_RG`
  cycles in and `N_RG` out. This is a model, to be measured.
- Each multiply-add completes in one clock cycle. Pipelining is a later,
  separate optimisation milestone.

| Purpose | `(N_RG, P, G_LANES)` |
|---|---|
| Edge shapes | (1,1,1), (5,8,1), (8,3,1), (8,8,1) |
| Baseline | (64,16,1), (256,64,1) |
| Parallel | (64,16,3), (64,16,4), (64,16,64) simulation only, (256,64,8) |

Synthesis and Series 7 mapping run on every row except the simulation-only one.

## Milestones

| Milestone | Content | Exit evidence |
|---|---|---|
| M2a | Golden reference, specification, digest manifest | Self-test PASS in the container; identical vectors on authoring and local machines |
| M2b | RTL with `G_LANES = 1`, testbench, runner | Edge and baseline fixtures PASS (gate and bit-exact); clean structural synthesis |
| M2c | `G_LANES > 1` | Parallel fixtures PASS; measured cycles compared with the model |
| M4/M5 | Series 7 mapping, cycle measurements, review document for Amir | AC5-AC7 evidence |
