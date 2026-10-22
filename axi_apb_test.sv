`ifndef AXI_APB_TEST_SV
`define AXI_APB_TEST_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_apb_env.sv"
`include "axi_apb_sequence.sv"

//====================================================================
// Base test (= smoke test). Every other test only overrides create_seq()
//====================================================================
class axi_apb_test extends uvm_test;
	`uvm_component_utils(axi_apb_test)

	axi_apb_env env;

	function new(string name = "axi_apb_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = axi_apb_env::type_id::create("env", this);
	endfunction

	virtual function uvm_sequence_base create_seq();
		axi_apb_sequence s;
		s = axi_apb_sequence::type_id::create("seq");
		return s;
	endfunction

	task run_phase(uvm_phase phase);
		uvm_sequence_base seq;
		phase.raise_objection(this);
		seq = create_seq();
		seq.start(env.agent.sequencer);
		#100ns;   // drain time: let monitors/scoreboard see the last handshake
		phase.drop_objection(this);
	endtask
endclass

class axi_apb_aw_first_test extends axi_apb_test;
	`uvm_component_utils(axi_apb_aw_first_test)
	function new(string name = "axi_apb_aw_first_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	virtual function uvm_sequence_base create_seq();
		axi_apb_aw_first_sequence s;
		s = axi_apb_aw_first_sequence::type_id::create("seq");
		return s;
	endfunction
endclass

class axi_apb_w_first_test extends axi_apb_test;
	`uvm_component_utils(axi_apb_w_first_test)
	function new(string name = "axi_apb_w_first_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	virtual function uvm_sequence_base create_seq();
		axi_apb_w_first_sequence s;
		s = axi_apb_w_first_sequence::type_id::create("seq");
		return s;
	endfunction
endclass

class axi_apb_same_cycle_test extends axi_apb_test;
	`uvm_component_utils(axi_apb_same_cycle_test)
	function new(string name = "axi_apb_same_cycle_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	virtual function uvm_sequence_base create_seq();
		axi_apb_same_cycle_sequence s;
		s = axi_apb_same_cycle_sequence::type_id::create("seq");
		return s;
	endfunction
endclass

class axi_apb_partial_write_test extends axi_apb_test;
	`uvm_component_utils(axi_apb_partial_write_test)
	function new(string name = "axi_apb_partial_write_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	virtual function uvm_sequence_base create_seq();
		axi_apb_partial_write_sequence s;
		s = axi_apb_partial_write_sequence::type_id::create("seq");
		return s;
	endfunction
endclass

class axi_apb_wait_state_test extends axi_apb_test;
	`uvm_component_utils(axi_apb_wait_state_test)
	function new(string name = "axi_apb_wait_state_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	virtual function uvm_sequence_base create_seq();
		axi_apb_wait_state_sequence s;
		s = axi_apb_wait_state_sequence::type_id::create("seq");
		return s;
	endfunction
endclass

class axi_apb_error_test extends axi_apb_test;
	`uvm_component_utils(axi_apb_error_test)
	function new(string name = "axi_apb_error_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	virtual function uvm_sequence_base create_seq();
		axi_apb_error_sequence s;
		s = axi_apb_error_sequence::type_id::create("seq");
		return s;
	endfunction
endclass

class axi_apb_backpressure_test extends axi_apb_test;
	`uvm_component_utils(axi_apb_backpressure_test)
	function new(string name = "axi_apb_backpressure_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	virtual function uvm_sequence_base create_seq();
		axi_apb_backpressure_sequence s;
		s = axi_apb_backpressure_sequence::type_id::create("seq");
		return s;
	endfunction
endclass

class axi_apb_random_test extends axi_apb_test;
	`uvm_component_utils(axi_apb_random_test)
	function new(string name = "axi_apb_random_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	virtual function uvm_sequence_base create_seq();
		axi_apb_random_sequence s;
		s = axi_apb_random_sequence::type_id::create("seq");
		return s;
	endfunction
endclass

class axi_apb_coverage_test extends axi_apb_test;
	`uvm_component_utils(axi_apb_coverage_test)
	function new(string name = "axi_apb_coverage_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	virtual function uvm_sequence_base create_seq();
		axi_apb_coverage_sequence s;
		s = axi_apb_coverage_sequence::type_id::create("seq");
		return s;
	endfunction
endclass

`endif
