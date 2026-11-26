---
title: "EXP001 M4 milestone prompt"
sub-title: "Post-synthesis simulation and Series 7 mapping of the DPC"
author: "Claude (planner)"
date: "2026-11-26"
---

# EXP001 M4 - post-synthesis simulation and Series 7 mapping

Implementer: Claude Code (D-064). Design under test: the accepted M2c RTL
(`experiments/exp001/rtl/`), unchanged. **No RTL changes in this milestone.** If a
check reveals an RTL defect, stop and report it; do not fix it here.

Start with a short plan (files, flow, run time estimate, risks), then wait for
Daniel's "go".

## 1. Goal

Produce the hardware-facing evidence that Amir will look at, for the final design:

1. the netlist produced by synthesis still computes bit-exact results;
2. what the design maps to on Xilinx Series 7 (LUTs, flip-flops, DSP blocks,
   LUTRAM, BRAM);
3. how resources grow with `G_LANES`;
4. a logic-depth indicator, explicitly not a timing number.

## 2. Part A - post-synthesis simulation (GHDL netlist)

- For each fixture below, run `ghdl --synth --std=08 --no-formal --out=vhdl` with its
  generics to produce a VHDL netlist.
- Simulate the netlist with the existing `tb_dpc.vhd` stimulus, checks, dumps and
  `dpc_ref.py --check`, in both stress (30 %) and timing (0 %) modes.
- The netlist entity probably has no generics. Choose the simplest mechanism that
  keeps the testbench logic identical: a separate work library, plus either a
  generated instantiation variant or a configuration. Document it.
- Any difference to the testbench beyond the DUT instantiation must be justified.

Fixtures: (8,3,1), (5,8,2), (8,8,3), (64,16,1), (64,16,4), (256,64,8).

Pass criteria:
- 0 mismatches and 0 protocol errors;
- 0 gate failures and 0 bit-exact mismatches;
- timing-mode cycle counts identical to the RTL (M2c formula).

Scope note: this checks GHDL's synthesis translation, which both the FIFO proofs and
the earlier synthesis results depended on. It does **not** check Yosys technology
mapping. Post-mapping simulation needs a Verilog simulator, and none is installed:
record it as BLOCKED, not as a failure.

## 3. Part B - Series 7 mapping

- Use the established flow (D-035, `scripts/benchmark_edu_fifo_xc7.sh`):

  ```text
  GHDL Verilog netlist -> read_verilog; synth_xilinx -family xc7 -top dpc -noiopad -noclkbuf;
  check -assert; stat -tech xilinx; write_json
  ```

- Out of context: no I/O pads and no clock buffers. No retiming. Primitive counts are
  estimates, not placed utilisation.

| Configurations | Strategies |
|---|---|
| (256,64) with `L` = 1, 2, 4, 8 | default |
| (64,16) with `L` = 1, 4 | default |
| (64,16,4) | additionally `-nodsp` and `-nolutram` (sensitivity: how much DSP and LUTRAM save) |

For each mapping, record:
- status and wall time;
- logic LUTs, FFs, CARRY4, MUXF7/8;
- DSP48E1;
- distributed RAM primitives by type, SRL, RAMB18/36;
- other cells.

Keep LUTRAM and SRL separate from logic LUTs, as in the FIFO study.

**Logic depth indicator:** after mapping, run `ltp -noff` and record the reported
longest path length in cells. Label it "logic depth (cells on the longest
combinational path)". It is **not** a delay, frequency or timing result.

Expectations to confirm or refute, and report either way:
- the memories map to LUTRAM, not BRAM, because the reads are asynchronous;
- the multipliers map to DSP48E1, with several per 24×24-bit multiplication;
- resources grow roughly linearly with `L`.

## 4. Part C - optional, time-boxed (30 minutes total)

Try Yosys equivalence (`equiv_make`, `equiv_simple`, `equiv_induct`) between the
generic netlist and the Series 7 netlist for (8,3,1) only.
- PROVEN, BOUNDED or INCONCLUSIVE are all acceptable results;
- record the commands and logs;
- include a deliberately failing control if a result is claimed as proven
  (EQ-DEFECT lessons).

## 5. Files

| Path | Content |
|---|---|
| `experiments/exp001/tb/run_m4.sh` | One-command runner for parts A, B and C, bash 3.2 host, tools in Docker |
| `experiments/exp001/RESULTS_M4.md` | Results in the style of `experiments/edu_fifo/benchmarks/xc7/RESULTS.md`: method, provenance, tables, findings, limitations |
| `experiments/exp001/evidence/m4_<run>/` | Compact evidence (logs, CSV of primitive counts, commands, tool versions). `MANIFEST.sha256` written last. Large netlists stay in `build/` |
| Research records | Decisions from the next free ID, STATUS, TODO, changelog, daily note |

## 6. Acceptance criteria

| ID | Criterion |
|---|---|
| E1 | Part A: all 6 fixtures in both modes PASS as defined in section 2 |
| E2 | Part B: all mappings complete with `check -assert` 0 problems, and metrics recorded |
| E3 | LUTRAM, BRAM and DSP expectations confirmed or refuted with numbers |
| E4 | Resource-versus-lanes table and per-lane increments for (256,64) |
| E5 | Protected and oracle digests PASS before and after; RTL files byte-identical to the M2c commit (record their hashes) |
| E6 | `RESULTS_M4.md` and records written; Part C reported or NOT_RUN; changes staged, not committed |

Defect handling: a tool or flow defect may be fixed within the runner (give it an
ID). An RTL defect stops the milestone. Stop after three failed attempts on one
issue.

## 7. Report

End with the `PLANNER REPORT` block. Include:
- the E1 to E6 table;
- the Part A summary;
- the mapping table per configuration;
- the logic depth values;
- per-lane increments;
- findings;
- the runner command and total run time.

Explain the results to Daniel in at most 10 plain-language lines, including what
the numbers do **not** show (timing, placement, power).
