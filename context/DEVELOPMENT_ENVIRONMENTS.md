---
title: "Development environments"
sub-title: "FPGA AI research bootstrap"
author: "Project planning team"
date: "2026-11-25"
---

# Development environments

GCP: sandboxed Ubuntu with Antigravity coding agent. Docker unavailable. Probe existing tools with read-only commands only; no installation, privilege escalation or sandbox workarounds. Generate Docker files but never claim image build or tool execution unless actually observed. Python/static checks may be run if available and approved.

Local: MacBook Pro M5, 16 GiB RAM. Docker Linux ARM64 only. Proposed tools: GHDL (VHDL-2008), cocotb, NumPy, pytest, Yosys with compatible VHDL frontend. Verify package/version availability and compatibility; pin tested versions after actual build. Use a small toolchain smoke test before component work. Do not assume GHDL simulation implies synthesis. No paid licenses. If blocked, record exact error and next action; request approval for changes. Transfer only approved public/synthetic project files via authorized channels. No internal repositories or credentials.
