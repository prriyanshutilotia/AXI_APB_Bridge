`ifndef AXI_APB_SCOREBOARD_SV
`define AXI_APB_SCOREBOARD_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`uvm_analysis_imp_decl(_axi)
`uvm_analysis_imp_decl(_apb)
`include "axi_apb_sequence_item.sv"

//====================================================================
// Scoreboard
//  - AXI monitor and APB monitor each push into their own queue
//  - one AXI transaction is matched with one APB transaction (FIFO order,
//    valid because the bridge handles one transaction at a time)
//  - per transaction it checks:
//      1. AXI request == APB transfer (type, address, wdata/pstrb, rdata)
//      2. APB PSLVERR is 1 only for address 15
//      3. AXI response is OKAY for 0-14, SLVERR for 15
//      4. read data == reference memory model (address 15 -> 0)
//  - expected_mem is updated byte-wise using WSTRB; address 15 never updates it
//====================================================================
class axi_apb_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(axi_apb_scoreboard)

	uvm_analysis_imp_axi #(axi_apb_sequence_item, axi_apb_scoreboard) axi_imp;
	uvm_analysis_imp_apb #(axi_apb_sequence_item, axi_apb_scoreboard) apb_imp;

	axi_apb_sequence_item axi_txn_queue[$];
	axi_apb_sequence_item apb_txn_queue[$];
	logic [31:0] expected_mem [0:15];

	static int total_checks;
	static int pass_count;
	static int fail_count;

	bit ok;   // result of the transaction currently being checked

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		axi_imp = new("axi_imp", this);
		apb_imp = new("apb_imp", this);
		for (int i = 0; i < 16; i++) expected_mem[i] = 32'b0;   // RAM resets to 0
	endfunction

	function void write_axi(axi_apb_sequence_item txn);
		axi_txn_queue.push_back(txn);
		try_match();
	endfunction

	function void write_apb(axi_apb_sequence_item txn);
		apb_txn_queue.push_back(txn);
		try_match();
	endfunction

	function void mismatch(string msg);
		ok = 1'b0;
		`uvm_error("SCB", msg)
	endfunction

	function void try_match();
		axi_apb_sequence_item axi_txn;
		axi_apb_sequence_item apb_txn;
		logic [1:0]           exp_resp;

		while (axi_txn_queue.size() > 0 && apb_txn_queue.size() > 0) begin
			axi_txn = axi_txn_queue.pop_front();
			apb_txn = apb_txn_queue.pop_front();
			ok = 1'b1;
			total_checks++;

			// 1. AXI request must equal the APB transfer the bridge produced
			if (axi_txn.txn_type != apb_txn.txn_type)
				mismatch($sformatf("type mismatch axi=%s apb=%s", axi_txn.txn_type.name(), apb_txn.txn_type.name()));
			if (axi_txn.addr != apb_txn.addr)
				mismatch($sformatf("addr mismatch axi=%0d apb=%0d", axi_txn.addr, apb_txn.addr));

			if (axi_txn.txn_type == axi_apb_sequence_item::AXI_WRITE) begin
				if (axi_txn.wdata !== apb_txn.wdata)
					mismatch($sformatf("wdata mismatch axi=%h apb=%h", axi_txn.wdata, apb_txn.wdata));
				if (axi_txn.wstrb !== apb_txn.pstrb)
					mismatch($sformatf("wstrb/pstrb mismatch axi=%b apb=%b", axi_txn.wstrb, apb_txn.pstrb));
			end
			else begin
				if (axi_txn.rdata !== apb_txn.rdata)
					mismatch($sformatf("rdata mismatch axi=%h apb=%h", axi_txn.rdata, apb_txn.rdata));
			end

			// 2/3. error handling: only address 15 errors
			exp_resp = (axi_txn.addr == 4'd15) ? 2'b10 : 2'b00;
			if (apb_txn.apb_pslverr !== (axi_txn.addr == 4'd15))
				mismatch($sformatf("pslverr mismatch addr=%0d pslverr=%b", axi_txn.addr, apb_txn.apb_pslverr));
			if (axi_txn.axi_resp !== exp_resp)
				mismatch($sformatf("resp mismatch addr=%0d got=%b exp=%b", axi_txn.addr, axi_txn.axi_resp, exp_resp));

			// 4. reference memory model
			if (axi_txn.txn_type == axi_apb_sequence_item::AXI_WRITE) begin
				if (axi_txn.addr != 4'd15) begin
					for (int i = 0; i < 4; i++) begin
						if (axi_txn.wstrb[i])
							expected_mem[axi_txn.addr][8*i +: 8] = axi_txn.wdata[8*i +: 8];
					end
				end
			end
			else begin
				if (axi_txn.addr == 4'd15) begin
					if (axi_txn.rdata !== 32'b0)
						mismatch($sformatf("error read must return 0, got %h", axi_txn.rdata));
				end
				else if (axi_txn.rdata !== expected_mem[axi_txn.addr]) begin
					mismatch($sformatf("read data mismatch addr=%0d got=%h exp=%h",
					                   axi_txn.addr, axi_txn.rdata, expected_mem[axi_txn.addr]));
				end
			end

			if (ok) pass_count++;
			else    fail_count++;
		end
	endfunction

	// anything left in a queue means one monitor saw a transaction the other did not
	function void check_phase(uvm_phase phase);
		super.check_phase(phase);
		if (axi_txn_queue.size() != 0 || apb_txn_queue.size() != 0) begin
			fail_count++;
			`uvm_error("SCB", $sformatf("unmatched transactions left: axi=%0d apb=%0d",
			                            axi_txn_queue.size(), apb_txn_queue.size()))
		end
	endfunction

	function void report_phase(uvm_phase phase);
		super.report_phase(phase);
		final_report();
	endfunction

	// a run with zero checks is NOT a pass
	static function bit all_passed();
		return (fail_count == 0 && total_checks > 0);
	endfunction

	static function void final_report();
		$display("SCB REPORT: Total=%0d Pass=%0d Fail=%0d", total_checks, pass_count, fail_count);
		if (all_passed()) $display("TEST PASSED");
		else              $display("TEST FAILED");
	endfunction
endclass

`endif
