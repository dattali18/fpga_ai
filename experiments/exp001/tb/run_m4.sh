#!/usr/bin/env bash
# run_m4.sh - EXP001 M4 runner: post-synthesis simulation and Series 7 mapping of
# the accepted M2c DPC design (M4_PROMPT.md). No RTL or testbench changes.
#
# Usage (from anywhere):   bash experiments/exp001/tb/run_m4.sh
#
# Host: bash 3.2 compatible. Every tool step runs in fpga_ai-toolchain:m1-arm64.
#   0  protected + oracle digests; RTL and testbench byte-identical to M2c commit
#   A  GHDL netlist simulation with saturated shift amounts (M4-TOOL-002, D-082)
#      and constant-Z selects resolved as in Yosys (M4-TOOL-003, D-083):
#      ghdl --synth --out=vhdl, rewrites N1 + N2, tb_dpc.vhd unchanged,
#      stress + timing, dpc_ref.py --check, cycles vs the M2c formula, negative
#      control, N1-only diagnostic control (all outputs X), Yosys Z-select test.
#      Mapped (Verilog) netlist simulation: BLOCKED (no Verilog simulator).
#   B  Series 7 mapping, out of context, synth_xilinx without the share step
#      (M4-TOOL-001, D-081); check -assert; stat -tech xilinx; write_json; ltp -noff
#   C  NOT_RUN (planner decision)
#   9  protected + oracle digests again; evidence with MANIFEST.sha256 written last
# Exit status 0 only if OVERALL is PASS.

set -u

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$REPO" || exit 2

IMAGE="${IMAGE:-fpga_ai-toolchain:m1-arm64}"
EXP="experiments/exp001"
REF_COMMIT="ded8d4a"                       # accepted M2c design (D-079)
RUN_ID="m4_$(date -u +%Y%m%dT%H%M%SZ)"
BUILD="$EXP/build/$RUN_ID"
EVID="${EVID_DIR:-$EXP/evidence/$RUN_ID}"   # EVID_DIR: smoke runs only
ORACLE="$EXP/reference/ORACLE_MANIFEST.sha256"
SEED=20261126
STRESS_PCT=30
RELOAD_TX=4

# Part A fixtures N:P:L
POSTSYN="${POSTSYN:-8:3:1 5:8:2 8:8:3 64:16:1 64:16:4 256:64:8}"
# Part B mappings N:P:L:strategy (sequential; smallest and safest first)
MAPPINGS="${MAPPINGS:-64:16:1:default 256:64:1:default 256:64:2:default 64:16:4:default \
256:64:4:default 64:16:4:nolutram 256:64:8:default 64:16:4:nodsp}"

mkdir -p "$BUILD/vectors" "$BUILD/postsyn" "$BUILD/map" "$BUILD/neg" "$BUILD/tools" "$EVID" || exit 2

tc() {
  docker run --rm --platform linux/arm64 -v "$REPO:/workspace" -w /workspace \
    "$IMAGE" bash -c "$1"
}

FAIL=0
BLOCKED=0
SUMMARY="$BUILD/summary.txt"
: > "$SUMMARY"
row() {               # row <PASS|FAIL|BLOCKED|NOT_RUN|INFO> <text>
  printf '%-7s %s\n' "$1" "$2" | tee -a "$SUMMARY"
  case "$1" in
    PASS|INFO|NOT_RUN) ;;
    BLOCKED) BLOCKED=1 ;;
    *) FAIL=1 ;;
  esac
}

echo "== run $RUN_ID"
START_S=$(date +%s)

# ------------------------------------------------------------ helper scripts
# N1 / M4-TOOL-002: rewrite to_integer (unsigned (s)) -> sat_shift (s) inside
# shift_left/shift_right calls only; also add the sat package to each use list.
cat > "$BUILD/tools/rewrite_shifts.py" <<'PY'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src).read()
pat = re.compile(r"(shift_(?:left|right) \(unsigned \(n\d+_o\), )"
                 r"to_integer ?\(unsigned \((n\d+_o)\)\)(\))")
total_calls = len(re.findall(r"shift_(?:left|right) ?\(", text))
with_toint = len(re.findall(r"shift_(?:left|right) \([^;]*to_integer", text))
new, n = pat.subn(r"\1sat_shift (\2)\3", text)
uses = new.count("use ieee.numeric_std.all;")
new = new.replace("use ieee.numeric_std.all;",
                  "use ieee.numeric_std.all;\nuse work.m4_sat_pkg.all;")
left = len(re.findall(r"shift_(?:left|right) \([^;]*to_integer", new))
open(dst, "w").write(new)
print(f"shift_calls={total_calls} shift_calls_with_to_integer={with_toint} "
      f"replaced={n} remaining_in_shifts={left} use_clauses_added={uses} "
      f"other_to_integer={new.count('to_integer')}")
sys.exit(0 if (n == with_toint and left == 0 and n > 0 and uses > 0) else 1)
PY

# N2 / M4-TOOL-003: resolve float_pkg's constant-Z metavalue selects as Yosys does.
cat > "$BUILD/tools/rewrite_zsel.py" <<'PY'
import sys
src, dst, lanes = sys.argv[1], sys.argv[2], int(sys.argv[3])
text = open(src).read()
needle = "std_logic'('Z') = '0'"
n = text.count(needle)
new = text.replace(needle, "true")
open(dst, "w").write(new)
print(f"zsel_replaced={n} expected={32 * lanes} remaining_Z_literals={new.count(chr(39) + 'Z' + chr(39))}")
sys.exit(0 if n == 32 * lanes else 1)
PY

# F1 / M4-TOOL-001: the hand-built coarse step must equal the standard coarse
# step of 'help synth_xilinx' minus 'share'.
COARSE_NOSHARE="techmap -map +/cmp2lut.v -map +/cmp2lcu.v -D LUT_WIDTH=6; alumacc; opt; memory -nomap; opt_clean"
cat > "$BUILD/tools/check_flow.py" <<'PY'
import re, sys
help_txt = open(sys.argv[1]).read()
used = [c.strip() for c in sys.argv[2].split(";") if c.strip()]
labels = re.findall(r"^    (\w+):", help_txt, re.M)
m = re.search(r"^    coarse:\n(.*?)\n\n", help_txt, re.M | re.S)
std = [l.strip() for l in m.group(1).splitlines() if l.strip()]
std_norm = [s.replace("LUT_WIDTH=[46]", "LUT_WIDTH=6") for s in std]
minus_share = [s for s in std_norm if s != "share"]
ok = (minus_share == used and std_norm.count("share") == 1
      and help_txt.count("\n        share\n") == 1
      and labels.index("coarse") == labels.index("map_dsp") + 1
      and labels.index("map_memory") == labels.index("coarse") + 1)
print("labels:", " ".join(labels))
print("standard coarse:", " | ".join(std))
print("used coarse    :", " | ".join(used))
print("noshare_option_present:", bool(re.search(r"-noshare", help_txt)))
print("RESULT:", "EQUAL_MINUS_SHARE" if ok else "MISMATCH")
sys.exit(0 if ok else 1)
PY

# Parse a mapping log: last 'stat -tech xilinx' block, check result, ltp, memory.
cat > "$BUILD/tools/parse_map.py" <<'PY'
import re, sys
log, cfg, strat, secs, rc = sys.argv[1:6]
t = open(log, errors="replace").read()
blocks = t.split("Printing statistics.")
cells = {}
if len(blocks) > 1:
    blk = blocks[-1].split("Executing")[0]
    for m in re.finditer(r"^\s{5,}([A-Za-z_$][\w$]*)\s+(\d+)\s*$", blk, re.M):
        cells[m.group(1)] = int(m.group(2))
prob = re.findall(r"Found and reported (\d+) problems", t)
ltp = re.findall(r"Longest topological path in \S+ \(length=(\d+)\)", t)
mem = re.findall(r"MEM: ([\d.]+) MB peak", t)
def s(f): return sum(v for k, v in cells.items() if f(k))
lut = s(lambda k: re.fullmatch(r"LUT[1-6]", k) is not None)
ff = s(lambda k: k.startswith("FD"))
lutram = s(lambda k: k.startswith("RAM") and not k.startswith("RAMB"))
srl = s(lambda k: k.startswith("SRL"))
b18 = cells.get("RAMB18E1", 0); b36 = cells.get("RAMB36E1", 0)
known = lut + ff + lutram + srl + b18 + b36 + sum(cells.get(k, 0) for k in
        ("CARRY4", "MUXF7", "MUXF8", "DSP48E1"))
total = sum(cells.values())
lutram_types = "+".join(f"{k}:{v}" for k, v in sorted(cells.items())
                        if k.startswith("RAM") and not k.startswith("RAMB")) or "-"
n, p, l = cfg.split(":")
check_ok = bool(prob) and prob[-1] == "0"
ltp_started = "Executing LTP pass" in t
if check_ok and cells and (rc == "0" or (rc == "137" and ltp_started)):
    status = "PASS"                      # mapping complete (ltp may have been killed)
elif rc == "137":
    status = "BLOCKED"                   # killed before the mapping completed
else:
    status = "FAIL"
ltp_v = ltp[-1] if ltp else ("BLOCKED" if rc == "137" else "NA")
row = [n, p, l, strat, status, secs, mem[-1] if mem else "NA",
       prob[-1] if prob else "NA", total, lut, ff, cells.get("CARRY4", 0),
       cells.get("MUXF7", 0), cells.get("MUXF8", 0), cells.get("DSP48E1", 0),
       lutram, lutram_types, srl, b18, b36, total - known, ltp_v]
print(",".join(str(x) for x in row))
with open(sys.argv[6], "a") as f:
    for k, v in sorted(cells.items()):
        f.write(f"{n},{p},{l},{strat},{k},{v}\n")
PY

# Closed-form cycle formula (D-076).
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

# ------------------------------------------------------------ 0 integrity
if tc "python3 scripts/verify_protected_digests.py --extra-manifest $ORACLE" \
     > "$BUILD/protected_before.txt" 2>&1; then
  row PASS "protected+oracle before: $(tail -1 "$BUILD/protected_before.txt")"
else
  row FAIL "protected+oracle before (see protected_before.txt)"
fi
shasum -a 256 "$ORACLE" > "$BUILD/oracle_manifest_sha256_before.txt"

: > "$BUILD/rtl_vs_m2c.txt"
same=1
for f in $EXP/rtl/dpc_pkg.vhd $EXP/rtl/dpc.vhd $EXP/tb/tb_dpc.vhd; do
  cur=$(shasum -a 256 "$f" | awk '{print $1}')
  ref=$(git show "$REF_COMMIT:$f" | shasum -a 256 | awk '{print $1}')
  echo "$cur  $f  (at $REF_COMMIT: $ref)" >> "$BUILD/rtl_vs_m2c.txt"
  [ "$cur" = "$ref" ] || same=0
done
if [ "$same" = "1" ]; then
  row PASS "RTL and tb_dpc.vhd byte-identical to M2c commit $REF_COMMIT"
else
  row FAIL "RTL or tb_dpc.vhd differ from M2c commit $REF_COMMIT (see rtl_vs_m2c.txt)"
fi

if tc "python3 $EXP/reference/dpc_ref.py --output $BUILD/vectors" > "$BUILD/reference.log" 2>&1; then
  row PASS "reference vectors: $(grep -c ': 7 transactions' "$BUILD/reference.log") files"
else
  row FAIL "reference vectors (see reference.log)"
fi

# F1 flow check (D-081)
tc "yosys -h synth_xilinx" > "$BUILD/help_synth_xilinx.txt" 2>&1
if tc "python3 -I $BUILD/tools/check_flow.py $BUILD/help_synth_xilinx.txt '$COARSE_NOSHARE'" \
     > "$BUILD/flow_check.txt" 2>&1; then
  row PASS "F1: hand-built coarse = standard coarse minus share; no -noshare option in Yosys 0.33"
else
  row FAIL "F1: flow check failed (see flow_check.txt)"
fi

# ------------------------------------------------------------ A netlist sim
# Three-line test: how Yosys resolves a constant-Z mux select (basis of N2).
mkdir -p "$BUILD/zsel_test"
cat > "$BUILD/zsel_test/t.v" <<'V'
module t(input [3:0] a, output [3:0] y);
  assign y = 1'bZ ? 4'b1010 : a;
endmodule
V
tc "cd $BUILD/zsel_test && yosys -p 'read_verilog t.v; proc; opt; write_verilog -noattr t_opt.v' > yosys.log 2>&1"
if grep -q 'assign y = a;' "$BUILD/zsel_test/t_opt.v" 2>/dev/null; then
  row PASS "Yosys resolves 1'bZ ? 4'b1010 : a to y = a (normal path); basis of N2"
else
  row FAIL "Yosys Z-select test: unexpected result (see zsel_test/)"
fi

echo "n_rg,p,lanes,original_sha256,n1_sha256,n1n2_sha256,n1_summary,n2_summary" > "$BUILD/postsyn/netlists.csv"
for f in $POSTSYN; do
  IFS=: read -r n p l <<EOF_FIX
$f
EOF_FIX
  tag="n${n}_p${p}_l${l}"
  d="$BUILD/postsyn/$tag"
  mkdir -p "$d/rtlwork" "$d/network"
  if ! tc "cd $d && ghdl -a --std=08 --workdir=rtlwork /workspace/$EXP/rtl/dpc_pkg.vhd /workspace/$EXP/rtl/dpc.vhd && \
           ghdl --synth --std=08 --no-formal --workdir=rtlwork -gG_N_RG=$n -gG_P=$p -gG_LANES=$l --out=vhdl dpc > net.vhdl" \
       > "$d/ghdl_synth.log" 2>&1; then
    row FAIL "A $tag: ghdl --synth --out=vhdl failed"; continue
  fi
  if tc "python3 -I $BUILD/tools/rewrite_shifts.py $d/net.vhdl $d/net_sat.vhdl" > "$d/rewrite.txt" 2>&1; then
    row PASS "A $tag rewrite: $(cat "$d/rewrite.txt")"
  else
    row FAIL "A $tag rewrite: $(cat "$d/rewrite.txt")"; continue
  fi
  diff -u "$d/net.vhdl" "$d/net_sat.vhdl" > "$d/net_sat.diff"
  if tc "python3 -I $BUILD/tools/rewrite_zsel.py $d/net_sat.vhdl $d/net_satz.vhdl $l" > "$d/rewrite_zsel.txt" 2>&1; then
    row PASS "A $tag N2: $(cat "$d/rewrite_zsel.txt")"
  else
    row FAIL "A $tag N2: count is not 32*L, fixture stopped: $(cat "$d/rewrite_zsel.txt")"; continue
  fi
  diff -u "$d/net_sat.vhdl" "$d/net_satz.vhdl" > "$d/net_satz.diff"
  echo "$n,$p,$l,$(shasum -a 256 "$d/net.vhdl" | awk '{print $1}'),$(shasum -a 256 "$d/net_sat.vhdl" | awk '{print $1}'),$(shasum -a 256 "$d/net_satz.vhdl" | awk '{print $1}'),\"$(cat "$d/rewrite.txt")\",\"$(cat "$d/rewrite_zsel.txt")\"" \
    >> "$BUILD/postsyn/netlists.csv"
  if ! tc "cd $d && ghdl -a --std=08 --workdir=network /workspace/$EXP/rtl/dpc_pkg.vhd /workspace/$EXP/tb/m4_sat_pkg.vhd net_satz.vhdl /workspace/$EXP/tb/tb_dpc.vhd && \
           ghdl -e --std=08 --workdir=network tb_dpc" > "$d/ghdl_netlist_analyse.log" 2>&1; then
    row FAIL "A $tag: netlist analysis/elaboration failed"; continue
  fi
  for mode in stress timing; do
    if [ "$mode" = "stress" ]; then pct=$STRESS_PCT; else pct=0; fi
    vec="vectors/dpc_n${n}_p${p}.txt"
    log="$d/sim_$mode.log"
    if tc "cd $d && ghdl -r --std=08 --workdir=network tb_dpc -gG_N_RG=$n -gG_P=$p -gG_LANES=$l \
            -gG_VECTOR_FILE=../../$vec -gG_DUMP_FILE=dump_$mode.txt -gG_STALL_PCT=$pct -gG_SEED=$SEED \
            --ieee-asserts=disable-at-0" > "$log" 2>&1 && grep -q "^PASS: ../../$vec" "$log"; then
      row PASS "A sim   ${tag}_$mode: $(grep -o '[0-9]* transactions, [0-9]* outputs, [0-9]* checks, [0-9]* errors' "$log")"
    else
      row FAIL "A sim   ${tag}_$mode: $(grep -o '[0-9]* transactions, [0-9]* outputs, [0-9]* checks, [0-9]* errors' "$log" | tail -1) (see $log)"
    fi
    if tc "python3 $EXP/reference/dpc_ref.py --check $BUILD/$vec $d/dump_$mode.txt" > "$d/check_$mode.log" 2>&1; then
      row PASS "A check ${tag}_$mode: $(tail -1 "$d/check_$mode.log")"
    else
      row FAIL "A check ${tag}_$mode: $(tail -1 "$d/check_$mode.log")"
    fi
  done
  grep '^CYCLES' "$d/sim_timing.log" > "$d/cycles.txt"
  expected_cycles "$n" "$p" "$l" "$(wc -l < "$d/cycles.txt" | tr -d ' ')" > "$d/cycles_formula.txt"
  if [ "$(wc -l < "$d/cycles.txt" | tr -d ' ')" = "7" ] && cmp -s "$d/cycles.txt" "$d/cycles_formula.txt"; then
    row PASS "A cycles $tag: netlist = RTL formula ($(sed -n 1p "$d/cycles.txt" | grep -o 'latency=[0-9]*'))"
  else
    row FAIL "A cycles $tag: netlist cycles differ from the M2c formula"
  fi
done

# Netlist-level negative control: bad Y must FAIL against the (8,3,1) netlist.
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
' $BUILD/vectors/dpc_n8_p3.txt $BUILD/neg/dpc_n8_p3_badY.txt" > "$BUILD/neg/ncA_prepare.log" 2>&1
d="$BUILD/postsyn/n8_p3_l1"
if cmp -s "$BUILD/vectors/dpc_n8_p3.txt" "$BUILD/neg/dpc_n8_p3_badY.txt"; then
  row FAIL "A NC bad Y (netlist 8,3,1): vector copy not modified"
elif tc "cd $d && ghdl -r --std=08 --workdir=network tb_dpc -gG_N_RG=8 -gG_P=3 -gG_LANES=1 \
          -gG_VECTOR_FILE=../../neg/dpc_n8_p3_badY.txt -gG_DUMP_FILE=dump_badY.txt -gG_STALL_PCT=0 \
          --ieee-asserts=disable-at-0" > "$BUILD/neg/ncA_sim.log" 2>&1 \
     || grep -q '^PASS:' "$BUILD/neg/ncA_sim.log"; then
  row FAIL "A NC bad Y (netlist 8,3,1): testbench did not fail"
else
  row PASS "A NC bad Y (netlist 8,3,1): testbench failed as intended ($(grep -o '[0-9]* errors' "$BUILD/neg/ncA_sim.log" | tail -1))"
fi

# Diagnostic control (D-083): the N1-only netlist of (8,3,1), without N2, gives
# unknown (X) data on every output, because VHDL resolves 'Z' = '0' as false and
# every float_pkg operation then classifies its inputs as isx.
dd="$BUILD/postsyn/n8_p3_l1"
mkdir -p "$dd/network_n1"
tc "cd $dd && ghdl -a --std=08 --workdir=network_n1 /workspace/$EXP/rtl/dpc_pkg.vhd /workspace/$EXP/tb/m4_sat_pkg.vhd net_sat.vhdl /workspace/$EXP/tb/tb_dpc.vhd && \
    ghdl -e --std=08 --workdir=network_n1 tb_dpc && \
    ghdl -r --std=08 --workdir=network_n1 tb_dpc -gG_N_RG=8 -gG_P=3 -gG_LANES=1 \
      -gG_VECTOR_FILE=../../vectors/dpc_n8_p3.txt -gG_DUMP_FILE=dump_n1only.txt -gG_STALL_PCT=0 \
      --ieee-asserts=disable-at-0" > "$BUILD/neg/diag_n1only_sim.log" 2>&1
nx=$(grep -c '^O XXXXXXXX XXXXXXXX$' "$dd/dump_n1only.txt" 2>/dev/null)
no=$(grep -c '^O ' "$dd/dump_n1only.txt" 2>/dev/null)
if [ "${no:-0}" = "56" ] && [ "${nx:-0}" = "56" ] && grep -q '56 errors' "$BUILD/neg/diag_n1only_sim.log"; then
  row PASS "A diagnostic N1-only (8,3,1): all 56 outputs X, 56 errors, as expected without N2"
else
  row FAIL "A diagnostic N1-only (8,3,1): expected 56 X outputs, got ${nx:-0} of ${no:-0}"
fi
cp "$dd/dump_n1only.txt" "$BUILD/neg/diag_n1only_dump.txt" 2>/dev/null

# ------------------------------------------------------------ B Series 7 mapping
MAP_CSV="$BUILD/map/mapping.csv"
echo "n_rg,p,lanes,strategy,status,wall_seconds,peak_mem_mb,problems,total_cells,logic_lut,ff,carry4,muxf7,muxf8,dsp48e1,lutram,lutram_types,srl,ramb18,ramb36,other,ltp_length_cells" > "$MAP_CSV"
echo "n_rg,p,lanes,strategy,cell_type,count" > "$BUILD/map/cell_types.csv"
for m in $MAPPINGS; do
  IFS=: read -r n p l strat <<EOF_FIX
$m
EOF_FIX
  tag="n${n}_p${p}_l${l}"
  d="$BUILD/map/$tag"
  mkdir -p "$d/work"
  if [ ! -f "$d/net.v" ]; then
    tc "cd $d && ghdl -a --std=08 --workdir=work /workspace/$EXP/rtl/dpc_pkg.vhd /workspace/$EXP/rtl/dpc.vhd && \
        ghdl --synth --std=08 --no-formal --workdir=work -gG_N_RG=$n -gG_P=$p -gG_LANES=$l --out=verilog dpc > net.v" \
      > "$d/ghdl_synth.log" 2>&1 || { row FAIL "B $tag: ghdl --synth failed"; continue; }
    shasum -a 256 "$d/net.v" | sed "s#$BUILD/##" >> "$BUILD/map/netlist_sha256.txt"
  fi
  case "$strat" in
    default)  opts="" ;;
    nodsp)    opts="-nodsp" ;;
    nolutram) opts="-nolutram" ;;
  esac
  sx="synth_xilinx -family xc7 -top dpc -noiopad -noclkbuf $opts"
  script="read_verilog net.v; $sx -run :coarse; $COARSE_NOSHARE; $sx -run map_memory:; check -assert; stat -tech xilinx; write_json map_$strat.json; ltp -noff"
  echo "{\"mapping\":\"$tag $strat\",\"yosys\":\"$script\"}" >> "$BUILD/map/commands.jsonl"
  tc "cd $d && s=\$(date +%s); yosys -p \"$script\" > map_$strat.log 2>&1; rc=\$?; echo \"\$rc \$((\$(date +%s) - s))\" > map_$strat.status"
  read -r rc secs < "$d/map_$strat.status"
  line=$(tc "python3 -I $BUILD/tools/parse_map.py $d/map_$strat.log $n:$p:$l $strat $secs $rc $BUILD/map/cell_types.csv")
  echo "$line" >> "$MAP_CSV"
  st=$(echo "$line" | cut -d, -f5)
  summ=$(echo "$line" | awk -F, '{printf "%ss mem=%sMB problems=%s LUT=%s FF=%s CARRY4=%s MUXF7/8=%s/%s DSP=%s LUTRAM=%s(%s) SRL=%s RAMB18/36=%s/%s other=%s depth=%s", $6,$7,$8,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22}')
  if [ "$st" = "BLOCKED" ]; then
    row BLOCKED "B $tag $strat: killed (exit 137, out of memory) after ${secs}s; flow unchanged (D-080 answer 4)"
  else
    row "$st" "B $tag $strat: $summ"
  fi
done

# Known, planner-acknowledged gap: reported as BLOCKED, does not change OVERALL.
printf '%-7s %s\n' BLOCKED "A mapped (Verilog) netlist simulation: no Verilog simulator in the image (acknowledged gap, not counted in OVERALL)" | tee -a "$SUMMARY"
row NOT_RUN "C equivalence generic vs xc7 netlist: skipped by planner decision (expected INCONCLUSIVE: DSP48E1 black box)"

# ------------------------------------------------------------ 9 integrity, evidence
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

TOTAL_S=$(( $(date +%s) - START_S ))
{
  echo "run_id: $RUN_ID"
  echo "command: bash experiments/exp001/tb/run_m4.sh"
  echo "date_utc_end: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "total_seconds: $TOTAL_S"
  echo "git_head: $(git rev-parse HEAD)"
  echo "design_commit: $REF_COMMIT"
  echo "image: $IMAGE ($(docker image inspect --format '{{.Id}}' "$IMAGE" 2>/dev/null))"
  echo "docker: $(docker info --format 'CPUs={{.NCPU}} MemTotal={{.MemTotal}}' 2>/dev/null)"
  echo "host: $(uname -sm)"
  echo "seed: $SEED  stress_pct: $STRESS_PCT"
  echo "git_status_short:"
  git status --short
} > "$BUILD/provenance.txt"
tc "ghdl --version | head -1; yosys -V; python3 --version" > "$BUILD/tool_versions.txt" 2>&1
shasum -a 256 $EXP/rtl/dpc_pkg.vhd $EXP/rtl/dpc.vhd $EXP/tb/tb_dpc.vhd $EXP/tb/m4_sat_pkg.vhd $EXP/tb/run_m4.sh \
  > "$BUILD/source_sha256.txt"

cp "$BUILD"/protected_before.txt "$BUILD"/protected_after.txt "$BUILD"/oracle_manifest_sha256_*.txt \
   "$BUILD"/rtl_vs_m2c.txt "$BUILD"/reference.log "$BUILD"/help_synth_xilinx.txt "$BUILD"/flow_check.txt \
   "$BUILD"/provenance.txt "$BUILD"/tool_versions.txt "$BUILD"/source_sha256.txt "$EVID"/
mkdir -p "$EVID/postsyn" "$EVID/map" "$EVID/neg"
cp "$BUILD"/postsyn/netlists.csv "$EVID/postsyn/"
for f in $POSTSYN; do
  IFS=: read -r n p l <<EOF_FIX
$f
EOF_FIX
  tag="n${n}_p${p}_l${l}"; d="$BUILD/postsyn/$tag"; e="$EVID/postsyn/$tag"
  mkdir -p "$e"
  for x in rewrite.txt rewrite_zsel.txt net_sat.diff net_satz.diff sim_stress.log sim_timing.log check_stress.log check_timing.log \
           cycles.txt cycles_formula.txt ghdl_synth.log ghdl_netlist_analyse.log; do
    [ -f "$d/$x" ] && cp "$d/$x" "$e/"
  done
done
cp "$BUILD"/neg/*.log "$BUILD"/neg/diag_n1only_dump.txt "$EVID/neg/" 2>/dev/null
mkdir -p "$EVID/zsel_test" && cp "$BUILD"/zsel_test/t.v "$BUILD"/zsel_test/t_opt.v "$BUILD"/zsel_test/yosys.log "$EVID/zsel_test/"
cp "$MAP_CSV" "$BUILD/map/cell_types.csv" "$BUILD/map/commands.jsonl" "$BUILD/map/netlist_sha256.txt" "$EVID/map/"
for m in $MAPPINGS; do
  IFS=: read -r n p l strat <<EOF_FIX
$m
EOF_FIX
  src="$BUILD/map/n${n}_p${p}_l${l}/map_$strat.log"
  [ -f "$src" ] || continue
  { echo "warnings: $(grep -c '^Warning:' "$src")"
    grep '^Warning:' "$src" | sed 's/(.*)$//' | sort | uniq -c
    echo "---- check, statistics, ltp, end (excerpt) ----"
    awk '/Executing CHECK pass/{f=1} /Printing statistics/{f=1} /Executing LTP pass/{f=1} f' "$src" \
      | grep -v '^ *[0-9]*: ' | tail -150
    grep -E 'Longest topological path|End of script' "$src"
  } > "$EVID/map/map_n${n}_p${p}_l${l}_${strat}_excerpt.log"
done

if [ "$FAIL" = "1" ]; then OVERALL=FAIL
elif [ "$BLOCKED" = "1" ]; then OVERALL=BLOCKED
else OVERALL=PASS; fi
echo "OVERALL: $OVERALL (total ${TOTAL_S}s)" >> "$SUMMARY"
cp "$SUMMARY" "$EVID/summary.txt"

# MANIFEST last (M2A-DEFECT-001 lesson).
( cd "$EVID" && find . -type f ! -name MANIFEST.sha256 ! -name '*.tmp' | sed 's#^\./##' | LC_ALL=C sort \
    | while read -r f; do shasum -a 256 "$f"; done ) > "$BUILD/MANIFEST.sha256.build"
mv "$BUILD/MANIFEST.sha256.build" "$EVID/MANIFEST.sha256"

echo
echo "== summary ($RUN_ID)"
cat "$SUMMARY"
echo "evidence: $EVID"
echo "build:    $BUILD"
[ "$OVERALL" = "PASS" ]
