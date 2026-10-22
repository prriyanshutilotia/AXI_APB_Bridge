`ifndef AXI_APB_DRIVER_SV
`define AXI_APB_DRIVER_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_apb_sequence_item.sv"

//====================================================================
// AXI master driver.
//  - every vif output uses a non-blocking assignment (<=) so the DUT and
//    the monitor both see the change AFTER the clock edge (no race)
//  - a handshake completes on the first edge where VALID=1 and READY=1,
//    so each task samples READY with  "@(posedge clk); while(!ready) @(posedge clk);"
//  - delay arguments come from the sequence item (aw_delay, w_delay,
//    ar_delay, bready_delay, rready_delay)
//====================================================================
class axi_apb_driver extends uvm_driver #(axi_apb_sequence_item);
	`uvm_component_utils(axi_apb_driver)

	virtual axi_apb_intf vif;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual axi_apb_intf)::get(this, "", "vif", vif))
			`uvm_fatal("NOVIF", "virtual interface not found")
	endfunction

	task run_phase(uvm_phase phase);
		axi_apb_sequence_item req;

		vif.awvalid <= 1'b0;
		vif.wvalid  <= 1'b0;
		vif.bready  <= 1'b0;
		vif.arvalid <= 1'b0;
		vif.rready  <= 1'b0;
		wait (vif.resetn);
		@(posedge vif.clk);

		forever begin
			seq_item_port.get_next_item(req); // Block until the sequence supplies a request.

			if (req.txn_type == axi_apb_sequence_item::AXI_WRITE) begin
				case (req.aw_w_order)
					axi_apb_sequence_item::AW_FIRST: begin
						drive_aw(req.addr, req.aw_delay);
						drive_w(req.wdata, req.wstrb, req.w_delay);
					end
					axi_apb_sequence_item::W_FIRST: begin
						drive_w(req.wdata, req.wstrb, req.w_delay);
						drive_aw(req.addr, req.aw_delay);
					end
					axi_apb_sequence_item::AW_W_SAME_CYCLE: begin
						fork
							drive_aw(req.addr, req.aw_delay);
							drive_w(req.wdata, req.wstrb, req.w_delay);
						join
					end
				endcase
				wait_and_capture_bresp(req.axi_resp, req.bready_delay);
			end
			else begin
				drive_ar(req.addr, req.ar_delay);
				wait_and_capture_rdata(req.rdata, req.axi_resp, req.rready_delay);
			end

			seq_item_port.item_done(); // Allow the sequence to issue the next transaction.
		end
	endtask

	//---------------- request channels ----------------
	task drive_aw(input logic [3:0] addr, input int delay);
		repeat (delay) @(posedge vif.clk);
		vif.awaddr  <= addr;
		vif.awvalid <= 1'b1; // Keep VALID high until the slave accepts address.
		@(posedge vif.clk);
		while (!vif.awready) @(posedge vif.clk);
		vif.awvalid <= 1'b0;
	endtask

	task drive_w(input logic [31:0] data, input logic [3:0] strb, input int delay);
		repeat (delay) @(posedge vif.clk);
		vif.wdata  <= data;
		vif.wstrb  <= strb;
		vif.wvalid <= 1'b1; // Keep VALID high until the slave accepts write data.
		@(posedge vif.clk);
		while (!vif.wready) @(posedge vif.clk);
		vif.wvalid <= 1'b0;
	endtask

	task drive_ar(input logic [3:0] addr, input int delay);
		repeat (delay) @(posedge vif.clk);
		vif.araddr  <= addr;
		vif.arvalid <= 1'b1; // Keep VALID high until the slave accepts read address.
		@(posedge vif.clk);
		while (!vif.arready) @(posedge vif.clk);
		vif.arvalid <= 1'b0;
	endtask

	//---------------- response channels ----------------
	task wait_and_capture_bresp(output logic [1:0] resp, input int delay);
		repeat (delay) @(posedge vif.clk);
		vif.bready <= 1'b1; // Apply configurable backpressure before accepting B response.
		@(posedge vif.clk);
		while (!vif.bvalid) @(posedge vif.clk);
		resp = vif.bresp;
		vif.bready <= 1'b0;
	endtask

	task wait_and_capture_rdata(output logic [31:0] data, output logic [1:0] resp, input int delay);
		repeat (delay) @(posedge vif.clk);
		vif.rready <= 1'b1; // Apply configurable backpressure before accepting R response.
		@(posedge vif.clk);
		while (!vif.rvalid) @(posedge vif.clk);
		resp = vif.rresp;
		data = vif.rdata;
		vif.rready <= 1'b0;
	endtask
endclass

`endif
