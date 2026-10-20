set_db init_lib_search_path {/home/install/GENUS211/share/synth/tutorials/tech}
set_db library {tutorial.lib}
read_hdl -sv {ahb2apb_bridge_synth.sv}
elaborate ahb2apb_bridge
create_clock -name HCLK -period 10 [get_ports HCLK]
create_clock -name PCLK -period 10 [get_ports PCLK]
syn_generic
syn_map
syn_opt
report_power > power_baseline.txt
report_area > area_baseline.txt
exit
