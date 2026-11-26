# EDU_FIFO - Series 7 technology mapping

Date: 2026-11-26. Status: ACCEPTED (resource mapping only).

## Method and provenance

Run: xc7.N6LCkjoT. Both RTL versions, 22 configurations, three strategies; all 132 mappings passed. Target xc7, out-of-context, no I/O pads or clock buffers. GHDL 4.1.0, Yosys 0.33. Source HEAD: 1131c808bf4921de2849b8d5b25c2631d850247b. Runner and ledger were uncommitted at execution; source hashes identify exact inputs.

Default allows BRAM/LUTRAM/SRL; no_bram disables BRAM; logic_only disables all three. No new simulation or mapped equivalence was performed.

## Aggregate results (sums over 22 independent configurations)

| Version | Strategy | Logic LUT cells | FF cells | Distributed RAM cells | BRAM cells | Mapping seconds |
|---|---|---:|---:|---:|---:|---:|
| v1 | default | 25241 | 31266 | 0 | 0 | 54.991 |
| v1 | no_bram | 25241 | 31266 | 0 | 0 | 55.215 |
| v1 | logic_only | 25241 | 31266 | 0 | 0 | 54.072 |
| v2 | default | 574 | 314 | 197 | 0 | 32.989 |
| v2 | no_bram | 574 | 314 | 197 | 0 | 32.387 |
| v2 | logic_only | 12539 | 31482 | 0 | 0 | 43.130 |

## Paired configuration results

| Width | Depth | Strategy | V1 LUT | V2 LUT | V1 FF | V2 FF | V2 LUTRAM |
|---:|---:|---|---:|---:|---:|---:|---:|
| 1 | 1 | default | 4 | 4 | 2 | 2 | 0 |
| 1 | 1 | no_bram | 4 | 4 | 2 | 2 | 0 |
| 1 | 1 | logic_only | 4 | 4 | 2 | 2 | 0 |
| 8 | 1 | default | 4 | 4 | 9 | 9 | 0 |
| 8 | 1 | no_bram | 4 | 4 | 9 | 9 | 0 |
| 8 | 1 | logic_only | 4 | 4 | 9 | 9 | 0 |
| 8 | 3 | default | 20 | 9 | 30 | 6 | 2 |
| 8 | 3 | no_bram | 20 | 9 | 30 | 6 | 2 |
| 8 | 3 | logic_only | 20 | 21 | 30 | 38 | 0 |
| 8 | 4 | default | 23 | 11 | 39 | 7 | 2 |
| 8 | 4 | no_bram | 23 | 11 | 39 | 7 | 2 |
| 8 | 4 | logic_only | 23 | 23 | 39 | 39 | 0 |
| 8 | 32 | default | 244 | 27 | 272 | 16 | 2 |
| 8 | 32 | no_bram | 244 | 27 | 272 | 16 | 2 |
| 8 | 32 | logic_only | 244 | 170 | 272 | 272 | 0 |
| 16 | 5 | default | 53 | 14 | 89 | 9 | 3 |
| 16 | 5 | no_bram | 53 | 14 | 89 | 9 | 3 |
| 16 | 5 | logic_only | 53 | 74 | 89 | 137 | 0 |
| 16 | 32 | default | 420 | 27 | 528 | 16 | 3 |
| 16 | 32 | no_bram | 420 | 27 | 528 | 16 | 3 |
| 16 | 32 | logic_only | 420 | 274 | 528 | 528 | 0 |
| 32 | 1 | default | 4 | 4 | 33 | 33 | 0 |
| 32 | 1 | no_bram | 4 | 4 | 33 | 33 | 0 |
| 32 | 1 | logic_only | 4 | 4 | 33 | 33 | 0 |
| 32 | 3 | default | 44 | 9 | 102 | 6 | 6 |
| 32 | 3 | no_bram | 44 | 9 | 102 | 6 | 6 |
| 32 | 3 | logic_only | 44 | 45 | 102 | 134 | 0 |
| 32 | 4 | default | 47 | 11 | 135 | 7 | 6 |
| 32 | 4 | no_bram | 47 | 11 | 135 | 7 | 6 |
| 32 | 4 | logic_only | 47 | 47 | 135 | 135 | 0 |
| 32 | 8 | default | 157 | 19 | 266 | 10 | 6 |
| 32 | 8 | no_bram | 157 | 19 | 266 | 10 | 6 |
| 32 | 8 | logic_only | 157 | 123 | 266 | 266 | 0 |
| 32 | 15 | default | 329 | 21 | 492 | 12 | 6 |
| 32 | 15 | no_bram | 329 | 21 | 492 | 12 | 6 |
| 32 | 15 | logic_only | 329 | 202 | 492 | 524 | 0 |
| 32 | 16 | default | 331 | 27 | 525 | 13 | 6 |
| 32 | 16 | no_bram | 331 | 27 | 525 | 13 | 6 |
| 32 | 16 | logic_only | 331 | 204 | 525 | 525 | 0 |
| 32 | 31 | default | 865 | 34 | 1007 | 15 | 6 |
| 32 | 31 | no_bram | 865 | 34 | 1007 | 15 | 6 |
| 32 | 31 | logic_only | 865 | 484 | 1007 | 1039 | 0 |
| 32 | 32 | default | 772 | 27 | 1040 | 16 | 6 |
| 32 | 32 | no_bram | 772 | 27 | 1040 | 16 | 6 |
| 32 | 32 | logic_only | 772 | 482 | 1040 | 1040 | 0 |
| 32 | 63 | default | 1831 | 26 | 2034 | 18 | 11 |
| 32 | 63 | no_bram | 1831 | 26 | 2034 | 18 | 11 |
| 32 | 63 | logic_only | 1831 | 774 | 2034 | 2066 | 0 |
| 32 | 64 | default | 1786 | 33 | 2067 | 19 | 11 |
| 32 | 64 | no_bram | 1786 | 33 | 2067 | 19 | 11 |
| 32 | 64 | logic_only | 1786 | 774 | 2067 | 2067 | 0 |
| 32 | 127 | default | 2845 | 67 | 4085 | 21 | 22 |
| 32 | 127 | no_bram | 2845 | 67 | 4085 | 21 | 22 |
| 32 | 127 | logic_only | 2845 | 1572 | 4085 | 4117 | 0 |
| 32 | 128 | default | 3935 | 75 | 4118 | 22 | 22 |
| 32 | 128 | no_bram | 3935 | 75 | 4118 | 22 | 22 |
| 32 | 128 | logic_only | 3935 | 1571 | 4118 | 4118 | 0 |
| 32 | 256 | default | 7167 | 71 | 8217 | 25 | 44 |
| 32 | 256 | no_bram | 7167 | 71 | 8217 | 25 | 44 |
| 32 | 256 | logic_only | 7167 | 3059 | 8217 | 8217 | 0 |
| 64 | 32 | default | 1476 | 27 | 2064 | 16 | 11 |
| 64 | 32 | no_bram | 1476 | 27 | 2064 | 16 | 11 |
| 64 | 32 | logic_only | 1476 | 898 | 2064 | 2064 | 0 |
| 128 | 32 | default | 2884 | 27 | 4112 | 16 | 22 |
| 128 | 32 | no_bram | 2884 | 27 | 4112 | 16 | 22 |
| 128 | 32 | logic_only | 2884 | 1730 | 4112 | 4112 | 0 |

## Findings

- F-FIFO-014: All 132 mapping runs passed.
- F-FIFO-015: V2 infers distributed RAM (RAM32M/RAM64M); V1 does not.
- F-FIFO-016: At W32 D256, default logic LUT cells decrease from 7167 to 71 (99.0%). Aggregate reduction 97.7%.
- F-FIFO-017: At W32 D256, default FF cells decrease from 8217 to 25 (99.7%); aggregate reduction 99.0%.
- F-FIFO-018: Logic-only W32 D256 uses 3059 vs 7167 LUT cells (57.3% fewer), with equal FF counts. Aggregate logic-only FF count rises in V2.
- F-FIFO-019: No BRAM inferred in either version; consistent with asynchronous read architecture, not a proof of causation.
- F-FIFO-020: Aggregate mapping time decreases in all three strategies in this single run.

## Limitations

Logic LUT counts exclude LUT resources consumed by distributed RAM. Primitive counts are not placed utilization, timing, or device capacity. Aggregate sums are descriptive, not a single deployed design. No physical implementation or mapped functional equivalence yet. Expert review pending. Raw logs and mapped JSON remain in the ignored build directory; compact evidence and commands are archived here.

## Next step

Investigate mapped-netlist functional equivalence before considering a separate BRAM-oriented architecture.
