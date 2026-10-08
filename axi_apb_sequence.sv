`ifndef AXI_APB_SEQUENCE_SV
	`define AXI_APB_SEQUENCE_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_apb_sequence_item.sv"

class axi_apb_sequence extends uvm_sequence #(axi_apb_sequence_item);
	`uvm_object_utils(axi_apb_sequence)

	function new(string name = "axi_apb_sequence");
		super.new(name);
	endfunction

	task body();
		axi_apb_sequence_item req;
		axi_apb_sequence_item req2;

		req = axi_apb_sequence_item::type_id::create("req");
		start_item(req);
                assert(req.randomize() with {
			txn_type == AXI_WRITE;
			addr == 4'd0;
			wstrb == 4'b1111;
			});
		finish_item(req);
		req2 = axi_apb_sequence_item::type_id::create("req2");
		start_item(req2);
		assert(req2.randomize() with {
			txn_type == AXI_READ;
			addr == 4'b0;
			});
			finish_item(req2);
	endtask
endclass
`endif
