# Configurable SPI Master-Slave RTL Design

A configurable Verilog RTL implementation of an SPI Master and register-based SPI Slave supporting all four SPI modes, 8-bit and 16-bit data transfers, configurable SPI clock frequency, error handling, and self-checking verification.

## 1. Features

- SPI Modes 0, 1, 2, and 3
- 8-bit and 16-bit data operations
- Register-based read/write transactions
- Configurable SPI clock frequency
- Full-duplex SPI communication
- Active-low chip select
- Busy, done, and error indication
- Timeout detection
- CS timing validation
- Invalid-address and invalid-operation detection
- Back-to-back transactions

---

## 2. Repository Structure

```text
configurable-spi-master-slave/
│
├── README.md
│
├── rtl/
│   ├── spi_master.v
│   └── spi_slave.v
│
├── tb/
│   └── spi_top_tb.v
│
└── results/
    ├── simulation_waveforms/
    │   ├── spi_mode_0/
    │   ├── spi_mode_1/
    │   ├── spi_mode_2/
    │   └── spi_mode_3/
    │
    ├── simulation.log
    │
    ├── spi_master_synthesis_report/
    │   ├── Synthesis_in_VIVADO
    │   └── Synthesis_in_Cadence_Genus
    │
    └── spi_slave_synthesis_report/
        ├── Synthesis_in_VIVADO
        └── Synthesis_in_Cadence_Genus
```

---

## 3. System Configuration

| Parameter                   |       Configuration      |
|-----------------------------|--------------------------|
| System Clock                |          50 MHz          | 
| Reset                       |        Active Low        |
| SPI Modes                   |            0–3           |
| Data Width                  |       8 / 16 bits        |
| SPI Clock Range             | 1 Hz to System Clock / 4 (eg. for system clock=50Mhz the maximum spi clock frequency is 50Mhz/4 ie. 12.5Mhz) |
| Chip Select                 |        Active Low        |
| Communication               |        Full Duplex       |

The system clock is configurable before synthesis.

---

## 4. SPI Modes

|  Mode | CPOL | CPHA | Clock Idle | Sample Edge | Change Edge |
|-------|------|------|------------|-------------|-------------|
|   0   |  0   |   0  |    Low     |   Rising    |   Falling   |
|   1   |  0   |   1  |    Low     |   Falling   |   Rising    |
|   2   |  1   |   0  |    High    |   Falling   |   Rising    |
|   3   |  1   |   1  |    High    |   Rising    |   Falling   |

The Master uses mode-specific transfer states (`TRANS_M0`–`TRANS_M3`) to implement the required clock and data timing.

---

## 5. Transaction Format

Each transaction contains:

```text
Operation bit + 7-bit Register Address + Data
```

### 8-bit Data Operation

```text
[ Read/Write | Register Address | Data   ]
[     1      |      7 bits      | 8 bits ]
```

Total: **16 SPI clock cycles**

### 16-bit Data Operation

```text
[ Read/Write | Register Address | Data    ]
[     1      |      7 bits      | 16 bits ]
```

Total: **24 SPI clock cycles**

For a read, the Master transmits dummy data during the data phase and receives the selected register value from the Slave on `miso`.

---

## 6. Master Interface

| Signal | Description |
|---|---|
| `clk` | 50 MHz system clock (Parameterised)|
| `rst` | Active-low reset |
| `start` | Starts a transaction |
| `spi_mode[1:0]` | SPI mode selection 
                    2'b00 → Mode 0
                    2'b01 → Mode 1
                    2'b10 → Mode 2
                    2'b11 → Mode 3|
| `bit_width` | `0` = 8-bit, `1` = 16-bit |
| `s_clk_freq[24:0]` | Requested SPI clock frequency |
| `data_to_slave[15:0]` | Write data |
| `write` | Read/write selection |
| `slave_addr[6:0]` | Register address |
| `busy` | Transaction active |
| `done` | Transaction complete |
| `err_e[2:0]` | Error code |
| `data_from_slave[15:0]` | Received data |

### Mode Encoding

```text
2'b00 → Mode 0
2'b01 → Mode 1
2'b10 → Mode 2
2'b11 → Mode 3
```

Configuration inputs are captured in the Master IDLE state when `start` is asserted. A new `start` request is not accepted while `busy` is active.

---

## 7. SPI Clock Generation

The SPI clock is derived from the 50 MHz system clock using the requested `s_clk_freq`.

The maximum supported SPI frequency is:

```text
F_SPI(max) = F_SYS / 4
           = 50 MHz / 4
           = 12.5 MHz
```

A requested frequency of `0 Hz` is treated as an invalid configuration.

The generated SPI clock uses the appropriate idle level and edge relationship for the selected CPOL/CPHA mode.

---

## 8. Chip-Select Timing

The Master controls the active-low `cs` signal.

The testbench defines the following timing parameters:

```text
cs_high_ns
cs_negedge_to_clk_edge_ns
clk_edge_to_cs_high_ns
```

These represent:

1. Minimum CS high time between transactions
2. Delay from CS assertion to the first SPI clock edge
3. Delay from the final SPI clock edge to CS deassertion

CS timing is also monitored for incorrect deassertion conditions.

---

## 9. Timeout Calculation

The timeout mechanism prevents a transaction from remaining active indefinitely.

For the implemented transaction structure:

```text
data_count = 7   for 8-bit data
data_count = 15  for 16-bit data
```

The timeout threshold is calculated from the transaction length and SPI clock timing:

```text
threshold_timeout =
    3 × (data_count + 9) × 2 × half_count_sclk
```

where:

- `data_count` represents the number of data bits minus one.
- `half_count_sclk` represents the system-clock count for one half-period of the generated SPI clock.
- `(data_count + 9)` accounts for the operation bit, address bits, data bits, and transaction overhead.
- The factor `2` converts SPI half-cycles to complete clock cycles.
- The factor `3` provides timeout margin.

The exact numerical threshold for a particular transaction therefore depends on the selected data width and SPI clock frequency.

---

## 10. Error Detection

The Master reports errors through `err_e[2:0]`.

| Code | Error | Priority |
|---|---|---:|
| `000` | No error | — |
| `001` | Timeout | 2 |
| `010` | Invalid register address | 3 |
| `011` | Incorrect CS high | 1 |
| `100` | Invalid operation | 4 |
| `101` | SPI clock frequency = 0 | 5 |

When multiple conditions are detected, the defined priority determines the reported error.

---

## 11. SPI Slave

The Slave provides a register-based SPI peripheral.

### Interface

```text
Inputs:
    clk
    rst
    bit_width
    spi_mode[1:0]
    cs
    sclk
    mosi

Outputs:
    miso
    done
```

`clk`, `rst`, `spi_mode`, and `bit_width` are driven by the testbench. The Master and Slave therefore receive the same configuration and timing-control signals from the testbench.

The SPI communication signals between Master and Slave are:

```text
cs
sclk
mosi
miso
```

---

## 12. Slave Register Map

| Address | Register | Access | Description |
|---|---|---|---|
| `0x00` | Device ID | RO | Communication verification |
| `0x01` | Control | R/W | Control register |
| `0x02` | Status | R/W | Status register |
| `0x03` | Data | R/W | Data register |

Device ID:

```text
16'hABCD
```

The Device ID register provides a simple mechanism for verifying Master-Slave communication.

---

## 13. Read and Write Operations

### Read

```text
Master → Slave : Read/Write bit + Register Address + Dummy Data
Slave  → Master: Selected Register Data
```

The Slave decodes the address and shifts the selected register value onto `miso`. The Master samples the data according to the selected SPI mode.

### Write

```text
Master → Slave : Write bit + Register Address + Write Data
```

The Slave decodes the address and updates the corresponding writable register.

---

## 14. Verification Environment

The verification environment is implemented in:

```text
tb/spi_top_tb.v
```

The testbench generates stimulus, drives Master and Slave configuration, monitors transactions, checks expected results, and logs failures.

### Main Test Cases

| Category | Tests |
|----------|-------|
| SPI Modes | Modes 0, 1, 2, 3 |
| Data Width | 8-bit, 16-bit |
| Operations | Read, Write |
| Clock | Multiple divider/frequency settings |
| Transactions | Back-to-back transfers |
| Control | Start while busy |
| Reset | Reset during transaction |
| Address | Invalid register address |
| Timing | Incorrect CS / clock count |
| Error | Timeout, invalid operation, zero frequency |
| Random | Randomized transactions |

The core waveform demonstrations can be organized as four cases per SPI mode:

1. 8-bit write
2. 8-bit read
3. 16-bit write
4. 16-bit read

---

## 15. Automated Checking

The testbench checks:

- Operation bit
- Register address
- Returned data
- Register updates
- Transaction completion
- Busy behavior
- Error code
- SPI mode timing
- Back-to-back operation

Results are written to:

```text
results/simulation.log
```

---

## 17. Synthesis Results

### Vivado — SPI Master

| Metric | Result |
|---|---:|
| LUTs | TBD |
| Flip-Flops | TBD |
| DSPs | TBD |
| BRAMs | TBD |
| I/O | TBD |
| WNS | TBD |
| Fmax | TBD |
| Power | TBD |

### Vivado — SPI Slave

| Metric | Result |
|---|---:|
| LUTs | TBD |
| Flip-Flops | TBD |
| DSPs | TBD |
| BRAMs | TBD |
| I/O | TBD |
| WNS | TBD |
| Fmax | TBD |
| Power | TBD |

### Cadence Genus — SPI Master

| Metric | Result |
|---|---:|
| Combinational Area | TBD |
| Sequential Area | TBD |
| Total Cell Area | TBD |
| Critical Path Delay | TBD |
| Slack | TBD |
| Total Power | TBD |

### Cadence Genus — SPI Slave

| Metric | Result |
|---|---:|
| Combinational Area | TBD |
| Sequential Area | TBD |
| Total Cell Area | TBD |
| Critical Path Delay | TBD |
| Slack | TBD |
| Total Power | TBD |

---

## 18. Tools

- Xilinx Vivado
- Cadence Genus

---


## 20. Future Improvements

- SystemVerilog Assertions
- Functional coverage
- UVM-based verification
- Formal protocol verification
- FIFO-based buffering
- Multiple SPI Slave support
- AXI/APB interface integration

---

## 21. Author

**Sanjay**  
B.Tech Electrical and Electronics Engineering, VIT Vellore (final-year)

Interests: RTL Design, Digital VLSI, FPGA Design, ASIC Design, Computer Architecture, and Hardware Verification.
