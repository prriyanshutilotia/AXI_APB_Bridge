`ifndef AXI_APB_SEQUENCE_SV
`define AXI_APB_SEQUENCE_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_apb_sequence_item.sv"

//====================================================================
// Base sequence: helper tasks shared by every sequence
//   do_write / do_read : send ONE transaction with fixed values
//   wr_rd              : write then read back the same address
//   aw_d,w_d,... are delays (in clock cycles) applied by the driver
//====================================================================
class axi_apb_base_sequence extends uvm_sequence #(axi_apb_sequence_item);
	`uvm_object_utils(axi_apb_base_sequence)

	int aw_d, w_d, b_d, ar_d, r_d;

	function new(string name = "axi_apb_base_sequence");
		super.new(name);
	endfunction

	task do_write(logic [3:0] a, logic [31:0] d, logic [3:0] s, axi_apb_sequence_item::order_e o);
		axi_apb_sequence_item req;
		req = axi_apb_sequence_item::type_id::create("req");
		start_item(req);
		assert(req.randomize() with {
			txn_type     == axi_apb_sequence_item::AXI_WRITE;
			addr         == a;
			wdata        == d;
			wstrb        == s;
			aw_w_order   == o;
			aw_delay     == aw_d;
			w_delay      == w_d;
			bready_delay == b_d;
		});
		finish_item(req);
	endtask

	task do_read(logic [3:0] a);
		axi_apb_sequence_item req;
		req = axi_apb_sequence_item::type_id::create("req");
		start_item(req);
		assert(req.randomize() with {
			txn_type     == axi_apb_sequence_item::AXI_READ;
			addr         == a;
			ar_delay     == ar_d;
			rready_delay == r_d;
		});
		finish_item(req);
	endtask

	task wr_rd(logic [3:0] a, axi_apb_sequence_item::order_e o);
		do_write(a, $urandom, 4'hF, o);
		do_read(a);
	endtask

	function axi_apb_sequence_item::order_e pick_order(int n);
		axi_apb_sequence_item::order_e o;
		case (n % 3)
			0:       o = axi_apb_sequence_item::AW_FIRST;
			1:       o = axi_apb_sequence_item::W_FIRST;
			default: o = axi_apb_sequence_item::AW_W_SAME_CYCLE;
		endcase
		return o;
	endfunction
endclass

//====================================================================
// 1. Smoke: one write, one read, address 0
//====================================================================
class axi_apb_sequence extends axi_apb_base_sequence;
	`uvm_object_utils(axi_apb_sequence)

	function new(string name = "axi_apb_sequence");
		super.new(name);
	endfunction

	task body();
		do_write(4'd0, 32'hA5A5_0001, 4'hF, axi_apb_sequence_item::AW_FIRST);
		do_read(4'd0);
	endtask
endclass

//====================================================================
// 2-4. Order sequences: 8 write+read pairs, all using the same order
//====================================================================
class axi_apb_order_sequence extends axi_apb_base_sequence;
	`uvm_object_utils(axi_apb_order_sequence)

	axi_apb_sequence_item::order_e ord = axi_apb_sequence_item::AW_FIRST;

	function new(string name = "axi_apb_order_sequence");
		super.new(name);
	endfunction

	task body();
		for (int i = 0; i < 8; i++) begin
			wr_rd(i[3:0], ord);
		end
	endtask
endclass

class axi_apb_aw_first_sequence extends axi_apb_order_sequence;
	`uvm_object_utils(axi_apb_aw_first_sequence)
	function new(string name = "axi_apb_aw_first_sequence");
		super.new(name);
		ord = axi_apb_sequence_item::AW_FIRST;
	endfunction
endclass

class axi_apb_w_first_sequence extends axi_apb_order_sequence;
	`uvm_object_utils(axi_apb_w_first_sequence)
	function new(string name = "axi_apb_w_first_sequence");
		super.new(name);
		ord = axi_apb_sequence_item::W_FIRST;
	endfunction
endclass

// delays stay 0, so AWVALID and WVALID rise on the same clock edge
class axi_apb_same_cycle_sequence extends axi_apb_order_sequence;
	`uvm_object_utils(axi_apb_same_cycle_sequence)
	function new(string name = "axi_apb_same_cycle_sequence");
		super.new(name);
		ord = axi_apb_sequence_item::AW_W_SAME_CYCLE;
	endfunction
endclass

//====================================================================
// 5. Error address 15: write + read, and check neighbour 14 is untouched
//====================================================================
class axi_apb_error_sequence extends axi_apb_base_sequence;
	`uvm_object_utils(axi_apb_error_sequence)

	function new(string name = "axi_apb_error_sequence");
		super.new(name);
	endfunction

	task body();
		wr_rd(4'd14, axi_apb_sequence_item::AW_FIRST);
		do_write(4'd15, 32'hDEAD_BEEF, 4'hF, axi_apb_sequence_item::AW_FIRST);
		do_read(4'd15);
		do_write(4'd15, 32'h1234_5678, 4'hF, axi_apb_sequence_item::W_FIRST);
		do_read(4'd15);
		do_write(4'd15, 32'hCAFE_F00D, 4'hF, axi_apb_sequence_item::AW_W_SAME_CYCLE);
		do_read(4'd15);
		do_read(4'd14);
	endtask
endclass

//====================================================================
// 6. Wait states: addresses 0..14 cover 0,1,2,3 APB wait cycles
//====================================================================
class axi_apb_wait_state_sequence extends axi_apb_base_sequence;
	`uvm_object_utils(axi_apb_wait_state_sequence)

	function new(string name = "axi_apb_wait_state_sequence");
		super.new(name);
	endfunction

	task body();
		for (int i = 0; i < 15; i++) begin
			wr_rd(i[3:0], axi_apb_sequence_item::AW_FIRST);
		end
	endtask
endclass

//====================================================================
// 7. Partial writes: every non-zero WSTRB value (all bytes + combinations)
//====================================================================
class axi_apb_partial_write_sequence extends axi_apb_base_sequence;
	`uvm_object_utils(axi_apb_partial_write_sequence)

	function new(string name = "axi_apb_partial_write_sequence");
		super.new(name);
	endfunction

	task body();
		do_write(4'd3, 32'h1122_3344, 4'hF, axi_apb_sequence_item::AW_FIRST);
		do_read(4'd3);
		for (int s = 1; s < 16; s++) begin
			do_write(4'd3, $urandom, s[3:0], axi_apb_sequence_item::AW_FIRST);
			do_read(4'd3);
		end
	endtask
endclass

//====================================================================
// 8. Backpressure: BREADY / RREADY (and request channels) delayed
//====================================================================
class axi_apb_backpressure_sequence extends axi_apb_base_sequence;
	`uvm_object_utils(axi_apb_backpressure_sequence)

	function new(string name = "axi_apb_backpressure_sequence");
		super.new(name);
	endfunction

	task body();
		for (int d = 0; d < 4; d++) begin
			aw_d = d;
			w_d  = 3 - d;
			ar_d = d;
			b_d  = d + 1;
			r_d  = d + 1;
			wr_rd(d[3:0], pick_order(d));
		end
		aw_d = 0;
		w_d  = 0;
		ar_d = 0;
		b_d  = 4;
		r_d  = 4;
		wr_rd(4'd8, axi_apb_sequence_item::AW_W_SAME_CYCLE);
	endtask
endclass

//====================================================================
// 9. Random: 40 fully random transactions (delays randomised too)
//====================================================================
class axi_apb_random_sequence extends axi_apb_base_sequence;
	`uvm_object_utils(axi_apb_random_sequence)

	function new(string name = "axi_apb_random_sequence");
		super.new(name);
	endfunction

	task body();
		repeat (40) begin
			axi_apb_sequence_item req;
			req = axi_apb_sequence_item::type_id::create("req");
			start_item(req);
			assert(req.randomize());
			finish_item(req);
		end
	endtask
endclass

//====================================================================
// 10. Everything in one run (directed sequences + random)
//====================================================================
class axi_apb_coverage_sequence extends axi_apb_base_sequence;
	`uvm_object_utils(axi_apb_coverage_sequence)

	function new(string name = "axi_apb_coverage_sequence");
		super.new(name);
	endfunction

	task body();
		axi_apb_aw_first_sequence      s1;
		axi_apb_w_first_sequence       s2;
		axi_apb_same_cycle_sequence    s3;
		axi_apb_error_sequence         s4;
		axi_apb_wait_state_sequence    s5;
		axi_apb_partial_write_sequence s6;
		axi_apb_backpressure_sequence  s7;
		axi_apb_random_sequence        s8;

		s1 = axi_apb_aw_first_sequence::type_id::create("s1");
		s2 = axi_apb_w_first_sequence::type_id::create("s2");
		s3 = axi_apb_same_cycle_sequence::type_id::create("s3");
		s4 = axi_apb_error_sequence::type_id::create("s4");
		s5 = axi_apb_wait_state_sequence::type_id::create("s5");
		s6 = axi_apb_partial_write_sequence::type_id::create("s6");
		s7 = axi_apb_backpressure_sequence::type_id::create("s7");
		s8 = axi_apb_random_sequence::type_id::create("s8");

		s1.start(m_sequencer, this);
		s2.start(m_sequencer, this);
		s3.start(m_sequencer, this);
		s4.start(m_sequencer, this);
		s5.start(m_sequencer, this);
		s6.start(m_sequencer, this);
		s7.start(m_sequencer, this);
		s8.start(m_sequencer, this);
	endtask
endclass

`endif
