# Educational Register - Validation

Date: 2026-11-26

## Results

- Python reference self-check: PASS
- VHDL compilation and elaboration: PASS
- Functional simulation: PASS (21 checks)
- GHDL-to-Verilog synthesis: PASS
- Yosys structural verification: PASS
- Protected bootstrap integrity: PASS

## Synthesis

- RTLIL cells: 1 ($sdffe)
- Wire bits: 27
- Structural problems: 0

## Development observations

- Claude implementation compiled on the first attempt.
- No RTL corrections were required.
- Independent review identified and corrected a testbench coverage gap.
- Post-synthesis equivalence and physical FPGA timing were not evaluated.
