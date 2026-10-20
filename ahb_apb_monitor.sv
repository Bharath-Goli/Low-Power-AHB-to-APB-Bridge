// =============================================================================
// AHB-APB Monitor
// ConfigVerMet++ Testbench (IEEE CIPHER 2026)
// =============================================================================
`ifndef AHB_APB_MONITOR_SV
`define AHB_APB_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class ahb_apb_monitor extends uvm_monitor;
    `uvm_component_utils(ahb_apb_monitor)

    virtual ahb_apb_if vif;
    uvm_analysis_port #(ahb_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual ahb_apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "ahb_apb_monitor: virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        ahb_transaction txn;
        forever begin
            @(vif.monitor_cb);
            // Capture a transfer when HTRANS is NONSEQ or SEQ
            if (vif.monitor_cb.HTRANS inside {2'b10, 2'b11} && |vif.monitor_cb.HSEL) begin
                txn = ahb_transaction::type_id::create("mon_txn");
                txn.HADDR  = vif.monitor_cb.HADDR;
                txn.HWDATA = vif.monitor_cb.HWDATA;
                txn.HWRITE = vif.monitor_cb.HWRITE;
                txn.HTRANS = vif.monitor_cb.HTRANS;
                txn.HBURST = vif.monitor_cb.HBURST;
                txn.HSEL   = vif.monitor_cb.HSEL;
                txn.wait_states = int'(vif.monitor_cb.wait_cfg);
                ap.write(txn);
            end
        end
    endtask
endclass : ahb_apb_monitor

`endif // AHB_APB_MONITOR_SV
