# Testbench contract

Entity `tb_edu_fifo`, generics `G_WIDTH : positive := 8`, `G_DEPTH : positive := 4`,
`G_VECTOR_FILE : string := "vectors.txt"`. No ports. Read planner-generated text
using std.textio; each line contains seven whitespace-separated fields:

    rst wr_valid wr_data rd_ready expected_wr_ready expected_rd_valid expected_rd_data

Control fields are integer 0/1. Data fields are exactly G_WIDTH binary digits,
MSB first (use bit_vector or std_logic_vector textio, not integer conversion).
For each line drive inputs with clk low, wait for combinational settling, check
ready/valid and rd_data only when expected_rd_valid=1, then drive a rising edge,
wait for settling and drive clk low. Begin with clk='0'. Use assert severity
failure on mismatch, reporting cycle and configuration. End with std.env.finish.
The first vector asserts reset. Do not assert data when invalid. Additionally
include a directed midcycle reset check or describe how synchronous state reset
is distinguished from asynchronous state reset: assert reset without a rising
edge then deassert it and verify that the prior nonempty head remains unchanged.
The interface flags are intentionally gated during reset, independent of state.

Run from a project-local build directory. Planner owns golden.py and generated
vectors; do not reproduce or modify the oracle. No need to return generated logs.
