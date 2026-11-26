#!/usr/bin/env bash
# run_ghdl.sh - generate reference vectors, simulate both exercises with GHDL,
# then (if Yosys is present) run a GHDL-to-Verilog + Yosys structural check.
# Run from the experiment directory:   bash tb/run_ghdl.sh
# All generated files go to build/; sources are not modified.
# Exit status: 0 only if every simulation passes and every requested
# synthesis step succeeds.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build"
mkdir -p "$BUILD"
cd "$BUILD"

CATS="directed edge special random_normal random_bits"
fail=0
summary=()

echo "== reference: selftest and vectors"
python3 "$ROOT/reference/complex_ref.py" --output vectors | tee reference.log || exit 1

echo "== GHDL analysis and elaboration"
ghdl -a --std=08 \
  "$ROOT/rtl/edu_complex_add.vhd" "$ROOT/rtl/edu_complex_mul.vhd" \
  "$ROOT/tb/tb_edu_complex_add.vhd" "$ROOT/tb/tb_edu_complex_mul.vhd" || exit 1
ghdl -e --std=08 tb_edu_complex_add || exit 1
ghdl -e --std=08 tb_edu_complex_mul || exit 1

echo "== simulation"
for op in add mul; do
  for cat in $CATS; do
    log="sim_${op}_${cat}.log"
    if ghdl -r --std=08 "tb_edu_complex_$op" -gG_VECTOR_FILE="vectors/${op}_${cat}.txt" \
         > "$log" 2>&1 && grep -q "PASS: vectors/${op}_${cat}.txt" "$log"; then
      res=PASS
    else
      res=FAIL; fail=1
    fi
    summary+=("sim  $op  $cat  $res  $(grep -o '[0-9]* vectors, [0-9]* checks, [0-9]* errors' "$log" | tail -1)")
  done
done

echo "== structural synthesis"
if command -v yosys >/dev/null 2>&1; then
  for op in add mul; do
    top="edu_complex_$op"
    if ghdl --synth --std=08 --no-formal --out=verilog "$top" > "$top.v" 2> "ghdl_synth_$op.log" &&
       yosys -p "read_verilog $top.v; hierarchy -check -top $top; proc; opt; memory; opt; check -assert; stat" \
         > "yosys_$op.log" 2>&1; then
      res=PASS
    else
      res=FAIL; fail=1
    fi
    summary+=("synth $op  -  $res  $(grep -c -i 'warning' "yosys_$op.log" 2>/dev/null) yosys warnings")
  done
else
  summary+=("synth -  -  BLOCKED  yosys not found")
fi

echo "== summary (logs in $BUILD)"
printf '%s\n' "${summary[@]}"
exit $fail
