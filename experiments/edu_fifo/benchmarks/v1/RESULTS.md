# EDU_FIFO V1 - Controlled benchmark

Date: 2026-11-26. Source commit: c884ca9. Run: benchmark.uMRVDG9y.

22 configurations, 50,626 oracle cycles, 44 synthesis views: all passed.
GHDL 4.1.0, Yosys 0.33, Python 3.12.3. See provenance for exact versions and hashes.

## Depth sweep (width 32)

| Depth | Storage bits | RTLIL cells | Mux cells | Retained memory objects | GHDL seconds | Logic-view seconds |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 32 | 21 | 5 | 0 | 0.101758 | 0.022523 |
| 4 | 128 | 54 | 14 | 0 | 0.255435 | 0.033197 |
| 8 | 256 | 83 | 22 | 0 | 0.342364 | 0.046047 |
| 16 | 512 | 140 | 38 | 0 | 0.516236 | 0.073265 |
| 32 | 1024 | 253 | 70 | 0 | 0.869356 | 0.125991 |
| 64 | 2048 | 478 | 134 | 0 | 1.555816 | 0.236951 |
| 128 | 4096 | 927 | 262 | 0 | 2.928838 | 0.464541 |
| 256 | 8192 | 1824 | 518 | 0 | 5.671891 | 0.976259 |

## Width sweep (depth 32)

| Width | Storage bits | RTLIL cells | Wire bits |
|---:|---:|---:|---:|
| 8 | 256 | 253 | 3460 |
| 16 | 512 | 253 | 5268 |
| 32 | 1024 | 253 | 8884 |
| 64 | 2048 | 253 | 16116 |
| 128 | 4096 | 253 | 30580 |

## Findings

- F-FIFO-001: all tested configurations passed the independent cycle oracle.
- F-FIFO-002: generic cell count rises approximately linearly with depth.
- F-FIFO-003: no retained memory objects in the memory-preserving view.
- F-FIFO-004: cell count remains 253 across the width sweep; multi-bit cell widths matter.
- F-FIFO-005: depths 3, 15, 31, 63 and 127 pass strict structural checks after the V1 correction.
- F-FIFO-006: host synthesis wall time increases with depth in this single run.

## Limitations

No technology mapping, physical timing, post-synthesis equivalence or BRAM utilization established. Wall times are single observations. Source commit identifies tracked RTL, but the runner and decision ledger were untracked at execution. Retain the local raw run; tracked CSV and provenance are a compact record, not all raw evidence. See decision ledger D-024 through D-027 for follow-up.

Original archive SHA-256: `19b0f4ea5f990c567507f9923771029447afd5533de1133455c66c07fa1ea046`.
