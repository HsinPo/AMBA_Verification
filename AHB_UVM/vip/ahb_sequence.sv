// ==============================================================================
// File        : vip/ahb_sequence.sv
// Description : UVM AHB Base Sequence (License-Free Randomization Version)
//               Generates a simple WRITE followed by a READ to the same address.
//               Uses $urandom to bypass constraint solver license limitations.
// ==============================================================================

class ahb_base_seq extends uvm_sequence #(ahb_transaction);

    // ==========================================================================
    // 1. Factory Registration
    // ==========================================================================
    `uvm_object_utils(ahb_base_seq)

    // ==========================================================================
    // 2. Constructor
    // ==========================================================================
    function new(string name = "ahb_base_seq");
        super.new(name);
    endfunction

    // ==========================================================================
    // 3. Body Task (The main execution thread of the sequence)
    // ==========================================================================
    virtual task body();
        ahb_transaction req;
        bit [31:0] target_addr;

        `uvm_info("SEQ", "Starting Write-then-Read Sequence (Manual Random)...", UVM_LOW)

        // ---------------------------------------------------------
        // Transaction 1: WRITE Operation
        // ---------------------------------------------------------
        req = ahb_transaction::type_id::create("req");
        
        // Step 1: Request permission from the sequencer
        start_item(req); 
        
        // Step 2: Manual assignment to bypass randomize() licensing restrictions
        // Force the address to be 4-byte aligned (Word alignment)
        req.haddr     = $urandom_range(32'h0000_0000, 32'h0000_FFFF) & 32'hFFFF_FFFC; 
        req.hwrite    = 1'b1;         // 1 = WRITE
        req.hsize     = 3'b010;       // 32-bit (Word transmission)
        req.hburst    = 3'b000;       // SINGLE burst mode
        
        // Allocate the dynamic array for data phase and inject random data
        req.hwdata    = new[1];       
        req.hwdata[0] = $urandom;    
        
        // Save the address to ensure the subsequent READ targets the same location
        target_addr = req.haddr;   
        
        // Step 3: Send to driver and wait for handshake completion
        finish_item(req); 
        
        `uvm_info("SEQ", $sformatf("Completed WRITE to addr: 0x%0h, Data: 0x%0h", target_addr, req.hwdata[0]), UVM_LOW)

        // ---------------------------------------------------------
        // Transaction 2: READ Operation (To the EXACT SAME address)
        // ---------------------------------------------------------
        req = ahb_transaction::type_id::create("req");
        
        // Step 1: Request permission again
        start_item(req);
        
        // Step 2: Manual assignment for READ transaction
        req.haddr  = target_addr;    // Target the exact same address
        req.hwrite = 1'b0;           // 0 = READ
        req.hsize  = 3'b010;         // 32-bit (Word transmission)
        req.hburst = 3'b000;         // SINGLE burst mode
        // Note: hwdata is driven by the Slave/Driver during READ, so no assignment needed here
        
        // Step 3: Send to driver
        finish_item(req);
        
        `uvm_info("SEQ", $sformatf("Completed READ from addr: 0x%0h", target_addr), UVM_LOW)

    endtask

endclass