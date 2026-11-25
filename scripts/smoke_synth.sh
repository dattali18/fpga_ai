#!/usr/bin/env bash
# In-container generic synthesis smoke test runner (VHDL-2008 + ieee.float_pkg via GHDL/Yosys).
# Exercises smoke_reg and smoke_fp32_add separately without suppressing failures.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

LOG_DIR="${LOG_DIR:-experiments/exp001/results/m1_smoke}"
SYNTH_FRONTEND_MODE="${SYNTH_FRONTEND_MODE:-auto}"
ALLOW_NON_ARM64="${ALLOW_NON_ARM64:-0}"
mkdir -p "${LOG_DIR}"

ARCH="$(uname -m)"
if [ "${ARCH}" != "aarch64" ] && [ "${ARCH}" != "arm64" ] && [ "${ALLOW_NON_ARM64}" != "1" ]; then
  echo "FAIL: Expected native arm64/aarch64 container, observed '${ARCH}' (set ALLOW_NON_ARM64=1 to override)." >&2
  exit 1
fi

if ! command -v yosys >/dev/null 2>&1; then
  echo "FAIL: yosys binary is absent in container (did you build --target sim only?)." >&2
  exit 1
fi

PLUGIN_AVAILABLE=0
if yosys -m ghdl -p "help ghdl" >/dev/null 2>&1; then
  PLUGIN_AVAILABLE=1
fi

case "${SYNTH_FRONTEND_MODE}" in
  plugin)
    SELECTED_MODE="plugin"
    ;;
  ghdl-verilog)
    SELECTED_MODE="ghdl-verilog"
    ;;
  auto)
    if [ "${PLUGIN_AVAILABLE}" -eq 1 ]; then
      SELECTED_MODE="plugin"
    else
      SELECTED_MODE="ghdl-verilog"
    fi
    ;;
  *)
    echo "FAIL: Invalid SYNTH_FRONTEND_MODE='${SYNTH_FRONTEND_MODE}' (expected auto|plugin|ghdl-verilog)." >&2
    exit 2
    ;;
esac

{
  echo "timestamp_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "uname=$(uname -srmo)"
  echo "yosys_ghdl_plugin_available=${PLUGIN_AVAILABLE}"
  echo "selected_synth_frontend_mode=${SELECTED_MODE}"
  if [ -f /opt/fpga_ai/synth_plugin_status.txt ]; then
    cat /opt/fpga_ai/synth_plugin_status.txt
  fi
  yosys -V
  ghdl --version
} > "${LOG_DIR}/synth_versions.log" 2>&1

SUMMARY_FILE="${LOG_DIR}/synth_summary.txt"
: > "${SUMMARY_FILE}"
OVERALL_RC=0

WORK_TMP="$(mktemp -d)"
trap 'rm -rf "${WORK_TMP}"' EXIT

synth_one_entity() {
  local vhd_path="$1"
  local top_name="$2"
  local work_sub="${WORK_TMP}/${top_name}"
  mkdir -p "${work_sub}"

  if [ "${SELECTED_MODE}" = "plugin" ]; then
    yosys -m ghdl -p \
      "ghdl --std=08 --workdir=${work_sub} ${vhd_path} -e ${top_name}; hierarchy -check -top ${top_name}; proc; opt; memory; opt; check -assert; stat"
  else
    local verilog_out="${work_sub}/${top_name}_synth.v"
    ghdl --synth --std=08 --workdir="${work_sub}" --out=verilog "${vhd_path}" -e "${top_name}" > "${verilog_out}"
    yosys -p \
      "read_verilog ${verilog_out}; hierarchy -check -top ${top_name}; proc; opt; memory; opt; check -assert; stat"
  fi
}

run_synth_step() {
  local name="$1"
  local logfile="${LOG_DIR}/${name}.log"
  shift
  echo "[smoke_synth] Running ${name} (mode=${SELECTED_MODE})..."
  set +e
  "$@" > "${logfile}" 2>&1
  local rc=$?
  set -e
  local status="PASS"
  if [ "${rc}" -ne 0 ]; then
    status="FAIL"
    OVERALL_RC=1
  fi
  printf "%-24s mode=%-12s status=%-4s exit_code=%d log=%s\n" \
    "${name}" "${SELECTED_MODE}" "${status}" "${rc}" "${logfile}" | tee -a "${SUMMARY_FILE}"
  if [ "${rc}" -ne 0 ]; then
    cat "${logfile}" >&2
  fi
}

run_synth_step "synth_smoke_reg" \
  synth_one_entity "docker/smoke/smoke_reg.vhd" "smoke_reg"

run_synth_step "synth_smoke_fp32_add" \
  synth_one_entity "docker/smoke/smoke_fp32_add.vhd" "smoke_fp32_add"

run_synth_step "verify_protected_post_synth" \
  python3 scripts/verify_protected_digests.py

exit "${OVERALL_RC}"
