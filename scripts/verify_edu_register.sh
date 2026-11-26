#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
[[ "$(pwd -P)" == "$(git rev-parse --show-toplevel)" && "$(basename "$PWD")" == fpga_ai ]] || { echo 'Run from fpga_ai root' >&2; exit 1; }
base=experiments/edu_register
for p in experiments "$base" "$base/rtl" "$base/tb" "$base/build"; do
    [[ ! -L "$p" ]] || { echo "Symlink refused: $p" >&2; exit 1; }
done
[[ ! -e "$base/build" ]] || { echo 'build already exists; move it within the project before rerunning' >&2; exit 1; }
python3 scripts/verify_protected_digests.py
mkdir "$base/build"
docker run --rm --platform linux/arm64 -v "$PWD:/workspace" -w /workspace/experiments/edu_register/build fpga_ai-toolchain:m1-arm64 bash -euo pipefail -c '
python3 ../golden.py
ghdl -a --std=08 ../rtl/edu_register.vhd ../tb/tb_edu_register.vhd
ghdl -e --std=08 tb_edu_register
ghdl -r --std=08 tb_edu_register --assert-level=error
ghdl --synth --std=08 --out=verilog --no-formal edu_register > edu_register.v
yosys -p "read_verilog edu_register.v; hierarchy -check -top edu_register; proc; opt; check -assert; stat"
' 2>&1 | tee "$base/build/verification.log"
python3 scripts/verify_protected_digests.py
