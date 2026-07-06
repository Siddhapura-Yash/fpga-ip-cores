# fpga-ip-cores

a collection of verilog rtl modules and ip cores, built while working on fpga projects. kept here as a reference and portfolio of rtl work.

plain, no vendor-specific primitives unless a module says so.

---

## structure

```
fpga-ip-cores/
├── flow_control/      -> ready/valid handshake, backpressure handling
├── protocols/         -> uart, spi, i2c, axi-stream, etc.
├── memory/            -> fifos, bram wrappers, line buffers
├── arithmetic/        -> mac units, fixed point ops
├── docs/              -> write-ups explaining the concepts
└── README.md
```

---

## conventions

- comments use `/* */`, not `//`
- widths/depths are parameterized where it makes sense
- reset is active-low, (`rst_n`), unless stated otherwise. some older modules may not follow this naming exactly - check each module's port list. going forward, rst_n is used consistently.
- each module has a small testbench sketch at the bottom

---

## why

these modules come from real FPGA projects and experiments rather than being written only to populate a repository.

issues, suggestions, and improvements are welcome.

## license

Open-source RTL collection for learning, experimentation, and hardware development.
