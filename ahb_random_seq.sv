// =============================================================================
// Base Sequence - constrained-random
// ConfigVerMet++ Testbench (IEEE CIPHER 2026)
// =============================================================================
`ifndef AHB_RANDOM_SEQ_SV
`define AHB_RANDOM_SEQ_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class ahb_random_seq extends uvm_sequence #(ahb_transaction);
    `uvm_object_utils(ahb_random_seq)

    int num_transactions = 200;

    function new(string name = "ahb_random_seq");
        super.new(name);
    endfunction

    task body();
        ahb_transaction txn;
        repeat (num_transactions) begin
            txn = ahb_transaction::type_id::create("txn");
            start_item(txn);
            if (!txn.randomize())
                `uvm_fatal("RAND_FAIL", "ahb_transaction randomization failed")
            finish_item(txn);
        end
    endtask
endclass : ahb_random_seq

`endif // AHB_RANDOM_SEQ_SV
