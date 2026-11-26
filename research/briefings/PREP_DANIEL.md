---
title: "Meeting preparation - Daniel"
sub-title: "Glossary for the Amir briefing, how to handle the FPGA meeting, and the talk track for the AI meeting"
author: "Claude Code (implementer), for Daniel Attali"
date: "2026-11-26"
---

# Meeting preparation

Companion documents:
- [BRIEF_AMIR.md](BRIEF_AMIR.md): the technical briefing with 31 anticipated questions;
- [BRIEF_AI_LEAD.md](BRIEF_AI_LEAD.md): the AI-oriented briefing.

## Part 1 - Glossary: the terms in the Amir briefing

Each term comes with a software analogy where one helps.

### 1.1 FPGA and hardware basics

| Term | Meaning | Software analogy |
|---|---|---|
| **FPGA** | A chip made of many small configurable logic blocks and wires. You "program" it by describing a circuit, not a sequence of instructions | Hardware you compile into, instead of code that runs on hardware |
| **RTL** (register-transfer level) | The description level of the design: registers, and the logic between them that computes their next value every clock | The source code |
| **VHDL / VHDL-2008** | The hardware description language we use (2008 = language version) | The programming language |
| **Clock, clock cycle** | A global tick. Every register updates once per tick, all at the same time | A global `step()` call; one cycle = one step |
| **Register / FF** (flip-flop) | 1 bit of memory that updates on the clock edge. "129 FFs per lane" = 129 such bits | A variable that is only assigned at `step()` |
| **Combinational logic** | Logic with no memory; the output follows the inputs within the same cycle | A pure function evaluated inside one step |
| **State machine (FSM)** | Registers holding a state such as IDLE or COMPUTE, plus rules for the next state | A `switch(state)` inside the step loop |
| **Reset (synchronous, active high)** | A signal that forces the control registers back to IDLE at the next clock edge when it is 1 | `init()` |
| **Generic** | A compile-time parameter (N_RG, P, L) | A C++ template parameter |
| **Testbench** | Simulation-only code that drives the design and checks its outputs | A unit-test harness |
| **Simulation** | Running the design in software, cycle by cycle (GHDL) | Running unit tests |
| **Metavalue ('U', 'X', 'Z')** | Simulation-only values: U = uninitialised, X = unknown, Z = not driven. Real hardware has only 0 and 1 | `undefined` / `NaN` in a debugger; does not exist in the shipped binary |
| **Tri-state** | A wire that can be "not driven" (Z); used for shared buses, normally not inside FPGA logic | - |
| **CDC** (clock-domain crossing) | Signals passing between different clocks; a classic bug source. We have one clock, so no CDC | Thread-safety between two threads |

### 1.2 From code to chip

| Term | Meaning |
|---|---|
| **Synthesis** | Converts RTL into a **netlist**: a graph of generic gates, adders, multipliers and memories (GHDL `--synth`, then Yosys) |
| **Netlist** | The circuit as a list of components and wires. "Netlist simulation" means simulating that graph instead of the source |
| **Technology mapping** | Converts the generic netlist into the actual primitives of a chip family (here Xilinx Series 7). Gives resource counts |
| **Place and route** | Places primitives at physical locations on the chip and routes the wires. **Not done**; only after this can real timing be known |
| **Out-of-context** | Mapping the block alone, without chip pins or clock buffers |
| **Vivado** | Xilinx's (AMD's) official tool. We used open-source tools only; Amir probably uses Vivado |
| **GHDL / Yosys** | Open-source VHDL simulator and synthesizer |
| **Equivalence checking** | Formal proof that two netlists compute the same thing. Not done for M4 (Part C NOT_RUN) |
| **`share` pass** | A Yosys optimisation that merges operations that are never used at the same time. It ran out of memory, so the counts are "likely upper bounds" |

### 1.3 Xilinx Series 7 resources (the mapping table)

| Term | Meaning |
|---|---|
| **LUT** (look-up table) | The basic logic cell: any function of up to 6 inputs. "Logic LUT" = LUTs used for logic, not as memory |
| **CARRY4** | Dedicated fast-adder hardware, 4 bits per cell; used for additions and comparisons |
| **MUXF7 / MUXF8** | Dedicated multiplexers that combine LUT outputs into wider selections |
| **INV** | Inverter cell; usually absorbed into LUTs by Vivado |
| **DSP48E1** | A hard multiplier block (25×18-bit multiply plus adder). A 24×24-bit float mantissa product needs 2 of them, so 4 multiplications = 8 per lane |
| **LUTRAM / distributed RAM** | LUTs used as small memories. **RAM64M** = 64 words × 3 bits; **RAM32M** = 32 words × 6 bits. Can be read in the same cycle (asynchronous read) |
| **BRAM** (block RAM, RAMB18/36) | Larger dedicated memory blocks; the read result arrives one clock later (synchronous read). We use none |
| **SRL** | LUT used as a shift register. We use none |
| **Device fit** | Whether the design fits a specific chip. We make no fit claim |

### 1.4 Performance terms

| Term | Meaning |
|---|---|
| **Latency (cycles)** | Clock cycles from the first input to the last output of a block, e.g. 2784 for (256,64,8) |
| **Throughput / samples per cycle** | How many samples per clock the design processes on average (0.092 at L = 8) |
| **Fmax** | Maximum clock frequency; set by the slowest combinational path after place and route. **Unknown here**; never give a number |
| **Timing closure** | Making every path fast enough for the target clock |
| **Critical path / logic depth** | The longest chain of logic between two registers. Our ~750 "cells" counts components on that chain; it is not a time, but long means slow |
| **Pipelining** | Cutting a long combinational path with registers. Higher Fmax, more cycles of latency. Planned for M6 |
| **Lanes (L)** | Parallel copies of the multiply-accumulate unit; each computes a different output at the same time |
| **MAC** (multiply-accumulate) | `acc += a*b`; here a complex MAC = 4 multiplications + 3 additions or subtractions |
| **Utilisation (lanes)** | Fraction of cycles the lanes do useful work (90 % at L = 8 during compute) |
| **Overlap / double buffering** | Loading the next block while computing the current one; removes the 2·N_RG term |

### 1.5 Interface terms

| Term | Meaning |
|---|---|
| **valid/ready handshake** | Sender raises *valid* when data is present; receiver raises *ready* when it can take it; a transfer happens when both are 1 at the clock edge |
| **Backpressure / stall** | The receiver holds *ready* low to pause the sender |
| **AXI4-Stream** | The industry-standard version of this handshake. Ours follows its key rules but is not claimed compliant (no TKEEP/TUSER) |
| **TLAST / `out_last`** | Marks the last word of a block |
| **Combinational ready** | Our `in_ready` depends on `ref_valid` in the same cycle. That is legal, but integrators must avoid making a loop |

### 1.6 Numerics terms

| Term | Meaning |
|---|---|
| **binary32** | IEEE-754 single-precision float (C `float`) |
| **Mantissa / exponent** | The 24-bit significand and 8-bit exponent of a float; the multipliers work on mantissas |
| **Round to nearest even** | The IEEE default rounding, applied after every operation |
| **Subnormal (denormal)** | Very small floats below the normal range. Supported by the design, **not covered by the DPC tests** |
| **NaN / Inf** | Special values; out of the tested scope |
| **float_pkg** | The VHDL-2008 standard floating-point package; behavioural, vendor neutral, large in hardware |
| **Guard bits** | Extra internal bits that make rounding correct |
| **Bit exact** | Every output word identical, bit for bit, to the reference model's |
| **Error-bound gate** | The second check: the error relative to exact maths stays within a proven bound. Stays valid if the summation order changes |
| **Fixed point / block floating point** | Integer-based alternatives: much cheaper hardware, but you must manage scaling |
| **FFT fast convolution** | The frequency-domain alternative for long pulses: FFT, multiply, inverse FFT |
| **Systolic / transposed FIR** | The classic FPGA filter: one MAC per pulse tap, about 1 output per clock, many DSPs |

### 1.7 Project and verification terms

| Term | Meaning |
|---|---|
| **Golden reference** | The frozen Python model that defines the right answer (`dpc_ref.py`) |
| **Fixture** | One configuration (N_RG, P, L) with its test vectors |
| **Stress / timing mode** | Testbench with random stalls / without stalls (for cycle counts) |
| **Negative control** | A deliberately broken input that must make the check FAIL |
| **N1 / N2** | The two counted text rewrites needed to simulate GHDL's netlist (section 5.7, Q26 of the Amir briefing) |
| **Classfp metavalue test** | A check inside float_pkg ("is this input U/X?") that is meaningless in hardware; root of N2 and of CA-OBS-001 |
| **BLOCKED / NOT_RUN** | Could not run (tool limit) / deliberately not run |

## Part 2 - The FPGA meeting with Amir

### 2.1 Your stance

- You are the owner of a research experiment, not the designer. Say so: "The agents
  designed it; I directed and approved it. I want your professional judgement."
- Your strongest ground is **evidence quality**. Your weakest is **hardware intuition**.
  Lead with the first and ask openly about the second.
- If a question goes beyond the briefing: "I don't know. Let me note it and come back
  with tool evidence." That is consistent with the project rules, and an expert will
  respect it.

### 2.2 Three messages (in order)

1. **Function is solid:**
   - bit exact against an independent IEEE reference, on 13 configurations, with random
     backpressure;
   - cycle exact against a closed formula;
   - the synthesized netlist matches too (5 of 6 sizes);
   - every check has a failing control.
2. **Performance is deliberately naive.** The whole complex MAC sits in one clock cycle
   (about 750 cells deep), and load, compute and output do not overlap. We want his
   pipelining guidance before touching it.
3. **One open portability question.** float_pkg synthesis relies on the tool resolving
   a simulation-only test correctly. Yosys does; is Vivado safe? Ask for a 30-minute
   Vivado check on (8,3,1).

### 2.3 Questions you will most likely get (memorise the short answers)

| He asks | You answer (short) | Detail |
|---|---|---|
| "What Fmax?" | "Unknown, no timing tools. The logic depth is very long, so expect it to be low. What would you estimate?" | Q20 |
| "Why floating point?" | "Specification choice for exact verification; we know it costs about 8000 LUTs per MAC. Would you use fixed point?" | Q4 |
| "Why not FFT?" | "Direct form keeps a fixed summation order, so we can check it bit for bit. FFT would be next for long pulses" | Q1 |
| "Did you test subnormals and NaN?" | "Not in the DPC vectors; only in the separate arithmetic test. Known gap" | Q8 |
| "Post-route simulation?" | "No. Generic netlist simulation yes; mapped netlist and post-route no" | Q25 |
| "Why no datapath reset?" | "Data is always written before use; saves resources. Happy to add it if that is your style" | Q14 |
| "LUTRAM vs BRAM?" | "Asynchronous reads keep control simple; for bigger blocks we would move to BRAM" | Q16 |
| "These rewrites look like cheating." | "Each is counted exactly, justified, and a negative control still fails after them" | Q26 |
| "Is it AXI-Stream?" | "Same valid/ready rules, not claimed compliant" | Q11 |

### 2.4 What to bring home (write it into the decision log)

- His Fmax estimate and pipelining priorities. They define M6.
- Whether he will run the Vivado check.
- His verdict criteria for "comparable to professional". This is the research yardstick.
- The verification items he would require.

## Part 3 - The AI meeting with your boss

You know this area better than any briefing, so this part covers only the framing and
the numbers.

### 3.1 The story in 60 seconds

> "I took a real radar DSP function, pulse compression in 32-bit float, and built it as
> an FPGA component without knowing VHDL. Claude plans and writes the milestone
> specification. Claude Code, an agentic CLI, implements it, runs the open-source FPGA
> tools in Docker, and reports. I approve every step. The agents' rules live in the repo
> as code: `AGENTS.md`, `.agents/` rules, skills and workflows, plus protected
> requirements that are fingerprinted, so the agent can't move the goalposts. From
> approved specification to a mapped, verified design took about 3 hours. It is bit
> exact on every test, and the process caught 6 defects, including 2 in the test
> harnesses. What is not proven yet is professional quality and speed on a real chip.
> That's the expert review next."

### 3.2 Points to land

1. **The process is the product.** Rules, protected inputs, evidence manifests and
   human gates are reusable for any team and any model. The model only executes.
2. **Agentic tool access removed the manual loop.** In phase 1 you zipped context,
   copied code and ran scripts by hand. Now the agent runs the tools, reads the logs and
   fixes, and you only approve. (Not a measured speed-up: the phase-1 components were
   much smaller.)
3. **Human in the loop where it matters:** scope, workarounds, acceptance. Three
   explicit stop-and-ask moments in M4 alone.
4. **The without-AI estimate:**
   - about 3.5-6 months for a newcomer, of which about 2-4 months is learning;
   - about 2-4 weeks for an expert;
   - about 3 hours elapsed for the core with AI.
   - Present it as an estimate, and say that human time was not measured.
5. **Honest limits:**
   - frontier cloud models only;
   - no vendor tools or hardware yet;
   - planner and implementer from the same model family;
   - quality verdict pending.

### 3.3 Questions he is likely to ask

| Question | Answer |
|---|---|
| "Would this work with local or offline models?" | "Unknown, and the key test for internal use. The process carries over as-is; model capability is the variable. Proposal: rerun one milestone with a local model and compare defect rate and gate interventions" |
| "How much of your time did it take?" | "Not logged; that's a gap I'm fixing from the next milestone (minutes per gate)" |
| "Can juniors use it?" | "The mechanics yes; the gate judgement is the open question. The written rules help, because juniors inherit the lessons" |
| "What's the risk?" | "Plausible-looking but wrong results. Mitigated by independent references, failing controls and protected inputs; never by trusting the model" |
| "What do you need?" | Your call. Candidates: expert time (Amir), a vendor tool licence for a Vivado check, and compute for larger runs (the 10 GB VM hit its limit twice) |

### 3.4 Watch-outs

- Do not quote resource counts as "fits device X", and never quote a clock speed.
- Do not say "professional quality". Say "functionally verified; professional review
  pending".
- Keep the company context out of the repository documents; the briefings are written
  generically on purpose.

## Part 4 - Before both meetings

- Commit M4 after the planner review. Open questions: (256,64,8) BLOCKED, VM memory,
  and the 11 large logs.
- Bring the [RESULTS_M4.md](../../experiments/exp001/RESULTS_M4.md) table and the
  latency table from the Amir briefing.
- Calendar: these meetings serve the FPGA + GenAI role. Keep M5/M6 scope bounded,
  because the next paper and the thesis (about 2 months each) share your time.
