# Educational register exercise

Date: 2026-11-26
Owner: planner
Scope: independent introductory digital logic exercise, not EXP001.

Implement an 8-bit register with synchronous active-high reset and clock enable.
At a rising edge, reset sets q to zero; otherwise enable captures d; otherwise q holds.
No application-specific interfaces or processing. Verify reset priority, hold, capture,
and consecutive writes. Use VHDL-2008 and standard IEEE packages.

Acceptance: GHDL analysis, elaboration and simulation pass; structural synthesis is
reported separately. No physical timing claims without device mapping.
