module apb_ram_slave(
	input  logic        pclk,
	input  logic        presetn,
	input  logic [3:0]  paddr,
	input  logic [31:0] pwdata,
	output logic [31:0] prdata,
	input  logic [3:0]  pstrb,
	input  logic        pwrite,
	input  logic        psel,
	input  logic        penable,
	output logic        pready,
	output logic        pslverr
	);
	logic [31:0] mem [0:15];

	logic [1:0] wait_cnt;    // 2 bits= 0 to 3(00,01,10,11)

        typedef enum logic {IDLE, ACCESS} state_t; // this makes new type name state_t, in this there are 2 possible values are there IDLE or ACCESS
	state_t state; // now by using this new type state_t, one actual signal created name state
	
	always_ff @(posedge pclk or negedge presetn) // pclk-> clock 0->1, presetn-> reset 1->0
	begin
		if (!presetn) begin
			pready <=1'b0; 
			prdata <=32'b0;
			pslverr<=1'b0;
			state  <=IDLE;
		end
		else begin
			pready <= 1'b0;
			case(state)
			IDLE : begin
				if (psel && !penable) 
				begin
					state<= ACCESS;
					wait_cnt <= paddr[1:0];
				end
			end
			
			ACCESS: begin
				if (wait_cnt != 0) begin
					wait_cnt <= wait_cnt - 1;
				end
				else begin
					pready <= 1'b1;
					state  <= IDLE;

					if (pwrite) begin
						if (paddr == 15)
					       	begin
							pslverr <= 1'b1;
						end
						else
						begin
							for (int i = 0; i < 4; i = i + 1) begin
								if(pstrb[i]) begin
									mem[paddr][8*i +: 8] <= pwdata[8*i +: 8];
								end 
							end
							pslverr <= 1'b0;
						end
					end
					else begin
						if (paddr == 15) begin
							prdata <= 32'b0;
							pslverr <= 1'b1;
						end
						else begin
							prdata <= mem[paddr];
							pslverr <= 1'b0;
						end
					end
				end

			end
		endcase
	end
end 
endmodule

