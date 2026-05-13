// ==============================================================================
// File        : tb/ahb_test.sv
// Description : Base test class to initialize the environment and start sequences.
// ==============================================================================
import uvm_pkg::*;
`include "uvm_macros.svh"
import ahb_pkg::*;


class ahb_base_test extends uvm_test;


    // 1. Factory Registration
    `uvm_component_utils(ahb_base_test)

    // 2. Declare the environment (the "laboratory")
    ahb_env env;
    
    // 3. Constructor
    function new(string name = "ahb_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // 4. Build Phase: Top-Down Construction
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TEST", "Building Environment...", UVM_LOW)
        
        // Create the environment instance
        env = ahb_env::type_id::create("env", this);
    endfunction

    // 5. Run Phase: The actual test execution
    virtual task run_phase(uvm_phase phase);
        // Declare the sequence (the list of transactions to send)
        ahb_base_seq seq;
        
        // [Step 1] Raise Objection
        // Tell UVM: "I am starting a test, do not end the simulation!"
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting AHB Base Sequence...", UVM_LOW)
        
        // Instantiate the sequence
        seq = ahb_base_seq::type_id::create("seq");
        
        // [Step 2] Start the sequence on the sequencer
        // Path: environment -> agent -> sequencer
        seq.start(env.agt.sqr); 
        
        `uvm_info("TEST", "Sequence Finished. Dropping Objection...", UVM_LOW)
        
        // [Step 3] Drop Objection
        // Tell UVM: "My test is done, you can stop the simulation now."
        phase.drop_objection(this);
    endtask

endclass