`ifndef AXI_APB_ENV_SV
	`define AXI_APB_ENV_SV

	`include "uvm_macros.svh"
	import uvm_pkg::*;
	`include "axi_apb_agent.sv"
	`include "apb_mon.sv"
	`include "axi_apb_scoreboard.sv"

	class axi_apb_env extends uvm_env;
		`uvm_component_utils(axi_apb_env)

		axi_apb_agent      agent;
		apb_mon            apb_monitor;
		axi_apb_scoreboard scoreboard;
		function new(string name, uvm_component parent);
			super.new(name, parent);
		endfunction

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			agent       =axi_apb_agent::type_id::create("agent",this);
			apb_monitor =apb_mon::type_id::create("apb_monitor",this);
		        scoreboard  =axi_apb_scoreboard::type_id::create("scoreboard",this);
		endfunction

		function void connect_phase(uvm_phase phase);
			super.connect_phase(phase);
			agent.monitor.ap.connect(scoreboard.axi_imp);
			apb_monitor.ap.connect(scoreboard.apb_imp);
		endfunction
	endclass
`endif
