# EDU_FIFO V2 - Standalone educational optimization assignment

You are the coding engineer for a generic synchronous FIFO exercise. Read the attached context ZIP. V1 is verified and immutable. Produce a separate VHDL-2008 candidate that preserves the entire cycle contract in SPECIFICATION.md. Aim to retain inferred memory objects for larger depths, without changing externally observable behavior. No vendor IP. All positive widths/depths, including depth 1 and non-powers of two. Do not relax ready/valid timing, capacity, no-empty-bypass, full replacement, reset gating/state semantics, ordering or stall stability. The existing oracle and testbench are immutable. The entity and ports/generics must have exactly the existing names so the planner can compile the candidate separately with the same testbench. Review the benchmark evidence and prior synthesis failure. Do not suppress structural checks or assume memory inference proves BRAM usage.

Return a ZIP named edu_fifo_v2.zip with exactly:
- rtl/edu_fifo.vhd (candidate only; will be integrated in a separate directory)
- DESIGN.md (architecture, state transitions, memory semantics, choices and rejected alternatives, risks, and any assumptions; explain handling of simultaneous operations and boundary cases)
- README.md (scope, verification instructions, honest test status)

Do not return modified V1 files, oracle, testbench, scripts, generated logs or binaries. If execution is unavailable state NOT RUN. Do not claim performance improvements without measurements. Planner will run all 22 identical configurations and strict GHDL/Yosys checks. A failure to infer memory is a measured outcome, not permission to change the contract. Keep response and documentation concise. Record each material implementation decision and rationale in DESIGN.md.
