// =============================================================================
// AHB2APB Bridge - RTL Design Under Test (DUT)
// Based on: ConfigVerMet++ (IEEE CIPHER 2026)
// Paper: "Towards Comprehensive Semi-Formal Verification of AMBA AHB/APB
// Interconnects"
// =============================================================================
// Supports: Single, INCR4, INCR8, INCR16, WRAP burst types
// Arbitration: Round-robin and fixed priority (configurable via policy_select)
// APB wait states: 0-3 cycles
// Clocks: AHB 100 MHz, APB 50 MHz
// =============================================================================
`ifndef AHB2APB_BRIDGE_SV
`define AHB2APB_BRIDGE_SV

//`include "uvm_macros.svh"
//import uvm_pkg::*;


// -----------------------------------------------------------------------------
// AHB2APB Bridge Top Module
// -----------------------------------------------------------------------------
module ahb2apb_bridge #(
    parameter DATA_WIDTH  = 32,
    parameter ADDR_WIDTH  = 32,
    parameter NUM_MASTERS = 2,
    parameter APB_WAIT_MAX = 3
)(
    // -------------------------------------------------------------------------
    // AHB Master-side Interface
    // -------------------------------------------------------------------------
    input  logic                     HCLK,
    input  logic                     HRESET,     // active-low reset
    input  logic [NUM_MASTERS-1:0]   HSEL,
    input  logic [ADDR_WIDTH-1:0]    HADDR,
    input  logic                     HWRITE,
    input  logic [1:0]               HTRANS,     // IDLE=2'b00, BUSY=2'b01, NONSEQ=2'b10, SEQ=2'b11
    input  logic [2:0]               HBURST,     // SINGLE=000, INCR4=011, INCR8=101, INCR16=111, WRAP4=010...
    input  logic [DATA_WIDTH-1:0]    HWDATA,
    output logic [DATA_WIDTH-1:0]    HRDATA,
    output logic                     HREADY,
    output logic [1:0]               HRESP,      // OKAY=2'b00, ERROR=2'b01

    // -------------------------------------------------------------------------
    // APB Slave-side Interface
    // -------------------------------------------------------------------------
    input  logic                     PCLK,
    input  logic                     PRESET,     // active-low reset
    output logic                     PSEL,
    output logic                     PENABLE,
    output logic [ADDR_WIDTH-1:0]    PADDR,
    output logic                     PWRITE,
    output logic [DATA_WIDTH-1:0]    PWDATA,
    input  logic [DATA_WIDTH-1:0]    PRDATA,
    input  logic                     PREADY,     // APB slave ready

    // -------------------------------------------------------------------------
    // Configuration / DFV Hooks (Design-for-Verification)
    // -------------------------------------------------------------------------
    input  logic [1:0]               policy_select, // 2'b00=RR, 2'b01=Fixed, 2'b10=Priority
    input  logic                     bridge_enable,

    // DFV observation outputs for formal/coverage binding
    output logic [1:0]               dfv_fsm_state,
    output logic [NUM_MASTERS-1:0]   dfv_grant,
    output logic [3:0]               dfv_burst_cnt
);

    // -------------------------------------------------------------------------
    // HTRANS encoding
    // -------------------------------------------------------------------------
    localparam IDLE   = 2'b00;
    localparam BUSY   = 2'b01;
    localparam NONSEQ = 2'b10;
    localparam SEQ    = 2'b11;

    // -------------------------------------------------------------------------
    // HBURST encoding
    // -------------------------------------------------------------------------
    localparam SINGLE = 3'b000;
    localparam INCR   = 3'b001;
    localparam WRAP4  = 3'b010;
    localparam INCR4  = 3'b011;
    localparam WRAP8  = 3'b100;
    localparam INCR8  = 3'b101;
    localparam WRAP16 = 3'b110;
    localparam INCR16 = 3'b111;

    // -------------------------------------------------------------------------
    // Bridge FSM States
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {
        BRIDGE_IDLE   = 2'b00,
        BRIDGE_SETUP  = 2'b01, // APB SETUP phase (PSEL=1, PENABLE=0)
        BRIDGE_ENABLE = 2'b10, // APB ENABLE phase (PSEL=1, PENABLE=1)
        BRIDGE_WAIT   = 2'b11  // Wait for PREADY
    } bridge_state_t;

    bridge_state_t state, next_state;

    // -------------------------------------------------------------------------
    // Arbiter
    // -------------------------------------------------------------------------
    logic [NUM_MASTERS-1:0] grant_ff;
    logic [NUM_MASTERS-1:0] grant_next;
    logic [$clog2(NUM_MASTERS)-1:0] rr_ptr; // round-robin pointer

    // -------------------------------------------------------------------------
    // Burst counter
    // -------------------------------------------------------------------------
    logic [4:0] burst_cnt;
    logic [4:0] burst_len; // expected beats from HBURST

    // -------------------------------------------------------------------------
    // Internal registers
    // -------------------------------------------------------------------------
    logic [ADDR_WIDTH-1:0] addr_reg;
    logic                  write_reg;
    logic [DATA_WIDTH-1:0] wdata_reg;
    logic [2:0]            hburst_reg;

    // -------------------------------------------------------------------------
    // Burst length decode
    // -------------------------------------------------------------------------
    function automatic logic [4:0] burst_length(input logic [2:0] hburst);
        case (hburst)
            SINGLE:        return 5'd1;
            INCR:          return 5'd1;  // undefined length, treat as 1
            WRAP4, INCR4:  return 5'd4;
            WRAP8, INCR8:  return 5'd8;
            WRAP16, INCR16: return 5'd16;
            default:       return 5'd1;
        endcase
    endfunction

    // -------------------------------------------------------------------------
    // Arbiter: round-robin / fixed priority / priority-encoded
    // -------------------------------------------------------------------------
    always_comb begin : ARBITER
        grant_next = '0;
        if (policy_select == 2'b00) begin
            // Round-robin: start from rr_ptr and find next requesting master
            for (int i = 0; i < NUM_MASTERS; i++) begin
                automatic int idx = (rr_ptr + i) % NUM_MASTERS;
                if (HSEL[idx] && grant_next == '0)
                    grant_next[idx] = 1'b1;
            end
        end else if (policy_select == 2'b01) begin
            // Fixed priority: master 0 has highest priority
            for (int i = 0; i < NUM_MASTERS; i++) begin
                if (HSEL[i] && grant_next == '0)
                    grant_next[i] = 1'b1;
            end
        end else begin
            // Weighted priority (same as fixed for 2 masters demo)
            for (int i = NUM_MASTERS-1; i >= 0; i--) begin
                if (HSEL[i])
                    grant_next[i] = 1'b1;
            end
        end
    end

    // Update round-robin pointer
    always_ff @(posedge HCLK or negedge HRESET) begin
        if (!HRESET) begin
            rr_ptr   <= '0;
            grant_ff <= '0;
        end else begin
            grant_ff <= grant_next;
            if (|grant_next)
                rr_ptr <= (rr_ptr + 1) % NUM_MASTERS;
        end
    end

    // -------------------------------------------------------------------------
    // AHB address/data capture on NONSEQ / SEQ
    // -------------------------------------------------------------------------
    always_ff @(posedge HCLK or negedge HRESET) begin
        if (!HRESET) begin
            addr_reg   <= '0;
            write_reg  <= 1'b0;
            wdata_reg  <= '0;
            hburst_reg <= SINGLE;
            burst_cnt  <= '0;
            burst_len  <= 5'd1;
        end else if (bridge_enable && |grant_ff) begin
            if (HTRANS == NONSEQ) begin
                addr_reg   <= HADDR;
                write_reg  <= HWRITE;
                wdata_reg  <= HWDATA;
                hburst_reg <= HBURST;
                burst_len  <= burst_length(HBURST);
                burst_cnt  <= 5'd1;
            end else if (HTRANS == SEQ) begin
                addr_reg  <= HADDR;
                wdata_reg <= HWDATA;
                burst_cnt <= burst_cnt + 5'd1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Bridge FSM - sequential
    // -------------------------------------------------------------------------
    always_ff @(posedge HCLK or negedge HRESET) begin
        if (!HRESET)
            state <= BRIDGE_IDLE;
        else
            state <= next_state;
    end

    // -------------------------------------------------------------------------
    // Bridge FSM - combinational next-state
    // -------------------------------------------------------------------------
    always_comb begin : BRIDGE_FSM
        next_state = state;
        case (state)
            BRIDGE_IDLE: begin
                if (bridge_enable && |grant_ff &&
                    (HTRANS == NONSEQ || HTRANS == SEQ))
                    next_state = BRIDGE_SETUP;
            end

            BRIDGE_SETUP: begin
                next_state = BRIDGE_ENABLE;
            end

            BRIDGE_ENABLE: begin
                if (!PREADY)
                    next_state = BRIDGE_WAIT;
                else if (burst_cnt < burst_len)
                    next_state = BRIDGE_SETUP; // next beat
                else
                    next_state = BRIDGE_IDLE;
            end

            BRIDGE_WAIT: begin
                if (PREADY) begin
                    if (burst_cnt < burst_len)
                        next_state = BRIDGE_SETUP;
                    else
                        next_state = BRIDGE_IDLE;
                end
            end

            default: next_state = BRIDGE_IDLE;
        endcase
    end

    // -------------------------------------------------------------------------
    // APB output drive
    // -------------------------------------------------------------------------
    always_ff @(posedge PCLK or negedge PRESET) begin
        if (!PRESET) begin
            PSEL    <= 1'b0;
            PENABLE <= 1'b0;
            PADDR   <= '0;
            PWRITE  <= 1'b0;
            PWDATA  <= '0;
        end else begin
            case (next_state)
                BRIDGE_IDLE: begin
                    PSEL    <= 1'b0;
                    PENABLE <= 1'b0;
                end
                BRIDGE_SETUP: begin
                    PSEL    <= 1'b1;
                    PENABLE <= 1'b0;
                    PADDR   <= addr_reg;
                    PWRITE  <= write_reg;
                    PWDATA  <= wdata_reg;
                end
                BRIDGE_ENABLE,
                BRIDGE_WAIT: begin
                    PSEL    <= 1'b1;
                    PENABLE <= 1'b1;
                end
                default: begin
                    PSEL    <= 1'b0;
                    PENABLE <= 1'b0;
                end
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // AHB response
    // -------------------------------------------------------------------------
    assign HREADY = (state == BRIDGE_IDLE) || (state == BRIDGE_ENABLE && PREADY);
    assign HRESP  = 2'b00; // always OKAY in this model
    assign HRDATA = PRDATA;

    // -------------------------------------------------------------------------
    // DFV observation outputs
    // -------------------------------------------------------------------------
    assign dfv_fsm_state = state;
    assign dfv_grant     = grant_ff;
    assign dfv_burst_cnt = burst_cnt[3:0];

endmodule : ahb2apb_bridge
`endif // AHB2APB_BRIDGE_SV
