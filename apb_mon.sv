`ifndef AXI_APB_M0N_SV
	`define AXI_APB_MON_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_apb_sequence_item.sv"

class apb_mon extends uvm_monitor;
	`uvm_component_utils(apb_mon)
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
	task run_phase(uvm_phase phase);
		int wait_count;
		logic [3:0]  paddr_reg;  
		logic        pwrite_reg; 
		logic [31:0] pwdata_reg ;	
		forever begin
			axi_apb_sequence_item txn;

			wait(vif.psel && !vif.penable);
			paddr_reg  = vif.paddr;
			pwrite_reg = vif.pwrite;
			pwdata_reg = vif.pwdata;
			wait_count = 0;

			while (!vif.pready)begin
				@(posedge vif.clk);
				wait_count = wait_count+1;
			end

			txn = axi_apb_sequence_item::type_id::create("txn");
			txn.addr            = paddr_reg;
			txn.axi_resp        = {1'b0, vif.pslverr};
			txn.apb_wait_cycles = wait_count;
			txn.apb_pslverr     = vif.pslverr;

			if(pwrite_reg) begin
				txn.txn_type = axi_apb_sequence_item::AXI_WRITE;
				txn.wdata    = pwdata_reg;
			end
			else begin
				txn.txn_type = axi_apb_sequence_item::AXI_READ;
				txn.rdata    = vif.prdata;
			end
			ap.write(txn);
		end
	endtask
endclass
`endif
