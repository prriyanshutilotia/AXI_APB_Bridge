`timescale 1ns/1ps
module apb_ram_tb;
logic clk;
logic resetn;

logic [3:0]  paddr;
logic [31:0] pwdata;
logic [31:0] prdata;
logic [31:0] read_data;
logic [31:0] read_data1;
logic [31:0] read_data2;
logic [3:0]  pstrb;
logic        pwrite;
logic        psel;
logic        penable;
logic        pready;
logic        pslverr;

initial clk = 0;
always #5 clk = ~clk;
initial begin
	resetn = 0;
	repeat(5) @(posedge clk);
	resetn = 1;
end
apb_ram_slave dut(
	.pclk(clk),
	.presetn(resetn),
	.paddr(paddr),
	.pwdata(pwdata),
	.prdata(prdata),
	.pstrb(pstrb),
	.pwrite(pwrite), 
	.psel(psel),
	.penable(penable),
	.pready(pready),
	.pslverr(pslverr)
	);

	task apb_write(input logic [3:0] addr, input logic [31:0] data, input logic [3:0] strb);
		paddr  = addr;
		pwdata = data;
		pstrb  = strb;
		pwrite = 1'b1;
		psel   = 1'b1;
		
		@(posedge clk);
		#1;
		penable = 1'b1;
		wait (pready);

		psel    = 1'b0;
		penable = 1'b0;
		@(posedge clk);

	endtask

	task apb_read(input logic [3:0] addr, output logic [31:0] result);
		paddr  = addr;
		pwrite = 1'b0;
		psel   = 1'b1;

		@(posedge clk);
		#1;
		penable = 1'b1;
		wait(pready);

		result  = prdata;
		psel    = 1'b0;
		penable = 1'b0;
		@(posedge clk);

	endtask
	
	initial begin
		psel    = 1'b0;
		penable = 1'b0;
		pwrite  = 1'b0;
                $monitor("t=%0t state=%s psel=%b penable=%b pready=%b prdata=%h read_data=%h", $time, dut.state, psel, penable, pready, prdata, read_data);
		wait(resetn);
		apb_write(0, 32'hAABBCCDD, 4'b1111);
		apb_read(0, read_data);

		if (read_data == 32'hAABBCCDD) begin
			$display("Pass");
		end
		else begin

			$display("Fail");
		end
		apb_write(15, 32'hDEADBEEF, 4'b1111);
		apb_read(15, read_data1);
		
		if (read_data1 == 32'b0) begin
			$display("pass - address 15 blocked");
		end
		else begin
			$display("fail - address 15 write should have been blocked");
		end
		apb_write(0, 32'h11223344, 4'b0001);
		apb_read(0, read_data2);

		if (read_data2 == 32'hAABBCC44) begin
			$display("pass - strb");
		end
		else begin
			$display("fail - strb");
		end
		$finish;
	end

endmodule
