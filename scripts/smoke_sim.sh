#!/usr/bin/env bash
# In-container simulation smoke test runner (VHDL-2008 + ieee.float_pkg + cocotb/pytest/NumPy).
# Independent of synthesis tools and independent of EXP001 functional specifications.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

LOG_DIR="${LOG_DIR:-experiments/exp001/results/m1_smoke}"
ALLOW_NON_ARM64="${ALLOW_NON_ARM64:-0}"
mkdir -p "${LOG_DIR}"

ARCH="$(uname -m)"
if [ "${ARCH}" != "aarch64" ] && [ "${ARCH}" != "arm64" ] && [ "${ALLOW_NON_ARM64}" != "1" ]; then
  echo "FAIL: Expected native arm64/aarch64 container, observed '${ARCH}' (set ALLOW_NON_ARM64=1 to override)." >&2
  exit 1
fi

{
  echo "timestamp_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "uname=$(uname -srmo)"
  python3 --version
  pytest --version
  cocotb-config --version
  ghdl --version
  echo "--- pip freeze ---"
  pip freeze
} > "${LOG_DIR}/sim_versions.log" 2>&1

SUMMARY_FILE="${LOG_DIR}/sim_summary.txt"
: > "${SUMMARY_FILE}"
OVERALL_RC=0

run_sim_step() {
  local name="$1"
  local logfile="${LOG_DIR}/${name}.log"
  shift
  echo "[smoke_sim] Running ${name}..."
  set +e
  "$@" > "${logfile}" 2>&1
  local rc=$?
  set -e
  local status="PASS"
  if [ "${rc}" -ne 0 ]; then
    status="FAIL"
    OVERALL_RC=1
  fi
  printf "%-24s status=%-4s exit_code=%d log=%s\n" "${name}" "${status}" "${rc}" "${logfile}" | tee -a "${SUMMARY_FILE}"
  if [ "${rc}" -ne 0 ]; then
    cat "${logfile}" >&2
  fi
}

run_pure_ghdl() {
  local workdir="$1"
  local dut_vhd="$2"
  local tb_vhd="$3"
  local tb_top="$4"
  rm -rf "${workdir}"
  mkdir -p "${workdir}"
  ghdl -a --std=08 --workdir="${workdir}" "${dut_vhd}" "${tb_vhd}"
  ghdl -e --std=08 --workdir="${workdir}" "${tb_top}"
  ghdl -r --std=08 --workdir="${workdir}" "${tb_top}"
  rm -rf "${workdir}"
}

WORK_TMP="$(mktemp -d)"
trap 'rm -rf "${WORK_TMP}"' EXIT

run_sim_step "sim_ghdl_reg" \
  run_pure_ghdl "${WORK_TMP}/reg" "docker/smoke/smoke_reg.vhd" "docker/smoke/tb_smoke_reg.vhd" "tb_smoke_reg"

run_sim_step "sim_ghdl_fp32_add" \
  run_pure_ghdl "${WORK_TMP}/fp32" "docker/smoke/smoke_fp32_add.vhd" "docker/smoke/tb_smoke_fp32_add.vhd" "tb_smoke_fp32_add"

run_sim_step "sim_cocotb_reg" \
  pytest -v docker/smoke/test_smoke_cocotb.py -k "test_cocotb_smoke_reg"

run_sim_step "sim_cocotb_fp32_add" \
  pytest -v docker/smoke/test_smoke_cocotb.py -k "test_cocotb_smoke_fp32_add"

run_sim_step "verify_protected_post_sim" \
  python3 scripts/verify_protected_digests.py

exit "${OVERALL_RC}"
