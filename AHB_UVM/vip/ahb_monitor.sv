// ==============================================================================
// File        : vip/ahb_monitor.sv
// Description : UVM AHB Monitor
//               Passively samples bus signals, handles pipeline delays, 
//               and broadcasts beat-by-beat transactions to the scoreboard.
// ==============================================================================

class ahb_monitor extends uvm_monitor;

    // 1. Factory Registration
    `uvm_component_utils(ahb_monitor)

    // 2. Virtual Interface
    virtual ahb_if vif;

    // 3. Analysis Port (Broadcaster)
    uvm_analysis_port #(ahb_transaction) ap;

    // 4. Constructor
    function new(string name = "ahb_monitor", uvm_component parent = null);
        super.new(name, parent);
        // Initialize the Analysis Port
        ap = new("ap", this);
    endfunction

    // 5. Build Phase: Retrieve virtual interface
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MON", "Failed to get virtual interface from config_db!")
        end
    endfunction

    // 6. Run Phase: The continuous sampling loop
    virtual task run_phase(uvm_phase phase);
        `uvm_info("MON", "Monitor is online! Start sampling...", UVM_LOW)
        
        forever begin
            ahb_transaction tr;
            
            // Step A: Wait for a valid Address Phase
            wait_for_address_phase();

            // Step B: Sample the Address Phase control signals
            tr = ahb_transaction::type_id::create("tr");
            sample_address_phase(tr);

            // Step C: Wait for and sample the corresponding Data Phase
            sample_data_phase(tr);

            // Step D: Broadcast the completed transaction to the Scoreboard
            ap.write(tr);
        end
    endtask

    // ==========================================================================
    // Task Implementations: AHB Pipelined Sampling Logic
    // ==========================================================================

    // --------------------------------------------------------------------------
    // Step A: Wait for Address Phase
    // --------------------------------------------------------------------------
    virtual task wait_for_address_phase();
        forever begin
            @(posedge vif.hclk);
            
            // AHB Rule: The address/control signals are only 
            // valid and accepted by the slave if hready is 1.
            if (vif.hready === 1'b1 && (vif.htrans === 2'b10 || vif.htrans === 2'b11)) begin
                break; // Found a valid NONSEQ or SEQ transfer
            end
        end
    endtask

    // --------------------------------------------------------------------------
    // Step B: Sample Address Phase
    // --------------------------------------------------------------------------
    virtual function void sample_address_phase(ahb_transaction tr);
        tr.haddr  = vif.haddr;
        tr.hwrite = vif.hwrite;
        tr.hsize  = vif.hsize;
        tr.hburst = vif.hburst;
        
        //use Beat-by-Beat broadcasting, so arrays are sized to 1
        tr.hwdata = new[1];
        tr.hrdata = new[1];
        tr.hresp  = new[1];
    endfunction

    // --------------------------------------------------------------------------
    // Step C: Sample Data Phase (Handles Pipeline & Wait States)
    // --------------------------------------------------------------------------
    virtual task sample_data_phase(ahb_transaction tr);
        
        // 1. Move to the next clock cycle (Data Phase lags Address Phase by 1 cycle)
        @(posedge vif.hclk);

        // 2. Wait State Handling: Wait for Slave to be ready (hready == 1)
        // If hready is 0, the slave is extending the data phase.
        while (vif.hready !== 1'b1) begin
            @(posedge vif.hclk); 
        end

        // 3. Data is now valid, capture
        if (tr.hwrite == 1'b1) begin
            tr.hwdata[0] = vif.hwdata; // Capture Write Data
        end else begin
            tr.hrdata[0] = vif.hrdata; // Capture Read Data
        end
        
        // Capture Slave Response (00: OKAY, 01: ERROR)
        tr.hresp[0] = vif.hresp; 
        
        // Print a high-level debug message showing what was sampled
        `uvm_info("MON", $sformatf("Sampled Beat - Addr: 0x%0h, Write: %0b, Data: 0x%0h, Resp: %0b", 
                  tr.haddr, tr.hwrite, (tr.hwrite ? tr.hwdata[0] : tr.hrdata[0]), tr.hresp[0]), UVM_HIGH)
    endtask

endclass