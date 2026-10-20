// =============================================================================
// Scoreboard - reference model for correctness checks
// ConfigVerMet++ Testbench (IEEE CIPHER 2026)
// =============================================================================
`ifndef AHB_APB_SCOREBOARD_SV
`define AHB_APB_SCOREBOARD_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class ahb_apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ahb_apb_scoreboard)

    uvm_analysis_imp #(ahb_transaction, ahb_apb_scoreboard) analysis_export;

    // Reference model: simple FIFO of expected APB transfers
    ahb_transaction expected_q[$];
    int pass_count = 0;
    int fail_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
    endfunction

    function void write(ahb_transaction txn);
        // Check AHB transfer is valid NONSEQ/SEQ
        if (txn.HTRANS inside {2'b10, 2'b11}) begin
            if (txn.HSEL == '0) begin
                `uvm_error("SB", $sformatf("Transfer with no HSEL asserted: %s", txn.convert2string()))
                fail_count++;
            end else begin
                `uvm_info("SB", $sformatf("Valid transfer: %s", txn.convert2string()), UVM_HIGH)
                pass_count++;
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB", $sformatf("Scoreboard Summary: PASS=%0d FAIL=%0d", pass_count, fail_count), UVM_NONE)
        if (fail_count > 0)
            `uvm_error("SB", "SCOREBOARD: Failures detected!")
    endfunction
endclass : ahb_apb_scoreboard

`endif // AHB_APB_SCOREBOARD_SV
