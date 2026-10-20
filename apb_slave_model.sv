// =============================================================================
// APB Slave Model (simple memory-mapped peripheral)
// ConfigVerMet++ Testbench (IEEE CIPHER 2026)
// =============================================================================
`ifndef APB_SLAVE_MODEL_SV
`define APB_SLAVE_MODEL_SV

module apb_slave_model #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_DEPTH  = 256,
    parameter MAX_WAIT   = 3
)(
    input  logic                  PCLK,
    input  logic                  PRESET,
    input  logic                  PSEL,
    input  logic                  PENABLE,
    input  logic [ADDR_WIDTH-1:0] PADDR,
    input  logic                  PWRITE,
    input  logic [DATA_WIDTH-1:0] PWDATA,
    output logic [DATA_WIDTH-1:0] PRDATA,
    output logic                  PREADY,
    // Configurable wait states for coverage
    input  logic [1:0]            wait_cfg
);
    logic [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
    logic [1:0] wait_cnt;

    always_ff @(posedge PCLK or negedge PRESET) begin
        if (!PRESET) begin
            PRDATA   <= '0;
            PREADY   <= 1'b1;
            wait_cnt <= '0;
        end else begin
            if (PSEL && !PENABLE) begin
                // SETUP phase - load wait counter
                wait_cnt <= wait_cfg;
                PREADY   <= (wait_cfg == 0) ? 1'b1 : 1'b0;
            end else if (PSEL && PENABLE) begin
                if (wait_cnt > 0) begin
                    wait_cnt <= wait_cnt - 1;
                    PREADY   <= (wait_cnt == 1) ? 1'b1 : 1'b0;
                end else begin
                    PREADY <= 1'b1;
                    if (PWRITE)
                        mem[PADDR[ADDR_WIDTH-1:2] % MEM_DEPTH] <= PWDATA;
                    else
                        PRDATA <= mem[PADDR[ADDR_WIDTH-1:2] % MEM_DEPTH];
                end
            end else begin
                PREADY <= 1'b1;
            end
        end
    end
endmodule : apb_slave_model

`endif // APB_SLAVE_MODEL_SV
