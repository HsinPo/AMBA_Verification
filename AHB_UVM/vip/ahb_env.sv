// ==============================================================================
// File        : vip/ahb_env.sv
// Description : AHB Environment - Contains Agents and Scoreboard.
// ==============================================================================

class ahb_env extends uvm_env;
    
    // 1. Factory Registration
    `uvm_component_utils(ahb_env)

    // 2. Declare sub-components
    ahb_agent agt;
    ahb_scoreboard scb;

    // 3. Constructor
    function new(string name = "ahb_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // 4. Build Phase: Top-Down Construction
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        `uvm_info("ENV", "Environment building the Agent...", UVM_LOW)
        
        // Create the instance
        agt = ahb_agent::type_id::create("agt", this);
        scb = ahb_scoreboard:: type_id::create("scb", this);       
    endfunction

    // 5. Connect Phase: Bottom-Up Connection
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.ap.connect(scb.ap_export);
    endfunction

endclass