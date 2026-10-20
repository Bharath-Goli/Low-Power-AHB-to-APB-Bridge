// =============================================================================
// AHB Transaction (sequence_item)
// ConfigVerMet++ Testbench (IEEE CIPHER 2026)
// =============================================================================
`ifndef AHB_TRANSACTION_SV
`define AHB_TRANSACTION_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class ahb_transaction extends uvm_sequence_item;
    // -------------------------------------------------------------------------
    // AHB fields
    // -------------------------------------------------------------------------
    rand logic [31:0] HADDR;
    rand logic [31:0] HWDATA;
    rand logic        HWRITE;
    rand logic [1:0]  HTRANS;      // IDLE/BUSY/NONSEQ/SEQ
    rand logic [2:0]  HBURST;      // SINGLE/INCR/WRAP4/INCR4...
    rand logic [1:0]  HSEL;        // which master
    rand int          wait_states; // simulated APB wait state (0-3)

    `uvm_object_utils_begin(ahb_transaction)
        `uvm_field_int(HADDR,       UVM_ALL_ON)
        `uvm_field_int(HWDATA,      UVM_ALL_ON)
        `uvm_field_int(HWRITE,      UVM_ALL_ON)
        `uvm_field_int(HTRANS,      UVM_ALL_ON)
        `uvm_field_int(HBURST,      UVM_ALL_ON)
        `uvm_field_int(HSEL,        UVM_ALL_ON)
        `uvm_field_int(wait_states, UVM_ALL_ON)
    `uvm_object_utils_end

    // -------------------------------------------------------------------------
    // Constraints
    // -------------------------------------------------------------------------
    // Valid AHB transfers only (no BUSY in this simplified model)
    constraint valid_trans_c {
        HTRANS inside {2'b00, 2'b10, 2'b11}; // IDLE, NONSEQ, SEQ
    }

    // Address aligned to 4 bytes
    constraint addr_align_c {
        HADDR[1:0] == 2'b00;
    }

    // Burst types from the paper's parameter set
    constraint burst_types_c {
        HBURST inside {3'b000,  // SINGLE
                       3'b011,  // INCR4
                       3'b101,  // INCR8
                       3'b111,  // INCR16
                       3'b010,  // WRAP4
                       3'b100,  // WRAP8
                       3'b110}; // WRAP16
    }

    // APB wait states 0-3
    constraint wait_state_c {
        wait_states inside {[0:3]};
    }

    // Only one master active at a time
    constraint one_master_c {
        $onehot0(HSEL);
    }

    function new(string name = "ahb_transaction");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "HSEL=%0b HTRANS=%0b HBURST=%0b HADDR=0x%0h HWRITE=%0b HWDATA=0x%0h WS=%0d",
            HSEL, HTRANS, HBURST, HADDR, HWRITE, HWDATA, wait_states
        );
    endfunction
endclass : ahb_transaction

`endif // AHB_TRANSACTION_SV
