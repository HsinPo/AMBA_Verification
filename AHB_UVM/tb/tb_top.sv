// ==============================================================================
// File        : tb/tb_top.sv
// Description : Top-level testbench module for AHB VIP.
//               Connects physical signals and kicks off the UVM framework.
// ==============================================================================

`timescale 1ns/1ps

module tb_top;

    // Import UVM macros and your AHB package classes
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import ahb_pkg::*;

    // ==========================================================================
    // Hardware Signals and Interface Instantiation
    // ==========================================================================
    logic hclk;
    logic hresetn;

    // Clock Generation (100MHz)
    initial begin
        hclk = 1'b0;
        forever #5 hclk = ~hclk; 
    end

    // Reset Generation (Active Low)
    initial begin
        hresetn = 1'b0;
        #20 hresetn = 1'b1;      // Release reset after 20ns
    end

    // Instantiate the Physical Interface
    ahb_if ahb_if_inst(
        .hclk(hclk),
        .hresetn(hresetn)
    );

    // ==========================================================================
    // DUT (Design Under Test) Instantiation 
    // ==========================================================================
    //
    // [REMINDER FOR MYSELF - DUT INTEGRATION]
    // Currently using a "Dummy Slave" (hready = 1) just to verify if the 
    // Master (Driver) can successfully drive waveforms without deadlocking.
    // 
    // ACTION: Once the Master works, delete the STEP 1 'assign' lines, 
    // and uncomment STEP 2 to connect the real AHB SRAM!
    // ==========================================================================

    // --- STEP 1: Dummy Slave (For Initial Bring-up Today) ---
    assign ahb_if_inst.hready = 1'b1;  // Force ready to prevent Driver deadlock
    assign ahb_if_inst.hresp  = 2'b00; // Force OKAY response

    // --- STEP 2: Real DUT (Uncomment this when ready to test SRAM) ---
    /*
    ahb_sram u_sram (
        .hclk(hclk),
        .hresetn(hresetn),
        .haddr(ahb_if_inst.haddr),
        .hwrite(ahb_if_inst.hwrite),
        .htrans(ahb_if_inst.htrans),
        .hsize(ahb_if_inst.hsize),
        .hburst(ahb_if_inst.hburst),
        .hwdata(ahb_if_inst.hwdata),
        .hrdata(ahb_if_inst.hrdata),
        .hready(ahb_if_inst.hready),
        .hresp(ahb_if_inst.hresp)
    );
    */

    // ==========================================================================
    // OOP Verification Environment Execution (UVM Kick-off)
    // ==========================================================================
    initial begin
        // [Task 1: Pass Virtual Interface to UVM]
        // Store the physical interface in the UVM config DB.
        // The UVM Driver will fetch this later using 'get'.
        uvm_config_db#(virtual ahb_if)::set(null, "*", "vif", ahb_if_inst);

        // [Task 2: Start UVM Phases]
        // Empty parentheses. The test name is passed from run.sh via +UVM_TESTNAME
        // This single command handles Build, Run, Drain, Report, and Finish automatically.
        run_test(); 
    end

endmodule