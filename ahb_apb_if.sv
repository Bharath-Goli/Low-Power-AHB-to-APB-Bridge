// =============================================================================
// AHB-APB Virtual Interface
// ConfigVerMet++ Testbench (IEEE CIPHER 2026)
// =============================================================================
`ifndef AHB_APB_IF_SV
`define AHB_APB_IF_SV

interface ahb_apb_if (input logic clk, input logic pclk, input logic rst_n);
    // AHB
    logic [31:0] HADDR;
    logic [31:0] HWDATA;
    logic [31:0] HRDATA;
    logic        HWRITE;
    logic [1:0]  HTRANS;
    logic [2:0]  HBURST;
    logic [1:0]  HSEL;
    logic        HREADY;
    logic [1:0]  HRESP;

    // APB
    logic        PSEL;
    logic        PENABLE;
    logic [31:0] PADDR;
    logic        PWRITE;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PREADY;

    // Config
    logic [1:0]  policy_select;
    logic        bridge_enable;

    // Testbench-controlled APB wait-state configuration (drives apb_slave_model)
    logic [1:0]  wait_cfg;

    // DFV
    logic [1:0]  dfv_fsm_state;
    logic [1:0]  dfv_grant;
    logic [3:0]  dfv_burst_cnt;

    // Clocking blocks
    clocking driver_cb @(posedge clk);
        output HADDR, HWDATA, HWRITE, HTRANS, HBURST, HSEL;
        output policy_select, bridge_enable;
        output wait_cfg;
        input  HRDATA, HREADY, HRESP;
    endclocking

    clocking monitor_cb @(posedge clk);
        input HADDR, HWDATA, HRDATA, HWRITE, HTRANS, HBURST, HSEL;
        input HREADY, HRESP;
        input PSEL, PENABLE, PADDR, PWRITE, PWDATA, PRDATA, PREADY;
        input dfv_fsm_state, dfv_grant, dfv_burst_cnt;
        input wait_cfg;
    endclocking
endinterface : ahb_apb_if

`endif // AHB_APB_IF_SV
