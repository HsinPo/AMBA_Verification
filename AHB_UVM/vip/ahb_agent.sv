// ==============================================================================
// File        : vip/ahb_agent.sv
// Description : UVM AHB Agent
//               phase build and connect.
// ==============================================================================
class ahb_agent extends uvm_agent;
    `uvm_component_utils(ahb_agent)

    ahb_sequencer sqr;
    ahb_driver    drv;

    function new(string name = "ahb_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Transmitter
        sqr = ahb_sequencer::type_id::create("sqr", this);
        drv = ahb_driver::type_id::create("drv", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // connet Driver to Sequencer
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass