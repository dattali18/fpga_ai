"""cocotb coroutine smoke test for smoke_reg.vhd."""

from __future__ import annotations

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge


@cocotb.test()
async def test_smoke_reg_passthrough(dut) -> None:
    dut.clk.value = 0

    dut.rst.value = 1
    dut.d_in.value = 0xAA
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start(start_high=False))
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    assert int(dut.q_out.value) == 0x00, f"Reset failed: got 0x{int(dut.q_out.value):02x}"

    dut.rst.value = 0
    for vec in (0x00, 0x55, 0xA5, 0xFF, 0x3C):
        dut.d_in.value = vec
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        got = int(dut.q_out.value)
        assert got == vec, f"Mismatch: expected 0x{vec:02x}, got 0x{got:02x}"
