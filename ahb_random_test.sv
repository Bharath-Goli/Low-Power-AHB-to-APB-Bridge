// =============================================================================
// Test 1: Random Regression
// ConfigVerMet++ Testbench (IEEE CIPHER 2026)
// =============================================================================
`ifndef AHB_RANDOM_TEST_SV
`define AHB_RANDOM_TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class ahb_random_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        ahb_random_seq seq;
        phase.raise_objection(this);
        `uvm_info("TEST", "Running random regression (200 transactions)", UVM_NONE)
        seq = ahb_random_seq::type_id::create("seq");
        seq.num_transactions = 200;
        seq.start(env.sequencer);
        phase.drop_objection(this);
    endtask
endclass : ahb_random_test

`endif // AHB_RANDOM_TEST_SV
