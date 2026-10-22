`timescale 1ns/1ps
// Shared pin-level interface used by DUT, driver, monitors and checkers.
interface axi_apb_intf(input logic clk, input logic resetn);
	logic [3:0]  awaddr;
	logic        awvalid;
	logic        awready;
	logic [31:0] wdata;
	logic [3:0]  wstrb;
	logic        wvalid;
	logic        wready;
	logic [1:0]  bresp;
	logic        bvalid;
	logic        bready;
	logic [3:0]  araddr;
	logic        arvalid;
        logic        arready;
        logic [31:0] rdata;
        logic [1:0]  rresp;	
	logic        rvalid;
        logic        rready;

	logic [3:0]  paddr;
	logic [31:0] pwdata;
	logic [31:0] prdata;
	logic [3:0]  pstrb;
	logic        pwrite;
	logic        psel;
	logic        penable;
	logic        pready;
	logic        pslverr;

	// Driver samples before an edge and drives after it, preventing DUT races.
	clocking driver_cb @(posedge clk);
		default input #1step output #1;
		output awaddr, awvalid, wdata, wstrb, wvalid, araddr, arvalid, bready, rready;
                input  awready, wready, bvalid, bresp, arready, rvalid, rdata, rresp;
         

	endclocking

	// Monitor samples stable, post-edge protocol values without driving signals.
        clocking monitor_cb @(posedge clk);
		default input #1step;
		input awaddr, awvalid, wdata, wstrb, wvalid, araddr, arvalid, bready, rready, awready, wready, bvalid, bresp, arready, rvalid, rdata, rresp, paddr, pwdata, prdata, pstrb, pwrite, psel, penable, pready, pslverr;

	endclocking

	modport DRIVER (clocking driver_cb, input clk, resetn);   // Active UVM driver view.
	modport MONITOR (clocking monitor_cb, input clk, resetn); // Passive UVM monitor view.



endinterface
