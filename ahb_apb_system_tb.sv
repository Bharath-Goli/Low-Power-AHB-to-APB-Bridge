// =============================================================================
// Top-Level Testbench
// ConfigVerMet++ Testbench (IEEE CIPHER 2026)
// =============================================================================
`ifndef AHB_APB_SYSTEM_TB_SV
`define AHB_APB_SYSTEM_TB_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

module ahb_apb_system_tb;
    // Clocks: AHB 100 MHz, APB 50 MHz
    logic clk, pclk, rst_n, preset_n;

    initial clk = 0;
    always #5 clk = ~clk;   // 100 MHz

    initial pclk = 0;
    always #10 pclk = ~pclk; // 50 MHz

    // Reset
    initial begin
        rst_n    = 0;
        preset_n = 0;
        repeat (5) @(posedge clk);
        rst_n    = 1;
        preset_n = 1;
    end

    // Interface instantiation
    ahb_apb_if dut_if(.clk(clk), .pclk(pclk), .rst_n(rst_n));

    // DUT
    ahb2apb_bridge_lp #(
        .DATA_WIDTH  (32),
        .ADDR_WIDTH  (32),
        .NUM_MASTERS (2),
        .APB_WAIT_MAX(3)
    ) dut (
        .HCLK          (clk),
        .HRESET        (rst_n),
        .HSEL          (dut_if.HSEL),
        .HADDR         (dut_if.HADDR),
        .HWRITE        (dut_if.HWRITE),
        .HTRANS        (dut_if.HTRANS),
        .HBURST        (dut_if.HBURST),
        .HWDATA        (dut_if.HWDATA),
        .HRDATA        (dut_if.HRDATA),
        .HREADY        (dut_if.HREADY),
        .HRESP         (dut_if.HRESP),
        .PCLK          (pclk),
        .PRESET        (preset_n),
        .PSEL          (dut_if.PSEL),
        .PENABLE       (dut_if.PENABLE),
        .PADDR         (dut_if.PADDR),
        .PWRITE        (dut_if.PWRITE),
        .PWDATA        (dut_if.PWDATA),
        .PRDATA        (dut_if.PRDATA),
        .PREADY        (dut_if.PREADY),
        .policy_select (dut_if.policy_select),
        .bridge_enable (dut_if.bridge_enable),
        .dfv_fsm_state (dut_if.dfv_fsm_state),
        .dfv_grant     (dut_if.dfv_grant),
        .dfv_burst_cnt (dut_if.dfv_burst_cnt)
    );

    // APB Slave model
    apb_slave_model #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32),
        .MEM_DEPTH (256)
    ) apb_slave (
        .PCLK    (pclk),
        .PRESET  (preset_n),
        .PSEL    (dut_if.PSEL),
        .PENABLE (dut_if.PENABLE),
        .PADDR   (dut_if.PADDR),
        .PWRITE  (dut_if.PWRITE),
        .PWDATA  (dut_if.PWDATA),
        .PRDATA  (dut_if.PRDATA),
        .PREADY  (dut_if.PREADY),
        .wait_cfg(dut_if.wait_cfg)
    );

    // NOTE: Assertion module bind removed for the "no formal verification /
    // simulation-only" build (ahb_apb_assertions.sv intentionally excluded).

    // UVM test launch
    initial begin
        uvm_config_db #(virtual ahb_apb_if)::set(null, "uvm_test_top.*", "vif", dut_if);
        run_test(); // Test name passed via +UVM_TESTNAME plusarg
    end

    // Waveform dump
    initial begin
        $dumpfile("ahb_apb_sim.vcd");
        $dumpvars(0, ahb_apb_system_tb);
    end

    // Simulation timeout
    initial begin
        #1_000_000;
        `uvm_fatal("TIMEOUT", "Simulation exceeded time limit")
    end
endmodule : ahb_apb_system_tb

`endif // AHB_APB_SYSTEM_TB_SV
