---
title: "EXP001 functional requirements"
sub-title: "FPGA AI research bootstrap"
author: "Project planning team"
date: "2026-11-25"
---

# EXP001 functional requirements

Scope: generic synthetic complex-vector filtering experiment, no application-specific deployment assumptions.

- R1: Input and output vectors have equal length N; coefficient/reference vector has length P. N and P are positive compile-time parameters. V1 processes one transaction at a time.
- R2: Each complex sample consists of two IEEE-754 binary32 values. Arithmetic uses binary32; numerical policy for special values and rounding must be approved before RTL implementation.
- R3: Direct time-domain linear filtering; no FFT. Input reference preparation such as windowing and normalization is external. The functional reference must specify conjugation, reversal, padding, and crop unambiguously and be approved independently of the coding agent.
- R4: Vendor-independent VHDL-2008. No third-party arithmetic IP; standard IEEE packages permitted.
- R5: Configurable compile-time computational parallelism. Architecture and physical data-transfer contract must be approved before implementation.
- R6: Reproducible Docker ARM64 environment, automated tests and documented execution.
- R7: No application-specific operational parameters, internal code, datasets or hardware interfaces.

Open specification gate: planner supplies approved golden reference and exact numerical/transaction contract. The coder must not invent these or start RTL before they are approved.
