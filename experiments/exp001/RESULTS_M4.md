---
title: "EXP001 M4 results"
sub-title: "DPC post-synthesis simulation and Xilinx Series 7 resource mapping"
author: "Claude Code (implementer)"
date: "2026-11-26"
---

# EXP001 M4 results - post-synthesis simulation and Series 7 mapping

Status: **candidate, for planner review.** The runner reported **OVERALL: FAIL** because of
one row: Part A (256,64,8), where GHDL could not compile the netlist (M4-TOOL-004,
[below](#m4-tool-004---the-256648-netlist-could-not-be-compiled)). Every other check
passed. All 8 Part B mappings passed.

Prompt: [M4_PROMPT.md](prompts/M4_PROMPT.md). Design: the accepted M2c RTL, commit
`ded8d4a` ([VALIDATION_M2C.md](VALIDATION_M2C.md)), unchanged. Decisions: D-081 to D-085.

## Method and provenance

| Item | Value |
|---|---|
| Run | [m4_20261126T123436Z](evidence/m4_20261126T123436Z/summary.txt) |
| Command | `bash experiments/exp001/tb/run_m4.sh` |
| Total time | 4628 s (77 min); Part B alone about 35 min |
| Git HEAD at the run | `ded8d4ad34d339c29f7812fd6da8863723c2d1dc` (runner and `m4_sat_pkg.vhd` uncommitted; their hashes are in `source_sha256.txt`) |
| Image | `fpga_ai-toolchain:m1-arm64` (`sha256:cfa652b2...8d85f`), GHDL 4.1.0, Yosys 0.33 |
| Docker VM | 8 CPUs, 10 GB memory (Colima) |
| Seed, stall rate | 20261126, 30 % |
| RTL and `tb_dpc.vhd` | byte-identical to `ded8d4a` (PASS) |
| Protected and oracle digests | PASS before and after; oracle manifest digest equals D-068 |

### Part A - netlist simulation

Wording approved by the planner (D-083):

> GHDL netlist simulation with saturated shift amounts (M4-TOOL-002) and constant-Z
> selects resolved as in Yosys (M4-TOOL-003); mapped netlist simulation BLOCKED (no
> Verilog simulator).

Per fixture:
1. `ghdl --synth --std=08 --no-formal --out=vhdl` turns the RTL into a flat VHDL netlist
   (`net.vhdl`).
2. Two exact text rewrites produce `net_satz.vhdl`; each count must equal its expected
   value or the fixture stops:
   - **N1** (M4-TOOL-002, D-082) replaces `to_integer (unsigned (s))` inside
     `shift_left`/`shift_right` calls with `sat_shift (s)`
     ([m4_sat_pkg.vhd](tb/m4_sat_pkg.vhd)). Reason: GHDL writes the float_pkg shifts
     with a 32-bit shift amount, and amounts of 2^31 or more fail VHDL's integer range
     check. The meaning is unchanged: shifting a W-bit vector by any amount ≥ W gives
     all zeros, and every vector in the netlist is far shorter than 2^30 bits.
   - **N2** (M4-TOOL-003, D-083) replaces `std_logic'('Z') = '0'` with `true`; expected
     count `32·L`. Reason: float_pkg's input classifier (`classfp`) tests for
     metavalues ('X', 'U', ...). Synthesis keeps that test as a multiplexer whose select
     is the constant 'Z'. The test has no hardware meaning. IEEE 1076.6 treats such
     comparisons as false in synthesis, and Yosys keeps the normal path. N2 applies the
     same reading in simulation.
3. The unchanged testbench `tb_dpc.vhd` drives the netlist in **stress** mode (30 %
   random stalls) and **timing** mode (no stalls). `dpc_ref.py --check` judges each
   output dump. The measured cycle counts must equal the closed form from M2c (D-076).

Original, N1 and N1+N2 netlist hashes are in
[netlists.csv](evidence/m4_20261126T123436Z/postsyn/netlists.csv). Both diffs are kept
per fixture.

**Yosys three-line test** (basis of N2, [zsel_test](evidence/m4_20261126T123436Z/zsel_test)):

```verilog
module t(input [3:0] a, output [3:0] y);
  assign y = 1'bZ ? 4'b1010 : a;
endmodule
```

After `proc; opt`, Yosys writes `assign y = a;`, which is the normal path. PASS.

**Controls:**
- **Netlist negative control:** the (8,3,1) N1+N2 netlist run against a vector file with
  one wrong Y word fails as intended (1 error). PASS.
- **Diagnostic control (N1 only, no N2):** (8,3,1) gives 56 of 56 outputs `X` (56
  errors), as expected. Without N2, every float operation classifies its inputs as
  invalid. PASS.

### Part B - Series 7 mapping

- Flow (F1, M4-TOOL-001, D-081): `synth_xilinx -family xc7 -top dpc -noiopad -noclkbuf`,
  with the coarse step run by hand **without `share`**. `share` (SAT-based resource
  sharing) was killed for lack of memory even on the smallest design.
  - The runner checks that the sequence used equals the standard coarse step minus
    `share` ([flow_check.txt](evidence/m4_20261126T123436Z/flow_check.txt), result
    `EQUAL_MINUS_SHARE`; Yosys 0.33 has no `-noshare` option).
  - All counts below are therefore a **likely upper bound (no resource sharing)**.
- Each mapping then runs `check -assert`, `stat -tech xilinx` and `ltp -noff`.
- Counts are Yosys cell counts, out of context, before placement. They are not Vivado
  utilisation.

### Part C - equivalence

NOT_RUN (planner decision). Expected result: INCONCLUSIVE, because DSP48E1 is a black box
to Yosys equivalence checking.

## Part A results

| Fixture (N_RG,P,L) | N1 replaced | N2 replaced (expected 32·L) | Stress | Timing | Bit-exact mismatches | Worst err/tol | Cycles = formula |
|---|---:|---:|---|---|---:|---:|---|
| (8,3,1) | 32 | 32 | PASS, 56 outputs | PASS | 0 | 0.2490 | PASS, latency 40 |
| (5,8,2) | 64 | 64 | PASS, 35 outputs | PASS | 0 | 0.1372 | PASS, latency 37 |
| (8,8,3) | 96 | 96 | PASS, 56 outputs | PASS | 0 | 0.1415 | PASS, latency 46 |
| (64,16,1) | 32 | 32 | PASS, 448 outputs | PASS | 0 | 0.1490 | PASS, latency 1152 |
| (64,16,4) | 128 | 128 | PASS, 448 outputs | PASS | 0 | 0.1490 | PASS, latency 432 |
| (256,64,8) | 256 | 256 | **FAIL**: netlist did not compile (M4-TOOL-004) | not run | - | - | - |

For the five fixtures that ran, the generic netlist computes exactly the same bits as the
RTL and the golden reference. It also takes exactly the same number of clock cycles.

### M4-TOOL-004 - the (256,64,8) netlist could not be compiled

| Observation | Value |
|---|---|
| Runner log | `/usr/bin/ghdl-gcc:error: exec error` after `ghdl -a` of `net_satz.vhdl` |
| Netlist size | 8.1 MB of VHDL; about 1 MB per lane |
| Earlier fixtures | (64,16,4): 4.0 MB, compiled in about 4 min (64 MB object file) |
| Assembly file left behind | `net_satz.s`, 296 MB, last written 8 min before the error |
| Assembler re-run on that file (diagnostic) | `as` rc=0, 3.6 GB peak, 10 s. It warns "end of file not at end of a line", so the file is **truncated** |

The code generator (the GCC back end inside GHDL) stopped partway through writing its
output and never finished. The diagnostic re-run of the analysis is described in
[DIAGNOSIS_M4_TOOL_004.md](evidence/m4_20261126T123436Z/DIAGNOSIS_M4_TOOL_004.md).
In that re-run, with the same image, the same 10 GB VM and nothing else running:
- `ghdl1` reached a **9.43 GB** peak;
- free VM memory fell to **0.33 GB**;
- after 18 min it failed with the same error;
- it left the same truncated 296,255,488-byte assembly file.

The failure is therefore reproducible memory exhaustion in GHDL's GCC back end. The
kernel's out-of-memory record was not read, because that needs `sudo`.

This is a tool resource limit, not a design result. The N1 and N2 counts for this
fixture were exact (256 = 32·8). The RTL of (256,64,8) was verified bit-exact in M2c.
The runner reported FAIL because its analysis step has no BLOCKED path. Proposal for
the planner: treat this row as BLOCKED, by analogy with decision 4 for mappings. See
[open questions](#open-questions-for-the-planner).

## Part B results

All 8 mappings: `check -assert` 0 problems, PASS.

| Config (N_RG,P,L) | Strategy | Status | Time (s) | Peak memory (GB) | Logic LUT | FF | CARRY4 | MUXF7 | MUXF8 | DSP48E1 | LUTRAM (types) | SRL | RAMB18/36 | Other (INV) | Logic depth |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---|---:|---:|
| (64,16,1) | default | PASS | 48 | 1.18 | 8404 | 96 | 1346 | 2028 | 714 | 8 | 34 (12 RAM32M + 22 RAM64M) | 0 | 0/0 | 498 | 712 |
| (256,64,1) | default | PASS | 50 | 1.18 | 8439 | 106 | 1351 | 2095 | 769 | 8 | 110 (RAM64M) | 0 | 0/0 | 497 | 722 |
| (256,64,2) | default | PASS | 104 | 2.23 | 16424 | 235 | 2672 | 4077 | 1473 | 16 | 110 (RAM64M) | 0 | 0/0 | 990 | 735 |
| (64,16,4) | default | PASS | 230 | 4.33 | 32052 | 483 | 5312 | 8117 | 2871 | 32 | 34 (12 RAM32M + 22 RAM64M) | 0 | 0/0 | 1976 | 768 |
| (256,64,4) | default | PASS | 245 | 4.33 | 32839 | 493 | 5316 | 8400 | 3025 | 32 | 110 (RAM64M) | 0 | 0/0 | 1981 | 758 |
| (256,64,8) | default | PASS | 924 | 8.56 | 64982 | 1006 | 10606 | 16171 | 5832 | 64 | 110 (RAM64M) | 0 | 0/0 | 3953 | 774 |
| (64,16,4) | -nolutram | PASS | 253 | 4.33 | 33515 | 5603 | 5312 | 7862 | 2797 | 32 | 0 | 0 | 0/0 | 1978 | 754 |
| (64,16,4) | -nodsp | PASS | 256 | 4.32 | 55622 | 483 | 5504 | 8222 | 2940 | 0 | 34 (12 RAM32M + 22 RAM64M) | 0 | 0/0 | 1976 | 781 |

How to read the table:
- **Logic LUT:** the sum of LUT1 to LUT6.
- **Other:** only INV (inverter) primitives in every row.
- **Logic depth:** logic depth (cells on the longest combinational path), from
  `ltp -noff`. It counts cells, not delay. It is **not** a frequency or timing result.
- All counts are likely upper bounds (no resource sharing).
- Full per-cell-type counts: [cell_types.csv](evidence/m4_20261126T123436Z/map/cell_types.csv)
  and [mapping.csv](evidence/m4_20261126T123436Z/map/mapping.csv).

**Probe result (not part of the run).** Before the run, (8,3,1) was mapped once to test
the flow. Its numbers are a probe result only:
- 47 s, 1.18 GB, 0 problems;
- logic LUT 8261, FF 83, CARRY4 1340, MUXF7/8 2024/735;
- DSP48E1 8, 24 RAM32M, BRAM 0, INV 495;
- logic depth 700.

## Expectations (E3)

| Expectation | Result | Numbers |
|---|---|---|
| Memories map to LUTRAM, not BRAM (asynchronous reads) | **Confirmed** | 0 RAMB18/36 in every row. Memory bits are exactly accounted for (below) |
| Several DSP48E1 per 24×24-bit multiplication | **Confirmed: 2 per multiplication** | 8 DSP48E1 per lane = 4 real multiplications × 2 (one DSP48E1 multiplies 25×18 bits). Exactly `8·L` in every default row |
| Resources grow roughly linearly with L | **Confirmed** | See the per-lane table below; increments are constant within 3 % |

LUTRAM accounting:
- **(256,64):** the two sample memories (256×32 bits) take 4 × 11 = 44 RAM64M each; the
  two pulse memories (64×32 bits) take 11 each. 2·44 + 2·11 = 110. One RAM64M stores
  64 words × 3 bits.
- **(64,16):** the sample memories (64×32 bits) take 11 RAM64M each = 22; the pulse
  memories (16×32 bits) take 6 RAM32M each = 12. One RAM32M stores 32 words × 6 bits,
  so these are half used.
- The LUTRAM count does not depend on L: the memories are shared by all lanes.

## Resources versus lanes, (256,64) (E4)

| L | Logic LUT | FF | CARRY4 | MUXF7 | MUXF8 | DSP48E1 | LUTRAM | INV | Logic depth |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 8439 | 106 | 1351 | 2095 | 769 | 8 | 110 | 497 | 722 |
| 2 | 16424 | 235 | 2672 | 4077 | 1473 | 16 | 110 | 990 | 735 |
| 4 | 32839 | 493 | 5316 | 8400 | 3025 | 32 | 110 | 1981 | 758 |
| 8 | 64982 | 1006 | 10606 | 16171 | 5832 | 64 | 110 | 3953 | 774 |

Increment per added lane:

| Step | Logic LUT / lane | FF / lane | CARRY4 / lane | DSP48E1 / lane | INV / lane |
|---|---:|---:|---:|---:|---:|
| L 1 → 2 | 7985 | 129 | 1321 | 8 | 493 |
| L 2 → 4 | 8208 | 129 | 1322 | 8 | 496 |
| L 4 → 8 | 8036 | 128 | 1323 | 8 | 493 |

- About **8000 logic LUTs, 129 FFs and 8 DSP48E1 per lane**.
- The fixed part (memories, control) is small: one lane alone is about 8400 LUTs.
- 128 of the 129 FFs per lane are the lane's accumulator (64 bits) and its window
  register (64 bits).
- Almost all the logic is the binary32 multiply-accumulate. It is built from
  `ieee.float_pkg`: four multiplications, a subtraction and two additions, all
  combinational within one clock cycle.
- N_RG and P hardly matter: (64,16,4) and (256,64,4) differ by 787 LUTs (2.4 %).
- **Logic depth grows only slightly with L, from 722 to 774 cells.** The longest path is
  one lane's multiply-accumulate, so it is long whatever L is. This only shows that each
  cycle does a lot of work. It does not give a clock frequency.

## Sensitivity, (64,16,4)

| Strategy | Logic LUT | FF | DSP48E1 | LUTRAM | Change versus default |
|---|---:|---:|---:|---:|---|
| default | 32052 | 483 | 32 | 34 | - |
| -nodsp | 55622 | 483 | 0 | 34 | +23570 LUT (+74 %); about 737 LUT per DSP48E1, or about 1470 LUT per 24×24 multiplication |
| -nolutram | 33515 | 5603 | 32 | 0 | +5120 FF (exactly the 80 words × 2 × 32 memory bits) and +1463 LUT for the read multiplexers |

DSP48E1 saves about 42 % of the logic LUTs. LUTRAM saves 5120 flip-flops for these
small memories. The saving grows with N_RG, because LUTRAM grows with N_RG while
everything else hardly changes.

## Findings

1. **Netlist equals RTL** for the five fixtures that compiled. Every output bit matches
   and every cycle count is the same, in stress and timing modes (E1 partial: 5 of 6).
2. **CA-OBS-001 explained (not fixed, D-084).**
   - Each of the 4 Yosys "limited tri-state support" warnings per float_pkg operation
     (32 per lane) is one constant-'Z' select from float_pkg's metavalue test.
   - The N2 count equals 32·L in all six fixtures.
3. **Portability finding for Amir (D-084).**
   - Synthesising `ieee.float_pkg` relies on each tool treating that metavalue test as
     false.
   - Yosys does. Vivado has not been tested.
   - A plain VHDL simulation of a GHDL netlist does not: it gives all-X outputs (the
     diagnostic control).
4. **Mapping memory and time grow fast with L.** (256,64,8) needed 8.56 GB of the 10 GB
   VM and 15 min. `share` could not run at all (M4-TOOL-001), so counts are upper
   bounds.
5. **GHDL's GCC back end could not compile the 8 MB (256,64,8) netlist**
   (M4-TOOL-004). Netlist simulation therefore covers L ≤ 4.

6. **Netlist simulation logs are full of harmless numeric_std warnings.**
   - The netlist simulations print "metavalue detected" warnings throughout each run
     (27,782 log lines for (8,3,1) stress).
   - They come from combinational logic evaluating registers and memory words that have
     not been written yet. In the RTL, float_pkg's metavalue test (the test N2 removes)
     hides these values.
   - Results are unaffected: 0 errors, bit exact.
   - Side effect: 11 simulation logs total 447 MB, the largest 114 MB, which is over
     GitHub's 100 MB file limit. They are listed in the run manifest but **not staged**.
     Gzip shrinks a 114 MB log to 0.6 MB. The planner decides the format (open question 3).

## Limitations

- No timing, no placement, no routing, no power. Logic depth is a cell count, not a
  delay. No Fmax claim.
- No Vivado. Counts are Yosys estimates before placement, without resource sharing
  (likely upper bounds). Vivado's counts can differ.
- Netlist simulation is of the **generic** GHDL netlist, with two documented text
  rewrites (N1, N2). The **mapped** Series 7 netlist was not simulated (BLOCKED: no
  Verilog simulator in the image), and no equivalence proof was attempted (Part C
  NOT_RUN).
- (256,64,8) netlist simulation not done (M4-TOOL-004).
- No device fit claim: the counts are not compared with any specific device.

## Open questions for the planner

1. Classify the Part A (256,64,8) row as BLOCKED (tool resource limit, M4-TOOL-004)
   instead of FAIL? The evidence is not edited either way; the classification would be
   recorded in the decision log and here.
2. If L = 8 netlist simulation is wanted: re-run that one fixture with more VM memory.
   That is the owner's decision (decision 4). Any L = 8 netlist is about 8 MB, so a
   smaller N_RG or P would not help.
3. The 11 large simulation logs (447 MB): commit them gzip-compressed, with a correction
   note listing the new digests (D-066 precedent), or keep them only in the ignored
   `build/` folder? Either way, their original SHA-256 values remain in the run manifest.
