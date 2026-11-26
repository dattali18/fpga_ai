---
title: "Correction - M2c run 20261126T113151Z"
sub-title: "DPC-DEFECT-002, partly written window array"
author: "Claude Code (implementer)"
date: "2026-11-26"
---

# Correction - M2c run 20261126T113151Z (DPC-DEFECT-002)

This is the first complete M2c run, with **OVERALL: FAIL**. It is kept unchanged as raw
evidence (D-053 policy): `MANIFEST.sha256` is not edited and does not list this file.
It is superseded by the next M2c run, recorded in
[VALIDATION_M2C.md](../../VALIDATION_M2C.md).

## Observation

Every simulation, `--check`, cycle-formula check and negative control passed, and
synthesis reported 0 structural problems. Three synthesis rows failed the expected
tri-state warning count (C4, `32L`):

| Fixture | Tri-state warnings | Expected |
|---|---|---|
| (64,16,3) | 98 | 96 |
| (64,16,4) | 130 | 128 |
| (256,64,8) | 258 | 256 |

The rows with `L = 1` had exactly 32. `$mul` was exactly `4L` in every row.

## Root cause (RTL, structural only)

The window arrays `w_re` and `w_im` had `L` entries, but the design writes only
`w[0..L-2]`; lane `L-1` reads the memory directly. GHDL synthesis represents the
never-written entry of a partly written register array as a high-impedance constant.
The (64,16,3) netlist shows it as `assign n45241_o = {n45239_q, 32'bZ};`. That gives
one extra tri-state warning each for `w_re` and `w_im`, so +2 for every `L > 1`.

The entry was never read, so simulation results were not affected.

## Fix

The window type now has exactly `L-1` entries (at least 1). For `L >= 2` every entry
is written; for `L = 1` none is written or read.

Checked after the fix on (8,3,1), (8,8,3) and (64,16,4):
- tri-state warnings 32 / 96 / 128;
- no `'bZ` constants in the netlist;
- 0 problems.

The full run was repeated. Attempts used: 1 of 3.
