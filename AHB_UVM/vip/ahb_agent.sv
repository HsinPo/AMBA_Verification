// ==============================================================================
// File        : vip/ahb_agent.sv
// Description : UVM AHB Agent
//               Encapsulates the Sequencer, Driver, and Monitor.
//               Configures the agent to be ACTIVE (Tx/Rx) or PASSIVE (Rx only).
// ==============================================================================

class ahb_agent extends uvm_agent;

    // ==========================================================================
    // 1. Factory Registration
    // ==========================================================================
    `uvm_component_utils(ahb_agent)

    // ==========================================================================
    // 2. Component Handles (Sub-components of the agent)
    // ==========================================================================
    ahb_sequencer sequencer;
    ahb_driver    driver;
    ahb_monitor   monitor;

    // ==========================================================================
    // 3. Analysis Port (Broadcaster to the outside world / Environment)
    // ==========================================================================
    uvm_analysis_port #(ahb_transaction) ap;

    // ==========================================================================
    // 4. Constructor
    // ==========================================================================
    function new(string name = "ahb_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // ==========================================================================
    // 5. Build Phase
    // ==========================================================================
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Instantiate the agent's analysis port
        ap = new("ap", this);

        // [Mandatory Component] Monitor is always required for both active and passive modes
        monitor = ahb_monitor::type_id::create("monitor", this);

        // [Conditional Components] Instantiate sequencer and driver ONLY in ACTIVE mode
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = ahb_sequencer::type_id::create("sequencer", this);
            driver    = ahb_driver::type_id::create("driver", this);
        end
    endfunction

    // ==========================================================================
    // 6. Connect Phase
    // ==========================================================================
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // [External Connection] Connect the monitor's analysis port to the agent's analysis port
        monitor.ap.connect(this.ap);

        // [Internal Connection] Connect driver's request port to sequencer's export ONLY in ACTIVE mode
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass