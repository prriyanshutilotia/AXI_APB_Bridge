`ifndef AXI_APB_MON_SV
	`define AXI_APB_MON_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_apb_sequence_item.sv"

class axi_apb_mon extends uvm_monitor;
	`uvm_component_utils(axi_apb_mon)
	virtual axi_apb_intf vif; // Handle to sampled DUT pins.
	uvm_analysis_port#(axi_apb_sequence_item)ap; // Broadcast completed transactions to scoreboard.

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual axi_apb_intf)::get(this,"","vif",vif))
			`uvm_fatal("NOVIF","virtual interface not found")
		ap = new("ap", this);
	endfunction
	// AXI write address and write data may arrive on different clocks, so save both.
	logic [3:0]  awaddr_reg;
	logic [31:0] wdata_reg;
	logic [3:0]  wstrb_reg;
	logic [3:0]  araddr_reg;
	logic        aw_seen;
	logic        w_seen;
	logic [3:0]  pstrb_reg;

	task run_phase(uvm_phase phase);
		forever begin
			@(vif.monitor_cb);

		//	if(vif.monitor_cb.bvalid || vif.monitor_cb.rvalid)
		//		`uvm_info("AXIMON", $sformatf("bvalid=%b bready=%b rvalid=%b rready=%b", vif.monitor_cb.bvalid, vif.monitor_cb.bready, vif.monitor_cb.bready, vif.monitor_cb.rvalid, vif.monitor_cb.rready), UVM_NONE)
			if(vif.monitor_cb.awvalid && vif.monitor_cb.awready) begin // AW handshake.
				awaddr_reg <= vif.monitor_cb.awaddr;				
				aw_seen    <= 1'b1;
			end
			if(vif.monitor_cb.wvalid && vif.monitor_cb.wready) begin // W handshake.
				wdata_reg <= vif.monitor_cb.wdata;
				wstrb_reg <= vif.monitor_cb.wstrb;
				pstrb_reg <= vif.monitor_cb.wstrb;
				w_seen    <= 1'b1;
			end
			if(vif.monitor_cb.bvalid && vif.monitor_cb.bready) begin // B handshake completes one write.
				axi_apb_sequence_item txn;
				txn = axi_apb_sequence_item::type_id::create("txn");
				txn.txn_type = axi_apb_sequence_item::AXI_WRITE;
				txn.addr     = awaddr_reg;
				txn.wdata    = wdata_reg;
				txn.wstrb    = wstrb_reg;
				txn.pstrb    = pstrb_reg;
				txn.axi_resp = vif.monitor_cb.bresp;
				ap.write(txn); // Publish the reconstructed AXI write transaction.

				aw_seen <= 1'b0;
				w_seen  <= 1'b0;
			end
			if(vif.monitor_cb.arvalid && vif.monitor_cb.arready) begin // AR handshake.
				araddr_reg <= vif.monitor_cb.araddr;
			end
			if(vif.monitor_cb.rvalid && vif.monitor_cb.rready) begin // R handshake completes one read.
				axi_apb_sequence_item txn;
				txn = axi_apb_sequence_item::type_id::create("txn");
				txn.txn_type = axi_apb_sequence_item::AXI_READ;
				txn.addr     = araddr_reg;
				txn.rdata    = vif.monitor_cb.rdata;
				txn.axi_resp = vif.monitor_cb.rresp;
				ap.write(txn);
			end
		end
	endtask
endclass
`endif
