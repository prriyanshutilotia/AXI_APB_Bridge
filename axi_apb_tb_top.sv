`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;

module axi_apb_tb_top;

logic clk;
logic resetn;

initial clk = 1'b0;
always #5 clk =~clk;     // 10 ns clock period.

initial begin
	resetn = 1'b0;
	repeat(5)@(posedge clk); // Keep reset active for five clock cycles.
	resetn = 1'b1;
end

axi_apb_intf axi_if (
	.clk     (clk),
	.resetn  (resetn)
	);

	axi_to_apb_bridge bridge_dut(
		.aclk    (clk),
		.aresetn (resetn),
		.awaddr  (axi_if.awaddr),
		.awvalid (axi_if.awvalid),
		.awready (axi_if.awready),
		.wdata   (axi_if.wdata),
		.wstrb   (axi_if.wstrb),
		.wvalid  (axi_if.wvalid),
		.wready  (axi_if.wready),
		.bready  (axi_if.bready),
		.bvalid  (axi_if.bvalid),
		.bresp   (axi_if.bresp),
		.araddr  (axi_if.araddr),
		.arvalid (axi_if.arvalid),
		.arready (axi_if.arready),
		.rready  (axi_if.rready),
		.rvalid  (axi_if.rvalid),
		.rdata   (axi_if.rdata),
		.rresp   (axi_if.rresp),
		.pready  (axi_if.pready),
		.prdata  (axi_if.prdata),
		.pslverr (axi_if.pslverr),
		.paddr   (axi_if.paddr),
		.pwdata  (axi_if.pwdata),
		.pstrb   (axi_if.pstrb),
		.pwrite  (axi_if.pwrite),
		.psel    (axi_if.psel),
		.penable (axi_if.penable)
	);

	apb_ram_slave apb_slave (
		.pclk    (clk),
		.presetn (resetn),
		.paddr   (axi_if.paddr),
		.pwdata  (axi_if.pwdata),
		.prdata  (axi_if.prdata),
		.pstrb   (axi_if.pstrb),
		.pwrite  (axi_if.pwrite),
		.psel    (axi_if.psel),
		.penable (axi_if.penable),
		.pready  (axi_if.pready),
		.pslverr (axi_if.pslverr)
	);

	// Assertions and coverage observe the interface without driving it.
	axi_assert_checker    axi_checks(axi_if);
	apb_assert_checker    apb_checks(axi_if);
	bridge_cov_collector  coverage(axi_if);

initial begin
	string test_name;
	uvm_config_db#(virtual axi_apb_intf)::set(null, "*", "vif", axi_if); // Pass interface to all UVM components.
	// run.do supplies +UVM_TESTNAME=<test>.  A direct vsim launch without
	// that argument still runs the smoke test instead of issuing UVM NOCOMP.
	if (!$value$plusargs("UVM_TESTNAME=%s", test_name))
		test_name = "axi_apb_test";
	run_test(test_name);
end

initial begin
	#2ms; // Stop the simulation if a transaction becomes stuck.
	`uvm_fatal("TB_TIMEOUT", "simulation timed out")
end

//final begin
//	axi_apb_scoreboard::final_report();
//end


endmodule
		
