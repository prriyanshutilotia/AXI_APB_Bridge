`ifndef AXI_APB_MON_SV
	`define AXI_APB_MOM_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_apb_sequence_item.sv"

class axi_apb_mon extends uvm_monitor;
	`uvm_component_utils(axi_apb_mon)
	virtual axi_apb_intf vif;
	uvm_analysis_port#(axi_apb_sequence_item)ap;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual axi_apb_intf)::get(this,"","vif",vif))
			`uvm_fatal("NOVIF","virtual interface not found")
		ap = new("ap", this);
	endfunction
	logic [3:0]  awaddr_reg;
	logic [31:0] wdata_reg;
	logic [3:0]  wstrb_reg;
	logic [3:0]  araddr_reg;
	logic        aw_seen;
	logic        w_seen;

	task run_phase(uvm_phase phase);
		forever begin
			@(posedge vif.clk);
			if(vif.awvalid && vif.awready) begin
				awaddr_reg <= vif.awaddr;
				aw_seen    <= 1'b1;
			end
			if(vif.wvalid && vif.wready) begin
				wdata_reg <= vif.wdata;
				wstrb_reg <= vif.wstrb;
				w_seen    <= 1'b1;
			end
			if(vif.bvalid && vif.bready) begin
				axi_apb_sequence_item txn;
				txn = axi_apb_sequence_item::type_id::create("txn");
				txn.txn_type = axi_apb_sequence_item::AXI_WRITE;
				txn.addr     = awaddr_reg;
				txn.wdata    = wdata_reg;
				txn.wstrb    = wstrb_reg;
				txn.axi_resp = vif.bresp;
				ap.write(txn);

				aw_seen <= 1'b0;
				w_seen  <= 1'b0;
			end
			if(vif.arvalid && vif.arready) begin
				araddr_reg <= vif.araddr;
			end
			if(vif.rvalid && vif.rready) begin
				axi_apb_sequence_item txn;
				txn = axi_apb_sequence_item::type_id::create("txn");
				txn.txn_type = axi_apb_sequence_item::AXI_READ;
				txn.addr     = araddr_reg;
				txn.rdata    = vif.rdata;
				txn.axi_resp = vif.rresp;
				ap.write(txn);
			end
		end
	endtask
endclass
`endif
