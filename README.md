# UVM Virtual Sequencer Usage Pattern

This repository provides a focused, self-contained implementation of the **UVM Virtual Sequencer** pattern. This is a critical technique for managing and coordinating stimulus in complex testbenches with multiple, independent agents and interfaces.

---

### Project Overview

When a Design-Under-Test (DUT) has more than one interface (e.g., a processor with separate instruction and data buses), a single test often needs to coordinate stimulus across all of them. A Virtual Sequencer is the standard UVM mechanism for achieving this. It acts as a master controller that directs the individual sequencers within each agent.



This project demonstrates this pattern with a simple DUT containing two independent modules (an `adder` and a `multiplier`), each managed by its own UVM agent. The environment shows how to:
1.  Create two independent agents (`add_agent`, `mul_agent`), each with its own sequencer.
2.  Create a **`v_sequencer`** component that contains handles to the sequencers inside each agent.
3.  Connect these handles to the actual agent sequencers during the `connect_phase`.
4.  Create a **`v_sequence`** (virtual sequence) that can create and start the agent-level sequences (`add_sequence`, `mul_sequence`) on their respective sequencers via the virtual sequencer handles.
5.  Run the virtual sequence from the test to drive both agents simultaneously.

---

### File Structure

-   `rtl/design.v`: Contains the simple multi-module DUT (`adder`, `multiplier`) and their interfaces.
-   `tb/virtual_sequencer_test.sv`: Contains the complete UVM code, including both agents, the virtual sequencer, virtual sequence, and the top-level test.

---

### Key Concepts Illustrated

-   **Stimulus Coordination**: The primary problem that virtual sequencers solve—managing stimulus across a multi-interface DUT.
-   **Virtual Sequencer**: A `uvm_sequencer` that does not connect to a driver but instead holds handles to other, "real" sequencers.
-   **Virtual Sequence**: A `uvm_sequence` that runs on the virtual sequencer. Its purpose is to control other sequences, allowing for complex, coordinated scenarios (e.g., starting an `add_sequence` and a `mul_sequence` in parallel).
-   **Hierarchical Sequencer Handles**: The mechanism of using handles (`add_seqr_h`, `mul_seqr_h`) within the virtual sequencer to gain access to the agent-level sequencers.

---

### How to Run

1.  Compile `rtl/design.v` and `tb/virtual_sequencer_test.sv` using a simulator that supports SystemVerilog and UVM.
2.  Set `tb` as the top-level module for simulation.
3.  Execute the simulation. The log will show interleaved messages from both the `ADD_DRV` and `MUL_DRV`, confirming that the `parallel_add_mul_vseq` successfully started both agent sequences in parallel.
