#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1 GIT_OPTIONAL_LOCKS=0
[[ "$(pwd -P)" == "$(git rev-parse --show-toplevel)" && "$(basename "$PWD")" == fpga_ai ]] || { echo 'Run from fpga_ai root' >&2; exit 1; }
base=experiments/edu_fifo
for p in experiments "$base" "$base/rtl" "$base/tb" "$base/build" "$base/golden.py" "$base/rtl/edu_fifo.vhd" "$base/tb/tb_edu_fifo.vhd" scripts scripts/verify_protected_digests.py; do
    [[ ! -L "$p" ]] || { echo "Symlink refused: $p" >&2; exit 1; }
done
python3 scripts/verify_protected_digests.py
mkdir -p "$base/build"
run=$(mktemp -d "$base/build/run.XXXXXXXX")
echo "Results: $run"
# Preserve the runner's exit status even when tee succeeds.
rc=0
docker run --rm --platform linux/arm64 -v "$PWD:/workspace" -w "/workspace/$run" fpga_ai-toolchain:m1-arm64 bash -euo pipefail -c '
export PYTHONDONTWRITEBYTECODE=1
mkdir -p tmp
export TMPDIR="$PWD/tmp"
python3 ../../golden.py --output vectors
ghdl -a --std=08 ../../rtl/edu_fifo.vhd ../../tb/tb_edu_fifo.vhd
ghdl -e --std=08 tb_edu_fifo
for cfg in "1 1" "8 1" "8 3" "8 4" "16 5" "32 8"; do
    read -r w d <<< "$cfg"
    tag="w${w}_d${d}"
    echo "SIM $tag"
    ghdl -r --std=08 tb_edu_fifo -gG_WIDTH="$w" -gG_DEPTH="$d" -gG_VECTOR_FILE="vectors/$tag.txt" --assert-level=error 2>&1 | tee "sim_$tag.log"
    echo "SYNTH $tag"
    ghdl --synth --std=08 --no-formal --out=verilog -gG_WIDTH="$w" -gG_DEPTH="$d" edu_fifo > "edu_fifo_$tag.v" 2> "ghdl_synth_$tag.log" || { cat "ghdl_synth_$tag.log"; exit 1; }
    yosys -p "read_verilog edu_fifo_$tag.v; hierarchy -check -top edu_fifo; proc; opt; memory; opt; check -assert; stat" > "yosys_$tag.log" 2>&1 || { cat "yosys_$tag.log"; exit 1; }
    sed -n "/Found and reported/p; /=== edu_fifo ===/,/End of script/p" "yosys_$tag.log"
    echo "PASS: simulation and structural synthesis $tag"
done
echo "PASS: all six configurations"
' 2>&1 | tee "$run/verification.log" || rc=$?
python3 scripts/verify_protected_digests.py
exit "$rc"
