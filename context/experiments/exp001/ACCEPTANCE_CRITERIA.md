---
title: "EXP001 acceptance criteria"
sub-title: "FPGA AI research bootstrap"
author: "Project planning team"
date: "2026-11-25"
---

# EXP001 acceptance criteria

Use PASS / FAIL / BLOCKED / NOT_RUN for every criterion. Link command, tool version, environment and raw evidence. No criterion may be weakened by the coder.

- AC1: Approved functional contract and protected golden reference present; verify digest before and after tests.
- AC2: Docker ARM64 build and VHDL simulator smoke test succeed locally.
- AC3: RTL compiles and elaborates for approved configurations.
- AC4: Independent numerical comparisons pass all approved fixtures and tolerances; verify output shape, order and repeatability. Tolerance and exceptional-value policy are pending planner approval.
- AC5: Generic synthesis succeeds without black boxes or unintentional unsynthesizable constructs; capture generic resource counts and limitations.
- AC6: Report measured transaction cycles and sample counts with explicit measurement boundaries; no nanosecond or Fmax claim from generic simulation.
- AC7: Code, execution instructions, evidence, known limitations and review handoff are complete.

No professional parity claim until a suitable baseline and expert assessment exist.
