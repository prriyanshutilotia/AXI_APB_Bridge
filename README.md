# AXI-Lite to APB Bridge with UVM Verification

## 1. Project overview

This project implements a small **AXI-Lite to APB bridge** in SystemVerilog.
The bridge accepts a single AXI-Lite read or write transaction, converts it to
an APB transfer, waits for the APB slave response, and returns the matching
AXI response.

The repository also contains a UVM verification environment with directed,
random, error, wait-state, partial-write, and backpressure tests.

## 2. Interfaces used

### AXI-Lite side

The simplified AXI-Lite interface has these channels:

| Channel | Signals | Use |
| --- | --- | --- |
| Write address | `AWADDR`, `AWVALID`, `AWREADY` | Carries the write address |
| Write data | `WDATA`, `WSTRB`, `WVALID`, `WREADY` | Carries data and byte enables |
| Write response | `BRESP`, `BVALID`, `BREADY` | Returns write status |
| Read address | `ARADDR`, `ARVALID`, `ARREADY` | Carries the read address |
| Read data | `RDATA`, `RRESP`, `RVALID`, `RREADY` | Returns data and read status |

AXI write address and write data channels are independent. For this reason,
the bridge stores AW and W information separately until both are available.

### APB side

| Signal | Use |
| --- | --- |
| `PSEL` | Selects the APB slave |
| `PENABLE` | Changes from 0 in setup to 1 in access |
| `PADDR` | Address sent to APB slave |
| `PWRITE` | 1 for write and 0 for read |
| `PWDATA` / `PSTRB` | Write data and byte enables |
| `PREADY` | Completes the APB access; can insert wait states |
| `PRDATA` | Read data from APB slave |
| `PSLVERR` | APB error indication |

## 3. Bridge operation

### Write transaction

1. The bridge accepts `AW` and `W` handshakes in any order.
2. Once both are captured, it drives APB setup: `PSEL=1`, `PENABLE=0`.
3. On the next cycle, `PENABLE=1` starts APB access.
4. The bridge waits while `PREADY=0`.
5. When `PREADY=1`, it saves `PSLVERR`, deasserts APB controls, and drives
   AXI `BVALID`.
6. When the AXI master raises `BREADY`, the bridge returns to idle.

### Read transaction

1. The bridge accepts an `AR` handshake.
2. It creates APB setup and access phases in the same way as a write.
3. When `PREADY=1`, it stores `PRDATA` and `PSLVERR`.
4. It drives `RVALID`, `RDATA`, and `RRESP`.
5. When the AXI master raises `RREADY`, the bridge returns to idle.

`PSLVERR=1` is converted to AXI `SLVERR` (`2'b10`). Otherwise, the bridge
returns AXI `OKAY` (`2'b00`).

## 4. RTL state machine

The bridge FSM is implemented in `axi_to_apb_bridge.sv`.

| State | Purpose |
| --- | --- |
| `IDLE` | Accept AXI request channels and decide read or write |
| `APB_SETUP_WRITE` | Drive write setup with `PENABLE=0` |
| `APB_ACCESS_WRITE` | Wait for APB write completion |
| `WRITE_RESPONSE` | Return AXI B response |
| `APB_SETUP_READ` | Drive read setup with `PENABLE=0` |
| `APB_ACCESS_READ` | Wait for APB read completion |
| `READ_RESPONSE` | Return AXI R response |

The bridge is intentionally a **single-entry design**: it completes the
current transaction before accepting another transaction of the same type.
This keeps the RTL simple and is suitable for a basic AXI-Lite bridge project.

## 5. APB RAM slave model

`apb_ram_slave.sv` is a small simulation-only APB slave used by the testbench.

- It contains sixteen 32-bit memory locations.
- Addresses `0` through `14` are normal RAM addresses.
- Address `15` deliberately returns `PSLVERR=1`; it is used to test AXI error
  response handling.
- The lower two address bits choose 0 to 3 APB wait cycles. This gives the
  verification environment a predictable wait-state scenario.
- `PSTRB` controls which byte lanes are updated during a write.

## 6. UVM verification architecture

```text
Test / Sequence
       |
       v
  Sequencer --> Driver --> AXI-Lite pins --> DUT --> APB RAM
                      |                    |
                      v                    v
                 AXI Monitor            APB Monitor
                      \                    /
                       \                  /
                        v                v
                           Scoreboard
```

### UVM components

| File | Component | Responsibility |
| --- | --- | --- |
| `axi_apb_sequence_item.sv` | Transaction item | Stores request, response, delay and APB fields |
| `axi_apb_sequence.sv` | Sequences | Produces directed and random transactions |
| `axi_apb_sequencer.sv` | Sequencer | Passes sequence items to the driver |
| `axi_apb_driver.sv` | AXI driver | Drives AXI handshakes and response backpressure |
| `axi_apb_mon.sv` | AXI monitor | Reconstructs completed AXI transactions |
| `apb_mon.sv` | APB monitor | Captures APB setup, data, waits and response |
| `axi_apb_scoreboard.sv` | Scoreboard | Compares AXI result against APB result and memory model |
| `axi_apb_agent.sv` | AXI agent | Groups sequencer, driver and AXI monitor |
| `axi_apb_env.sv` | Environment | Connects monitors to the scoreboard |
| `axi_apb_test.sv` | Tests | Selects the sequence for each test class |
| `axi_apb_tb_top.sv` | Top module | Creates clock, reset, DUT, RAM and UVM configuration |

## 7. Scoreboard checks

The scoreboard receives one completed transaction from the AXI monitor and
one from the APB monitor. Transactions are compared in FIFO order because the
bridge handles one transfer at a time.

It checks:

- AXI request type matches APB `PWRITE` direction.
- AXI address matches APB address.
- AXI write data and `WSTRB` match APB write data and `PSTRB`.
- AXI read data matches APB read data.
- Address `15` produces `PSLVERR` and AXI `SLVERR`.
- Normal addresses produce AXI `OKAY`.
- Partial writes update only the byte lanes enabled by `WSTRB`.
- All AXI and APB monitor transactions are matched.

## 8. Tests

| UVM test name | Main purpose |
| --- | --- |
| `axi_apb_test` | Basic write followed by read |
| `axi_apb_aw_first_test` | AW channel arrives before W channel |
| `axi_apb_w_first_test` | W channel arrives before AW channel |
| `axi_apb_same_cycle_test` | AW and W arrive in the same clock cycle |
| `axi_apb_partial_write_test` | Tests all non-zero byte-strobe combinations |
| `axi_apb_wait_state_test` | Tests APB wait states from 0 to 3 cycles |
| `axi_apb_error_test` | Tests error address 15 and `SLVERR` responses |
| `axi_apb_backpressure_test` | Delays BREADY and RREADY |
| `axi_apb_random_test` | Runs 40 random read/write transactions |
| `axi_apb_coverage_test` | Runs all directed tests plus random traffic |

## 9. Assertions

Assertions are passive checks. They report an error if the protocol is used
incorrectly; they do not change DUT outputs.

| File | Checks |
| --- | --- |
| `axi_assert_checker.sv` | VALID remains asserted until READY; B/R response stays stable while stalled |
| `apb_assert_checker.sv` | APB setup is followed by access; access remains active until PREADY; PENABLE clears after completion |
| `bridge_assert_checker.sv` | No simultaneous read/write response and no premature APB abort |
| `bridge_bind_all.sv` | Binds bridge-specific assertions to the bridge module |

## 10. Functional coverage

`bridge_cov_collector.sv` contains covergroup `bridge_cg`. It records:

- AXI write-address, write-data and read-address handshakes
- APB read versus write completion
- Legal APB addresses and the error address
- APB wait-state values
- Write byte-strobe values
- Read/write direction crossed with address

The coverage test is meant to exercise the main protocol scenarios. A high
percentage is useful, but coverage should always be read together with the
test plan and scoreboard results.

## 11. Running the project in Questa

Open Questa in the project directory.

### Run all tests

```tcl
do run.do
```

This compiles the design, runs all ten UVM tests, prints scoreboard results,
and saves a waveform database for each test.

Expected result format:

```text
SCB REPORT: Total=<number> Pass=<number> Fail=0
TEST PASSED
```

### Open waveform and coverage GUI

```tcl
do wave.do
```

This runs `axi_apb_coverage_test`, automatically adds important AXI/APB/FSM
signals to the Wave window, prints functional coverage in the transcript, and
opens the Coverage window.

## 12. Important waveform signals

For a write, observe this order:

```text
AWVALID/AWREADY and WVALID/WREADY
        -> PSEL=1, PENABLE=0
        -> PSEL=1, PENABLE=1
        -> PREADY=1
        -> BVALID/BREADY
```

For a read, replace the write channels with AR and replace B response with
`RVALID`, `RREADY`, `RDATA`, and `RRESP`.

## 13. Scope and limitations

- Address width is 4 bits and data width is 32 bits.
- Only one transaction is handled at a time; there is no pipelining.
- The design models AXI-Lite style single-beat transfers only.
- The APB RAM model is included for verification and is not intended as a
  production memory macro.
- APB wait states and the error address are generated by the test RAM model.


