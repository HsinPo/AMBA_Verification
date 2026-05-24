// ==============================================================================
// File        : tb/ahb_base_test.sv
// Description : UVM AHB Base Test
//               The top-level controller that instantiates the environment
//               and starts the base sequence during the run_phase.
// ==============================================================================

class ahb_base_test extends uvm_test;

    // ==========================================================================
    // 1. Factory Registration
    // ==========================================================================
    `uvm_component_utils(ahb_base_test)

    // ==========================================================================
    // 2. Component Handles (The Environment)
    // ==========================================================================
    ahb_env env;

    // ==========================================================================
    // 3. Constructor
    // ==========================================================================
    function new(string name = "ahb_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // ==========================================================================
    // 4. Build Phase (Create the Verification Universe)
    // ==========================================================================
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Instantiate the Environment. 
        // This triggers the top-down build process: Env -> Agent -> Driver/Monitor
        env = ahb_env::type_id::create("env", this);
    endfunction

    // ==========================================================================
    // 5. Run Phase (The Dynamic Execution Phase)
    // ==========================================================================
    virtual task run_phase(uvm_phase phase);
        ahb_base_seq seq;

        // Step 1: Create the sequence (The bullet)
        seq = ahb_base_seq::type_id::create("seq");

        // Step 2: Raise objection
        // Tells the UVM engine: "I am doing work, do not kill the simulation!"
        phase.raise_objection(this, "Starting AHB Base Sequence");
        `uvm_info("TEST", "Simulation Started. Sequence is firing...", UVM_LOW)

        // Step 3: Start the sequence on the target sequencer (Dynamic Handshake)
        seq.start(env.agt.sequencer);

        #50;

        // Step 4: Drop objection
        // Tells the UVM engine: "My work is done, you can stop the simulation."
        `uvm_info("TEST", "Sequence execution completed. Ending simulation...", UVM_LOW)
        phase.drop_objection(this, "Finished AHB Base Sequence");
        
    endtask

endclass