// ==============================================================================
// File        : vip/ahb_transaction.sv
// Description : AHB transaction item, inherits from UVM standard sequence item.
//               Defines the payload and protocol signals for AHB transfers.
// ==============================================================================

import uvm_pkg::*;
`include "uvm_macros.svh"

class ahb_transaction extends uvm_sequence_item;

    // --- 1. Payload and Protocol Signals (Randomized) ---
    rand bit [31:0] haddr;
    rand bit [31:0] hwdata;
    rand bit        hwrite;
    rand bit [2:0]  hsize;
    rand bit [2:0]  hburst;
    
    // --- Hardware Response Signals (Not Randomized) ---
    bit [31:0]      hrdata;
    bit             hready;
    bit [1:0]       hresp;

    // --- 2. UVM Factory Registration and Field Macros ---
    // Automates print(), copy(), compare(), and record() functions.
    `uvm_object_utils_begin(ahb_transaction)
        `uvm_field_int(haddr,  UVM_ALL_ON)
        `uvm_field_int(hwdata, UVM_ALL_ON)
        `uvm_field_int(hwrite, UVM_ALL_ON)
        `uvm_field_int(hsize,  UVM_ALL_ON)
        `uvm_field_int(hburst, UVM_ALL_ON)
        `uvm_field_int(hrdata, UVM_ALL_ON)
        `uvm_field_int(hready, UVM_ALL_ON)
        `uvm_field_int(hresp,  UVM_ALL_ON)
    `uvm_object_utils_end

    // --- 3. Constructor ---
    function new(string name = "ahb_transaction");
        super.new(name);
    endfunction

endclass