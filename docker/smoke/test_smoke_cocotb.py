"""pytest entry points running GHDL + cocotb smoke tests for smoke_reg and smoke_fp32_add."""

from __future__ import annotations

import os
from pathlib import Path

try:
    from cocotb.runner import get_runner
except ImportError:  # pragma: no cover - cocotb >= 2.0 fallback
    from cocotb_tools.runner import get_runner

SMOKE_DIR = Path(__file__).resolve().parent


def _run_ghdl_cocotb(vhdl_file: str, toplevel: str, test_module: str, build_dir: Path) -> None:
    runner = get_runner("ghdl")
    runner.build(
        vhdl_sources=[SMOKE_DIR / vhdl_file],
        hdl_toplevel=toplevel,
        build_args=["--std=08"],
        build_dir=build_dir,
        always=True,
    )
    extra_env = {"PYTHONPATH": f"{SMOKE_DIR}{os.pathsep}{os.environ.get('PYTHONPATH', '')}"}
    runner.test(
        hdl_toplevel=toplevel,
        test_module=test_module,
        test_args=["--std=08"],
        build_dir=build_dir,
        test_dir=build_dir,
        extra_env=extra_env,
    )


def test_cocotb_smoke_reg(tmp_path: Path) -> None:
    _run_ghdl_cocotb(
        vhdl_file="smoke_reg.vhd",
        toplevel="smoke_reg",
        test_module="cocotb_smoke_reg",
        build_dir=tmp_path / "sim_build_reg",
    )


def test_cocotb_smoke_fp32_add(tmp_path: Path) -> None:
    _run_ghdl_cocotb(
        vhdl_file="smoke_fp32_add.vhd",
        toplevel="smoke_fp32_add",
        test_module="cocotb_smoke_fp32",
        build_dir=tmp_path / "sim_build_fp32",
    )
