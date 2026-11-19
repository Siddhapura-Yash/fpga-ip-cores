# Synchronous FIFO IP

A parameterized synchronous FIFO implemented in SystemVerilog, functionally equivalent to the Verilog Sync FIFO IP, with fewer status flags.

## Parameters

| Parameter | Description |
|---|---|
| `DATA_WIDTH` | Width of each data word |
| `DEPTH` | FIFO storage depth |
| `PTR_WIDTH` | Pointer width, default `$clog2(DEPTH)` |

## Features
- Standard and FWFT operating modes.
- Read and write enable control.
- Data count, full and empty flags.
- Read valid, overflow and underflow flags.
- Simplified status flag implementation compared to the Verilog version.

## Verification
Functionally verified using a SystemVerilog testbench.
