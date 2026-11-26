---
title: "Correction - M2b run 20261126T111341Z"
sub-title: "DPC-DEFECT-001, memory metric of the first M2b run"
author: "Claude Code (implementer)"
date: "2026-11-26"
---

# Correction - M2b run 20261126T111341Z (DPC-DEFECT-001)

This is the first complete M2b run. It is kept unchanged as raw evidence
(`MANIFEST.sha256` not edited; this file is not listed in it). It is
**superseded** by run
[m2b_20261126T111903Z](../m2b_20261126T111903Z/MANIFEST.sha256) for the M2b
acceptance (D-073).

## Defect

`syn/synthesis_summary.csv` and `summary.txt` report `memories=0 bits=0` for every
fixture. This is wrong: the count-only Yosys pass (`memory -nomap; stat`) shows four
`$mem_v2` cells (sample re/im, pulse re/im) in every fixture.

## Root cause

A runner defect, not an RTL defect. Yosys 0.33 `stat` reports "Number of memories" and
"Number of memory bits" only for unpacked RTLIL memories. `memory -nomap` packs them
into `$mem_v2` cells, so both lines read 0. The runner parsed those lines.

## Fix (run 20261126T111903Z)

- The count-only flow adds `memory_unpack` before `stat`. Checked by hand on the
  (8,3) netlist of this run: 4 memories, 768 bits, which is 2 x 8 x 32 + 2 x 4 x 32.
- A positive control was added: a memory count of 0 now fails the run.

All other results of this run are unaffected: simulation, `--check`, negative
controls, structural problems, cell counts, `$mul` counts and warnings. They are
identical to the superseding run.
