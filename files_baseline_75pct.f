// Filelist: Simulation-only (no formal verification) build
// Reproduces Table I "Simulation-only (UVM)" row / Table IV "Without" column
// Expected result: ~75% functional coverage, ~80% code coverage
// Compile order matters: interface -> transaction/sequence -> driver/monitor/
// scoreboard/coverage -> env -> tests -> DUT/slave -> top

ahb_apb_if.sv
ahb_transaction.sv
ahb_random_seq.sv
ahb_driver.sv
ahb_apb_monitor.sv
ahb_apb_scoreboard.sv
ahb_apb_coverage.sv
ahb_apb_env.sv
ahb_apb_base_test.sv
ahb_random_test.sv
apb_slave_model.sv
icg_cell.sv
ahb2apb_bridge.sv
ahb_apb_system_tb.sv
