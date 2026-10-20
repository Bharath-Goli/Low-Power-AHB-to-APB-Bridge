# Simulation-Only (No Formal Verification) Build — Cadence Xcelium

Reproduces the paper's baseline: **~75% functional coverage, ~80% code coverage**
(Sec VII.A / Table I "Simulation-only (UVM)" row / Table IV "Without" column).

`ahb_apb_assertions.sv` and its `bind` are intentionally excluded — this is a
pure UVM constrained-random regression with no ABV/formal layer.

## Files (13)
See `files_baseline_75pct.f` for the compile order.

## 1. Compile + elaborate + run

```bash
xrun -uvm -sv \
     -f files_baseline_75pct.f \
     -timescale 1ns/1ps \
     -coverage all -covoverwrite \
     -covdut ahb2apb_bridge \
     +UVM_TESTNAME=ahb_random_test \
     +UVM_VERBOSITY=UVM_MEDIUM \
     -access +rwc \
     -l baseline_run.log
```

## 2. Open the IMC coverage tool and generate the report

```bash
imc -exec "
load_metrics -db cov_work/scope/test
report_summary -metrics all -out baseline_cov_report.txt
report_summary -metrics all
exit
"
```

## 3. Quick functional-coverage-only check (fastest way to see ~75%)

```bash
imc -exec "
load_metrics -db cov_work/scope/test
report -summary -metrics functional -out functional_cov_summary.txt
exit
"

cat functional_cov_summary.txt
```

## 4. (Optional) View waveform

```bash
simvision ahb_apb_sim.vcd
```

## 5. (Optional) Multiple seeds to converge on the plateau reported in the paper

The paper describes the 75% figure as where baseline randomization *plateaus*,
so a single seed may land a few points off. Run a small regression to confirm
the plateau:

```bash
for seed in 1 2 3 4 5; do
  xrun -uvm -sv \
       -f files_baseline_75pct.f \
       -timescale 1ns/1ps \
       -coverage all -covoverwrite -covdut ahb2apb_bridge \
       -covworkdir cov_work_seed${seed} \
       +UVM_TESTNAME=ahb_random_test \
       +ntb_random_seed=${seed} \
       -access +rwc -l run_seed${seed}.log
done

imc -exec "
merge -out merged_cov -dir cov_work_seed*
load_metrics -db merged_cov
report_summary -metrics all -out merged_baseline_cov.txt
exit
"
```

Expected output in `functional_cov_summary.txt` / `merged_baseline_cov.txt`
should show **Functional Coverage (Total) ≈ 75%**, matching Table III's
"Baseline Functional Coverage ≈ 75%" row.
