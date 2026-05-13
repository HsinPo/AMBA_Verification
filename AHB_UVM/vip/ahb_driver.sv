// ==============================================================================
// File        : vip/ahb_driver.sv
// Description : UVM AHB Master Driver
//               Fetches items from Sequencer and drives them onto the AHB bus.
// ==============================================================================

class ahb_driver extends uvm_driver #(ahb_transaction);

    // 1. Factory Registration
    `uvm_component_utils(ahb_driver)

    // 2. Virtual Interface Declaration
    virtual ahb_if vif;

    // 3. Constructor
    function new(string name = "ahb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // 4. Build Phase: Retrieve virtual interface from config_db
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("DRV", "Failed to get virtual interface from config_db!")
        end
    endfunction

    // 5. Run Phase: Main execution loop replacing the old task run()
    virtual task run_phase(uvm_phase phase);
        // Initialize pins (Reset state)
        vif.haddr  <= 0;
        vif.hwdata <= 0;
        vif.hwrite <= 0;
        vif.htrans <= 0;

        `uvm_info("DRV", "Driver is online! Monitoring sequencer...", UVM_LOW)

        // Infinite loop to process items
        forever begin
            // Step A: Fetch next item from Sequencer (replaces mbx.get)
            seq_item_port.get_next_item(req);
            
            // `uvm_info("DRV", $sformatf("Driving Addr: 0x%0h", req.haddr), UVM_HIGH)

            // Step B: Drive physical pins based on the transaction
            drive_transfer(req);

            // Step C: Report completion back to Sequencer
            seq_item_port.item_done();
        end
    endtask

    // 6. Core Driving Logic (Upgraded to UVM and AHB Protocol Timing)
    virtual task drive_transfer(ahb_transaction req);
        
        // ==========================================================
        // 1. Address Phase (Address and Control Signals)
        // ==========================================================
        @(posedge vif.hclk);
        vif.haddr  <= req.haddr;
        vif.hwrite <= req.hwrite;
        vif.htrans <= 2'b10; // NONSEQ
        
        // Additional control signals
        vif.hsize  <= req.hsize;
        vif.hburst <= req.hburst;

        // ==========================================================
        // 2. Data Phase (Data Write and Wait State Handling)
        // ==========================================================
        @(posedge vif.hclk);
        vif.htrans <= 2'b00; // IDLE (Assuming single transfer for now)

        // [CRITICAL] Wait for slave to be ready (hready == 1)
        wait(vif.hready == 1'b1);

        if (req.hwrite == 1'b1) begin
            // Drive data onto the bus for write operations
            vif.hwdata <= req.hwdata;
        end

        // ==========================================================
        // 3. Cleanup Phase
        // ==========================================================
        @(posedge vif.hclk);
        
        // Note: Read Sampling (tr.data = vif.hrdata) is removed!
        // In UVM, the Driver does not alter 'req'. The Monitor will capture read data.

        // Clear the write data bus to avoid X-propagation
        vif.hwdata <= 32'h0;
        
    endtask

endclass