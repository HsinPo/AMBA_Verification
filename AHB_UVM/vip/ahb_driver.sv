// ==============================================================================
// File        : vip/ahb_driver.sv
// Description : UVM AHB Driver
//               Translates software transactions into physical pin wiggles
//               according to the AHB pipelined protocol.
// ==============================================================================

class ahb_driver extends uvm_driver #(ahb_transaction);

    // ==========================================================================
    // 1. Factory Registration
    // ==========================================================================
    `uvm_component_utils(ahb_driver)

    // ==========================================================================
    // 2. Virtual Interface
    // ==========================================================================
    virtual ahb_if vif;

    // ==========================================================================
    // 3. Constructor
    // ==========================================================================
    function new(string name = "ahb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // ==========================================================================
    // 4. Build Phase: Retrieve Virtual Interface
    // ==========================================================================
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("DRV", "Failed to get virtual interface from config_db!")
        end
    endfunction

    // ==========================================================================
    // 5. Run Phase: The Main Execution Loop
    // ==========================================================================
    virtual task run_phase(uvm_phase phase);
        
        // --- Initialization (Reset State) ---
        vif.haddr  <= 32'h0;
        vif.hwdata <= 32'h0;
        vif.hwrite <= 1'b0;
        vif.htrans <= 2'b00; // IDLE
        vif.hsize  <= 3'b000;
        vif.hburst <= 3'b000;

        `uvm_info("DRV", "Driver is online! Waiting for reset to release...", UVM_LOW)

        // --- Wait for Hardware Reset to Complete ---
        wait(vif.hresetn === 1'b1);
        @(posedge vif.hclk); // Wait one more clock to ensure stability

        `uvm_info("DRV", "Reset released! Monitoring sequencer...", UVM_LOW)

        // --- Infinite Loop to Process Transactions ---
        forever begin
            // Step A: Attempt to fetch the next item without blocking
            seq_item_port.try_next_item(req);

            // Step B: Check if an item was successfully fetched
            if (req != null) begin
                
                // Drive the transaction onto the physical bus
                drive_transfer(req);
                
                // Handshake: Notify sequencer that we are done with this item
                seq_item_port.item_done();
                
            end 
            else begin
                // No item available: Actively drive IDLE to prevent X-propagation
                vif.htrans <= 2'b00; // IDLE
                
                // CRITICAL: Wait for the next clock cycle before asking again
                @(posedge vif.hclk);
            end
        end
    endtask

    // ==========================================================================
    // 6. Task: drive_transfer (AHB Protocol Implementation)
    // ==========================================================================
    virtual task drive_transfer(ahb_transaction req);
        
        // ---------------------------------------------------------
        // Phase 1: Address Phase
        // ---------------------------------------------------------
        @(posedge vif.hclk); // Align to the rising edge of the clock
        
        vif.haddr  <= req.haddr;
        vif.hwrite <= req.hwrite;
        vif.hsize  <= req.hsize;
        vif.hburst <= req.hburst;
        vif.htrans <= 2'b10; // NONSEQ (Start of a new transfer)

        // ---------------------------------------------------------
        // Phase 2: Data Phase
        // ---------------------------------------------------------
        @(posedge vif.hclk); // Move to the next clock cycle
        
        // Immediately return control signals to IDLE (unless pipelining the next req)
        vif.htrans <= 2'b00; 

        // If it is a WRITE operation, drive the data onto hwdata
        if (req.hwrite == 1'b1) begin
            vif.hwdata <= req.hwdata[0];
        end

        // ---------------------------------------------------------
        // Phase 3: Wait State Handling
        // ---------------------------------------------------------
        // AHB Rule: Master must hold signals steady while Slave hready is 0
        while (vif.hready !== 1'b1) begin
            @(posedge vif.hclk);
        end

        // Exit loop means hready == 1, transaction is successfully captured by slave
        `uvm_info("DRV", $sformatf("Fired - Addr: 0x%0h, Write: %0b", req.haddr, req.hwrite), UVM_HIGH)
        
    endtask

endclass