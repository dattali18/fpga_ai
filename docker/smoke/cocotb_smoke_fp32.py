"""cocotb + NumPy binary32 coroutine smoke test for smoke_fp32_add.vhd."""

from __future__ import annotations

import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge


def f32_to_u32(val: np.float32) -> int:
    return int(np.float32(val).view(np.uint32))


@cocotb.test()
async def test_smoke_fp32_adder(dut) -> None:
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    dut.rst.value = 1
    dut.a_bits.value = f32_to_u32(np.float32(1.5))
    dut.b_bits.value = f32_to_u32(np.float32(2.25))
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    assert int(dut.y_bits.value) == 0, f"Reset failed: got 0x{int(dut.y_bits.value):08x}"

    dut.rst.value = 0
    pairs = [
        (np.float32(1.5), np.float32(2.25)),
        (np.float32(-0.5), np.float32(0.5)),
        (np.float32(1.25), np.float32(-3.5)),
        (np.float32(12.5), np.float32(0.125)),
        (np.float32(1e-6), np.float32(2.5e-6)),
    ]
    for a_val, b_val in pairs:
        exp_val = np.float32(a_val + b_val)
        exp_u32 = f32_to_u32(exp_val)

        dut.a_bits.value = f32_to_u32(a_val)
        dut.b_bits.value = f32_to_u32(b_val)
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)

        got_u32 = int(dut.y_bits.value)
        got_f32 = np.uint32(got_u32).view(np.float32)
        assert got_u32 == exp_u32, (
            f"FP32 sum mismatch for {a_val} + {b_val}: "
            f"expected {exp_val} (0x{exp_u32:08x}), got {got_f32} (0x{got_u32:08x})"
        )
