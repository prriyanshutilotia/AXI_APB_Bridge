`ifndef AXI_APB_AGENT_SV
	`define AXI_APB_AGENT_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_apb_sequencer.sv"
`include "axi_apb_driver.sv"
`include "axi_apb_mon.sv"

class axi_apb_agent extends uvm_agent;
	`uvm_component_utils(axi_apb_agent)

	axi_apb_sequencer sequencer;
	axi_apb_driver    driver;
	axi_apb_mon       monitor;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		sequencer = axi_apb_sequencer::type_id::create("sequencer",this);
		driver    = axi_apb_driver::type_id::create("driver",this);
		monitor   = axi_apb_mon::type_id::create("monitor",this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		driver.seq_item_port.connect(sequencer.seq_item_export);
	endfunction
endclass
`endif
