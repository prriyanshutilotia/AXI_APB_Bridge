`ifndef AXI_APB_SEQUENCER_SV
	`define AXI_APB_SEQUENCER_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_apb_sequence_item.sv"

class axi_apb_sequencer extends uvm_sequencer #(axi_apb_sequence_item);
	`uvm_component_utils(axi_apb_sequencer)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
endclass
`endif
