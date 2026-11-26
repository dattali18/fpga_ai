---
title: "Briefing for Amir - EXP001 DPC"
sub-title: "Design, verification evidence, anticipated review questions with answers, and what we need from an FPGA expert"
author: "Claude Code (implementer), for Daniel Attali"
date: "2026-11-26"
---

# Briefing for Amir - EXP001 digital pulse compression

## 1. Purpose of the review

The project asks whether a software engineer without FPGA training, working with LLM
agents, can produce an FPGA component comparable to professional work.

- Only a professional can judge that; your review is the final acceptance step (AC7).
- We ask for **judgement, not implementation**: what you would flag in a design review,
  which evidence is missing, and what "comparable" would mean to you.
- Everything is synthetic and public. No device was available, so there is no timing,
  power or hardware claim.

Material:
- specification: [DPC_SPECIFICATION.md](../../experiments/exp001/docs/DPC_SPECIFICATION.md);
- RTL: [dpc.vhd](../../experiments/exp001/rtl/dpc.vhd) (355 lines) and
  [dpc_pkg.vhd](../../experiments/exp001/rtl/dpc_pkg.vhd) (134 lines);
- testbench: [tb_dpc.vhd](../../experiments/exp001/tb/tb_dpc.vhd);
- records: [VALIDATION_M2B.md](../../experiments/exp001/VALIDATION_M2B.md),
  [VALIDATION_M2C.md](../../experiments/exp001/VALIDATION_M2C.md) and
  [RESULTS_M4.md](../../experiments/exp001/RESULTS_M4.md);
- decision log: [DECISION_LOG.md](../DECISION_LOG.md) (D-060 to D-085 for this component).

## 2. The component in one page

**Function** (G2):

```text
y[n] = sum_{k=0}^{P-1} conj(r[k]) * x[n+k],   n = 0 .. N_RG-1,   x[m] = 0 for m >= N_RG
```

- Time-domain matched filter (correlation), block based. The hardware conjugates the
  supplied pulse; the user applies any window.
- The last P−1 outputs are partial sums (zero padding beyond the block). They are
  computed and checked.

**Numerics** (G3):
- IEEE-754 binary32 throughout, round to nearest even, subnormals supported, no
  exception flags.
- Fixed evaluation order:
  - each complex product is four rounded multiplications, then one rounded subtraction
    (real part) and one rounded addition (imaginary part);
  - each output starts at acc = +0 and adds the terms in order k = 0..P−1, one rounding
    per addition.
- Arithmetic is `ieee.float_pkg` (VHDL-2008 standard package) with explicit settings:
  `round_nearest`, `guard => 3`, `check_error => true`, `denormalize => true`.

**Interface** (G4):

| Channel | Signals | Notes |
|---|---|---|
| Clock and reset | `clk`, `rst` | One clock. Synchronous active-high reset returns to idle and forgets the pulse |
| Pulse load | `ref_valid/ready`, `ref_re/im` | P samples. Accepted only when idle. Kept for following blocks |
| Input block | `in_valid/ready`, `in_re/im` | N_RG samples. Refused until a pulse is loaded |
| Output | `out_valid/ready`, `out_re/im`, `out_last` | N_RG results in order. `out_last` on n = N_RG−1 |

Data ports are 32-bit binary32 bit patterns. N_RG, P and L are **compile-time
generics**.

**Architecture** (G5, D-076, D-077):

```text
          ┌──────────── load phase ───────────┐   ┌──── compute phase ────┐   ┌─ output ─┐
ref ───►  pulse memory r[0..P-1] (LUTRAM) ──────► conj(r[k]) to all lanes
in  ───►  sample memory x[0..N_RG-1] (LUTRAM) ──► sliding window w[0..L-2] + current read
                                                   lane j: acc_j += conj(r[k]) * x[n0+j+k]
                                                   (L lanes, one complex MAC each per cycle)
                                                                               acc_j ──► out
```

- **States:** IDLE, LOAD_REF, LOAD_IN, FILL (L−1 cycles), COMPUTE (P cycles), OUT
  (≤ L cycles).
- **Groups:** outputs are computed in groups of L neighbours, n0 = 0, L, 2L, ...
  - All lanes use the same conj(r[k]) in the same cycle.
  - Lane j needs x[n0+j+k], so the L operands form a window that slides by one sample
    per cycle.
  - **One sample read and one pulse read per cycle, whatever L is.**
- **Zero padding:** the sample index is wider than the memory address. It is compared
  with N_RG *before* truncation, and the zero word is substituted.
- **Accumulators:** they are the output buffer. The accumulator input is +0 at k = 0,
  so there is no clear cycle. In OUT, a bounded multiplexer selects acc(j_out).
- **Datapath:** each complex MAC (4 mul, 1 sub, 2 add) is **combinational between
  registers, in one clock cycle**. No pipelining yet; that is planned for M6, after your
  review.
- **Memories:**
  - padded to a power of two;
  - fixed-width address counters with explicit wrap;
  - **asynchronous read** (maps to distributed RAM, LUTRAM);
  - synchronous write;
  - no reset.

**Cycle count** (measured in simulation; equals the closed form on all 13 fixtures and
in the netlist):

```text
latency = 2*N_RG + ceil(N_RG/L) * (P + L - 1)     (out_ready = 1)
period  = latency  (+P if the next block starts with a pulse reload)
```

| (N_RG,P,L) | Latency (cycles) | Source | Speed-up vs L = 1 | Samples per cycle | Lane utilisation in compute |
|---|---:|---|---:|---:|---:|
| (256,64,1) | 16896 | measured | 1.00 | 0.015 | 100 % |
| (256,64,2) | 8832 | formula | 1.91 | 0.029 | 98.5 % |
| (256,64,4) | 4800 | formula | 3.52 | 0.053 | 95.5 % |
| (256,64,8) | 2784 | measured | 6.07 | 0.092 | 90.1 % |

"Formula" rows were not simulated at (256,64). The formula was confirmed by measurement
on all 13 simulated fixtures. Lane utilisation in compute is P/(P+L−1); the loss is the
FILL cycles. The 2·N_RG term
(load and unload, not overlapped with compute) is the main loss at large L.

## 3. Evidence summary

| Level | What was done | Result | Evidence |
|---|---|---|---|
| Golden reference | Python, standard library only. Exact rational model, binary32 sequential model, error bound, vector generator, output judge. Frozen with digests | Self-test PASS | `reference/`, D-062 |
| RTL simulation | 13 configurations, 7 back-to-back transactions each (impulses at the first, middle and last sample; chirp echo plus noise; uniform and wide-range random; one pulse reload) | Bit exact on all outputs; error bound holds | M2b, M2c |
| Backpressure | 30 % random idle cycles on `ref_valid` and `in_valid`, and on `out_ready` | 0 protocol errors | stress mode |
| Cycle model | No-stall timing mode, run twice, must repeat identically | Equal to the closed form | timing mode |
| Protocol checks | Output stable under stall; `out_last` exact; no input before pulse; `in_ready` = 0 while busy; ref-over-input priority; reset | All PASS | tb_dpc.vhd |
| Negative controls | One flipped bit in a dump; a wrong expected value; a wrong y[7] in a lane test | All detected | M2b/M2c NC1-NC3 |
| Generic synthesis | GHDL `--synth` → Yosys `proc; opt; memory; opt; check -assert` | 0 problems; 4·L multipliers; 4 memories | M2c |
| Netlist simulation | GHDL's synthesized netlist, same testbench, two documented rewrites | Bit and cycle exact for 5 of 6 configurations (up to L = 4) | M4 |
| Series 7 mapping | Yosys `synth_xilinx`, out of context, without `share` | 8/8, 0 problems | M4 |

## 4. Series 7 resource estimate (Yosys 0.33, not Vivado, not placed)

| (N_RG,P,L) | Logic LUT | FF | CARRY4 | MUXF7/F8 | DSP48E1 | LUTRAM | BRAM | Logic depth |
|---|---:|---:|---:|---:|---:|---|---:|---:|
| (64,16,1) | 8404 | 96 | 1346 | 2028/714 | 8 | 12 RAM32M + 22 RAM64M | 0 | 712 |
| (256,64,1) | 8439 | 106 | 1351 | 2095/769 | 8 | 110 RAM64M | 0 | 722 |
| (256,64,2) | 16424 | 235 | 2672 | 4077/1473 | 16 | 110 RAM64M | 0 | 735 |
| (64,16,4) | 32052 | 483 | 5312 | 8117/2871 | 32 | 12 RAM32M + 22 RAM64M | 0 | 768 |
| (256,64,4) | 32839 | 493 | 5316 | 8400/3025 | 32 | 110 RAM64M | 0 | 758 |
| (256,64,8) | 64982 | 1006 | 10606 | 16171/5832 | 64 | 110 RAM64M | 0 | 774 |
| (64,16,4) `-nodsp` | 55622 | 483 | 5504 | 8222/2940 | 0 | 34 | 0 | 781 |
| (64,16,4) `-nolutram` | 33515 | 5603 | 5312 | 7862/2797 | 32 | 0 | 0 | 754 |

How to read the table:
- **Per lane:** about 8000 logic LUTs, 129 FFs (accumulator 64 + window 64 + 1),
  1322 CARRY4 and 8 DSP48E1. Linear in L within 3 %.
- **Fixed part** (memories, control): small.
- **INV cells** (about 495 per lane) are counted separately.
- **Logic depth** is `ltp -noff`, the number of cells on the longest combinational
  path. Every CARRY4 segment and MUX counts as one cell, so it is not a count of LUT
  levels and **not a delay**.
- **Flow:** Yosys's SAT-based `share` pass ran out of memory in the 10 GB VM and was
  removed (M4-TOOL-001), so the counts are likely upper bounds.

## 5. Anticipated questions and our answers

Each answer says what is **shown** (tool evidence), what is **reasoned** (argument, not
measured) and what is **unknown**.

### 5.1 Architecture and algorithm

**Q1. Why time-domain correlation and not FFT-based fast convolution, the usual
approach for long pulses?**
- **Reasoned:**
  - Direct correlation gives a fixed summation order, so the result can be checked bit
    for bit against a simple model. That made verification unambiguous for a first
    experiment.
  - FFT convolution changes the rounding entirely; only the error-bound gate could
    judge it.
  - For P = 64 the direct form costs N_RG·P complex MACs per block. Whether FFT wins
    depends on P and N_RG, and we expect it to win for long pulses. Not evaluated.
- **Ask:** at what P would you switch to the frequency domain?

**Q2. Why parallelise over outputs (lanes) rather than taps (a systolic or transposed
FIR)?**
- **Reasoned:**
  - Output lanes keep one sample read and one pulse read per cycle, and they keep each
    output's sequential summation order, which preserves bit exactness.
  - A fully parallel P-tap FIR would reach about 1 output per cycle, but it needs P
    complex MACs (512 DSP48E1 at P = 64 with this MAC) and its adder tree or chain
    changes the summation order.
  - The lane count gives a cost/throughput knob between those extremes.
- **Shown:** speed-up 6.07× at L = 8, with lane utilisation 90 % during compute.

**Q3. Why block processing with load, compute and output in sequence? Real systems
stream continuously.**
- The specification chose one block at a time for a clear contract.
- The 2·N_RG load/unload term is the largest remaining inefficiency at high L:
  - (256,64,8): 512 of 2784 cycles.
  - Removing it needs double-buffered sample memory and overlapping output with the
    next computation.
- Planned for M6. Your priorities welcome.

**Q4. Why floating point, not fixed point or block floating point?**
- Decided at planning (D-056, G3): binary32 avoids scaling and bit-growth decisions and
  allows an exact reference and an error bound.
- **Known cost:** about 8000 LUTs per complex MAC (section 4).
- Fixed point would be far cheaper and is common in radar front ends. That is a
  specification-level trade-off for you to comment on.

**Q5. Are N_RG and P configurable at run time?**
- No, both are generics. A run-time pulse length (P ≤ P_max) or range window would be
  a specification change.

**Q6. What happens in the last group when L does not divide N_RG?**
- The extra lanes compute on padding and are never output (checked with (64,16,3)).
- For (64,16,64), all 64 outputs are computed in one group (simulation only).

### 5.2 Numerics

**Q7. Is the result really bit exact, and against what?**
- Yes. Every output word equals the binary32 model that evaluates the same operations
  in the same order (`seq32` in `dpc_ref.py`). That model is cross-checked against a
  NumPy float32 loop.
- A second gate bounds the error against exact rational arithmetic:
  `|y_hw − y_exact| ≤ γ·S + (P+2)·2^-149`, with γ = (P+2)u/(1−(P+2)u).
- The worst observed error is 0.25 of the bound.
- Because each lane uses the same order, results are identical for every L.

**Q8. Were subnormals, NaN, infinity and overflow tested?**
- **Honestly, not in the DPC vectors.**
- We checked the vector files: no input, pulse or expected output word is subnormal.
  The smallest product is around 2^-76, far from the subnormal range.
- NaN and infinity inputs are out of the tested scope (G3), and test magnitudes are ≤ 1,
  so overflow does not occur.
- The same float_pkg operations, with the same settings, were tested separately on
  8124 vectors, including subnormal and special-value categories (edu_complex_arithmetic,
  D-058/D-059, bit exact).
- That is indirect evidence only. **A directed DPC test with subnormal and special
  inputs is a known gap.**

**Q9. Why `guard => 3` and `denormalize => true`? They cost logic.**
- These settings give correctly rounded IEEE results with subnormal support. They are
  required for bit exactness against the IEEE model.
- Flushing subnormals to zero would save logic but break the specification.
- Not measured: how much logic they cost.

**Q10. A pipelined floating-point adder breaks the one-cycle accumulation. How will
you keep bit exactness?**
- **Reasoned, important for M6:** interleaving independent outputs through a pipelined
  accumulator keeps each output's sequential order, so it stays bit exact.
  - Example: with adder latency D, lane j works on D different outputs in turn.
- Partial sums or tree reduction change the order. They would pass only the error-bound
  gate, which the current specification does not accept on its own.
- Your preference decides the M6 design.

### 5.3 Interface and protocol

**Q11. Is the handshake AXI4-Stream compliant?**
- It follows the AXI-Stream valid/ready rules that matter:
  - a transfer happens when valid and ready are high at the rising edge;
  - no valid depends on any ready;
  - outputs are stable while stalled (checked).
- There are no TKEEP or TUSER signals, and no input TLAST. `out_last` plays the role
  of TLAST.
- Full compliance is not claimed.

**Q12. `in_ready` depends combinationally on `ref_valid`. Is that a problem?**
- It is deliberate (D-069): a pulse load wins if both arrive in the same idle cycle.
- Ready depending on valid is allowed by AXI-Stream. Here, though, it crosses two
  channels, which creates an input-to-output combinational path through the block.
- **Risks:**
  - a loop if the upstream logic makes `ref_valid` depend on `in_ready`;
  - an extra path for boundary timing.
- The alternative, registered mutually exclusive readies, costs one idle cycle.

**Q13. What does backpressure do?**
- `out_ready = 0` only holds the current output; computation of the next group waits.
- Inputs are refused (`in_ready = 0`) from the last input of a block until its last
  output.
- Tested with 30 % random stalls on all three channels.

### 5.4 Reset, clocking, initialisation

**Q14. Why are the datapath registers and memories not reset?**
- The control state is reset synchronously. Data registers (window, accumulators) and
  memories are always written before they are used:
  - the accumulator input is forced to +0 at k = 0;
  - the window is filled before compute.
- This saves reset routing and lets the memories map to LUTRAM, which cannot be reset.
- The window and accumulators also carry an initial value of +0 (FPGA INIT).
- **Visible side effect:** netlist simulations print many "metavalue detected"
  warnings, because combinational logic evaluates not-yet-written values. Outputs are
  unaffected.
- If your house style requires datapath resets, that is a cheap change.

**Q15. Clock domains, CDC?**
- One clock, no clock-domain crossings, no clock enables. Out-of-context mapping uses
  no I/O buffers or clock buffers.

### 5.5 Memories and mapping

**Q16. LUTRAM rather than BRAM. Why, and does it scale?**
- Asynchronous reads were chosen so the read data is available in the same cycle,
  which keeps the control simple.
- **Shown:** every configuration maps to LUTRAM with 0 BRAM. The (256,64) memories use
  110 RAM64M, which accounts for every memory bit:
  - 2 × 256 × 32 bits for samples, 2 × 64 × 32 bits for the pulse;
  - one RAM64M holds 64 × 3 bits;
  - so 2 × (4 × 11) + 2 × 11 = 110.
- Without LUTRAM, the same memories cost 5120 FFs plus 1463 LUTs for (64,16,4).
- For large N_RG, BRAM (synchronous read, one cycle of read latency) would be the
  normal choice. It needs a pipeline register before the window. That is a planned
  architecture change (D-075).

**Q17. 8 DSP48E1 per lane. Is that right?**
- Yes: 4 real multiplications per complex product, each a 24×24-bit mantissa product.
- One DSP48E1 multiplies 25×18 signed, so each product needs 2. 4 × 2 = 8. Exactly
  8·L in every default mapping.
- Without DSPs, (64,16,4) needs 74 % more LUTs (about 1470 LUTs per mantissa
  multiplication).

**Q18. About 8000 LUTs per complex MAC seems large.**
- Probably yes. The MAC is 7 IEEE operations with full rounding, subnormal and special
  value handling, written as generic behavioural VHDL (float_pkg) with no vendor
  optimisation.
- Vendor floating-point cores are expected to be considerably smaller per operator. We
  have **not** compared them with verified numbers.
- The missing `share` pass also inflates the counts somewhat.
  - **Reasoned:** probably not much, since all 7 operations are active every cycle and
    cannot share hardware.
  - Not measured.
- **Ask:** compare with your Vivado and Floating-Point IP experience.

**Q19. Which device does it fit?**
- No device is targeted and no fit is claimed. The counts are pre-placement Yosys
  estimates for the 7-series family.
- (256,64,8) is about 65k logic LUTs plus 64 DSP48E1.

### 5.6 Timing and performance

**Q20. What Fmax do you expect?**
- **Unknown.** There are no timing tools, so we make no claim.
- **Shown:** the longest combinational path has about 750 cells. It runs through one
  lane's MAC: LUTRAM read → multiplier → normalise and round → subtract → normalise and
  round → accumulate add → normalise and round → register.
- **Reasoned:** that is a very deep path. Expect a low clock until it is pipelined.
- **Ask:** your estimate for a 7-series part, and where to cut first.

**Q21. Where would you pipeline?**
- Planned for M6. Candidates:
  - register the LUTRAM read;
  - pipeline the multipliers using the DSP48E1 internal registers;
  - register between multiply and add;
  - pipeline the adders;
  - interleave outputs in the accumulator (Q10).
- Each stage changes the cycle formula but not the numerics, if the summation order is
  kept.

**Q22. Why not overlap load and output with compute?**
- See Q3. It removes the 2·N_RG term and is the second M6 candidate.

### 5.7 Verification depth

**Q23. Were the testbenches checked themselves?**
- Yes:
  - every check has a deliberately failing control;
  - the testbench never imports the reference: only vector files and output dumps
    cross the boundary;
  - two defects in earlier verification harnesses were found this way (EQ-DEFECT-001/002,
    FIFO formal equivalence).

**Q24. Code coverage, formal verification, assertions?**
- There is no code coverage tool and no formal property checking on the DPC.
- Protocol properties are checked as assertions in the testbench.
- A formal equivalence check was done earlier for the FIFO building block, not for the
  DPC.
- Known gap.

**Q25. Post-synthesis and post-implementation simulation?**
- **Done:** GHDL's own synthesized netlist (generic gates, before Yosys mapping),
  simulated with the RTL testbench. Bit and cycle exact for 5 of 6 configurations.
- **Not done:**
  - simulation of the Yosys Series 7 netlist (no Verilog simulator in the toolchain);
  - an equivalence proof (DSP48E1 is a black box to Yosys equivalence);
  - (256,64,8), where GHDL ran out of memory compiling the 8 MB netlist (M4-TOOL-004);
  - anything after place and route.

**Q26. What are the two text rewrites in the netlist simulation, and do they hide
bugs?**
- **N1, saturated shift amounts (M4-TOOL-002).**
  - GHDL's VHDL netlist writes float_pkg's normalisation shifts with a 32-bit shift
    amount, converted by `to_integer`. Amounts of 2^31 or more overflow VHDL's integer
    range in simulation only.
  - We clamp amounts at 2^30. A shift by at least the vector width already gives zero,
    so the result is unchanged.
  - Exactly 32·L call sites per netlist are rewritten, counted.
- **N2, constant-'Z' selects (M4-TOOL-003).**
  - float_pkg's `classfp` first tests whether the input contains metavalues ('X',
    'U'...). That test has no hardware meaning.
  - GHDL synthesis keeps it as a multiplexer whose select is the constant 'Z'.
  - VHDL simulation evaluates `'Z' = '0'` as false and takes the "is X" branch, so
    every output is X (shown by the diagnostic control, 56/56 X).
  - IEEE 1076.6 treats such comparisons as false in synthesis. Yosys resolves the
    select to the normal path, shown by a three-line test.
  - N2 replaces exactly that comparison text with `true`, counted: exactly 32·L.
- The bad-value negative control still fails on the rewritten netlist, so the rewrites
  do not make the check pass trivially.
- N2 also explains the long-standing 4 "tri-state" warnings per float operation in
  Yosys (CA-OBS-001).

### 5.8 Portability and production readiness

**Q27. Will this synthesise correctly in Vivado?**
- **Unknown, and the main portability risk.** Correct hardware depends on the tool
  treating float_pkg's metavalue test as false (Q26):
  - Yosys does;
  - Vivado was not available.
- If a tool resolved it the other way, every operation would take the "invalid input"
  path.
- **Ask:** synthesise (8,3,1) in Vivado and run a post-synthesis functional simulation
  with our testbench. That would settle the question in a few minutes of your time.

**Q28. Would you ship float_pkg in a product?**
- That is your call. It is vendor neutral and was bit exact against IEEE here, but:
  - it is large;
  - it is combinational;
  - it is tool dependent (Q27).
- Vendor Floating-Point IP or fixed point is the conventional choice.

**Q29. Coding style issues?**
- Points we already know about:
  - one large clocked process for control and MACs;
  - variables inside the MAC loop;
  - functions returning concatenated 64-bit vectors;
  - asynchronous memory reads;
  - a cross-channel combinational ready.
- Your review of naming, structure and synthesis style is exactly what we need.

### 5.9 Tools and reproducibility

**Q30. Which tools, and can I rerun it?**
- All runs are in one Docker image: GHDL 4.1.0, Yosys 0.33, Python 3.12. One command
  per milestone, for example `bash experiments/exp001/tb/run_m4.sh`.
- Each run writes an evidence folder with a SHA-256 manifest.
- The protected specification and reference are digest-checked before and after every
  run.

**Q31. Why was `share` removed? Is the flow still standard?**
- `share` was killed for lack of memory even on the smallest design.
- The runner proves that the flow used equals the standard `synth_xilinx` coarse step
  minus `share`, by comparing it with Yosys's own help listing.
- Counts are labelled likely upper bounds.

## 6. Known gaps (we would rather you hear them from us)

1. No timing, placement, power or hardware results; logic depth is not timing.
2. No Vivado run; the float_pkg metavalue resolution in Vivado is untested.
3. Mapped Series 7 netlist not simulated; no equivalence proof.
4. (256,64,8) netlist simulation not completed (tool memory).
5. No subnormal, NaN, infinity or overflow cases in the DPC vectors.
6. One random seed (20261126); no code coverage; no formal properties on the DPC.
7. Fully combinational MAC; no load/compute overlap; compile-time N_RG and P only.
8. Resource counts are Yosys estimates without resource sharing.

## 7. What we ask from you

1. A rough Fmax expectation for the current design, and a pipelining priority list.
2. A Vivado synthesis and post-synthesis simulation of (8,3,1) (Q27), if you have 30
   minutes.
3. Your view on float_pkg versus vendor IP versus fixed point for this function.
4. Sanity check of the resource numbers against your experience.
5. A code-review pass on dpc.vhd (style, structure, reset policy, interface).
6. Which missing verification items you would require before trusting the block.
7. Your criteria for "comparable to professional work" for a block like this. They
   will become the project's yardstick.
