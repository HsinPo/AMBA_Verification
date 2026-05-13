// ==============================================================================
// File        : vip/ahb_sequence.sv
// Description : Base Sequence for AHB VIP. Generates random AHB transactions.
// ==============================================================================

class ahb_base_seq extends uvm_sequence #(ahb_transaction);

    // Factory Registration (Sequence is an object, so no 'parent' argument)
    `uvm_object_utils(ahb_base_seq)

    function new(string name = "ahb_base_seq");
        super.new(name);
    endfunction

    // All stimulus generation logic goes into the body() task
    virtual task body();
        `uvm_info("SEQ", "Starting AHB Base Sequence...", UVM_LOW)

        repeat(5) begin
            // 1. Create a transaction via Factory
            req = ahb_transaction::type_id::create("req");
            
            // 2. Request Sequencer to prepare for sending
            start_item(req);
            
            // 3. Randomize the transaction payload
            // comment out cause free license doesn't support
            /* if (!req.randomize()) begin
                `uvm_error("SEQ", "Randomization failed!")
            end */
            req.haddr  = $urandom_range(32'h0000_1FFF, 32'h0000_0000);
            req.hwrite = $urandom % 2;                                 
            req.hwdata = $urandom;
            req.hsize  = $urandom_range(2, 0);
            req.hburst = $urandom_range(7, 0);

                        // 4. Send to Driver and wait for completion
            finish_item(req);
        end
        
        `uvm_info("SEQ", "Finished AHB Base Sequence.", UVM_LOW)
    endtask

endclass