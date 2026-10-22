# Open an interactive waveform for the complete directed + random regression.
# Invoke in the Questa transcript with:  do wave.do
if {![file exists work]} {vlib work}
vmap work work

vlog -work work -sv +acc +cover=bcesf axi_apb_top.svh
vsim -coverage -voptargs=+acc work.axi_apb_tb_top +UVM_TESTNAME=axi_apb_coverage_test +UVM_NO_RELNOTES

add wave -divider {Clock and reset}
add wave sim:/axi_apb_tb_top/clk
add wave sim:/axi_apb_tb_top/resetn

add wave -divider {AXI write address channel}
add wave -radix hex sim:/axi_apb_tb_top/axi_if/awaddr
add wave sim:/axi_apb_tb_top/axi_if/awvalid
add wave sim:/axi_apb_tb_top/axi_if/awready

add wave -divider {AXI write data and response}
add wave -radix hex sim:/axi_apb_tb_top/axi_if/wdata
add wave -radix hex sim:/axi_apb_tb_top/axi_if/wstrb
add wave sim:/axi_apb_tb_top/axi_if/wvalid
add wave sim:/axi_apb_tb_top/axi_if/wready
add wave -radix hex sim:/axi_apb_tb_top/axi_if/bresp
add wave sim:/axi_apb_tb_top/axi_if/bvalid
add wave sim:/axi_apb_tb_top/axi_if/bready

add wave -divider {AXI read address and response}
add wave -radix hex sim:/axi_apb_tb_top/axi_if/araddr
add wave sim:/axi_apb_tb_top/axi_if/arvalid
add wave sim:/axi_apb_tb_top/axi_if/arready
add wave -radix hex sim:/axi_apb_tb_top/axi_if/rdata
add wave -radix hex sim:/axi_apb_tb_top/axi_if/rresp
add wave sim:/axi_apb_tb_top/axi_if/rvalid
add wave sim:/axi_apb_tb_top/axi_if/rready

add wave -divider {APB transfer}
add wave -radix hex sim:/axi_apb_tb_top/axi_if/paddr
add wave -radix hex sim:/axi_apb_tb_top/axi_if/pwdata
add wave -radix hex sim:/axi_apb_tb_top/axi_if/prdata
add wave -radix hex sim:/axi_apb_tb_top/axi_if/pstrb
add wave sim:/axi_apb_tb_top/axi_if/pwrite
add wave sim:/axi_apb_tb_top/axi_if/psel
add wave sim:/axi_apb_tb_top/axi_if/penable
add wave sim:/axi_apb_tb_top/axi_if/pready
add wave sim:/axi_apb_tb_top/axi_if/pslverr

add wave -divider {Bridge internal state}
add wave sim:/axi_apb_tb_top/bridge_dut/state
add wave sim:/axi_apb_tb_top/bridge_dut/aw_captured
add wave sim:/axi_apb_tb_top/bridge_dut/w_captured
add wave sim:/axi_apb_tb_top/bridge_dut/ar_captured

run -all
wave zoom full
coverage report -cvg
view coverage
