#!/usr/bin/env bash
# Host-side controller for native linux/arm64 Docker build, smoke tests, and interactive shell.
# Do NOT execute on GCP sandbox where Docker is unavailable/prohibited.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

ACTION="${1:-}"
IMAGE_NAME="${IMAGE_NAME:-fpga_ai-toolchain:m1-arm64}"
DOCKER_PLATFORM="${DOCKER_PLATFORM:-linux/arm64}"
DOCKER_TARGET="${DOCKER_TARGET:-full}"
LOG_DIR="${LOG_DIR:-experiments/exp001/results/m1_smoke}"

usage() {
  cat <<EOF
Usage: bash scripts/docker_ctl.sh <build|smoke-sim|smoke-synth|smoke|shell>

Environment variables:
  IMAGE_NAME       Docker image tag (default: ${IMAGE_NAME})
  DOCKER_PLATFORM  Target platform (default: ${DOCKER_PLATFORM})
  DOCKER_TARGET    Dockerfile stage for build: full | sim (default: ${DOCKER_TARGET})
  LOG_DIR          Repo-relative directory for logs & exit codes (default: ${LOG_DIR})
EOF
}

record_exit_code() {
  local step="$1"
  local rc="$2"
  local ts
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  mkdir -p "${LOG_DIR}"
  printf "%s\t%s\texit_code=%d\n" "${ts}" "${step}" "${rc}" >> "${LOG_DIR}/exit_codes.log"
}

run_logged() {
  local step="$1"
  local logfile="$2"
  shift 2
  mkdir -p "${LOG_DIR}"
  set +e
  "$@" 2>&1 | tee "${logfile}"
  local rc="${PIPESTATUS[0]}"
  set -e
  record_exit_code "${step}" "${rc}"
  return "${rc}"
}

do_build() {
  local logfile="${LOG_DIR}/docker_build_${DOCKER_TARGET}.log"
  echo "[docker_ctl] Building ${IMAGE_NAME} (platform=${DOCKER_PLATFORM}, target=${DOCKER_TARGET})..."
  run_logged "docker_build_${DOCKER_TARGET}" "${logfile}" \
    docker build \
      --platform "${DOCKER_PLATFORM}" \
      --target "${DOCKER_TARGET}" \
      -t "${IMAGE_NAME}" \
      -f docker/Dockerfile \
      .
}

do_smoke_sim() {
  local logfile="${LOG_DIR}/host_smoke_sim.log"
  echo "[docker_ctl] Running simulation smoke suite in ${IMAGE_NAME} (${DOCKER_PLATFORM})..."
  run_logged "smoke_sim" "${logfile}" \
    docker run --rm \
      --platform "${DOCKER_PLATFORM}" \
      -v "${REPO_ROOT}:/workspace" \
      -w /workspace \
      -e "LOG_DIR=${LOG_DIR}" \
      "${IMAGE_NAME}" \
      bash /workspace/scripts/smoke_sim.sh
}

do_smoke_synth() {
  local logfile="${LOG_DIR}/host_smoke_synth.log"
  echo "[docker_ctl] Running synthesis smoke suite in ${IMAGE_NAME} (${DOCKER_PLATFORM})..."
  run_logged "smoke_synth" "${logfile}" \
    docker run --rm \
      --platform "${DOCKER_PLATFORM}" \
      -v "${REPO_ROOT}:/workspace" \
      -w /workspace \
      -e "LOG_DIR=${LOG_DIR}" \
      "${IMAGE_NAME}" \
      bash /workspace/scripts/smoke_synth.sh
}

do_smoke_all() {
  mkdir -p "${LOG_DIR}"
  local sim_rc=0
  local synth_rc=0

  set +e
  do_smoke_sim
  sim_rc=$?
  do_smoke_synth
  synth_rc=$?
  set -e

  {
    echo "=== M1 Combined Smoke Summary ==="
    echo "smoke-sim   exit_code=${sim_rc}"
    echo "smoke-synth exit_code=${synth_rc}"
  } | tee "${LOG_DIR}/smoke_combined_summary.txt"

  if [ "${sim_rc}" -ne 0 ] || [ "${synth_rc}" -ne 0 ]; then
    return 1
  fi
  return 0
}

do_shell() {
  exec docker run --rm -it \
    --platform "${DOCKER_PLATFORM}" \
    -v "${REPO_ROOT}:/workspace" \
    -w /workspace \
    "${IMAGE_NAME}" \
    /bin/bash
}

case "${ACTION}" in
  build)       do_build ;;
  smoke-sim)   do_smoke_sim ;;
  smoke-synth) do_smoke_synth ;;
  smoke)       do_smoke_all ;;
  shell)       do_shell ;;
  -h|--help|"")
    usage
    [ -z "${ACTION}" ] && exit 1 || exit 0
    ;;
  *)
    echo "ERROR: Unknown action '${ACTION}'" >&2
    usage >&2
    exit 2
    ;;
esac
