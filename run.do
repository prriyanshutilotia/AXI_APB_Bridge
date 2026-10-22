# Compile once, then run every UVM test.  Invoke from the Questa transcript:
#   do run.do
if {![file exists work]} {vlib work}
vmap work work

vlog -work work -sv +acc +cover=bcesf axi_apb_top.svh

set tests {
    axi_apb_test
    axi_apb_aw_first_test
    axi_apb_w_first_test
    axi_apb_same_cycle_test
    axi_apb_partial_write_test
    axi_apb_wait_state_test
    axi_apb_error_test
    axi_apb_backpressure_test
    axi_apb_random_test
    axi_apb_coverage_test
}

foreach t $tests {
    echo "================ $t ================"
    vsim -c -coverage -wlf ${t}.wlf -onfinish stop -voptargs=+acc work.axi_apb_tb_top +UVM_TESTNAME=$t +UVM_NO_RELNOTES
    log -r /*
    run -all
    echo "================ COVERAGE: $t ================"
    coverage report -cvg -details -output ${t}_coverage.txt
    coverage save ${t}.ucdb
    quit -sim
}
