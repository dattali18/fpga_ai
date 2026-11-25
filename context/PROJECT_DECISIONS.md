---
title: "Approved decisions"
sub-title: "FPGA AI research bootstrap"
author: "Project planning team"
date: "2026-11-25"
---

# Approved decisions

1. Planner and owner define and approve implementation plans; coder implements only approved milestones.
2. No third-party hardware IP for V1; IEEE standard libraries allowed.
3. Dimensions are synthesis-time VHDL generics.
4. Packet-oriented logical interface, one complex vector per transaction. Physical transfer protocol is not yet approved.
5. Standalone single-transaction PoC; no continuous pipeline integration.
6. Vendor-independent VHDL-2008; no vendor tool or physical board required initially.
7. IEEE-754 binary32 I/O and arithmetic; no fixed-point replacement.
8. External coefficient preparation; conjugation/reversal semantics specified in the functional contract.
9. Independent immutable Python golden reference approved by planner/owner before RTL work.
10. Compile-time configurable computational parallelism; exact architecture awaits approval.
11. Correct baseline first, then empirical optimization.
12. Agent-independent, chat-compatible workflow; AGY today, limited personal model access tomorrow.
13. Single repository: fpga_ai.
14. Nine-hour local execution session on 2026-11-26; best case component plus documentation for expert review.
15. Engineering and research records, not full prompt transcripts.
16. Docker Linux ARM64 for actual toolchain execution.
17. Minimal foundational skills now, extend using observed lessons.
18. Generate skeleton and code today where approved; run/fix locally tomorrow.
19. Explicit approval at every milestone; no autonomous git commits/pushes.
20. Select and adapt existing agentic resources rather than importing unrelated projects.

Open: dimension fixtures, physical interface, numerical exceptional-value policy, tolerance, exact design and tool versions. These are not delegated silent defaults.
