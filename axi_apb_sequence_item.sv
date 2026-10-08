`ifndef AXI_APB_SEQUENCE_ITEM_SV
	`define AXI_APB_SEQUENCE_ITEM_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

class axi_apb_sequence_item extends uvm_sequence_item;
	typedef enum {AXI_WRITE, AXI_READ} txn_type_e; 
	typedef enum {AW_FIRST, W_FIRST, AW_W_SAME_CYCLE} order_e;

	rand txn_type_e txn_type;
	rand logic [3:0]  addr;
	rand logic [31:0] wdata;
	rand logic [3:0]  wstrb;
	rand order_e aw_w_order;

        rand int   aw_delay;        
        rand int   w_delay;	
        rand int   ar_delay;
        rand int   bready_delay;
        rand int   rready_delay;
	rand int   seq_number;

	logic [31:0] rdata;
	logic [1:0]  axi_resp;
	int          apb_wait_cycles;
	logic        apb_pslverr;

	constraint addr_range_c {
		addr inside {[0:15]};
		}
		`uvm_object_utils_begin(axi_apb_sequence_item)
                `uvm_field_enum  (txn_type_e, txn_type , UVM_ALL_ON)
                `uvm_field_int   (addr           ,UVM_ALL_ON)
                `uvm_field_int   (wdata          ,UVM_ALL_ON)
                `uvm_field_int   (wstrb          ,UVM_ALL_ON)
                `uvm_field_int   (aw_delay       ,UVM_ALL_ON)
                `uvm_field_int   (w_delay        ,UVM_ALL_ON)
                `uvm_field_int   (ar_delay       ,UVM_ALL_ON)
                `uvm_field_int   (bready_delay   ,UVM_ALL_ON)
                `uvm_field_int   (rready_delay   ,UVM_ALL_ON)
                `uvm_field_int   (seq_number     ,UVM_ALL_ON)
                `uvm_field_int   (rdata          ,UVM_ALL_ON)
                `uvm_field_int   (axi_resp       ,UVM_ALL_ON)
                `uvm_field_int   (apb_wait_cycles,UVM_ALL_ON)
                `uvm_field_int   (apb_pslverr    ,UVM_ALL_ON)
                `uvm_field_enum  (order_e, aw_w_order , UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "axi_apb_sequence_item");
			super.new(name);
		endfunction
endclass
`endif
