// ==============================================================================
// File        : vip/ahb_pkg.sv
// Description : Package for AHB VIP components.
// ==============================================================================

package ahb_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "ahb_transaction.sv"
    `include "ahb_driver.sv"
    `include "ahb_monitor.sv"
    `include "ahb_sequence.sv"
    `include "ahb_sequencer.sv"
    `include "ahb_agent.sv"
    `include "ahb_scoreboard.sv"
    `include "ahb_env.sv"
endpackage