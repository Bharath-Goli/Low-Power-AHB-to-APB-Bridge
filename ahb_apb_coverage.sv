// =============================================================================
// Coverage Collector - functional coverage model
// ConfigVerMet++ Testbench (IEEE CIPHER 2026)
// =============================================================================
`ifndef AHB_APB_COVERAGE_SV
`define AHB_APB_COVERAGE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class ahb_apb_coverage extends uvm_subscriber #(ahb_transaction);
    `uvm_component_utils(ahb_apb_coverage)

    // ---------------------------------------------------------------------------
    // Latched locals sampled into the covergroups below.
    // (Using plain covergroups with no-arg sample() instead of
    //  "covergroup ... with function sample(args)" for broad tool compatibility.)
    // ---------------------------------------------------------------------------
    logic [2:0]  s_hburst;
    logic        s_hwrite;
    logic [1:0]  s_htrans;
    logic [1:0]  s_hsel;
    logic [31:0] s_haddr;
    int          s_wait_states;

    logic       s_psel;
    logic       s_penable;
    logic       s_pready;
    logic [1:0] s_fsm_state;

    // ---------------------------------------------------------------------------
    // Covergroup: AHB transfer properties
    // ---------------------------------------------------------------------------
    covergroup transfer_cg;
        option.per_instance = 1;
        // Burst type coverage (all 7 types from the paper)
        cp_burst: coverpoint s_hburst {
            bins single = {3'b000};
            bins incr4  = {3'b011};
            bins incr8  = {3'b101};
            bins incr16 = {3'b111};
            bins wrap4  = {3'b010};
            bins wrap8  = {3'b100};
            bins wrap16 = {3'b110};
        }
        // Read / Write
        cp_rw: coverpoint s_hwrite {
            bins read  = {0};
            bins write = {1};
        }
        // Transfer type
        cp_htrans: coverpoint s_htrans {
            bins idle   = {2'b00};
            bins nonseq = {2'b10};
            bins seq    = {2'b11};
        }
        // Which master
        cp_master: coverpoint s_hsel {
            bins master0_only = {2'b01};
            bins master1_only = {2'b10};
            bins both_request = {2'b11};
        }
        // APB wait states
        cp_wait: coverpoint s_wait_states {
            bins ws0 = {0};
            bins ws1 = {1};
            bins ws2 = {2};
            bins ws3 = {3};
        }
        // Address boundary coverage (lower 8 bits)
        cp_addr_boundary: coverpoint s_haddr[7:2] {
            bins low_addr  = {[0:15]};
            bins mid_addr  = {[16:47]};
            bins high_addr = {[48:63]};
        }

        // -----------------------------------------------------------------------
        // Cross-coverage: arbitration policy x burst type x wait-state
        // (Sec. IV.B of the paper)
        // -----------------------------------------------------------------------
        cx_burst_rw:     cross cp_burst, cp_rw;
        cx_burst_wait:   cross cp_burst, cp_wait;
        cx_master_burst: cross cp_master, cp_burst;
        cx_master_wait:  cross cp_master, cp_wait;
    endgroup

    // ---------------------------------------------------------------------------
    // Covergroup: safety bins (reset, starvation indicators via DFV)
    // ---------------------------------------------------------------------------
    covergroup safety_cg;
        option.per_instance = 1;
        cp_psel:    coverpoint s_psel;
        cp_penable: coverpoint s_penable;
        cp_pready:  coverpoint s_pready;
        cp_fsm: coverpoint s_fsm_state {
            bins idle   = {2'b00};
            bins setup  = {2'b01};
            bins enable = {2'b10};
            bins wait_s = {2'b11};
        }
        cx_apb_states: cross cp_psel, cp_penable, cp_pready;
    endgroup

    virtual ahb_apb_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        transfer_cg = new();
        safety_cg   = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual ahb_apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "ahb_apb_coverage: virtual interface not found")
    endfunction

    function void write(ahb_transaction t);
        s_hburst      = t.HBURST;
        s_hwrite      = t.HWRITE;
        s_htrans      = t.HTRANS;
        s_hsel        = t.HSEL;
        s_haddr       = t.HADDR;
        s_wait_states = t.wait_states;
        transfer_cg.sample();
    endfunction

    // Continuously sample the APB-handshake / DFV safety covergroup directly
    // from the interface every clock, since it depends on live PSEL/PENABLE/
    // PREADY/fsm_state rather than on a completed transaction object.
    task run_phase(uvm_phase phase);
        forever begin
            @(vif.monitor_cb);
            s_psel      = vif.monitor_cb.PSEL;
            s_penable   = vif.monitor_cb.PENABLE;
            s_pready    = vif.monitor_cb.PREADY;
            s_fsm_state = vif.monitor_cb.dfv_fsm_state;
            safety_cg.sample();
        end
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf("Transfer CG coverage:    %.1f%%", transfer_cg.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("Safety/APB CG coverage:  %.1f%%", safety_cg.get_inst_coverage()), UVM_NONE)
    endfunction
endclass : ahb_apb_coverage

`endif // AHB_APB_COVERAGE_SV
