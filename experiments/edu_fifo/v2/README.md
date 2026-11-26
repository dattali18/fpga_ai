# EDU_FIFO V2 candidate

## Scope

`rtl/edu_fifo.vhd` is a drop-in replacement for the V1 RTL, with the same entity,
generics, ports and cycle contract. It changes only the storage structure, aiming to
keep inferred memory objects (see `DESIGN.md`). It includes no testbench, oracle or
scripts. Use the planner's immutable V1 `tb/tb_edu_fifo.vhd` and `golden.py`
unchanged.

## Verification instructions (planner flow, separate directory)

```sh
mkdir -p build && cd build
ghdl -a --std=08 <v2>/rtl/edu_fifo.vhd <v1>/tb/tb_edu_fifo.vhd
ghdl -e --std=08 tb_edu_fifo
ghdl -r --std=08 tb_edu_fifo -gG_WIDTH=<W> -gG_DEPTH=<D> -gG_VECTOR_FILE=<vectors>
ghdl --synth --std=08 -gG_WIDTH=<W> -gG_DEPTH=<D> --out=verilog <v2>/rtl/edu_fifo.vhd -e edu_fifo > edu_fifo.v
```

Run the same 22 configurations and strict Yosys views as V1 (`benchmark.csv`). Fields
to compare with V1:

- `memory_objects` and `memory_bits`. Expect padding: bits = `2**clog2(D)·W` for
  `D ≥ 2`.
- `logic_cells` and `logic_mux_cells`.
- Strict check pass/fail at depths 3, 5, 15, 31, 63 and 127, which is the V1 failure
  class.

## Test status

| Item | Status |
|---|---|
| GHDL analysis, elaboration, simulation (22 configurations) | **NOT RUN.** GHDL is not available in the authoring environment. |
| GHDL `--synth` and Yosys strict checks, memory and logic views | **NOT RUN.** GHDL and Yosys are not available. |
| Memory object retention | **NOT RUN.** Unknown. |
| Performance or resource change versus V1 | **None claimed.** Nothing has been measured. |
| Algorithm cross-check (scratch, not delivered) | **RUN.** A Python model of the V2 storage and pointer algorithm, with padded addressing and a depth-1 register, matched `golden.vectors()` in all 22 benchmark configurations (50,626 cycles; same total as `RESULTS.md`). This checks the logic only, not the VHDL. |
