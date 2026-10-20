// =============================================================================
// AHB Driver
// ConfigVerMet++ Testbench (IEEE CIPHER 2026)
// =============================================================================
`ifndef AHB_DRIVER_SV
`define AHB_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class ahb_driver extends uvm_driver #(ahb_transaction);
    `uvm_component_utils(ahb_driver)

    virtual ahb_apb_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual ahb_apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "ahb_driver: virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        ahb_transaction txn;
        // Initial idle state
        vif.driver_cb.HTRANS        <= 2'b00;
        vif.driver_cb.HSEL          <= 2'b00;
        vif.driver_cb.bridge_enable <= 1'b1;
        vif.driver_cb.policy_select <= 2'b00; // round-robin default
        vif.driver_cb.wait_cfg      <= 2'b00;
        forever begin
            seq_item_port.get_next_item(txn);
            drive_transaction(txn);
            seq_item_port.item_done();
        end
    endtask

    task drive_transaction(ahb_transaction txn);
        // Apply AHB phase
        @(vif.driver_cb);
        vif.driver_cb.HSEL     <= txn.HSEL;
        vif.driver_cb.HADDR    <= txn.HADDR;
        vif.driver_cb.HWRITE   <= txn.HWRITE;
        vif.driver_cb.HTRANS   <= txn.HTRANS;
        vif.driver_cb.HBURST   <= txn.HBURST;
        vif.driver_cb.HWDATA   <= txn.HWDATA;
        // Configure the real APB slave model's wait states so that
        // txn.wait_states is actually exercised in the DUT (and therefore
        // meaningfully covered), instead of being faked on the driver side.
        vif.driver_cb.wait_cfg <= txn.wait_states[1:0];

        // Wait until the bridge signals completion via the real HREADY
        // (driven by the DUT based on the real apb_slave_model's PREADY)
        do begin
            @(vif.driver_cb);
        end while (!vif.driver_cb.HREADY);

        // Return to idle
        vif.driver_cb.HTRANS <= 2'b00;
        vif.driver_cb.HSEL   <= 2'b00;
    endtask
endclass : ahb_driver

`endif // AHB_DRIVER_SV
