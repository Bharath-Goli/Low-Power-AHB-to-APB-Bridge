read_upf power_intent.upf
analyze -sv icg_cell.sv ahb2apb_bridge_lp.sv ahb_apb_if.sv ahb_apb_system_tb.sv apb_slave_model.sv
elaborate -top ahb_apb_system_tb
check_lp_structure
check_lp_iso
check_lp_iso_cross
check_lp_reset
report_lp_state
