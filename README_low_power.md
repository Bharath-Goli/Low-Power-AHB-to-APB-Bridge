# Low Power Implementation - AHB2APB Bridge

## Files added
| File | Purpose |
|---|---|
| `icg_cell.sv.txt` | Behavioral integrated clock-gating (ICG) cell, synthesis-recognized template |
| `ahb2apb_bridge_lp.sv.txt` | Low-power variant of `ahb2apb_bridge.sv` with `HCLK`/`PCLK` clock gating wired in |
| `power_intent.upf` | UPF 2.1 power intent: domains, power switch, isolation, PST |
| `README_low_power.md` | This file |

Your original `ahb2apb_bridge.sv` is untouched. `ahb2apb_bridge_lp.sv` is the module you swap in.

## What changed in the RTL
- Two clock-gating enables: `ahb_clk_en` (active on any grant/in-flight transaction) and `apb_clk_en` (active whenever the bridge is not idle).
- Two `icg_cell` instances produce `HCLK_g` / `PCLK_g`; every register that was clocked on `HCLK`/`PCLK` now clocks on the gated version. Async resets stay on the original `HRESET`/`PRESET` so reset is never blocked by gating.
- Two new observation ports, `lp_ahb_clk_en` / `lp_apb_clk_en`, for coverage or waveform debug (left unconnected in your existing testbench — that's legal for outputs).

## Step 1 — swap the file into your compile list
In `files_baseline_75pct.f`, replace the line pointing at `ahb2apb_bridge.sv` with `ahb2apb_bridge_lp.sv`, and add `icg_cell.sv` above it (it must compile before it's instantiated):

```
icg_cell.sv.txt
ahb2apb_bridge_lp.sv.txt
```

## Step 2 — functional regression (no UPF yet)
Run your existing Xcelium regression exactly as before. `icg_cell` is functionally transparent (clk & enable, glitch-safe latch), so all existing tests and coverage should pass unchanged — this proves the gating didn't break function before you add power intent.

```
xrun -f files_baseline_75pct.f -uvm -access +rwc
```

## Step 3 — power-aware simulation with the UPF
```
xrun -f files_baseline_75pct.f -uvm -access +rwc \
     -power -upf power_intent.upf \
     -powerlog
```
Watch for: isolation clamp values taking effect when `bridge_enable` drops, and no X-propagation into the always-on domain.

## Step 4 — JasperGold Low Power App (static/formal checks)
```tcl
# jg_lp.tcl
read_upf power_intent.upf
analyze -sv ahb_apb_extracted/*.sv
elaborate -top ahb_apb_system_tb
check_lp_structure          ;# UPF/PST consistency, missing supplies
check_lp_iso                ;# isolation cell existence + correctness
check_lp_iso_cross          ;# isolation vs. domain crossing correctness
check_lp_reset              ;# reset behavior across power states
report_lp_state             ;# reachable/unreachable PST states
```
Run with:
```
jg -tcl jg_lp.tcl -app lp
```
Fix anything flagged before moving to physical implementation (missing isolation, unreachable PST states, retention gaps).

## Step 5 — coverage on power states
Add a covergroup sampling `lp_ahb_clk_en`, `lp_apb_clk_en`, and `dut.bridge_enable` transitions (ON→OFF→ON) to `ahb_apb_coverage.sv` so your existing 75%-baseline coverage report also tracks power-state entry/exit, not just functional bins.

## Notes / open items
- No retention is implemented — see the comment block in `power_intent.upf` section 5 for when you'd need it.
- `PSW_BRIDGE` control is tied directly to `dut.bridge_enable`; if your real system gates power from an external PMU signal instead, change the `-control_port` mapping.
- The isolation clamp values (`HREADY`→1, `HRESP/HRDATA/PSEL/PENABLE/...`→0) assume "isolate to idle/OK" is safe for your system; adjust if your integration expects different safe values.
