# edu_fifo: educational synchronous FIFO

A standalone first-word-fall-through FIFO implemented to `SPECIFICATION.md`, with a
testbench that follows `TEST_CONTRACT.md`. It uses VHDL-2008 and IEEE/std packages
only, with no vendor IP and no external dependencies.

| Path | Content |
|---|---|
| `rtl/edu_fifo.vhd` | Entity `edu_fifo` (`G_WIDTH`, `G_DEPTH`) |
| `tb/tb_edu_fifo.vhd` | Entity `tb_edu_fifo` (`G_WIDTH`, `G_DEPTH`, `G_VECTOR_FILE`), self-checking, driven by vectors |

## Architecture rationale

| Element | Choice | Why |
|---|---|---|
| Storage | `mem(0 to G_DEPTH-1)`, **not reset** | Push is already gated off during reset, and stale words are unreachable once `count = 0`, so a storage reset would add logic for no benefit. |
| Pointers | `rd_ptr`, `wr_ptr` in `0..G_DEPTH-1`, wrap by compare-to-`G_DEPTH-1` then clear | Works for non-power-of-two depths and for depth 1, where the pointer is a constant 0. Natural binary overflow would work only for powers of two. |
| Occupancy | `count` in `0..G_DEPTH` | Full and empty are told apart directly, with no extra wrap bit or "last op" flag. A simultaneous push and pop leaves `count` unchanged. |
| Head | `rd_data <= mem(rd_ptr)` (combinational) | Gives first-word fall-through. This does not promise BRAM inference. |
| Reset | Synchronous. Clears `rd_ptr`, `wr_ptr` and `count`. `wr_ready`/`rd_valid` are gated combinationally by `rst`. | The gating is independent of state, as the spec requires. State changes only at a rising edge. |

Depth 1, full, with a simultaneous read and write: `rd_ptr = wr_ptr = 0`. Before the
edge, `rd_data` shows the old word. At the edge, `mem(0)` takes the new word and
`count` stays at 1.

## Interface timing

All signals are evaluated before the rising edge of `clk`.

| Condition (`rst = 0`) | Output / effect |
|---|---|
| `count > 0` | `rd_valid = 1`, `rd_data` = oldest word |
| `count < G_DEPTH` or (`rd_valid` and `rd_ready`) | `wr_ready = 1` |
| `rd_valid and rd_ready` | pop at the edge |
| `wr_valid and wr_ready` | push at the edge (visible from the next cycle; no empty bypass) |
| `rd_valid = 1`, `rd_ready = 0` | `rd_data` stays stable |
| `rst = 1` | `wr_ready = rd_valid = 0` straight away; queue is empty after the next rising edge |

`rd_data` is unspecified while `rd_valid = 0` and is never checked in that state.

## Testbench

- Reads `G_VECTOR_FILE` with `std.textio`, one cycle per line:
  `rst wr_valid wr_data rd_ready exp_wr_ready exp_rd_valid exp_rd_data`.
  Data fields are read as `bit_vector` (`G_WIDTH` binary digits), never as integers.
- For each line it:
  1. drives the inputs with `clk = 0` and waits 1 ns;
  2. checks `wr_ready` and `rd_valid`, and checks `rd_data` only when `exp_rd_valid = 1`;
  3. raises `clk`, waits 1 ns, lowers `clk` and waits 1 ns.
- A mismatch causes an `assert ... severity failure` that reports the cycle and the
  configuration.
- All expected values come from the planner's `golden.py`. The testbench contains no
  FIFO model.
- **Directed midcycle reset check** (runs after the vectors):
  1. Reset, push A (and push B if `G_DEPTH > 1`), and check the head is A.
  2. Raise `rst` while `clk` stays low. Expect `rd_valid = wr_ready = 0`.
  3. Lower `rst` with no edge. Expect `rd_valid = 1`, the head still A, and
     `wr_ready` matching the fill level. This passes for a synchronous reset and
     would fail for an asynchronous one.
  4. As a contrast, apply a reset sampled at an edge and check the FIFO is empty.
- The run ends with `std.env.finish`.

## Commands

From the repository root run `bash scripts/verify_edu_fifo.sh`.
The runner generates independent vectors, checks all six configurations,
and retains logs in a fresh project-local build directory.

## Assumptions

- `golden.py` sits in the exercise root, one level above `build/`.
- Vector paths are relative to the simulation working directory (`build/`).
- Initial values (`:= 0`) on pointers and count are simulation conveniences only.
  Correct behaviour relies on the first vector asserting reset.
- The producer holds `wr_valid`/`wr_data` until accepted (spec). The testbench
  simply replays the vectors.

## Verification status

**GHDL and Yosys were not available in the authoring environment. None of the
VHDL has been analysed, elaborated, simulated or synthesised.**

What was executed:

- `golden.py --output` in a scratch directory outside the project. All six
  configurations printed `PASS` (2025 to 2074 cycles each).
- A throwaway Python re-model of this RTL's *algorithm* (pointers, count,
  non-reset storage, reset gating), compared against those vectors. All six
  configurations matched.

This raises confidence in the design logic only. It is not evidence that the VHDL
compiles or simulates correctly. The scratch model is not delivered.
