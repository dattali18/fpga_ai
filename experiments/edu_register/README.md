# Educational register exercise

8-bit register with synchronous, active-high reset (priority over enable) and
clock enable, per `SPECIFICATION.md`. VHDL-2008, IEEE standard packages only.

| Path | Content |
|---|---|
| `rtl/edu_register.vhd` | Entity `edu_register`: `clk`, `rst`, `en` (`std_logic`); `d`, `q` (`std_logic_vector(7 downto 0)`) |
| `tb/tb_edu_register.vhd` | Self-checking testbench `tb_edu_register` |

`SPECIFICATION.md` and `golden.py` are not modified and not included here.

## Behaviour (rising edge of `clk`)

| `rst` | `en` | next `q` |
|---|---|---|
| 1 | – | `x"00"` |
| 0 | 1 | `d` |
| 0 | 0 | `q` (hold) |

This is the same priority as `golden.py` `next_state`. `q` has no defined value
before the first reset edge (simulates as `'U'`).

## Testbench coverage

Inputs change on the falling edge; `q` is sampled 1 ns after each rising edge
and compared against a literal expected value and a model mirroring
`golden.py`. Any mismatch is an `error` assertion; a non-zero error count
triggers a final `failure` assertion, otherwise `PASS: all N checks passed`
is reported and `std.env.finish` ends the run.

| Test | What is checked |
|---|---|
| T1 Reset | `rst=1, en=0` clears `q` from power-up |
| T2 Capture | single enabled write; `q` stable until next edge |
| T3 Hold | `en=0`, `d` changing each cycle; `q` unchanged |
| T4 Consecutive writes | `en=1` on 6 back-to-back cycles, new `d` each cycle |
| T5 Reset priority | `rst=1, en=1` with `d=5A` and `d=FF`; `q=00` |
| T6 Reset from non-zero | load `E7`, then `rst=1, en=0` |
| T7 After reset | hold zero, then capture after reset release |

## Running with GHDL (project-local build directory)

All GHDL artefacts (`work-obj08.cf`, object files, executable, waveform) go
into `build/`, keeping the source tree clean. From the exercise directory:

```sh
mkdir -p build
cd build
ghdl -a --std=08 ../rtl/edu_register.vhd ../tb/tb_edu_register.vhd   # analysis
ghdl -e --std=08 tb_edu_register                                      # elaboration
ghdl -r --std=08 tb_edu_register --assert-level=error                 # simulation
cd ..
```

Notes:

- Analysis order matters: the RTL is analysed before the testbench.
- `--assert-level=error` makes GHDL stop with a non-zero exit code on the
  first `error` assertion; omit it to see all mismatches followed by the
  summary `failure`.
- Optional waveform: append `--wave=tb_edu_register.ghw` to the `-r` command
  (run inside `build/`) and open it with GTKWave.
- Clean up with `rm -rf build`.
- Expected success output ends with
  `tb_edu_register.vhd:...: (report note): PASS: all 21 checks passed`.
- Synthesis and timing are out of scope here (the specification requires
  structural synthesis to be reported separately and forbids physical timing
  claims without device mapping).

## Verification status

The VHDL has **not** been analysed, elaborated or simulated: GHDL was not
available in the authoring environment and installation was not permitted.
Only `golden.py`'s own self-check was run (unmodified), and it printed
`PASS: reference self-check`.
