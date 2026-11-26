#!/usr/bin/env bash
set -u
set -o pipefail

# Run from the fpga_ai repository root. No installations or external output files.
root=$(pwd -P)
repo=$(git rev-parse --show-toplevel 2>/dev/null) || { echo 'Run from the cloned fpga_ai repository root.' >&2; exit 1; }
repo=$(cd "$repo" && pwd -P)
if [[ "$root" != "$repo" || ! -f AGENTS.md || ! -f Makefile || ! -f docker/Dockerfile ]]; then
    echo 'Run from the fpga_ai repository root.' >&2; exit 1
fi
report="$root/fpga_ai_host_report.txt"
# Refuse existing files (including symlinks) to prevent accidental overwrite.
if [[ -e "$report" || -L "$report" ]]; then
    echo 'Report already exists. Rename or remove it within the project before rerunning.' >&2; exit 1
fi
set -o noclobber
exec 3> "$report" || exit 1
set +o noclobber
# Disable Python bytecode generation and Homebrew auto-update.
export PYTHONDONTWRITEBYTECODE=1 HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1
export GIT_OPTIONAL_LOCKS=0
section() { printf '\n========================================\n %s\n========================================\n' "$1"; }
probe() {
    local name="$1"; shift
    if command -v "$name" >/dev/null 2>&1; then
        printf '\n[FOUND] %s: %s\n' "$name" "$(command -v "$name")"
        "$name" "$@" 2>&1 | sed -n '1,4p'
    else
        printf '\n[MISSING] %s\n' "$name"
    fi
}
{
section SYSTEM
sw_vers
uname -m
sysctl -n machdep.cpu.brand_string
printf 'Logical CPUs: '; sysctl -n hw.ncpu
printf 'Physical CPUs: '; sysctl -n hw.physicalcpu
sysctl -n hw.memsize | awk '{printf "RAM: %.0f GiB\n", $1/1073741824}'
df -h .
section HOMEBREW
probe brew --version
if command -v brew >/dev/null 2>&1; then brew --prefix; fi
section 'DEVELOPMENT TOOLS'
probe git --version
probe make --version
probe cmake --version
probe clang --version
probe gcc --version
probe python3 --version
probe pip3 --version
probe uv --version
probe code --version
printf '\nXcode Command Line Tools:\n'; xcode-select -p 2>&1
section 'CONTAINER TOOLS'
probe docker --version
probe colima --version
probe podman --version
probe orb --version
if command -v docker >/dev/null 2>&1; then
    printf '\nDocker contexts:\n'; docker context ls 2>&1
    printf '\nDocker Buildx:\n'; docker buildx version 2>&1
    printf '\nDocker engine:\n'; docker info --format 'OS={{.OSType}} ARCH={{.Architecture}} CPUs={{.NCPU}} RAM={{.MemTotal}}' 2>&1
    printf '\nDocker Compose:\n'; docker compose version 2>&1
fi
section 'NATIVE FPGA TOOLS (OPTIONAL)'
probe ghdl --version
probe nvc --version
probe yosys -V
probe verilator --version
# Avoid launching GTKWave (a GUI application).
if command -v gtkwave >/dev/null 2>&1; then printf '[FOUND] gtkwave: %s\n' "$(command -v gtkwave)"; else echo '[MISSING] gtkwave'; fi
section 'PYTHON PACKAGES (OPTIONAL)'
if command -v python3 >/dev/null 2>&1; then
python3 -B - <<'PY'
from importlib.metadata import version, PackageNotFoundError
for package in ('numpy', 'scipy', 'pytest', 'cocotb', 'pyyaml'):
    try:
        print(f'[FOUND] {package}: {version(package)}')
    except PackageNotFoundError:
        print(f'[MISSING] {package}')
PY
fi
section 'FPGA_AI REPOSITORY'
pwd
git branch --show-current
git log -5 --oneline
git status --short
for path in AGENTS.md README.md Makefile .agents context docker/Dockerfile docker/requirements.txt scripts/docker_ctl.sh scripts/verify_protected_digests.py research/STATUS.md research/TODO.md; do
    if [[ -e "$path" ]]; then printf '[FOUND] %s\n' "$path"; else printf '[MISSING] %s\n' "$path"; fi
done
section 'END OF REPORT'
} 2>&1 | tee /dev/fd/3
status=$?
exec 3>&-
printf '\nReport: %s\n' "$report"
exit "$status"
