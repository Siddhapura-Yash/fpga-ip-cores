# AXI4-Lite Slave with Independent Write Channels

## Overview

A configurable AXI4-Lite slave supporting memory-mapped register read and write transactions, independent write-address and write-data channel handshaking, and byte-level write control.

## Features

- 32-bit configurable address and data widths.
- Configurable base address and register count.
- Independent write-address (AW) and write-data (W) channel handshaking.
- Write response and read response channel handling.
- Byte-level write support using `WSTRB`.
- Configurable register read/write permissions.
- Read and write error status flags.

## Write Channel Handling

The AXI4-Lite write-address and write-data channels are handled independently.

The slave does not require the address and data channels to arrive in the same clock cycle.

Two possible sequences are supported:

1. **Address first:** The slave accepts the write address and stores it internally until the write data arrives.
2. **Data first:** The slave accepts the write data and strobe information and stores them internally until the write address arrives.

Once both address and data have been received, the slave performs the register write and generates the write response.

This allows independent handshaking of the AW and W channels.

## Write Strobe Support

The slave supports byte-level write control through the 4-bit `WSTRB` signal.

| WSTRB | Description |
|---|---|
| `4'b0001` | Write byte 0 |
| `4'b0010` | Write byte 1 |
| `4'b0100` | Write byte 2 |
| `4'b1000` | Write byte 3 |
| `4'b0011` | Write lower 16 bits |
| `4'b1100` | Write upper 16 bits |
| `4'b0101` | Write bytes 0 and 2 |
| `4'b1111` | Write all 32 bits |

Unselected byte lanes retain their previous values during partial writes.

## Register Access Control

Register access is controlled using address validation and register indices.

- **Readable:** Register indices 0–26.
- **Writable:** Register indices 0, 2, and 3–18.
- **Read-only:** Register indices 1 and 19–26.
- **Reserved:** Register indices 27–31.
- Unaligned and out-of-range accesses are rejected.

**Read validation:**

```systemverilog
assign read_addr_valid =
    (ARADDR_i[ADDR_WIDTH-1:7] == BASE_ADDRESS[ADDR_WIDTH-1:7]) &&
    (ARADDR_i[1:0] == 2'b00) &&
    (ARADDR_i[6:2] <= 5'd26);
```

**Write permission:**

```systemverilog
assign write_allowed =
    write_addr_valid &&
    ((write_index == 5'd0) ||
     (write_index == 5'd2) ||
     ((write_index >= 5'd3) && (write_index <= 5'd18)));
```

Register access permissions can be modified by changing these conditions.

## Address Validation

The slave validates incoming addresses using the following conditions:

- Address must belong to the configured base address region.
- Register index must fall within the supported range.
- Write access must satisfy the configured register permissions.

The base address and register count are configurable through module parameters.

## Error Handling

The design includes separate read and write error flags.

**Write Error (`write_error_bit`)**
- Goes HIGH when a write transaction attempts to access an invalid address or a restricted register.
- Clears after the next valid write transaction.

**Read Error (`read_error_bit`)**
- Goes HIGH when a read transaction attempts to access an invalid address.
- Clears after the next valid read transaction.

### AXI Response Codes

| Response | Value | Description |
|---|---|---|
| OKAY | `2'b00` | Successful transaction |
| SLVERR | `2'b10` | Write to a restricted register |
| DECERR | `2'b11` | Invalid or out-of-range address |



## Configurable Parameters

| Parameter | Default Value | Description |
|---|---|---|
| `ADDR_WIDTH` | `32` | Address bus width |
| `DATA_WIDTH` | `32` | Data bus width |
| `NO_OF_REG` | `32` | Number of implemented register array entries |
| `BASE_ADDRESS` | `32'h400F8000` | Base address of the slave |


## Current Limitations

- `AWPROT_i` and `ARPROT_i` protection attributes are not currently used.
- Read and write transactions are handled sequentially by the FSM, simultaneous read/write execution is not supported.
