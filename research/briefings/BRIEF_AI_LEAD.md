---
title: "Briefing - AI-assisted FPGA development"
sub-title: "How a software engineer without FPGA training builds a verified FPGA component with frontier LLM agents and a human in the loop"
author: "Claude Code (implementer), for Daniel Attali"
date: "2026-11-26"
---

# AI-assisted FPGA development - briefing

## 1. The question and the short answer

**Question** ([PROJECT_VISION.md](../../context/PROJECT_VISION.md)): can an
experienced software engineer **without FPGA training**, aided by frontier LLM planning
and coding agents, produce an FPGA component comparable to one built by a professional?

**Short answer so far:**
- **Yes for function.** The component computes exactly the right bits in every test.
- **Not yet known for professional quality.** Speed on a real chip, size and
  production style still need the expert review.
- **Speed:** from the approved specification to a design mapped onto a Xilinx FPGA
  family took about 3 hours of elapsed time (git timestamps). That includes
  verification and a full evidence trail.

The component is a **digital pulse compression** block, a standard radar signal
processing function. It correlates received samples with the transmitted pulse, in
32-bit floating point. All data are synthetic and public.

## 2. Starting point: what the owner did not know

Daniel is a software, GPU and AI engineer. Before this project he had no training in:
- hardware description languages (VHDL), or thinking in clock cycles and registers;
- FPGA architecture: logic cells (LUTs), carry chains, DSP blocks, on-chip RAM;
- IEEE-754 rounding at the level hardware needs (every rounding step matters for a bit
  match);
- hardware verification practice: testbenches, backpressure, netlist simulation;
- the open-source FPGA tools (GHDL simulator, Yosys synthesis).

He brought the requirements, software engineering discipline, critical reading of
evidence and the approvals.

## 3. The workflow: frontier models with a human in the loop

### 3.1 Roles

| Role | Who | Does | Never does |
|---|---|---|---|
| Owner | Daniel | Sets goals, approves every plan, decides trade-offs, commits | Write VHDL |
| Planner and reviewer | Claude (chat, frontier model) | Specification, milestone prompts with acceptance criteria, review of results | Run tools, edit files |
| Implementer | Claude Code (agentic CLI, frontier model) | Writes RTL, testbenches and scripts; runs the tools in Docker; diagnoses failures; writes evidence and records | Commit, change requirements, edit protected files |
| Judge | Docker toolchain (GHDL, Yosys, Python) | Produces the only accepted evidence | - |
| Expert | Amir, senior FPGA engineer | Final professional review | - |

### 3.2 The loop (one per milestone)

```text
 ┌───────────────┐  prompt   ┌────────┐  prompt   ┌─────────────────────────────┐
 │ Planner (LLM) │──────────►│ Daniel │──────────►│ Implementer (LLM agent)     │
 └───────────────┘           └────────┘           │ 1. posts a plan             │
        ▲                     ▲   │ "go"          │ 2. waits                    │
        │ review              │   └──────────────►│ 3. implements, runs tools   │
        │                     │                   │ 4. writes evidence, records │
        │   PLANNER REPORT    │                   │ 5. stages, does not commit  │
        └─────────────────────┴───────────────────┴─────────────────────────────┘
```

- The two agents never talk directly. Every handover passes through Daniel, so he
  sees and can stop every step.
- **Stop-and-ask rule:** when a check fails, or a tool needs a workaround, the agent
  stops and asks. It does not decide alone. In M4 this happened three times. Each
  workaround was approved explicitly and is labelled in the results.

### 3.3 How it evolved (itself a finding)

| Phase | Setup | Observation |
|---|---|---|
| 1 | ChatGPT planner and reviewer, Claude chat coder fed with ZIP files of context, scripts run by hand (D-006) | Worked for a register and a FIFO, but it was slow and the context handover was manual |
| 2 | Claude chat as planner and coder (D-055) | Fewer handovers; less independence between planner and coder |
| 3 | Claude chat planner + **Claude Code agent** implementing and running tools itself (D-064) | The DPC core (M2b, M2c, M4) took about 3 hours; the human gates stayed |

Lesson (reasoned, not measured): giving the agent **direct, sandboxed tool access** (run,
read logs, fix, re-run) removed the manual steps: zipping context, copying code, running
scripts by hand, pasting logs back. The phase-1 components were much smaller, so their
times are not directly comparable with the DPC.

## 4. How the agents are steered: "configuration as code"

All agent instructions live in the repository as plain text under version control.
Every session, and any model, starts from the same rules.

| File or folder | What it is | Example content |
|---|---|---|
| `AGENTS.md` | Entry point for any coding agent | Read the context first; the planner owns requirements; stop for approval at each gate |
| `.agents/rules/` (8 files) | Hard rules | "PASS requires observed evidence"; "never weaken tests"; "missing tools are BLOCKED, not PASS"; "no hardware timing claims"; "public synthetic data only" |
| `.agents/skills/` (13 files) | Reusable procedures the agent loads on demand | RTL verification, synthesis, benchmarking, claim tracing, changelog, daily notes, session resume |
| `.agents/workflows/` (2 files) | The two loops | Implement a milestone; review a milestone |
| `CLAUDE.md` | Project memory for Claude Code | Toolchain commands, roles, **lessons from past defects** so they are not repeated |
| `context/` | Requirements, acceptance criteria, vision | **Protected:** the agent may not edit what it is judged against |
| `research/DECISION_LOG.md` | Append-only decision record (D-001 to D-085) | Who decided what, alternatives, rationale |
| `experiments/*/prompts/` | One prompt per milestone, written by the planner | Scope, files, checks, acceptance table |

### Guard rails that are enforced, not just written down

1. **Protected inputs.** Requirements, rules and the golden reference model carry
   SHA-256 fingerprints. A script checks them before and after every test run, so the
   agent cannot quietly move the goalposts.
2. **An independent golden reference.** A Python model, frozen before any hardware code
   existed, defines the correct answer. The hardware tests never import it; they only
   exchange files.
3. **Controls.** Every check also runs on deliberately wrong input, to prove that it can
   fail. "Verification code needs verification" is now a written lesson.
4. **Evidence manifests.** Each run leaves a folder of logs with a hash manifest.
   Results documents link to it. Raw evidence is never edited; mistakes get a
   CORRECTION note.
5. **Four status words.** PASS, FAIL, BLOCKED, NOT_RUN. PASS only with tool output.
6. **No commits without the owner.** The agent stages; Daniel commits.

## 5. What the process caught

| ID | What went wrong | Caught by | Lesson |
|---|---|---|---|
| FIFO-DEFECT-001 | Memory addressing error in an early FIFO | Synthesis structural check | Written into CLAUDE.md; avoided by design in the DPC |
| EQ-DEFECT-001/002 | Two bugs in the formal-equivalence *harness* | Negative controls | Every harness needs a failing control |
| M2A-DEFECT-001 | An evidence manifest written while its log was still open | Agent audit | Write manifests last; correct with a note, never rewrite |
| DPC-DEFECT-001 | A test metric that always read 0 | Agent noticed the implausible number | Positive control added |
| DPC-DEFECT-002 | A structural flaw in the parallel design | Exact-count check on synthesis warnings | Count expectations exactly; do not tolerate "a few more warnings" |
| M4-TOOL-001..004 | Four limits of the open-source tools | Agent stopped and asked | Workarounds approved by the human and labelled in results |

A side result: while working around a tool limit, the agent **explained** a warning
that had been open since the first floating-point exercise (CA-OBS-001). It also found
a real **portability risk** for the expert: the standard floating-point library relies
on each synthesis tool resolving a simulation-only test the same way. That is
engineering insight, not just code generation.

## 6. Results in plain language

| Milestone | Output | Status |
|---|---|---|
| Warm-up | Register, FIFO (2 versions, resource study, formal equivalence), floating-point complex arithmetic (8124 test vectors, bit exact) | Accepted |
| M2a | Specification and frozen golden reference | Done |
| M2b | Working design, 1 compute lane | Accepted |
| M2c | Parallel design, L lanes: 6.07× fewer cycles at 8 lanes | Accepted |
| M4 | Synthesized circuit matches bit for bit (5 of 6 sizes); FPGA resource estimate | For review |

- About 8000 logic cells and 8 DSP blocks per lane; on-chip memory in distributed RAM.
- Not yet established, and not claimed:
  - clock speed;
  - power;
  - behaviour on a real chip;
  - results in the vendor tool (Vivado);
  - professional-quality code style.

## 7. What would it take without AI? (estimate, not measured)

The baseline below is a reasoned estimate for the **same scope and the same evidence
level**: specification, golden reference with an error bound, RTL, testbench with
controls, parallel version, synthesis, mapping and records. It is not a measurement.

### 7.1 The same software engineer, without AI

| Learning area | Estimated time (full-time weeks) |
|---|---:|
| Digital design basics: clocks, registers, state machines, combinational logic, timing concepts | 3-6 |
| VHDL-2008, simulation semantics, synthesizable subset | 3-6 (overlaps) |
| IEEE-754 in hardware: rounding, subnormals, float_pkg | 1-2 |
| Hardware verification: testbenches, handshakes, backpressure, controls | 1-2 |
| Open-source toolchain: GHDL, Yosys, Docker setup | 1 |
| FPGA architecture, enough to read mapping reports (LUT, CARRY4, DSP48E1, LUTRAM) | 1-2 |
| **Learning subtotal** (with overlap) | **about 8-16 weeks** |

| Work item | Estimated time (weeks) |
|---|---:|
| Specification and golden reference with an exact error bound | 1-2 |
| Single-lane RTL and testbench, including debugging | 2-3 |
| Parallel lanes | 1-2 |
| Synthesis, mapping, netlist simulation, tool workarounds (the N1/N2 diagnoses need knowledge of GHDL and float_pkg internals) | 1-3 |
| Evidence and records at this level of rigour | 1 |
| **Work subtotal** | **about 6-11 weeks** |

**Total: about 14-27 weeks (roughly 3.5-6 months)** of full-time effort for a newcomer. Realistically
longer part-time, with a real risk of stalling on tool problems without a mentor.

### 7.2 For comparison

| Who | Estimated effort for the same scope |
|---|---|
| Experienced FPGA engineer, no AI | About 2-4 weeks. Likely faster with vendor floating-point IP, which changes the design |
| This project (SWE + AI) | About 12 hours of elapsed time over 2 days for everything, including warm-ups; about 3 hours for the DPC core from approved specification to M4 |

### 7.3 Caveats (say these out loud)

- Human time was **not measured**. Elapsed time includes Daniel's approvals and his
  copying of prompts between agents, but nobody logged minutes.
- The comparison is with an estimate, not with a controlled experiment.
- Quality is **not yet expert-validated**. If Amir finds the design unusable for
  production, much of the time advantage becomes redesign work.
- The planner LLM supplied much of the domain expertise (the specification and the
  numerical contract). The finding is "SWE + frontier LLMs", not "SWE alone".
- Planner and implementer are the same model family, so they are not independent.
  Human gates and tool evidence compensate, but only partly.

## 8. Implications for using AI in FPGA development

| Works well | Needs the human | Needs the expert |
|---|---|---|
| Turning a precise specification into correct, verified RTL | Approving scope and architecture | Timing closure, pipelining strategy |
| Writing test infrastructure, controls, scripts | Judging tool workarounds | Device choice, vendor flow (Vivado) |
| Diagnosing tool failures from logs | Deciding what counts as evidence | Production coding style |
| Keeping complete research records | Spotting implausible numbers | "Is this professional grade?" |

**Untested so far, and important for any deployment:**
1. **Smaller or offline models.** This used frontier cloud models. The process (rules,
   skills, gates, evidence) is model-independent text and can be carried over. Model
   capability is the open variable.
2. **Vendor tools and real hardware.** Everything here is open-source and
   simulation-level.
3. **Effort accounting.** Human minutes per gate, and model cost, should be logged from
   the next milestone on.
4. **Junior users.** Whether a junior engineer would make the same gate decisions is
   unknown.

## 9. Next steps

1. Planner review of M4.
2. M5: review package for Amir; his review is the quality verdict.
3. M6: performance optimisation (pipelining, overlap), guided by his feedback.
4. Start logging human time per gate, so the next experiment has a measured effort
   figure.
