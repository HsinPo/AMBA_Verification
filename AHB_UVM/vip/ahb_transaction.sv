// ==============================================================================
// File        : vip/ahb_transaction.sv
// Description : UVM AHB Transaction (Sequence Item)
//               Encapsulates the AHB bus signals into a data object.
//               Upgraded to support Burst transfers with dynamic arrays and 
//               slave response monitoring.
// ==============================================================================

class ahb_transaction extends uvm_sequence_item;

    // ==========================================================================
    // 1. Transaction Variables (Payload)
    // ==========================================================================
    rand bit [31:0] haddr;
    rand bit        hwrite;
    rand bit [2:0]  hsize;
    rand bit [2:0]  hburst;
    
    // hwdata is a dynamic array to support multiple transfers in a burst
    rand bit [31:0] hwdata[];

    // --------------------------------------------------------------------------
    // hrdata and hresp use 'logic' (4-state). It is CRITICAL for the Monitor.
    // If the RTL has a bug and outputs an 'X' (unknown state), a 'bit' would 
    // silently convert it to '0'. Using 'logic' allows the Scoreboard to catch 
    // the 'X' and report a failure.
    // --------------------------------------------------------------------------
    logic [31:0] hrdata[];
    logic [1:0]  hresp[];  // Slave Response: 2'b00 = OKAY, 2'b01 = ERROR

    // ==========================================================================
    // 2. Constraints for Burst Transfers
    // ==========================================================================
    // Constrain the dynamic array size to match the AHB burst type.
    // This ensures the array has the exact number of data elements needed.
    constraint c_burst_size {
        if (hburst == 3'b000) hwdata.size() == 1;  // SINGLE
        if (hburst == 3'b001) hwdata.size() >= 1;  // INCR (Undefined length)
        if (hburst == 3'b010 || hburst == 3'b011) hwdata.size() == 4;  // WRAP4 / INCR4
        if (hburst == 3'b100 || hburst == 3'b101) hwdata.size() == 8;  // WRAP8 / INCR8
        if (hburst == 3'b110 || hburst == 3'b111) hwdata.size() == 16; // WRAP16 / INCR16
    }

    // ==========================================================================
    // 3. UVM Factory Registration & Field Macros
    // ==========================================================================
    `uvm_object_utils_begin(ahb_transaction)
        // Using UVM_HEX to print address and data in hexadecimal format
        `uvm_field_int(haddr, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(hwrite, UVM_ALL_ON)
        `uvm_field_int(hsize, UVM_ALL_ON)
        `uvm_field_int(hburst, UVM_ALL_ON)
        
        // Use the _array_int macro for dynamic arrays so the UVM print() 
        // function can correctly display all elements inside the array.
        `uvm_field_array_int(hwdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_array_int(hrdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_array_int(hresp,  UVM_ALL_ON | UVM_BIN)
    `uvm_object_utils_end

    // ==========================================================================
    // 4. Constructor
    // ==========================================================================
    function new(string name = "ahb_transaction");
        super.new(name);
    endfunction

endclass