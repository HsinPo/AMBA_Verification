// ==============================================================================
// File        : vip/ahb_scoreboard.sv
// Description : UVM AHB Scoreboard
//               Acts as the verifier. It maintains a reference memory model,
//               stores data on WRITE, and compares expected vs actual on READ.
// ==============================================================================

class ahb_scoreboard extends uvm_scoreboard;

    // ==========================================================================
    // 1. Factory Registration
    // ==========================================================================
    `uvm_component_utils(ahb_scoreboard)

    // ==========================================================================
    // 2. Analysis Implementation (The Receiver / Destination Port)
    // ==========================================================================
    // Parameter 1: The transaction type to receive (ahb_transaction)
    // Parameter 2: The class that implements the write() function (ahb_scoreboard)
    uvm_analysis_imp #(ahb_transaction, ahb_scoreboard) ap_export;

    // ==========================================================================
    // 3. Reference Model (Golden Model)
    // ==========================================================================
    // Using an associative array to model memory. 
    // It dynamically allocates memory only for written addresses, saving RAM.
    bit [31:0] ref_mem [int]; 

    // ==========================================================================
    // 4. Constructor
    // ==========================================================================
    function new(string name = "ahb_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // ==========================================================================
    // 5. Build Phase
    // ==========================================================================
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Instantiate the receiving port
        ap_export = new("ap_export", this);
    endfunction

    // ==========================================================================
    // 6. Write Function (Triggered automatically by the Monitor's ap.write())
    // ==========================================================================
    virtual function void write(ahb_transaction tr);
        bit [31:0] addr = tr.haddr;
        bit [31:0] data;
        
        // Ensure this is a successful transaction (hresp == 0 means OKAY)
        if (tr.hresp[0] !== 1'b0) begin
            `uvm_warning("SCB_WARN", $sformatf("Ignored transaction with ERROR response at addr: 0x%0h", addr))
            return;
        end

        // Check if it's a WRITE or READ operation
        if (tr.hwrite == 1'b1) begin
            // ----------------------------------------------------
            // [WRITE] Update the Reference Memory Model
            // ----------------------------------------------------
            data = tr.hwdata[0];
            ref_mem[addr] = data; // Store data into the associative array
            `uvm_info("SCB_WRITE", $sformatf("Stored  -> Addr: 0x%0h, Data: 0x%0h", addr, data), UVM_LOW)

        end else begin
            // ----------------------------------------------------
            // [READ] Compare Actual Data vs Expected Data
            // ----------------------------------------------------
            data = tr.hrdata[0];
            
            // Check 1: Has this address been written to before
            if (!ref_mem.exists(addr)) begin
                `uvm_warning("SCB_UNINIT", $sformatf("Read from uninitialized addr: 0x%0h, Data read: 0x%0h", addr, data))
            
            // Check 2: Does the read data match our stored reference data
            end else if (ref_mem[addr] == data) begin
                `uvm_info("SCB_PASS", $sformatf("MATCHED -> Addr: 0x%0h, Expected: 0x%0h, Actual: 0x%0h", addr, ref_mem[addr], data), UVM_LOW)
            
            // Check 3: Data mismatch. Bug found.
            end else begin
                `uvm_error("SCB_FAIL", $sformatf("MISMATCH -> Addr: 0x%0h, Expected: 0x%0h, Actual: 0x%0h", addr, ref_mem[addr], data))
            end
        end
    endfunction

endclass


/* ---------------------------
UVM Analysis TLM Reference Notes
1. uvm_analysis_port (The Broadcaster)
    Typically used by: Monitor.
    Function: Broadcasts transactions to the verification environment. When a transaction is captured, the component calls ap.write(tr).
    Characteristics: It is a non-blocking, one-to-many communication mechanism. It does not process data and does not care how many receivers are connected (it can broadcast to 0, 1, or N subscribers).
2. uvm_analysis_export (The Pass-through)
    Typically used by: Agent, Env.
    Function: Acts as a hierarchical bridge. Due to UVM's strict encapsulation, internal ports (e.g., inside a Monitor) cannot be seen directly by upper-level components. An export is declared on the parent's boundary to route the internal port outward.
    Characteristics: It purely forwards the connection. It does not process or store any data itself.
3. uvm_analysis_imp (The Implementation / Receiver)
    Typically used by: Scoreboard, Coverage Collector.
    Function: The final destination where the transaction is actually processed.
    Mandatory Contract: "imp" stands for implementation. Declaring an imp creates a strict contractual obligation: the class containing the imp must physically implement a write() function.
    Execution: When a connected uvm_analysis_port calls write(tr), the UVM underlying mechanism instantly triggers the write() function implemented inside the target class in zero simulation time. Failure to define this function results in a compilation error.
------------------------------*/