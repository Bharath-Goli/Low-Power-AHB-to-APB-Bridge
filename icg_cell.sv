// =============================================================================
// icg_cell.sv - Integrated Clock Gating (ICG) cell, behavioral template
// =============================================================================
// This is written in the standard "latch + AND" template that Genus/DC
// recognize automatically and map to a technology ICG cell (e.g. CKLNQD1,
// CGLDL, etc.) during synthesis. For RTL simulation it behaves functionally
// the same as clk & gclk_en, but is glitch-safe because the enable is
// captured in a transparent-low latch on the negative edge of clk.
// -----------------------------------------------------------------------------
module icg_cell (
    input  logic clk_in,
    input  logic enable,     // active-high gate enable
    input  logic test_en,    // scan/test bypass, tie to 0 if unused
    output logic clk_out
);

    logic en_latched;

    // Transparent latch: enable only updates while clk_in is low,
    // preventing mid-cycle glitches on the gated clock.
    always_latch begin
        if (!clk_in)
            en_latched <= enable | test_en;
    end

    assign clk_out = clk_in & en_latched;

endmodule : icg_cell
