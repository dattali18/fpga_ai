# EDU_FIFO formal equivalence - initial pilot

Date: 2026-11-26. Evidence: equiv.YNCk1sRd.

18 reset-constrained comparisons; 3 PROVEN (all W1 D1), 15 BOUNDED; no reachable observable counterexamples reported. All 15 incomplete induction attempts reached eight steps, not a solver timeout. See equivalence.csv and individual proof logs.

F-FIFO-021: all bounded checks passed. F-FIFO-022: three depth-one complete proofs. F-FIFO-023: remaining induction attempts did not converge. F-FIFO-024: no solver timeout observed. F-FIFO-025: missing hidden-state invariants are a working explanation, not yet confirmed by a strengthened proof.

The model compares GHDL-translated Verilog, not an independent interpretation of VHDL. It forces an initial synchronous reset and compares ready/valid and valid data; subsequent inputs arbitrary binary. No physical mapping equivalence established. Induction traces can represent unreachable states.

Retained proof logs, harnesses, traces and provenance. Original full archive retained locally; generated netlists omitted from this compact archive.
