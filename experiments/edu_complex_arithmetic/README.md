# Educational complex arithmetic: `edu_complex_add`, `edu_complex_mul`

These are two standalone VHDL-2008 exercises: complex addition and complex
multiplication with IEEE-754 binary32 real and imaginary parts. They use IEEE
standard packages only (`ieee.float_pkg`, `ieee.fixed_float_types`), with no
vendor IP and no application-specific integration.

| Path | Content |
|---|---|
| `rtl/edu_complex_add.vhd` | Entity `edu_complex_add` |
| `rtl/edu_complex_mul.vhd` | Entity `edu_complex_mul` |
| `reference/complex_ref.py` | Independent reference and vector generator (standard library only) |
| `reference/crosscheck_numpy.py` | Second, NumPy-based check of the reference |
| `tb/tb_edu_complex_add.vhd`, `tb/tb_edu_complex_mul.vhd` | Self-checking testbenches driven by vector files |
| `tb/run_ghdl.sh` | Vector generation, simulation of every vector set, optional Yosys check |

## Mathematical behaviour

| Exercise | Real part | Imaginary part | Rounded operations |
|---|---|---|---|
| add | `a_re + b_re` | `a_im + b_im` | 2, one per part |
| mul | `(a_re*b_re) - (a_im*b_im)` | `(a_re*b_im) + (a_im*b_re)` | 6: four products, then one subtraction and one addition |

The evaluation order is part of the contract. The multiplier uses neither a
fused multiply-add nor the three-multiplier (Gauss) form, because either would
round differently.

## Numerical decisions

| Item | Decision |
|---|---|
| Representation | IEEE-754 binary32 for each part. Ports carry raw bit patterns as `std_logic_vector(31 downto 0)` (bit 31 sign, 30–23 exponent, 22–0 fraction). |
| Rounding | Round to nearest, ties to even, on every operation. This is set explicitly in each `float_pkg` call (`round_style => round_nearest`, `guard => 3`), not left to package defaults. |
| Subnormals | Supported on input and output (`denormalize => true`), with gradual underflow. No flush-to-zero. |
| Overflow | A result beyond the largest finite value becomes ±Inf. |
| Invalid operations | `Inf - Inf` and `0 * Inf` give NaN, and any NaN input gives NaN. NaN sign and payload are unspecified, so tests check only that the result is a NaN. |
| Signed zero | IEEE rules: `x + (-x) = +0`, `(-0) + (-0) = -0`, product sign is the XOR of the operand signs, and an underflow to zero keeps its sign. Tested bit-exactly. |
| Exception flags | Not provided. Overflow, underflow and inexact cannot be observed at the interface. |
| Precision, add | Each part is correctly rounded: relative error ≤ u = 2⁻²⁴, and exact when the sum is representable. |
| Precision, mul | Each part's absolute error ≤ (2u + u²)·(\|x₁\| + \|x₂\|), where x₁, x₂ are the two exact products that part combines. This assumes no intermediate overflow or underflow. The relative error of a part is **unbounded** under cancellation (when x₁ ≈ x₂). |
| Overflow inside mul | If one product overflows, the result can be ±Inf, and if two do, the result can be NaN (`Inf - Inf`). This holds even when the exact result is finite; for example, `MAX·MAX − MAX·MAX` gives NaN. The `edge` vectors include such cases. |
| Pass criterion | Results must match bit for bit (any NaN counts as a match where NaN is expected). There is no tolerance: with a fixed operation order, IEEE rounding is deterministic. |

These choices apply to this exercise only. They are consistent with
`PROJECT_DECISIONS` item 7 (binary32, no fixed-point substitute). **They do not
settle `exp001` gate G3** (tolerance and summation-order policy for the filter),
which remains with the planner.

## Interface and timing

Both entities have identical ports.

| Port | Dir | Meaning |
|---|---|---|
| `clk` | in | Rising-edge clock |
| `rst` | in | Synchronous, active high. Clears `out_valid` only, and takes priority over `in_valid`. |
| `in_valid` | in | Operands are valid at this rising edge |
| `a_re`, `a_im`, `b_re`, `b_im` | in | binary32 bit patterns |
| `out_valid` | out | `y_re`/`y_im` hold the result for the operands sampled at the previous edge |
| `y_re`, `y_im` | out | binary32 bit patterns |

- **Latency is 1 cycle, and a new operand set can be accepted every cycle.**
  There is no backpressure.
- The arithmetic between the input pins and the output register is
  combinational. That is acceptable for an exercise with no performance
  requirement, but the path is long (see limitations).
- Data registers are not reset, and they hold their value while
  `in_valid = '0'`. Outputs are meaningful only when `out_valid = '1'`.

## Reference model

`reference/complex_ref.py` decodes each binary32 operand to an exact rational
(`fractions.Fraction`). It computes each operation exactly and rounds once to
binary32 (ties to even, with subnormals and overflow). It shares no code or
algorithm with the RTL.

It writes one vector file per exercise and category, with 8124 vectors in total
at the defaults (seed 20261126, `--random-count 2000`):

| Category | Count per exercise | Content |
|---|---:|---|
| `directed` | 16 | Ordinary values with known results, the unit `i`, conjugate pairs, rounding ties, inexact operands such as 0.1 |
| `edge` | 20 | Signed zeros, subnormals, subnormal-to-normal transitions, underflow to ±0, overflow to Inf, product overflow giving NaN |
| `special` | 26 | ±Inf, quiet and signalling NaNs, negative NaN, `Inf − Inf`, `0 · Inf` |
| `random_normal` | 2000 | Seeded random normal operands. One vector in eight targets cancellation in the real part, one in the imaginary part, and one in the products of the multiplier's real part. Exponent ranges are ±100 for add and ±60 for mul (so products cannot overflow). |
| `random_bits` | 2000 | Seeded arbitrary bit patterns, with extra subnormals and zeros. NaN and Inf appear at their natural rate. |

Line format: `a_re a_im b_re b_im y_re y_im nan_re nan_im`, as hex words plus
0/1 flags. Generation is deterministic.

## Testbench

- Inputs change on the falling edge. Outputs are checked 1 ns after the next
  rising edge, with vectors applied back to back.
- Mismatches are counted rather than stopping the run. The first 20 are printed
  with all four operands; any mismatch ends the run with `severity failure`.
- The final interface checks cover:
  - reset beating `in_valid`;
  - outputs holding steady for 3 cycles with `in_valid = '0'` and changed operands;
  - reset clearing `out_valid`;
  - recovery after reset is released.
- Each category runs separately, so a deviation in one class (for example
  signed zero or NaN handling in `float_pkg`) does not hide the results of the
  ordinary finite cases.

## Running

From the experiment directory, inside the project container (GHDL 4.1.0 and
Yosys 0.33 per M1):

```sh
bash tb/run_ghdl.sh           # everything goes into build/; exit 0 only if all pass
python3 reference/crosscheck_numpy.py   # optional, needs NumPy (present in the container)
```

The script does the following:
1. Runs the reference self-test and generates the vectors.
2. Analyses and elaborates both testbenches.
3. Runs all 10 vector sets, passing `-gG_VECTOR_FILE=...` at run time, as
   `scripts/verify_edu_fifo.sh` does.
4. If Yosys is present, runs
   `ghdl --synth --std=08 --no-formal --out=verilog` followed by
   `hierarchy -check; proc; opt; memory; opt; check -assert; stat` for each
   entity. Otherwise it reports BLOCKED.

A single set can be run by hand inside `build/`, for example
`ghdl -r --std=08 tb_edu_complex_mul -gG_VECTOR_FILE=vectors/mul_edge.txt`. Do
not pass `--assert-level=error` if you want the full mismatch count.

## Test status

Validated on 2026-11-26 in the project container (run `20261126T103335Z`); see
[VALIDATION.md](VALIDATION.md) and [evidence](evidence/run_20261126T103335Z/).

| Test | Status |
|---|---|
| Reference self-test (21 assertions) | PASS |
| Reference vs NumPy float32, 8124 vectors | PASS, 0 mismatches (also on x86_64 during authoring) |
| GHDL simulation, 10 vector sets, 24,462 checks | PASS, 0 errors |
| GHDL synthesis and Yosys structural check | PASS, 0 problems; 8 (add) and 24 (mul) tri-state warnings, CA-OBS-001 |
| Post-synthesis equivalence, FPGA mapping, timing | NOT_RUN |

`tb/run_ghdl.sh` over-reports the warning count by one (CA-DEFECT-001).

## Assumptions

- `ieee.fixed_float_types` and `ieee.float_pkg` from GHDL 4.1.0 are used as provided; their
  results matched the independent reference on every tested vector.
- `-g` overrides of the top-level string generic work at `ghdl -r` time (confirmed).

## Limitations

- Full binary32 operators are combinational in front of a single register stage; no
  pipelining, no DSP mapping, size and depth not optimised.
- No exception flags, no configurable rounding, binary32 only.
- Simulation results cover the RTL only; the generated netlist has not been checked
  numerically.

## Outstanding validation

1. Explain the tri-state warnings from the generated Verilog (CA-OBS-001).
2. Post-synthesis simulation or formal equivalence against the same vectors.
3. Technology mapping (for example Series 7) if these blocks are reused.
4. Pipelining, overflow/scaling and accumulation error belong to the exp001 gates
   G3 and G5, not to this exercise.
