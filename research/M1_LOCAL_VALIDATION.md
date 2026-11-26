---
title: "M1 local validation"
sub-title: "ARM64 toolchain acceptance and research evidence"
author: "Project planner"
date: "2026-11-26"
---

# M1 local validation

## Scope and decision

M1 infrastructure authoring was completed on GCP on 2026-11-25 using Gemini 4 Carbon (High) in Antigravity. Local validation on 2026-11-26 used ChatGPT-assisted debugging on the owner-operated MacBook. The infrastructure is accepted for further generic HDL development. This is a local validation sub-milestone, not completion of M2 or the full M4 experiment.

The results below are transcribed from owner-supplied terminal outputs and synthesis logs. This logging script does not rerun simulation or synthesis. Its own protected-file check is executed at logging time.

## Environment

| Item | Observed version/configuration |
|---|---|
| Host | macOS 26.6.2, Apple M5, ARM64, 10 CPUs, 16 GiB RAM |
| Host Python | 3.12.12 |
| Host Make | GNU Make 3.81 |
| Container runtime | Colima, Apple Virtualization Framework, virtiofs |
| Docker client / engine | 29.10.1 / 29.5.2 |
| Buildx | 0.39.1 |
| Container | Ubuntu 24.04, linux/arm64 |
| Image tag | fpga_ai-toolchain:m1-arm64 |
| GHDL | 4.1.0, GCC backend |
| Yosys | 0.33 |
| GCC | 13.3.0 |
| Container Python | 3.12.3 |
| NumPy / pytest / cocotb | 2.1.3 / 8.3.3 / 1.9.2 |
| Synthesis frontend | GHDL generated Verilog, then Yosys; plugin not used |

The native image built successfully on the first attempt. cocotb compiled from source for aarch64. The Dockerfile emitted one constant-platform warning; no rebuild was required for the two subsequent fixes. Versions are observed, not a claim of fully locked transitive dependencies.

## Verification matrix

| Check | Initial | After correction |
|---|---|---|
| Protected-file integrity (35 files) | PASS | PASS |
| make help | PASS | PASS |
| Native ARM64 image build | PASS | PASS (original build) |
| GHDL register simulation | PASS | PASS |
| GHDL binary32 addition simulation | PASS | PASS |
| cocotb register | FAIL | PASS |
| cocotb binary32 addition | FAIL | PASS |
| GHDL-to-Verilog register synthesis | PASS | PASS |
| GHDL-to-Verilog FP32 + Yosys structural check | FAIL | PASS |
| Post-synthesis numerical equivalence | NOT_RUN | NOT_RUN |
| Physical FPGA mapping/timing | NOT_RUN | NOT_RUN |

Protected baseline combined SHA-256: `e10a800fe0a2a1407ee46656bc4a73d4eb2373cefd43641d20b7e3d2482a129c`.

## DEFECT-001 - Clock initialization

- Both cocotb tests failed at 5 ns with an unresolvable `U` output after synchronous reset. Native VHDL testbenches passed and VPI loaded successfully.
- Original tests already sampled on the falling edge. The likely cause was the initial clock transition from unknown to high, not simply an output delta-cycle race.
- The planner supplied a targeted fix initializing the clock low and starting the clock with `start_high=False`. The owner applied it locally.
- Modified: `docker/smoke/cocotb_smoke_reg.py`, `docker/smoke/cocotb_smoke_fp32.py`.
- Subsequent `make smoke-sim`: all five checks PASS. No RTL or Docker changes. Do not mask unknown logic values using COCOTB_RESOLVE_X.

## DEFECT-002 - Synthesis assertion translation

- GHDL produced Verilog, but Yosys rejected a generated `$fatal` task while reading the FP32 adder. Register synthesis passed.
- The planner supplied a targeted fix adding `--no-formal` to the GHDL-to-Verilog synthesis path, explicitly propagating GHDL errors and retaining generated artifacts in the project results tree. The owner applied it locally.
- Modified: `scripts/smoke_synth.sh`.
- Subsequent `make smoke-synth`: all three checks PASS. Simulation assertions remain enabled. Disabling synthesis assertions is not a proof of equivalence.

## FP32 addition structural synthesis

Observed Yosys output: 1088 wires, 8558 wire bits, 0 memories, 0 processes, 510 generic RTL cells, 0 reported structural problems, 0.18 s Yosys user CPU time, 22.04 MB peak memory.

| Cell type | Count |
|---|---:|
| $add | 5 |
| $and | 5 |
| $eq | 51 |
| $ge | 1 |
| $gt | 5 |
| $le | 1 |
| $logic_not | 9 |
| $lt | 78 |
| $mux | 200 |
| $neg | 3 |
| $not | 3 |
| $or | 98 |
| $pmux | 26 |
| $reduce_and | 3 |
| $reduce_or | 12 |
| $sdff | 1 |
| $shl | 1 |
| $shr | 3 |
| $sub | 5 |

Four tri-state warnings remain. The generic cells are not physical LUTs, DSPs or flip-flop counts. No target-specific utilization or Fmax is established.

## Evidence and reproducibility

Commands used: `make verify`, `make help`, `make build`, `make smoke-sim`, `make smoke-synth`. Logs are under `experiments/exp001/results/m1_smoke/`; generated Verilog under its `synth_work/` subdirectory. The supplied FP32 log references run `J4uc7mMF`. A separate combined `make smoke` exit status has not been supplied; the individual suite outputs establish their reported passes.

## Lessons and open items

- Explicit clock initialization and phase-aware sampling are essential in co-simulation.
- Separate simulation from synthesis; retain intermediate netlists and propagate failures at each stage.
- Verify generated netlists numerically before asserting arithmetic equivalence; investigate tri-state warnings and test multiplication independently.
- The earlier pytest temporary directory was inside the container, not the host project. Moving simulation artifacts into the project remains a filesystem-discipline follow-up.
- Do not infer professional engineering parity from toolchain success. No experiment component is accepted by this milestone.
- Protected agent skills remain unchanged; incorporate lessons only with separate approval.

## Repository snapshot at logging time

```text
HEAD: abad05d
M docker/smoke/cocotb_smoke_fp32.py
 M docker/smoke/cocotb_smoke_reg.py
 M scripts/smoke_synth.sh
?? experiments/exp001/results/
?? fix_smoke_clock.sh
?? fix_smoke_synth.sh
?? fpga_ai_host_report.txt
?? host_diagnostic.sh
?? log_m1_validation.sh
?? tb_smoke_fp32_add
?? tb_smoke_reg
```
