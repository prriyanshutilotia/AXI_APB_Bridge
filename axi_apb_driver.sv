`ifndef AXI_APB_DRIVER_SV
	`define AXI_APB_DRIVER_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_apb_sequence_item.sv"

class axi_apb_driver extends uvm_driver #(axi_apb_sequence_item);
	`uvm_component_utils(axi_apb_driver)
	virtual axi_apb_intf vif;
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual axi_apb_intf)::get(this,"","vif",vif))
			`uvm_fatal("NOVIF","virtual interface not found")
	endfunction

	task run_phase(uvm_phase phase);
		axi_apb_sequence_item req;
                vif.awvalid = 1'b0;
                vif.wvalid  = 1'b0;
                vif.bready  = 1'b0;
                vif.arvalid = 1'b0;
                vif.rready  = 1'b0;
                wait(vif.resetn);

		forever begin
			seq_item_port.get_next_item(req);
			if (req.txn_type == axi_apb_sequence_item::AXI_WRITE) begin
				case (req.aw_w_order)
					axi_apb_sequence_item::AW_FIRST:begin
						drive_aw(req.addr);
						drive_w(req.wdata, req.wstrb);
					end
					axi_apb_sequence_item::W_FIRST:begin
						drive_w(req.wdata, req.wstrb);
						drive_aw(req.addr);
					end
					axi_apb_sequence_item::AW_W_SAME_CYCLE:begin
						fork
							drive_aw(req.addr);
							drive_w(req.wdata, req.wstrb);
						join
					end
				endcase
				wait_and_capture_bresp(req.axi_resp);
			end
			else begin
				drive_ar(req.addr);
				wait_and_capture_rdata(req.rdata, req.axi_resp);
			end
			seq_item_port.item_done();
		end
	endtask

	task drive_aw(input logic[3:0] addr);
		vif.awaddr = addr;
		vif.awvalid= 1'b1;
		@(posedge vif.clk);
		wait(vif.awready);
		vif.awvalid= 1'b0;
	endtask
	task drive_w(input logic[31:0]data, input logic [3:0]strb);
		vif.wdata  = data;
		vif.wvalid = 1'b1;
		vif.wstrb  = strb;
		@(posedge vif.clk);
		wait(vif.wready);
		vif.wvalid = 1'b0;
	endtask
	task drive_ar(input logic[3:0]addr);
		vif.araddr  = addr;
		vif.arvalid = 1'b1;
		@(posedge vif.clk);
		wait(vif.arready);
		vif.arvalid = 1'b0;
	endtask
	task wait_and_capture_bresp(output logic [1:0]resp);
		vif.bready = 1'b1;
		wait(vif.bvalid);
		resp       = vif.bresp;
		@(posedge vif.clk);
		vif.bready = 1'b0;
	endtask
	task wait_and_capture_rdata (output logic[31:0]data, output logic[1:0]resp);
		vif.rready = 1'b1;
		wait(vif.rvalid);
		resp       = vif.rresp;
		data       = vif.rdata;
		@(posedge vif.clk);
		vif.rready = 1'b0;
	endtask
endclass
`endif
