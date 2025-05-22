import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge,Timer

async def start_clocks(dut, w_per=7, r_per=13):
    cocotb.start_soon(Clock(dut.wclk, w_per, units="ns").start())
    cocotb.start_soon(Clock(dut.rclk, r_per, units="ns").start())

async def wr_clk_edge(dut):
    await RisingEdge(dut.wclk)

async def rd_clk_edge(dut):
    await RisingEdge(dut.rclk)

async def reset_dut(dut):
    await start_clocks(dut)

    dut.we.value = 0
    dut.re.value = 0
    dut.wdata.value = 0
    
    dut.reset_n.value = 1
    await wr_clk_edge(dut)
    
    dut.reset_n.value = 0
    for _ in range(3):
        await wr_clk_edge(dut)
    
    dut.reset_n.value = 1
    await wr_clk_edge(dut)
    await rd_clk_edge(dut)

async def write(dut, val):
    while dut.full.value:
        await wr_clk_edge(dut)

    dut.wdata.value = val
    dut.we.value = 1
    await wr_clk_edge(dut)

    dut.we.value = 0
    await wr_clk_edge(dut)

async def read(dut):
    while dut.empty.value:
        await rd_clk_edge(dut)

    dut.re.value = 1
    await rd_clk_edge(dut)
    data = int(dut.rdata.value)
    dut.re.value = 0
    await rd_clk_edge(dut)

    return data

# single write and single read
@cocotb.test()
async def test_single_wr_rd(dut):
    await reset_dut(dut)

    width = int(dut.WIDTH) if hasattr(dut, "WIDTH") else 8
    payload = random.randint(0, 2 ** width - 1)

    await write(dut, payload)
    for _ in range(3): # wait for synchronizer
        await FallingEdge(dut.rclk)
    assert not dut.empty.value, "FIFO should NOT be EMPTY"

    data = await read(dut)
    assert data == payload, f"Mismatch: wrote 0x{payload:X}, read 0x{data:X}"

    await rd_clk_edge(dut)
    assert dut.empty.value, "FIFO did not assert EMPTY at the end"

# fill up, cant write
@cocotb.test()
async def test_full_write(dut):
    await reset_dut(dut)
    depth = int(dut.DEPTH) if hasattr(dut, "DEPTH") else 4
    depth = 2 ** depth

    # fill up
    for i in range(depth):
        assert not bool(dut.full.value), f"FULL high too soon (i={i})"
        await write(dut, i)
    assert bool(dut.full.value), "FULL not asserted after filling up"

    # check that a write stalls
    extra_wr = cocotb.start_soon(write(dut, 0xDE))

    # free one up
    _ = await read(dut)
    for _ in range(2): # wait for synchronizer
        await FallingEdge(dut.rclk)
        assert not extra_wr.done(), "Write completed while FIFO still FULL"
    assert not bool(dut.full.value), "FULL stayed high after reading"

    await extra_wr

@cocotb.test()
async def test_empty_read(dut):
    await reset_dut(dut)
    assert bool(dut.empty.value), "EMPTY not high after reset"

    stalled_rd = cocotb.start_soon(read(dut))
    for _ in range(3):
        await rd_clk_edge(dut)
        assert not stalled_rd.done(), "Read finished while FIFO EMPTY"

    await write(dut, 0xA5)
    value = await stalled_rd
    assert value == 0xA5, f"Expected 0xA5, got 0x{value:X}"


