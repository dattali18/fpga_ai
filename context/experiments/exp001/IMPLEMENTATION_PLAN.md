---
title: "EXP001 milestone plan"
sub-title: "FPGA AI research bootstrap"
author: "Project planning team"
date: "2026-11-25"
---

# EXP001 milestone plan

This is a proposed milestone sequence, not blanket authorization. Before each milestone, submit a bounded file-level plan, acceptance checks and blockers to owner; wait for explicit approval. M0/M1 may be performed today, M2 only after specification gate, M3 handoff today. Local execution tomorrow.

M0 - Bootstrap: inventory repo, check selected rules, propose directory tree and record status. Do not alter protected files.

M1 - Infrastructure: propose Dockerfile and reproducibility scripts, toolchain smoke test, test harness layout. No Docker execution on GCP. Record untested commands. Stop for review.

M2 - Implementation: blocked until planner approves exact interface, mathematical oracle, numeric tolerances, architecture and file-level plan. Implement only approved generic DSP RTL and tests. Run available checks; document missing checks. Stop for review.

M3 - Handoff: review diffs, record actual verification states, local commands, blockers and prioritized TODOs. No unsupported claims. Stop for review.

M4 - Local execution: build container, run smoke checks, compile/simulate/test/synthesize where available. Report evidence and propose bounded fixes. Stop for review.

M5 - Evaluation: after correctness, measure approved configurations and propose optimizations as separate milestones. Preserve baseline evidence and prepare expert review. No target-specific performance claims without target-specific evidence.
