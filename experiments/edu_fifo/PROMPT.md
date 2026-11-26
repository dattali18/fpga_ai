# Coding assignment: educational synchronous FIFO

Read all files in the attached context ZIP. Implement only the standalone
`edu_fifo` digital logic exercise. Return one ZIP named `edu_fifo.zip` containing
exactly these relative paths:

- `rtl/edu_fifo.vhd`
- `tb/tb_edu_fifo.vhd`
- `README.md`

Follow the exact entity/generic/port and cycle contract in SPECIFICATION.md and
testbench contract in TEST_CONTRACT.md. Use VHDL-2008 and standard IEEE packages.
Support depth=1 and non-power-of-two depths, full simultaneous read/write,
no empty bypass, stable stalled output, and synchronous state reset. Pay special
attention to pointer wrap and occupancy updates. Do not reset storage unnecessarily.
The testbench must consume the supplied independent oracle's generated vectors,
not generate expected data using the RTL algorithm. Include the directed midcycle
reset test described in TEST_CONTRACT.md.

README: concise architecture rationale, interface timing, assumptions, commands
for GHDL simulation and GHDL-to-Verilog/Yosys structural checking. No external
IP, dependencies, installations or modifications to other project files. Do not
include or modify planner files. Do not claim tests ran unless actually executed.
No application-specific logic. Return ZIP and short list of unverified items.
