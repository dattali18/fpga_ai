# Educational synchronous FIFO

Date: 2026-11-26. Owner: planner. Independent digital logic exercise, separate from EXP001.

## Interface

VHDL-2008 entity `edu_fifo`, generics `G_WIDTH : positive := 8` and
`G_DEPTH : positive := 4`. Ports `clk`, `rst`, `wr_valid`, `rd_ready`
(inputs std_logic), `wr_ready`, `rd_valid` (outputs std_logic),
`wr_data` (input) and `rd_data` (output), both std_logic_vector(G_WIDTH-1 downto 0).
All positive depths including 1 and non-powers-of-two must work.

## Cycle contract

Single clock; active-high synchronous reset dominates state updates. During reset,
wr_ready and rd_valid are combinationally suppressed (no accepted transfers).
After reset is sampled at a rising edge the queue is empty. Memory contents need
not be reset. Inputs/outputs are evaluated before the rising edge. When rst=0:

- rd_valid = 1 iff occupancy > 0. rd_data is the oldest queued word when valid.
- wr_ready = 1 iff occupancy < G_DEPTH OR (rd_valid=1 AND rd_ready=1).
- pop iff rd_valid AND rd_ready; push iff wr_valid AND wr_ready.
- Simultaneous pop/push removes the old head, then appends the new word.
- No empty bypass: a push into an empty FIFO becomes visible after the edge.
- A full FIFO can accept a write on the same edge as a read, including depth 1.
- rd_data must remain stable while rd_valid=1 and rd_ready=0, unless reset.
- rd_data when rd_valid=0 is unspecified; do not test its value.
- Producer holds wr_valid and wr_data until accepted, or abandons on reset.

Suggested implementation: circular storage, explicit modulo-depth pointer wrap,
occupancy counter ranging 0..G_DEPTH, combinational head read. No vendor IP.
This is a first-word-fall-through interface, not a promise of BRAM inference.
No physical frequency or resource claims from generic RTLIL statistics.

## Acceptance

Use the immutable planner-generated vectors and a self-checking VHDL testbench.
Test configurations (width, depth): (1,1), (8,1), (8,3), (8,4), (16,5), (32,8).
Test reset, empty, full, stall, wraparound, simultaneous transfer at full and
partial occupancy, and random traffic. Check pre-edge ready/valid and valid data;
check reset gating and post-edge state via subsequent observations. Run GHDL
analysis/elaboration/simulation and GHDL-to-Verilog/Yosys structural check for each
configuration. No physical timing or post-synthesis equivalence claims.
