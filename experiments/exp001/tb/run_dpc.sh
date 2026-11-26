#!/usr/bin/env bash
# run_dpc.sh - EXP001 runner: DPC RTL verification in one command (M2b, extended in M2c).
#
# Usage (from anywhere):   bash experiments/exp001/tb/run_dpc.sh
#
# Runs on the host (bash 3.2 compatible: no mapfile, no associative arrays, no
# ${x,,}); every tool step runs in the fpga_ai-toolchain:m1-arm64 container.
# Steps (M2B_PROMPT.md section 6, M2C_PROMPT.md sections 4-5):
#   1 protected files + oracle manifest       6 negative controls (must fail)
#   2 reference vectors (build/, not committed) 7 synthesis of the 6 fixtures
#   3 GHDL analysis and elaboration           8 protected files + oracle manifest
#   4 simulation: stress, timing, timing repeat 9 evidence; MANIFEST.sha256 last
#   5 dpc_ref.py --check on every dump; CYCLES lines against the closed-form
#     formula (M2c, D-076): latency = 2*N + ceil(N/L)*(P+L-1), period = latency
#     (+P when the next transaction reloads the pulse, t=4), last period NA
# Exit status 0 only if every check passed.

set -u

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$REPO" || exit 2

IMAGE="${IMAGE:-fpga_ai-toolchain:m1-arm64}"
EXP="experiments/exp001"
RUN_ID="m2c_$(date -u +%Y%m%dT%H%M%SZ)"
BUILD="$EXP/build/$RUN_ID"
EVID="$EXP/evidence/$RUN_ID"
# N_RG:P:G_LANES:synth (1 = synthesize this fixture)
FIXTURES="1:1:1:1 5:8:1:1 8:3:1:1 8:8:1:1 64:16:1:1 256:64:1:1 \
64:16:3:1 64:16:4:1 256:64:8:1 \
64:16:64:0 \
8:3:8:0 5:8:2:0 8:8:3:0"
RELOAD_TX=4      # transaction 5 reloads the pulse (spec G1 table)
STRESS_PCT=30
SEED=20261126
ORACLE="$EXP/reference/ORACLE_MANIFEST.sha256"

mkdir -p "$BUILD/vectors" "$BUILD/sim" "$BUILD/syn" "$BUILD/neg" "$EVID" || exit 2

# Run a command string in the toolchain container, repository mounted at /workspace.
tc() {
  docker run --rm --platform linux/arm64 -v "$REPO:/workspace" -w /workspace \
    "$IMAGE" bash -c "$1"
}

FAIL=0
SUMMARY="$BUILD/summary.txt"
: > "$SUMMARY"
row() {               # row <status> <text...>
  printf '%-5s %s\n' "$1" "$2" | tee -a "$SUMMARY"
  if [ "$1" != "PASS" ]; then FAIL=1; fi
}

echo "== run $RUN_ID"

# --------------------------------------------------------------- 1 protected
if tc "python3 scripts/verify_protected_digests.py --extra-manifest $ORACLE" \
     > "$BUILD/protected_before.txt" 2>&1; then
  row PASS "protected+oracle before: $(tail -1 "$BUILD/protected_before.txt")"
else
  row FAIL "protected+oracle before (see protected_before.txt)"
fi
shasum -a 256 "$ORACLE" > "$BUILD/oracle_manifest_sha256_before.txt"

# --------------------------------------------------------------- 2 vectors
if tc "python3 $EXP/reference/dpc_ref.py --output $BUILD/vectors" \
     > "$BUILD/reference.log" 2>&1; then
  row PASS "reference vectors: $(grep -c ': 7 transactions' "$BUILD/reference.log") files"
else
  row FAIL "reference vectors (see reference.log)"
fi

# --------------------------------------------------------------- 3 GHDL
if tc "cd $BUILD && ghdl -a --std=08 /workspace/$EXP/rtl/dpc_pkg.vhd /workspace/$EXP/rtl/dpc.vhd /workspace/$EXP/tb/tb_dpc.vhd && ghdl -e --std=08 tb_dpc" \
     > "$BUILD/ghdl_analyse.log" 2>&1; then
  row PASS "ghdl analysis + elaboration"
else
  row FAIL "ghdl analysis + elaboration (see ghdl_analyse.log)"
  cat "$BUILD/ghdl_analyse.log"
fi

# --------------------------------------------------------------- 4+5 simulate, check
# Modes: stress (G_STALL_PCT=30), timing (0), timing2 (0, determinism repeat, B6).
sim_one() {           # sim_one <n> <p> <l> <mode> <pct>
  n=$1; p=$2; l=$3; mode=$4; pct=$5
  tag="n${n}_p${p}_l${l}_${mode}"
  vec="vectors/dpc_n${n}_p${p}.txt"
  log="$BUILD/sim/sim_$tag.log"
  if tc "cd $BUILD && ghdl -r --std=08 tb_dpc -gG_N_RG=$n -gG_P=$p -gG_LANES=$l \
          -gG_VECTOR_FILE=$vec -gG_DUMP_FILE=sim/dump_$tag.txt \
          -gG_STALL_PCT=$pct -gG_SEED=$SEED" > "$log" 2>&1 \
     && grep -q "^PASS: $vec" "$log"; then
    row PASS "sim   $tag: $(grep -o '[0-9]* transactions, [0-9]* outputs, [0-9]* checks, [0-9]* errors' "$log")"
  else
    row FAIL "sim   $tag: $(grep -o '[0-9]* transactions, [0-9]* outputs, [0-9]* checks, [0-9]* errors' "$log" | tail -1) (see $log)"
  fi
  clog="$BUILD/sim/check_$tag.log"
  if tc "python3 $EXP/reference/dpc_ref.py --check $BUILD/$vec $BUILD/sim/dump_$tag.txt" \
       > "$clog" 2>&1; then
    row PASS "check $tag: $(tail -1 "$clog")"
  else
    row FAIL "check $tag: $(tail -1 "$clog")"
  fi
}

# Closed-form cycle formula (D-076); writes the expected CYCLES lines.
expected_cycles() {   # expected_cycles <n> <p> <l> <ntx>
  n=$1; p=$2; l=$3; ntx=$4
  g=$(( (n + l - 1) / l ))
  lat=$(( 2 * n + g * (p + l - 1) ))
  t=0
  while [ $t -lt $ntx ]; do
    if [ $t -eq $((ntx - 1)) ]; then per=NA
    elif [ $t -eq $RELOAD_TX ]; then per=$((lat + p))
    else per=$lat; fi
    echo "CYCLES t=$t latency=$lat period=$per"
    t=$((t + 1))
  done
}

for f in $FIXTURES; do
  IFS=: read -r n p l syn <<EOF_FIX
$f
EOF_FIX
  fx="n${n}_p${p}_l${l}"
  sim_one "$n" "$p" "$l" stress "$STRESS_PCT"
  sim_one "$n" "$p" "$l" timing 0
  sim_one "$n" "$p" "$l" timing2 0
  grep '^CYCLES' "$BUILD/sim/sim_${fx}_timing.log"  > "$BUILD/sim/cycles_${fx}.txt"
  grep '^CYCLES' "$BUILD/sim/sim_${fx}_timing2.log" > "$BUILD/sim/cycles_${fx}_repeat.txt"
  if [ -s "$BUILD/sim/cycles_${fx}.txt" ] &&
     cmp -s "$BUILD/sim/cycles_${fx}.txt" "$BUILD/sim/cycles_${fx}_repeat.txt"; then
    row PASS "cycles $fx: identical in two timing runs ($(wc -l < "$BUILD/sim/cycles_${fx}.txt" | tr -d ' ') lines)"
  else
    row FAIL "cycles $fx: missing or different between timing runs"
  fi
  ntx=$(wc -l < "$BUILD/sim/cycles_${fx}.txt" | tr -d ' ')
  expected_cycles "$n" "$p" "$l" "$ntx" > "$BUILD/sim/cycles_${fx}_formula.txt"
  if [ "$ntx" = "7" ] && cmp -s "$BUILD/sim/cycles_${fx}.txt" "$BUILD/sim/cycles_${fx}_formula.txt"; then
    row PASS "formula $fx: measured = 2N+ceil(N/L)(P+L-1) = $(sed -n 1p "$BUILD/sim/cycles_${fx}_formula.txt" | sed 's/.*latency=\([0-9]*\).*/\1/')"
  else
    row FAIL "formula $fx: measured cycles differ from the closed-form formula"
  fi
done

# --------------------------------------------------------------- 6 negative controls
# NC1: flip one bit of one output in a copy of a dump; --check must fail.
cp "$BUILD/sim/dump_n8_p3_l1_timing.txt" "$BUILD/neg/dump_bitflip.txt"
tc "python3 -I -c '
import sys
p = sys.argv[1]
lines = open(p).read().splitlines()
tag, re, im = lines[3].split()
lines[3] = \"%s %08X %s\" % (tag, int(re, 16) ^ 1, im)
open(p, \"w\").write(\"\\n\".join(lines) + \"\\n\")
' $BUILD/neg/dump_bitflip.txt" > "$BUILD/neg/nc1_prepare.log" 2>&1
if cmp -s "$BUILD/sim/dump_n8_p3_l1_timing.txt" "$BUILD/neg/dump_bitflip.txt"; then
  row FAIL "NC1 bit flip: dump copy not modified"
elif tc "python3 $EXP/reference/dpc_ref.py --check $BUILD/vectors/dpc_n8_p3.txt $BUILD/neg/dump_bitflip.txt" \
     > "$BUILD/neg/nc1_check.log" 2>&1; then
  row FAIL "NC1 bit flip: --check returned 0 (control did not fail)"
else
  row PASS "NC1 bit flip: --check failed as intended ($(tail -1 "$BUILD/neg/nc1_check.log"))"
fi

# NC2: change one Y word in a copy of a vector file; the testbench must FAIL.
tc "python3 -I -c '
import sys
src, dst = sys.argv[1], sys.argv[2]
out, done = [], False
for line in open(src).read().splitlines():
    if not done and line.startswith(\"Y \"):
        tag, re, im = line.split()
        line = \"Y %08X %s\" % (int(re, 16) ^ 1, im)
        done = True
    out.append(line)
open(dst, \"w\").write(\"\\n\".join(out) + \"\\n\")
' $BUILD/vectors/dpc_n8_p3.txt $BUILD/neg/dpc_n8_p3_badY.txt" > "$BUILD/neg/nc2_prepare.log" 2>&1
if cmp -s "$BUILD/vectors/dpc_n8_p3.txt" "$BUILD/neg/dpc_n8_p3_badY.txt"; then
  row FAIL "NC2 bad Y: vector copy not modified"
elif tc "cd $BUILD && ghdl -r --std=08 tb_dpc -gG_N_RG=8 -gG_P=3 \
          -gG_VECTOR_FILE=neg/dpc_n8_p3_badY.txt -gG_DUMP_FILE=neg/dump_badY.txt -gG_STALL_PCT=0" \
     > "$BUILD/neg/nc2_sim.log" 2>&1 || grep -q '^PASS:' "$BUILD/neg/nc2_sim.log"; then
  row FAIL "NC2 bad Y: testbench did not fail"
else
  row PASS "NC2 bad Y: testbench failed as intended ($(grep -o '[0-9]* errors' "$BUILD/neg/nc2_sim.log" | tail -1))"
fi

# NC3 (M2c, lane-specific): corrupt the expected value of the LAST output of the
# first block of (8,8), run with L = 3 (L does not divide N_RG: last group has
# lanes 6, 7 active and lane 8 inactive). The testbench must FAIL.
tc "python3 -I -c '
import sys
src, dst = sys.argv[1], sys.argv[2]
lines = open(src).read().splitlines()
ys = [i for i, line in enumerate(lines) if line.startswith(\"Y \")]
i = ys[7]                                  # 8th Y line = y[N_RG-1] of transaction 0
tag, re, im = lines[i].split()
lines[i] = \"Y %s %08X\" % (re, int(im, 16) ^ 1)
open(dst, \"w\").write(\"\\n\".join(lines) + \"\\n\")
' $BUILD/vectors/dpc_n8_p8.txt $BUILD/neg/dpc_n8_p8_badlast.txt" > "$BUILD/neg/nc3_prepare.log" 2>&1
if cmp -s "$BUILD/vectors/dpc_n8_p8.txt" "$BUILD/neg/dpc_n8_p8_badlast.txt"; then
  row FAIL "NC3 bad last output (L=3): vector copy not modified"
elif tc "cd $BUILD && ghdl -r --std=08 tb_dpc -gG_N_RG=8 -gG_P=8 -gG_LANES=3 \
          -gG_VECTOR_FILE=neg/dpc_n8_p8_badlast.txt -gG_DUMP_FILE=neg/dump_badlast.txt -gG_STALL_PCT=0" \
     > "$BUILD/neg/nc3_sim.log" 2>&1 || grep -q '^PASS:' "$BUILD/neg/nc3_sim.log"; then
  row FAIL "NC3 bad last output (L=3): testbench did not fail"
elif grep -q 'n = 7 got' "$BUILD/neg/nc3_sim.log"; then
  row PASS "NC3 bad last output (L=3): testbench failed as intended at n = 7 ($(grep -o '[0-9]* errors' "$BUILD/neg/nc3_sim.log" | tail -1))"
else
  row FAIL "NC3 bad last output (L=3): failed, but not at the corrupted output n = 7"
fi

# --------------------------------------------------------------- 7 synthesis
# Acceptance flow (CLAUDE.md): proc; opt; memory; opt; check -assert; stat.
# Count-only flow: memory -nomap; opt; memory_unpack; stat (memory objects and
# bits, D-070). memory_unpack is needed because stat counts only unpacked
# memories; packed $mem_v2 cells report "Number of memories: 0" (DPC-DEFECT-001).
SYN_CSV="$BUILD/syn/synthesis_summary.csv"
echo "n_rg,p,lanes,status,problems,cells,mul,memories,memory_bits,warnings,tristate_warnings" > "$SYN_CSV"
for f in $FIXTURES; do
  IFS=: read -r n p l syn <<EOF_FIX
$f
EOF_FIX
  [ "$syn" = "1" ] || continue
  tag="n${n}_p${p}_l${l}"
  if tc "cd $BUILD && ghdl --synth --std=08 --no-formal -gG_N_RG=$n -gG_P=$p -gG_LANES=$l --out=verilog dpc > syn/dpc_$tag.v 2> syn/ghdl_synth_$tag.log && \
         yosys -p 'read_verilog syn/dpc_$tag.v; hierarchy -check -top dpc; proc; opt; memory; opt; check -assert; stat' > syn/yosys_$tag.log 2>&1 && \
         yosys -p 'read_verilog syn/dpc_$tag.v; hierarchy -check -top dpc; proc; opt; memory -nomap; opt; memory_unpack; stat' > syn/yosys_count_$tag.log 2>&1"; then
    ylog="$BUILD/syn/yosys_$tag.log"; clog="$BUILD/syn/yosys_count_$tag.log"
    problems=$(grep -o 'Found and reported [0-9]* problems' "$ylog" | tail -1 | grep -o '[0-9]*')
    cells=$(grep 'Number of cells:' "$ylog" | tail -1 | awk '{print $NF}')
    muls=$(grep -E '^ +\$mul ' "$ylog" | tail -1 | awk '{print $NF}')
    mems=$(grep 'Number of memories:' "$clog" | tail -1 | awk '{print $NF}')
    membits=$(grep 'Number of memory bits:' "$clog" | tail -1 | awk '{print $NF}')
    warns=$(grep -c '^Warning:' "$ylog")
    tri=$(grep '^Warning:' "$ylog" | grep -c -i 'tri-state')
    echo "$n,$p,$l,PASS,${problems:-NA},${cells:-NA},${muls:-0},${mems:-0},${membits:-0},$warns,$tri" >> "$SYN_CSV"
    # Positive control for the memory count (DPC-DEFECT-001): the RTL has four
    # memories (sample re/im, pulse re/im); a count of 0 means the metric is broken.
    if [ "${mems:-0}" = "0" ] || [ "${membits:-0}" = "0" ]; then
      row FAIL "synth $tag: memory count is 0 (metric extraction broken)"
    elif [ "${muls:-0}" != "$((4 * l))" ] || [ "$tri" != "$((32 * l))" ]; then
      row FAIL "synth $tag: \$mul=${muls:-0} (expected $((4 * l))), tri-state $tri (expected $((32 * l)))"
    elif [ "${problems:-x}" = "0" ]; then
      row PASS "synth $tag: problems=0 cells=$cells \$mul=${muls:-0} memories=${mems:-0} bits=${membits:-0} warnings=$warns (tri-state $tri)"
    else
      row FAIL "synth $tag: problems=${problems:-NA}"
    fi
  else
    echo "$n,$p,$l,FAIL,NA,NA,NA,NA,NA,NA,NA" >> "$SYN_CSV"
    row FAIL "synth $tag: tool failure (see syn/ghdl_synth_$tag.log, syn/yosys_$tag.log)"
  fi
done

# --------------------------------------------------------------- 8 protected
if tc "python3 scripts/verify_protected_digests.py --extra-manifest $ORACLE" \
     > "$BUILD/protected_after.txt" 2>&1; then
  row PASS "protected+oracle after: $(tail -1 "$BUILD/protected_after.txt")"
else
  row FAIL "protected+oracle after (see protected_after.txt)"
fi
shasum -a 256 "$ORACLE" > "$BUILD/oracle_manifest_sha256_after.txt"
if cmp -s "$BUILD/oracle_manifest_sha256_before.txt" "$BUILD/oracle_manifest_sha256_after.txt" &&
   grep -q '^1f26c582f6507d2b742d24bc8d658fdc0043fa06be674c5cdc261e94294bb294 ' "$BUILD/oracle_manifest_sha256_after.txt"; then
  row PASS "oracle manifest digest = D-068 value, unchanged"
else
  row FAIL "oracle manifest digest differs from D-068 or changed during the run"
fi

# --------------------------------------------------------------- 9 evidence
{
  echo "run_id: $RUN_ID"
  echo "command: bash experiments/exp001/tb/run_dpc.sh"
  echo "date_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "git_head: $(git rev-parse HEAD)"
  echo "image: $IMAGE ($(docker image inspect --format '{{.Id}}' "$IMAGE" 2>/dev/null))"
  echo "host: $(uname -sm)"
  echo "seed: $SEED  stress_pct: $STRESS_PCT"
  echo "git_status_short:"
  git status --short
} > "$BUILD/provenance.txt"
tc "ghdl --version | head -1; yosys -V; python3 --version" > "$BUILD/tool_versions.txt" 2>&1
shasum -a 256 $EXP/rtl/dpc_pkg.vhd $EXP/rtl/dpc.vhd $EXP/tb/tb_dpc.vhd $EXP/tb/run_dpc.sh \
  > "$BUILD/source_sha256.txt"
shasum -a 256 "$BUILD"/vectors/*.txt | sed "s#$BUILD/##" > "$BUILD/vector_sha256.txt"

cp "$BUILD"/protected_before.txt "$BUILD"/protected_after.txt \
   "$BUILD"/oracle_manifest_sha256_before.txt "$BUILD"/oracle_manifest_sha256_after.txt \
   "$BUILD"/reference.log "$BUILD"/ghdl_analyse.log "$BUILD"/provenance.txt \
   "$BUILD"/tool_versions.txt "$BUILD"/source_sha256.txt "$BUILD"/vector_sha256.txt "$EVID"/
mkdir -p "$EVID/sim" "$EVID/neg" "$EVID/syn"
cp "$BUILD"/sim/sim_*.log "$BUILD"/sim/check_*.log "$BUILD"/sim/cycles_*.txt "$EVID/sim/"
cp "$BUILD"/neg/*.log "$EVID/neg/"
cp "$SYN_CSV" "$BUILD"/syn/ghdl_synth_*.log "$EVID/syn/"
# Yosys logs: keep the check and statistics sections (full logs stay in build/).
for f in $FIXTURES; do
  IFS=: read -r n p l syn <<EOF_FIX
$f
EOF_FIX
  for kind in yosys yosys_count; do
    src="$BUILD/syn/${kind}_n${n}_p${p}_l${l}.log"
    [ -f "$src" ] || continue
    { grep '^Warning:' "$src"
      echo "---- check and statistics (last sections) ----"
      awk '/Executing CHECK pass/{f=1} /Printing statistics/{f=1} f' "$src"
    } > "$EVID/syn/${kind}_n${n}_p${p}_l${l}_summary.log"
  done
done

if [ "$FAIL" = "0" ]; then OVERALL=PASS; else OVERALL=FAIL; fi
echo "OVERALL: $OVERALL" >> "$SUMMARY"
cp "$SUMMARY" "$EVID/summary.txt"

# MANIFEST last: every log above is closed; exclude the manifest itself and temp
# files; write it outside the folder first, then move it in (M2A-DEFECT-001).
( cd "$EVID" && find . -type f ! -name MANIFEST.sha256 ! -name '*.tmp' | sed 's#^\./##' | LC_ALL=C sort \
    | while read -r f; do shasum -a 256 "$f"; done ) > "$BUILD/MANIFEST.sha256.build"
mv "$BUILD/MANIFEST.sha256.build" "$EVID/MANIFEST.sha256"

echo
echo "== summary ($RUN_ID)"
cat "$SUMMARY"
echo "evidence: $EVID"
echo "build:    $BUILD"
[ "$OVERALL" = "PASS" ]
