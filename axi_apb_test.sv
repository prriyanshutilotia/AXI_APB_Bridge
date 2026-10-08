`ifndef AXI_APB_TEST_SV
	`define AXI_APB_TEST_SV

	`include "uvm_macros.svh"
	import uvm_pkg::*;
	`include "axi_apb_env.sv"
	`include "axi_apb_sequence.sv"

	class axi_apb_test extends uvm_test;
		`uvm_component_utils(axi_apb_test)

		axi_apb_env env;
		
		function new(string name, uvm_component parent);
			super.new(name, parent);
		endfunction

		function void build_phase(uvm_component parent);
			super.build_phase(phase);
			env = axi_apb_env::type_id::create("env",this);
		endfunction
	endclass
`endif
