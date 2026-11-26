---
title: "EXP001 M2b milestone prompt"
sub-title: "DPC RTL baseline with G_LANES = 1"
author: "Claude (planner)"
date: "2026-11-26"
---

# EXP001 M2b - DPC RTL baseline (`G_LANES = 1`)

Implementer: Claude Code (D-064). Contract:
[DPC_SPECIFICATION.md](../docs/DPC_SPECIFICATION.md). Where this prompt and the
specification disagree, the specification wins; stop and report the conflict.

Start by posting a short plan (files, checks, risks), then wait for Daniel's "go".

## 1. Goal

Build the first working DPC component with one multiply-add lane, verify it
bit-exactly against the frozen golden reference on every edge and baseline fixture,
and confirm clean structural synthesis.

Out of scope for this milestone: `G_LANES > 1` (M2c), pipelining, Series 7 mapping
(M4), cocotb.

## 2. Files

| Path | Content |
|---|---|
| `experiments/exp001/rtl/dpc_pkg.vhd` (optional) | binary32 helper functions |
| `experiments/exp001/rtl/dpc.vhd` | entity `dpc` |
| `experiments/exp001/tb/tb_dpc.vhd` | vector-driven self-checking testbench |
| `experiments/exp001/tb/run_dpc.sh` | runner: everything below, one command |
| `experiments/exp001/VALIDATION_M2B.md` | results, written from evidence |
| `experiments/exp001/evidence/m2b_<run>/` | compact evidence |

Do not touch `experiments/exp001/reference/`, `context/`, `.agents/`, `AGENTS.md`,
`START_PROMPT.md` or `experiments/exp001/tb/conftest.py`.

## 3. Entity

```vhdl
entity dpc is
  generic (
    G_N_RG  : positive;          -- samples per block
    G_P     : positive;          -- pulse length
    G_LANES : positive := 1      -- M2b supports 1 only
  );
  port (
    clk, rst                     : in  std_logic;
    ref_valid                    : in  std_logic;
    ref_ready                    : out std_logic;
    ref_re, ref_im               : in  std_logic_vector(31 downto 0);
    in_valid                     : in  std_logic;
    in_ready                     : out std_logic;
    in_re, in_im                 : in  std_logic_vector(31 downto 0);
    out_valid                    : out std_logic;
    out_ready                    : in  std_logic;
    out_re, out_im               : out std_logic_vector(31 downto 0);
    out_last                     : out std_logic
  );
end entity dpc;
```

- Include an elaboration-time assertion that `G_LANES = 1`, with `severity failure`
  and the message "G_LANES > 1 is M2c".
- Follow G4 exactly:
  - synchronous active-high `rst` returns to idle and forgets the pulse;
  - the pulse is accepted only when idle, in order `k = 0..P-1`, and replaces the
    previous one;
  - `in_ready = 0` until a pulse has been loaded at least once;
  - one block at a time: no new input until the previous block's last output has
    been transferred;
  - a transfer happens at a rising edge where `valid = ready = 1`;
  - once `out_valid = 1`, `out_re`, `out_im` and `out_last` stay stable until the
    transfer.

## 4. Datapath rules (these decide bit-exactness)

1. **Product:** `t = conj(r[k]) * x[n+k]`, where `conj` negates the imaginary sign
   bit (exact). Use the same operation order and `float_pkg` parameters as
   `experiments/edu_complex_arithmetic/rtl/edu_complex_mul.vhd`:
   - `t_re = sub(mul(cr, xr), mul(ci, xi))`;
   - `t_im = add(mul(cr, xi), mul(ci, xr))`;
   - with `cr = Re r[k]` and `ci = -Im r[k]`.
2. **Accumulate:** for each output, set `acc = +0` (all bits zero), then
   `acc = add(acc, t)` for `k = 0, 1, ..., P-1` in that order, per part.
   - Do **not** initialise with `acc = t_0`.
   - Do **not** reorder or skip terms.
3. **Zero padding:** for `n + k >= N_RG`, use the sample `+0 + j(+0)` (all bits
   zero) and still perform the multiply-add.
4. **One multiply-add per clock cycle**, combinational between registers, as in the
   validated blocks.
5. **Memories:** sample memory of `N_RG` words and pulse memory of `P` words.
   - Pad each to a power of two with fixed-width `unsigned` addresses and explicit
     wrap; this is the FIFO-DEFECT-001 lesson.
   - Use plain indexed asynchronous reads and synchronous writes, with no reset on
     storage.
6. **Output:** for `G_LANES = 1`, compute `y[n]`, hold it in the output register until
   it is transferred, then compute `y[n+1]`. No result memory is needed. Report the
   measured cycle counts; matching the specification's G5 model is not required
   in M2b.

## 5. Testbench `tb_dpc`

- **Generics:**
  - `G_N_RG`, `G_P`, `G_LANES`;
  - `G_VECTOR_FILE`, `G_DUMP_FILE`;
  - `G_STALL_PCT` (0 to 100);
  - `G_SEED`.
- **Timing:** drive on the falling edge, sample after the rising edge.
  `ieee.math_real.uniform` may be used for random gaps.
- **Vector file:** read `T`/`R`/`X`/`Y` lines (spec G1).
  - When a transaction has `R` lines, load the pulse through the `ref` stream first.
  - Then send the `X` samples and collect `N_RG` outputs.
- **With `G_STALL_PCT > 0`:** insert random idle cycles on `ref_valid` and
  `in_valid`, and random `out_ready = 0` cycles.
- **Every output:**
  - write `O <re> <im>` (8 hex digits each) to `G_DUMP_FILE`;
  - compare with `Y` bit for bit;
  - check `out_last` is 1 exactly on the last output of each block.
- **Protocol checks**, each counted as a check:
  - output data and `out_last` stay stable while `out_valid = 1` and `out_ready = 0`;
  - before any pulse is loaded, `in_valid = 1` for 5 cycles produces no transfer
    (`in_ready = 0`);
  - while a block is being processed, `in_ready = 0` until its last output is
    transferred;
  - after the final transaction, assert `rst` for one edge, then check that
    `in_ready = 0` (pulse forgotten).
- **Cycle report (when `G_STALL_PCT = 0`):** per transaction, print:
  - latency = cycles from the first input transfer to the last output transfer,
    inclusive;
  - period = cycles from this block's first input transfer to the next block's
    first input transfer.
  - Use the exact format `CYCLES t=<i> latency=<c> period=<c or NA>`.
- **End of run:**
  - print `<file>: <tx> transactions, <outputs> outputs, <checks> checks, <errors> errors`;
  - `severity failure` if `errors > 0`;
  - otherwise `PASS: <file>` and `std.env.finish`;
  - print at most the first 20 mismatches with details.

## 6. Runner `tb/run_dpc.sh`

It runs on the host (bash 3.2 compatible) and does all tool work in the
`fpga_ai-toolchain:m1-arm64` container. In order:

1. Protected files and the oracle manifest
   (`--extra-manifest experiments/exp001/reference/ORACLE_MANIFEST.sha256`).
2. `dpc_ref.py --output build/m2b_<run>/vectors` (do not commit vectors).
3. GHDL analysis and elaboration.
4. For each fixture `(N_RG, P)` in (1,1), (5,8), (8,3), (8,8), (64,16), (256,64),
   run twice: stress (`G_STALL_PCT = 30`) and timing (`G_STALL_PCT = 0`).
5. `dpc_ref.py --check <vectors> <dump>` on every dump: the error-bound gate and the
   bit-exact check.
6. **Negative controls** (they must fail, otherwise the run fails):
   - flip one bit of one output in a copy of a dump, and `--check` must return
     non-zero;
   - change one `Y` word in a copy of a vector file, and the testbench run must end
     with FAIL.
7. Synthesis for each of the 6 fixtures:
   - `ghdl --synth --std=08 --no-formal -gG_N_RG=.. -gG_P=..` followed by the Yosys
     `check -assert` flow from `CLAUDE.md`;
   - record cells, `$mul` count, memory objects and bits, and the tri-state warning
     count. Count `Warning:` lines, not the summary line (CA-DEFECT-001).
8. Protected files and the oracle manifest again.
9. Evidence:
   - copy logs, cycle reports and the synthesis summary to
     `experiments/exp001/evidence/m2b_<run>/`;
   - **write `MANIFEST.sha256` last, after every log is closed, excluding itself
     and any temporary file** (M2A-DEFECT-001 lesson);
   - print a summary table;
   - exit 0 only if everything passed.

## 7. Acceptance criteria

| ID | Criterion |
|---|---|
| B1 | 12 simulation runs (6 fixtures x 2 modes): 0 mismatches, 0 protocol errors |
| B2 | `--check` on all 12 dumps: 0 gate failures, 0 bit-exact mismatches |
| B3 | Both negative controls fail as intended |
| B4 | Synthesis of 6 fixtures: 0 structural problems; metrics recorded |
| B5 | Protected and oracle digests PASS before and after |
| B6 | Cycle counts reported for all 6 fixtures; identical between two runs of the timing mode (determinism) |
| B7 | `VALIDATION_M2B.md`, decision log (continue from the last ID), STATUS, TODO, changelog, daily note; changes staged, not committed |

If a check fails:
- diagnose and fix within scope;
- give each defect an ID (`DPC-DEFECT-nnn`) with its root cause in
  `VALIDATION_M2B.md`;
- never change the reference, the vectors or the acceptance criteria.

If three fix attempts fail on the same issue, stop and report.

## 8. Report

End with the `PLANNER REPORT` block from `CLAUDE.md`. Include:
- the B1 to B7 table;
- the cycle counts per fixture;
- synthesis metrics per fixture;
- the defect list;
- the exact runner command.

Explain the results to Daniel in plain language, in at most 10 lines.
