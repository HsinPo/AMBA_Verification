// ==============================================================================
// File        : vip/ahb_env.sv
// Description : AHB Environment - Contains Agents and Scoreboard.
// ==============================================================================

class ahb_env extends uvm_env;
    
    // 1. Factory Registration
    `uvm_component_utils(ahb_env)

    // 2. Declare sub-components (Only Agent for now)
    ahb_agent agt;
    
    // (We will add: ahb_scoreboard scb; here tomorrow)

    // 3. Constructor
    function new(string name = "ahb_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // 4. Build Phase: Top-Down Construction
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        `uvm_info("ENV", "Environment building the Agent...", UVM_LOW)
        
        // Create the Agent instance
        // This is where 'env' builds its 'agt'
        agt = ahb_agent::type_id::create("agt", this);
        
        // (We will create the scoreboard here tomorrow)
    endfunction

    // 5. Connect Phase: Bottom-Up Connection
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // No connections needed in Env today! 
        // The internal connection (Driver <-> Sequencer) is handled inside the Agent.
        // Tomorrow, we will use this phase to connect the Agent's Monitor to the Scoreboard.
    endfunction

endclass