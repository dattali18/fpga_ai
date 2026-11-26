---
title: "Educational complex arithmetic - validation"
sub-title: "edu_complex_add and edu_complex_mul, binary32"
author: "Claude (planner and coder); executed by the project owner"
date: "2026-11-26"
---

# Educational complex arithmetic - validation

Status: ACCEPTED within simulation and generic structural synthesis scope.
Evidence run: `20261126T103335Z` ([evidence](evidence/run_20261126T103335Z/)), Git HEAD at run time
`8398b0b213d8ee777f55639bdaf82c55c2d80742`.

## Environment

| Item | Value |
|---|---|
| Image | `fpga_ai-toolchain:m1-arm64`, `sha256:cfa652b2fa6b6e661c83bed5d8ef9a35eb616683644b1bb49f75db3f8bb8d85f` |
| GHDL | 4.1.0 (GCC backend) |
| Yosys | 0.33 |
| Python / NumPy | 3.12.3 / 2.1.3 (container, aarch64) |

## Results

| Check | Result |
|---|---|
| Reference self-test (21 assertions) | PASS |
| Reference vs NumPy float32, 8124 vectors | PASS, 0 mismatches |
| GHDL analysis and elaboration | PASS |
| Simulation, 10 vector sets, 8124 vectors, 24,462 checks | PASS, 0 errors, bit-exact (NaN by class) |
| GHDL-to-Verilog + Yosys `check -assert` | PASS, 0 structural problems |
| Protected bootstrap files before and after | PASS (35 files) |

| Set | add vectors / checks | mul vectors / checks |
|---|---:|---:|
| directed | 16 / 57 | 16 / 57 |
| edge | 20 / 69 | 20 / 69 |
| special | 26 / 87 | 26 / 87 |
| random_normal | 2000 / 6009 | 2000 / 6009 |
| random_bits | 2000 / 6009 | 2000 / 6009 |

## Generic synthesis (Yosys RTLIL cells, not FPGA resources)

| Entity | Cells | Multipliers ($mul) | Muxes ($mux) | Registers |
|---|---:|---:|---:|---|
| edu_complex_add | 1021 | 0 | 400 | 2 $dffe + 1 $sdff |
| edu_complex_mul | 2098 | 4 | 898 | 2 $dffe + 1 $sdff |

## Findings

- CA-OBS-001: Yosys reports "limited support for tri-state logic" exactly 4 times per
  binary32 operation (8 for add, 24 for mul), consistent with the 4 warnings seen for one
  addition in M1. Origin is attributed to GHDL's translation of `ieee.float_pkg`, not yet
  confirmed from the generated Verilog. Structural check still reports 0 problems.
- CA-DEFECT-001 (reporting only): `tb/run_ghdl.sh` printed 9 and 25 Yosys warnings
  because its count included the Yosys summary line. Actual counts are 8 and 24. Not
  corrected, to keep the validated files unchanged; fix in a later revision.
- The `float_pkg` behaviour for signed zero, subnormals, Inf and NaN matched IEEE-754
  on all tested vectors; this was the main pre-run risk.

## Development observations

- Single Claude submission; no RTL, testbench or reference corrections.
- Claude acted as both planner and coder for this exercise (D-055); review independence
  rests on the independent reference, the NumPy cross-check and local tool evidence.

## Not established

Post-synthesis numerical equivalence, FPGA technology mapping, resources, timing and
hardware behaviour. No exception flags. Results apply to the tested vectors only.
