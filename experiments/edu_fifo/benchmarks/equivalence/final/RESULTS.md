# EDU_FIFO - Formal equivalence pilot: final audit

Date: 2026-11-26
Status: ACCEPTED for six fixed configurations under the modeled assumptions only.

## Experiment chronology

| Run | Outcome | Evidentiary status |
|---|---|---|
| equiv.YNCk1sRd | 3 proven, 15 bounded | Invalidated: harness missing proc |
| equiv_invariants.i3iVLTt8 | 18 proven | Invalidated: harness missing proc |
| equiv.YFk4aJez | 18 inconclusive | Negative-control parser blocked actual proofs |
| equiv_invariants.qD0jLL6B | 18 inconclusive | Negative-control parser blocked actual proofs |
| equiv.VFD9H4vr | 3 proven, 15 bounded | Corrected observable-only baseline |
| equiv_invariants.Uu1w69q7 | 18 proven | Corrected invariant-strengthened pilot |

EQ1 compares V1 translated RTL with generic synthesized V1; EQ2 does the same for V2; EQ3 compares the translated architectures. All final bounded checks passed. All strengthened induction proofs completed at length one. The corrected runs include initialization and activation checks and a deliberately false property rejected with a counterexample. The initial experiments are historical evidence, not accepted proof evidence.

## Final pilot

| Width | Depth | Horizon | Observable-only EQ1/2/3 | Strengthened EQ1/2/3 |
|---:|---:|---:|---|---|
| 1 | 1 | 10 | PROVEN | PROVEN |
| 2 | 2 | 12 | BOUNDED | PROVEN |
| 2 | 3 | 14 | BOUNDED | PROVEN |
| 2 | 4 | 16 | BOUNDED | PROVEN |
| 8 | 3 | 14 | BOUNDED | PROVEN |
| 8 | 4 | 16 | BOUNDED | PROVEN |

## Findings

- F-FIFO-026: Audit detected missing process lowering and incorrect SAT diagnostic parsing in planner-generated tooling.
- F-FIFO-027: Corrected positive and negative activation controls passed in all 36 final problems.
- F-FIFO-028: Corrected observable-only results reproduced the 3/18 proof completion rate.
- F-FIFO-029: Strengthened state invariants increased completion to 18/18.
- F-FIFO-030: Strengthened proofs completed with one-step temporal induction.
- F-FIFO-031: No FIFO RTL changes were required for the corrected pilot.

## Limitations

Binary-valued, reset-aware, cycle-level formal model; output data compared only when valid. State invariants are proved, not assumed. Results cover fixed parameters, not arbitrary generics. Both sides depend on GHDL translation; no independent proof of that translation, no XC7 mapped-netlist equivalence and no physical timing claim. Solver timings are single-run measurements. Prior invalidated runs must never be counted as successful proofs. Expert review remains outstanding.

## Evidence retention

The final archive preserves solver logs, commands, harnesses, intermediate netlists, counterexample traces and source metadata from all six runs. Compiled object and GHDL work-library files are excluded. The existing initial archive remains untouched. The manifest lists SHA-256 hashes of original evidence bytes; Git text normalization can change checkout bytes. Raw build directories and transfer ZIPs remain local.
