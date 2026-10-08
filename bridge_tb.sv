`timescale 1ns/1ps
module bridge_tb;
logic clk;
logic resetn;
initial clk = 0;
always #5 clk=~clk;
initial begin
	resetn = 0;
	repeat(5) @(posedge clk);
	resetn = 1; 
	end

// AXI signals
logic [3:0]  awaddr;
logic        awvalid;
logic        awready;
logic [31:0] wdata;
logic [3:0]  wstrb;
logic        wvalid;
logic        wready;
logic        bready; 
logic        bvalid;
logic [1:0]  bresp;
logic [3:0]  araddr;
logic        arvalid;
logic        arready;
logic        rready;
logic        rvalid;
logic [31:0] rdata;
logic [1:0]  rresp;
logic [1:0]  wresp;
logic [31:0] rdata_result;
logic [1:0]  rresp_result;
logic [31:0] rdata_result1;
logic [1:0]  rresp_result1;
logic [31:0] rdata_result2;
logic [1:0]  rresp_result2;
logic [31:0] rdata_result3;
logic [1:0]  rresp_result3;
//APB signals
logic [3:0]  paddr;
logic [31:0] pwdata;
logic [31:0] prdata;
logic [3:0]  pstrb;
logic        pwrite;
logic        psel;
logic        penable;
logic        pready;
logic        pslverr;

axi_to_apb_bridge bridge_dut (
	.aclk   (clk),
	.aresetn(resetn),
	.awaddr (awaddr),
	.awvalid(awvalid),
	.awready(awready),
	.wdata  (wdata),
	.wstrb  (wstrb),
	.wvalid (wvalid),
	.wready (wready),
	.bready (bready),
	.bvalid (bvalid),
	.bresp  (bresp),
	.araddr (araddr),
	.arvalid(arvalid),
	.arready(arready),
	.rready (rready),
	.rvalid (rvalid),
	.rdata  (rdata),
	.rresp  (rresp),
	.paddr  (paddr),
	.pwdata (pwdata),
	.prdata (prdata),
	.pstrb  (pstrb),
	.pwrite (pwrite),
	.psel   (psel),
	.penable(penable),
	.pready (pready),
	.pslverr(pslverr)
	);
	apb_ram_slave dut(
	.pclk   (clk),
	.presetn(resetn),
	.paddr  (paddr),
	.pwdata (pwdata),
	.prdata (prdata),
	.pstrb  (pstrb),
	.pwrite (pwrite), 
	.psel   (psel),
	.penable(penable),
	.pready (pready),
	.pslverr(pslverr)
	);

	task drive_aw (input logic [3:0] addr);
		awaddr  = addr;
		awvalid = 1'b1;
		@(posedge clk);
		wait(awready);
		awvalid = 1'b0;
	endtask
	task drive_w (input logic [31:0] data, input logic [3:0] strb);
		wdata  = data;
		wvalid = 1'b1;
		wstrb  = strb;
		@(posedge clk);
		wait(wready);
		wvalid = 1'b0;
	endtask
	task drive_ar (input logic [3:0] addr);
		araddr  = addr;
		arvalid = 1'b1;
		@(posedge clk);
		wait(arready);
		arvalid = 1'b0;
	endtask
	task wait_and_capture_bresp(output logic [1:0] resp);
		bready = 1'b1;
		wait(bvalid);
		resp   = bresp;
		@(posedge clk);
		bready = 1'b0;
	endtask
	task wait_and_capture_rdata (output logic [31:0] data, output logic [1:0] resp);
		rready = 1'b1;
		wait(rvalid);
		resp   = rresp;
		data   = rdata;
		@(posedge clk);
		rready = 1'b0;
	endtask
	task axi_write(input logic [3:0] addr, input logic [31:0] data, input logic [3:0] strb, input int order, output logic [1:0] resp);
		case(order)
			0: begin // AW_FIRST
			drive_aw(addr);
			drive_w(data, strb);
		end
		        1: begin // W_FIRST 
			drive_w(data, strb);
			drive_aw(addr);
		end
		        2: begin // SAME_CYCLE
			fork
				drive_aw(addr);
				drive_w(data, strb);
			join
		end
	endcase 
	wait_and_capture_bresp(resp);
endtask
        
        task axi_read(input logic[3:0] addr, output logic [31:0] data, output logic [1:0] resp);
		drive_ar(addr);
		wait_and_capture_rdata(data, resp);
	endtask

	initial begin
	       $monitor("t=%0t state=%s awvalid=%b awready=%b wvalid=%b wready=%b bvalid=%b bready=%b psel=%b penable=%b pready=%b", 
          $time, bridge_dut.state, awvalid, awready, wvalid, wready, bvalid, bready, psel, penable, pready);	

		awvalid = 1'b0; 
		wvalid  = 1'b0; 
		bready  = 1'b0; 
		arvalid = 1'b0; 
		rready  = 1'b0;

		wait(resetn);
		axi_write(0, 32'hCAFEBABE, 4'b1111, 0, wresp);
		axi_read(0, rdata_result, rresp_result);

		if (rdata_result == 32'hCAFEBABE) begin
			$display("Pass-AW_FIRST write-read match");
		end
		else begin
			$display("Fail-AW_FIRST write-read mismatch");
		end

		axi_write(1, 32'h11112222, 4'b1111, 1, wresp);
		axi_read(1, rdata_result1, rresp_result1);

		if(rdata_result1 == 32'h11112222) begin
			$display("Pass-W_FIRST write-read match");
		end
		else begin 
			$display("Fail-W_FIRST write-read mismatch");
		end

		axi_write(2, 32'hDEAD1234, 4'b1111, 2, wresp);
		axi_read(2, rdata_result2, rresp_result2);

		if(rdata_result2 == 32'hDEAD1234) begin
			$display("Pass-SAME_CYCLE write-read matched");
		end
		else begin
			$display("Fail-SAME_CYCLE write-read mismatched");
		end

		axi_write(15, 32'hDEAD12CA, 4'b1111, 0, wresp);
		axi_read(15, rdata_result3, rresp_result3);

		if(wresp == 2'b10 && rresp_result3 == 2'b10) begin
			$display("Pass-address15 SLVERR check");
		end
		else begin
			$display("Fail-address15 SLVERR check");
		end

		$finish;

	end
endmodule
