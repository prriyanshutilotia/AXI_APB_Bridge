`ifndef AXI_APB_SCOREBOARD_SV
	`define AXI_APB_SCOREBOARD_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`uvm_analysis_imp_decl(_axi)
`uvm_analysis_imp_decl(_apb)
`include "axi_apb_sequence_item.sv"

class axi_apb_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(axi_apb_scoreboard)
	uvm_analysis_imp_axi #(axi_apb_sequence_item, axi_apb_scoreboard) axi_imp;
	uvm_analysis_imp_apb #(axi_apb_sequence_item, axi_apb_scoreboard) apb_imp;

	axi_apb_sequence_item axi_txn_queue[$];
	axi_apb_sequence_item apb_txn_queue[$];
	logic [31:0] expected_mem[15:0];
        static int total_checks;
        static int pass_count;
        static int fail_count;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		axi_imp = new("axi_imp",this);
		apb_imp = new("apb_imp",this);
	endfunction

	function void write_axi(axi_apb_sequence_item txn);
		axi_txn_queue.push_back(txn);
		try_match();
	endfunction

	function void write_apb(axi_apb_sequence_item txn);
		apb_txn_queue.push_back(txn);
		try_match();
	endfunction

	function void try_match();

		axi_apb_sequence_item axi_txn;
		axi_apb_sequence_item apb_txn;

		if (axi_txn_queue.size() > 0 && apb_txn_queue.size() > 0) begin
			axi_txn = axi_txn_queue.pop_front();
			apb_txn = apb_txn_queue.pop_front();
			total_checks = total_checks + 1;

			if (axi_txn.txn_type == axi_apb_sequence_item::AXI_WRITE) begin
				if (axi_txn.addr == 15) begin
					if (axi_txn.axi_resp == 2'b10) begin
						pass_count = pass_count + 1;
					end
					else begin
						fail_count = fail_count + 1;
					end
				end
				else begin
					expected_mem[axi_txn.addr] = axi_txn.wdata;
					if (axi_txn.axi_resp == 2'b00)
				       	begin
						pass_count = pass_count + 1;
					end
					else begin
						fail_count = fail_count + 1;
					end
				end
			end
			else begin
				if(axi_txn.addr == 15)
				begin
					if (axi_txn.axi_resp == 2'b10 && axi_txn.rdata == 32'b0)
					begin
						pass_count++;
					end
					else begin
						fail_count++;
					end
				end
				else begin
					if (axi_txn.rdata == expected_mem[axi_txn.addr])
					begin
						pass_count++;
					end
					else begin
						fail_count++;
					end
				end
			end
		end
	endfunction

	static function bit all_passed();
	return (fail_count == 0);
endfunction
static function void final_report();
$display("SCB REPORT :Total =%0d pass =%0d fail =%0d", total_checks, pass_count, fail_count,);
endfunction
endclass
`endif
