#!/usr/bin/env bash
# collect_handoff.sh
# Read-only: collects the files needed to take over the project into one ZIP.
# Nothing in the project is modified; the only file written is the output ZIP.
#
# Version 2: adds .agents/, edu_complex_arithmetic, macOS-safe timestamps/listing.
#
# Usage (from anywhere):   bash scripts/collect_handoff.sh [output.zip]
# Default output:          <project root>/handoff_<timestamp>.zip
#
# Included: project docs, context, research notes, scripts, docker smoke sources,
#           edu_register + edu_fifo sources (V1, V2), benchmark/equivalence summaries
#           and provenance, a few representative per-config logs/harnesses,
#           generated git + tool metadata, a file listing and a SHA-256 manifest.
# Excluded: build products (.o, .cf, binaries), vectors, netlist JSON, VCD,
#           old handoff ZIPs, anything over MAX_BYTES, likely secrets.

set -euo pipefail
shopt -s nullglob

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
if command -v shasum >/dev/null 2>&1; then HASH="shasum -a 256"; else HASH="sha256sum"; fi
OUT="${1:-$ROOT/handoff_${STAMP}.zip}"
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac
MAX_BYTES=$((2 * 1024 * 1024))   # skip single files above 2 MiB (listed in report)

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
PKG="$STAGE/handoff"
META="$PKG/_handoff"
mkdir -p "$META"
LIST="$STAGE/candidates.txt";   : > "$LIST"
SKIPPED="$STAGE/skipped.txt";   : > "$SKIPPED"

# ---------------------------------------------------------------- helpers
add() {                      # explicit files / shell globs
  local p
  for p in "$@"; do [ -f "$p" ] && printf '%s\n' "${p#./}" >> "$LIST"; done
  return 0
}
add_find() {                 # add_find <dir> <find predicates...>
  local d="$1"; shift
  [ -d "$d" ] || return 0
  find "$d" -type f \( "$@" \) -print | sed 's|^\./||' >> "$LIST"
}
EB=experiments/edu_fifo/benchmarks
EF=experiments/edu_fifo

# ------------------------------------------------------------- 1. root docs
add AGENTS.md README.md START_PROMPT.md Makefile .gitignore .gitattributes .dockerignore

# ------------------------------------------------- 2. context and research
add_find .agents  -name '*.md'
add_find context  -name '*.md'
add_find research -name '*.md'

# ----------------------------------------------------- 3. tooling and docker
add_find scripts -name '*.sh' -o -name '*.py' -o -name '*.ys' -o -name '*.tcl'
add docker/Dockerfile docker/requirements.txt
add_find docker/smoke -name '*.vhd' -o -name '*.py'

# --------------------------------------------------------- 4. edu_register
add experiments/edu_register/*.md experiments/edu_register/golden.py \
    experiments/edu_register/rtl/*.vhd experiments/edu_register/tb/*.vhd \
    experiments/edu_register/build/verification.log

# ------------------------------------------------------ 5. edu_fifo sources
add $EF/*.md $EF/golden.py $EF/rtl/*.vhd $EF/tb/*.vhd
add $EF/v2/*.md $EF/v2/rtl/*.vhd

# ------------- 6. benchmark / equivalence summaries + provenance (no per-config dirs)
SUMMARY_NAMES=( -name '*.md' -o -name 'benchmark.csv' -o -name 'cell_types.csv'
  -o -name 'equivalence.csv' -o -name 'configs.tsv' -o -name 'tools.txt'
  -o -name 'git_head.txt' -o -name 'git_status.txt' -o -name 'image_id.txt'
  -o -name 'source_sha256.txt' -o -name 'runner_sha256.txt' -o -name 'variant.txt'
  -o -name 'commands.jsonl' -o -name 'evidence_manifest.json'
  -o -name 'benchmark.log' -o -name 'equivalence.log' )
if [ -d "$EB" ]; then
  find "$EB" -path '*/w[0-9]*_d[0-9]*' -prune -o -type f \( "${SUMMARY_NAMES[@]}" \) -print \
    | sed 's|^\./||' >> "$LIST"
fi

# --------- 7. representative per-config evidence (depth 1 and non-power-of-two)
for run in final_invariants final_observable; do
  for cfg in w1_d1 w2_d3; do
    add_find "$EB/equivalence/final/$run/$cfg" -name '*.log' -o -name 'harness.v' -o -name 'raw.v'
  done
done
for xc in $EF/build/xc7.*; do
  for v in v1 v2; do
    for cfg in w32_d31 w32_d32; do
      add_find "$xc/$v/$cfg" -name '*.log'
    done
  done
done

# ------------------------------------------ 8. latest edu_fifo verification logs
add $EF/build/run.*/verification.log

# ----------------------------------------------- 8b. edu_complex_arithmetic
ECA=experiments/edu_complex_arithmetic
add $ECA/README.md $ECA/rtl/*.vhd $ECA/tb/*.vhd $ECA/tb/*.sh $ECA/reference/*.py $ECA/*.md
latest_ev="$(ls -d $ECA/build/evidence_* 2>/dev/null | sort | tail -1)"
[ -n "$latest_ev" ] && add_find "$latest_ev" -name '*.txt' -o -name '*.log'

# ------------------------------------------------------------------- 9. exp001
add_find experiments/exp001/docs -name '*.md'
add experiments/exp001/tb/conftest.py
add experiments/exp001/results/m1_smoke/*.txt experiments/exp001/results/m1_smoke/*.log

# --------------------------------------------------- filter, size cap, stage
sort -u "$LIST" | while IFS= read -r f; do
  [ -f "$f" ] || continue
  case "$f" in
    *.o|*.cf|*.vcd|*.zip|*_netlist.json) echo "excluded-type  $f" >> "$SKIPPED"; continue ;;
    *.env|*.pem|*.key|*id_rsa*|*secret*|*token*) echo "excluded-secret $f" >> "$SKIPPED"; continue ;;
  esac
  sz=$(wc -c < "$f")
  if [ "$sz" -gt "$MAX_BYTES" ]; then
    echo "excluded-size  $f ($sz bytes)" >> "$SKIPPED"; continue
  fi
  mkdir -p "$PKG/$(dirname "$f")"
  cp -p "$f" "$PKG/$f"
done

# ------------------------------------------------------- generated metadata
{
  echo "generated_utc: $STAMP"
  echo "host: $(uname -a)"
  echo "root: $ROOT"
} > "$META/info.txt"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git log --oneline --decorate -n 150          > "$META/git_log.txt"        2>&1 || true
  git log -n 30 --stat --format='--- %h %ad %s' --date=iso > "$META/git_log_stat.txt" 2>&1 || true
  git status --porcelain=v1 --branch            > "$META/git_status.txt"     2>&1 || true
  git diff --stat                               > "$META/git_diff_stat.txt"  2>&1 || true
  git ls-files                                  > "$META/git_ls_files.txt"   2>&1 || true
  git branch -a -vv                             > "$META/git_branches.txt"   2>&1 || true
else
  echo "not a git work tree" > "$META/git_status.txt"
fi

{
  for t in "ghdl --version" "yosys -V" "python3 --version" "docker --version" \
           "nextpnr-xilinx --version" "iverilog -V" "sby --version"; do
    echo "\$ $t"; $t 2>&1 | head -n 3 || echo "(not available)"; echo
  done
} > "$META/tool_versions.txt" 2>&1 || true

# full project listing (sizes), excluding .git
python3 - > "$META/all_files.tsv" <<'PYEOF'
import os
for d, dirs, files in os.walk("."):
    dirs[:] = [x for x in dirs if x != ".git"]
    for f in files:
        p = os.path.join(d, f)
        try:
            print(f"{os.path.getsize(p)}\t{p[2:]}")
        except OSError:
            pass
PYEOF

cp "$SKIPPED" "$META/skipped.txt"
( cd "$PKG" && find . -type f ! -path './_handoff/MANIFEST.sha256' -print0 \
    | sort -z | xargs -0 $HASH ) > "$META/MANIFEST.sha256"

cat > "$META/README.txt" <<EOF
Handoff bundle produced by collect_handoff.sh (read-only collection).
Paths mirror the project root. _handoff/ holds generated metadata:
  info.txt, git_*.txt, tool_versions.txt, all_files.tsv (full listing),
  skipped.txt (excluded files and why), MANIFEST.sha256 (included files).
Representative per-config evidence: equivalence w1_d1 and w2_d3 (final runs),
xc7 v1/v2 w32_d31 and w32_d32 logs. Everything else under benchmarks/ is summaries.
EOF

# -------------------------------------------------------------------- zip
rm -f "$OUT"
if command -v zip >/dev/null 2>&1; then
  ( cd "$STAGE" && zip -qr "$OUT" handoff )
else
  ( cd "$STAGE" && python3 -m zipfile -c "$OUT" handoff )
fi

n_files=$(find "$PKG" -type f | wc -l)
n_skip=$(wc -l < "$SKIPPED")
echo "Wrote $OUT"
echo "  files: $n_files   skipped: $n_skip (see handoff/_handoff/skipped.txt)"
echo "  size:  $(du -h "$OUT" | cut -f1)"
