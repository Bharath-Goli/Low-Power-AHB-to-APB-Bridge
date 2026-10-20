// =============================================================================
// Base Test
// ConfigVerMet++ Testbench (IEEE CIPHER 2026)
// =============================================================================
`ifndef AHB_APB_BASE_TEST_SV
`define AHB_APB_BASE_TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class ahb_apb_base_test extends uvm_test;
    `uvm_component_utils(ahb_apb_base_test)

    ahb_apb_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ahb_apb_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("TEST", "Base test started", UVM_NONE)
        // Override in child tests
        phase.drop_objection(this);
    endtask
endclass : ahb_apb_base_test

`endif // AHB_APB_BASE_TEST_SV
