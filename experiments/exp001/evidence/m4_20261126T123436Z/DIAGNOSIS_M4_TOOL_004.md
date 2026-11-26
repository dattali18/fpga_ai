---
title: "Diagnosis - M4 run 20261126T123436Z, Part A (256,64,8)"
sub-title: "M4-TOOL-004, GHDL GCC back end runs out of memory on the 8 MB netlist"
author: "Claude Code (implementer)"
date: "2026-11-26"
---

# Diagnosis - M4-TOOL-004

This note was written after the run. It does not change the run's evidence:
- `MANIFEST.sha256` is not edited and does not list this file;
- `summary.txt` still reads `FAIL A n256_p64_l8: netlist analysis/elaboration failed`
  and `OVERALL: FAIL`.

## Observation in the run

`postsyn/n256_p64_l8/ghdl_netlist_analyse.log` contains one line:
`/usr/bin/ghdl-gcc:error: exec error`.

The rewritten netlist `net_satz.vhdl` is 8.1 MB:
- N1 replaced 256 shift calls;
- N2 replaced 256 constant-Z selects (expected 32·8).

In the build folder (not committed), GHDL left `network/net_satz.s` (296,255,488 bytes).
It was last written 8 minutes before the error. No object file was produced.

## Diagnostic 1 - the assembly file is truncated

`as` was run on the leftover `net_satz.s` inside the same image. The build folder was
mounted read-only and the output went to a scratch directory.

```text
net_satz.s:14355072: Warning: end of file not at end of a line; newline inserted
as rc=0 peak_kB=3632648 secs=10
```

The assembler itself is not the problem (3.6 GB, 10 s). The file ends mid-line, so
the code generator stopped while writing it.

## Diagnostic 2 - repeat of the failed step with memory tracking

Same image, same 10 GB VM, nothing else running. Steps:
1. Analyse `dpc_pkg.vhd` and `m4_sat_pkg.vhd`.
2. Run `ghdl -a --std=08` on the run's `net_satz.vhdl`.
3. Every 3 s, sample the peak resident memory (VmHWM) of the `ghdl1` and `as` child
   processes, and the VM's MemAvailable.

```text
ghdl -a rc=3 secs=1079 peak_child_kB=9425032 child=ghdl1 min_MemAvailable_kB=325756
/usr/bin/ghdl-gcc:error: exec error
-rw-r--r-- 1 root root 296255488 Nov 26 14:04 net_satz.s
```

## Conclusion

- The failure is reproducible.
- The code generator `ghdl1` grew to 9.43 GB, and the VM's free memory fell to 0.33 GB
  of about 10 GB. The process then ended abnormally, leaving the same truncated
  assembly file, byte for byte the same size.
- **Conclusion: memory exhaustion in GHDL's GCC back end.** It is not a design or
  netlist content error.
- The kernel's out-of-memory record was not read, because that needs `sudo` inside the
  VM, which the project does not allow. So the kill signal itself is not observed.
- For comparison, the 4.0 MB (64,16,4) netlist compiled in about 4 minutes. Netlist
  size grows with L, about 1 MB per lane.
- Options for the planner and owner:
  - classify the row as BLOCKED;
  - or re-run this fixture in a VM with more memory.
