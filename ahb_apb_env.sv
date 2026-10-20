// =============================================================================
// UVM Environment
// ConfigVerMet++ Testbench (IEEE CIPHER 2026)
// =============================================================================
`ifndef AHB_APB_ENV_SV
`define AHB_APB_ENV_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class ahb_apb_env extends uvm_env;
    `uvm_component_utils(ahb_apb_env)

    ahb_driver           driver;
    ahb_apb_monitor       monitor;
    ahb_apb_scoreboard     scoreboard;
    ahb_apb_coverage       coverage;
    uvm_sequencer #(ahb_transaction) sequencer;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver     = ahb_driver::type_id::create("driver", this);
        monitor    = ahb_apb_monitor::type_id::create("monitor", this);
        scoreboard = ahb_apb_scoreboard::type_id::create("scoreboard", this);
        coverage   = ahb_apb_coverage::type_id::create("coverage", this);
        sequencer  = uvm_sequencer #(ahb_transaction)::type_id::create("sequencer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
        monitor.ap.connect(scoreboard.analysis_export);
        monitor.ap.connect(coverage.analysis_export);
    endfunction
endclass : ahb_apb_env

`endif // AHB_APB_ENV_SV
