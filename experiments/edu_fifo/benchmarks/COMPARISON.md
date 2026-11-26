# EDU_FIFO V1/V2 paired comparison

Date: 2026-11-26. Both runs passed all 22 configurations; identical vectors, tool versions, image and configuration manifest. V1 retained zero memory objects; V2 retained one for all 19 depth>1 configurations.

## All configurations

| Width | Depth | Cycles/version | V1 memory cells | V2 memory cells | V2 memory bits | V1 mapped cells | V2 mapped cells | Change |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1 | 2025 | 21 | 21 | 0 | 21 | 21 | +0.0% |
| 8 | 1 | 2025 | 21 | 21 | 0 | 21 | 21 | +0.0% |
| 8 | 3 | 2039 | 48 | 32 | 32 | 48 | 48 | +0.0% |
| 8 | 4 | 2046 | 54 | 32 | 32 | 54 | 48 | -11.1% |
| 8 | 32 | 2242 | 253 | 32 | 256 | 253 | 179 | -29.2% |
| 16 | 5 | 2053 | 64 | 32 | 128 | 64 | 69 | +7.8% |
| 16 | 32 | 2242 | 253 | 32 | 512 | 253 | 179 | -29.2% |
| 32 | 1 | 2025 | 21 | 21 | 0 | 21 | 21 | +0.0% |
| 32 | 3 | 2039 | 48 | 32 | 128 | 48 | 48 | +0.0% |
| 32 | 4 | 2046 | 54 | 32 | 128 | 54 | 48 | -11.1% |
| 32 | 8 | 2074 | 83 | 32 | 256 | 83 | 69 | -16.9% |
| 32 | 15 | 2123 | 134 | 32 | 512 | 134 | 106 | -20.9% |
| 32 | 16 | 2130 | 140 | 32 | 512 | 140 | 106 | -24.3% |
| 32 | 31 | 2235 | 247 | 32 | 1024 | 247 | 179 | -27.5% |
| 32 | 32 | 2242 | 253 | 32 | 1024 | 253 | 179 | -29.2% |
| 32 | 63 | 2459 | 472 | 32 | 2048 | 472 | 316 | -33.1% |
| 32 | 64 | 2466 | 478 | 32 | 2048 | 478 | 316 | -33.9% |
| 32 | 127 | 2907 | 921 | 32 | 4096 | 921 | 585 | -36.5% |
| 32 | 128 | 2914 | 927 | 32 | 4096 | 927 | 585 | -36.9% |
| 32 | 256 | 3810 | 1824 | 32 | 8192 | 1824 | 1110 | -39.1% |
| 64 | 32 | 2242 | 253 | 32 | 2048 | 253 | 179 | -29.2% |
| 128 | 32 | 2242 | 253 | 32 | 4096 | 253 | 179 | -29.2% |

## Measured host execution time (seconds)

| Stage | V1 | V2 | V1/V2 |
|---|---:|---:|---:|
| sim_seconds | 0.229323 | 0.270998 | 0.85x |
| ghdl_seconds | 22.914490 | 3.384785 | 6.77x |
| memory_seconds | 3.842769 | 0.508528 | 7.56x |
| logic_seconds | 3.898746 | 1.663570 | 2.34x |
| Total | 30.885328 | 5.827881 | 5.30x |

## Findings and limitations

F-FIFO-007 through F-FIFO-013: V2 passed first-submission regression without RTL corrections; memory inference succeeded; at W32 D256 mapped cells decreased from 1824 to 1110 and mux cells from 518 to 264. W16 D5 increases mapped cells from 64 to 69 and inferred storage from 80 logical bits to 128 allocated bits. Timing measurements are single-run host tool times, not hardware latency. No physical BRAM, timing closure or post-synthesis equivalence claim. Expert review outstanding.

Oracle cycles per version: 50626.
Raw archive SHA-256: 829719d638c291c1ee7b43b6c1d416a5d33a94c3e8d6ca8d5be7e12632f9080e
Source hashes and dirty working-tree status retained in paired provenance. CSV line endings may be normalized by Git. Original V1 benchmark remains unchanged.
