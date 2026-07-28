````markdown
# Router

## Overview

The router is the core communication component of the Bidirectional Ring Network-on-Chip (NoC). It receives flits from the local Network Interface Controller (NIC) or neighboring routers, determines the appropriate output direction, resolves contention between multiple incoming requests, and forwards the flits to the next router or local destination.

The router is designed using a modular architecture consisting of input FIFOs, routing logic, an arbiter, a crossbar switch, and a credit manager.

---

## Router Architecture

```
                 +-----------------------+
                 |      Router Top       |
                 +-----------------------+
                           |
        +------------------+------------------+
        |                  |                  |
        ▼                  ▼                  ▼
   Local FIFO         CW Input FIFO     CCW Input FIFO
        |                  |                  |
        +------------------+------------------+
                           |
                           ▼
                   Routing Logic
                           |
                           ▼
                        Arbiter
                           |
                           ▼
                     Crossbar Switch
                           |
        +------------------+------------------+
        |                  |                  |
        ▼                  ▼                  ▼
    Local Output      CW Output        CCW Output
```

---

## Router Modules

| Module | Description |
|---------|-------------|
| `input_fifo.sv` | Temporarily stores incoming flits before routing. |
| `routing_logic.sv` | Determines the output direction based on the destination router. |
| `arbiter.sv` | Resolves conflicts when multiple inputs request the same output. |
| `crossbar.sv` | Connects the selected input to the appropriate output port. |
| `credit_manager.sv` | Tracks available buffer credits to prevent overflow. |
| `router_top.sv` | Integrates all router modules into a single unit. |

---

## Input Ports

The router accepts flits from three sources:

- Local Network Interface (NIC)
- Clockwise Neighbor
- Counter-Clockwise Neighbor

---

## Output Ports

The router forwards flits to:

- Local Network Interface (Destination Node)
- Clockwise Neighbor
- Counter-Clockwise Neighbor

---

## Router Operation

1. Incoming flits are stored in their respective input FIFOs.
2. The routing logic examines the destination field of each flit.
3. The shortest direction (Clockwise or Counter-Clockwise) is selected.
4. If multiple inputs request the same output, the arbiter grants access to one request.
5. The crossbar switch connects the selected input to the required output.
6. Credit information is checked before transmission to avoid buffer overflow.
7. The flit is forwarded to the next router or local destination.

---

## Routing Algorithm

The router implements **deterministic shortest-path routing**.

Based on the current router ID and destination router ID, the routing logic selects:

- Local output if the destination matches the current router.
- Clockwise output if the clockwise path is shorter.
- Counter-clockwise output otherwise.

This approach minimizes hop count while keeping routing logic simple.

---

## Flow Control

The router uses **credit-based flow control**.

Before transmitting a flit, the router checks whether the receiving router has available buffer space. Transmission proceeds only when sufficient credits are available, preventing packet loss due to buffer overflow.

---

## Verification

The router functionality is verified using a dedicated SystemVerilog testbench.

The testbench validates:

- FIFO read/write operations
- Routing decisions
- Arbitration logic
- Crossbar switching
- Credit management
- End-to-end flit forwarding

---

## Files

```text
rtl/router/
├── input_fifo.sv
├── routing_logic.sv
├── arbiter.sv
├── crossbar.sv
├── credit_manager.sv
└── router_top.sv
```

---

## Future Enhancements

- Adaptive routing
- Virtual channels
- Round-robin arbitration
- Priority-based scheduling
- Error detection support
- Performance monitoring counters
````

