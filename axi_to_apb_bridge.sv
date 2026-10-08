module axi_to_apb_bridge (
	input logic   aclk,
	input logic   aresetn,
	//AXI signals
        //AW channel
	input  logic [3:0]  awaddr,
	input  logic        awvalid,
	output logic        awready,
	//W channel
	input  logic [31:0] wdata,
	input  logic [3:0]  wstrb,
	input  logic        wvalid,
	output logic        wready,
	//B channel
	input  logic        bready,
	output logic        bvalid,
	output logic [1:0]  bresp,
	//AR channel
	input  logic [3:0]  araddr,
	input  logic        arvalid,
	output logic        arready,
	//R channel
	input  logic        rready,
	output logic        rvalid,
	output logic [31:0] rdata,
	output logic [1:0]  rresp,

	
	// APB Signals
	
	input  logic        pready,
	input  logic [31:0] prdata,
	input  logic        pslverr,
	output logic [3:0]  paddr,
	output logic [31:0] pwdata,
	output logic [3:0]  pstrb,
	output logic        pwrite,
	output logic        psel,
	output logic        penable

	);

	typedef enum logic [2:0] {IDLE, APB_SETUP_WRITE, APB_ACCESS_WRITE, WRITE_RESPONSE, APB_SETUP_READ, APB_ACCESS_READ, READ_RESPONSE} state_t;
	state_t state;

	logic [3:0]  awaddr_reg;
	logic [31:0] wdata_reg;
	logic [3:0]  wstrb_reg;
	logic [3:0]  araddr_reg;
	logic        aw_captured;
	logic        w_captured;
	logic        ar_captured;
	logic        latched_pslverr;
	logic [31:0] latched_prdata;


	always_ff @(posedge aclk or negedge aresetn) begin
		if(!aresetn) begin
			// reset: everything need to be 0
			aw_captured <= 1'b0;
			w_captured  <= 1'b0;
			ar_captured <= 1'b0;

		end
		else begin
			// AW capture check
			if (awvalid && awready) begin
				awaddr_reg  <= awaddr;
				aw_captured <= 1'b1;
			end
			// W  capture check
			if (wvalid && wready) begin
				wdata_reg  <= wdata;
				wstrb_reg  <= wstrb;
				w_captured <= 1'b1;
			end
			// AR capture check
			if (arvalid && arready) begin
				araddr_reg  <= araddr;
				ar_captured <= 1'b1;
			end
		end
	end

	always_ff @(posedge aclk or negedge aresetn) begin
		if(!aresetn) begin
		state   <= IDLE;
		bvalid  <= 1'b0;
		rvalid  <= 1'b0;
		psel    <= 1'b0;
		penable <= 1'b0;
		end
		else begin
		case(state)
			IDLE : begin
				psel    <= 1'b0;
				penable <= 1'b0;
				if (aw_captured && w_captured) begin
					state  <= APB_SETUP_WRITE;
					psel   <= 1'b1;
					pwrite <= 1'b1;
					paddr  <= awaddr_reg;
					pwdata <= wdata_reg;
					pstrb  <= wstrb_reg;
			end
			else if (ar_captured) begin
			       state  <= APB_SETUP_READ;
		               psel   <= 1'b1;
		               pwrite <= 1'b0;
		               paddr  <= araddr_reg;
		       end
	       end	       
			APB_SETUP_WRITE  : begin
				penable <= 1'b1;
				state   <= APB_ACCESS_WRITE;
			end
			APB_ACCESS_WRITE : begin
				if (pready) begin
					latched_pslverr <= pslverr;
					latched_prdata  <= prdata;
					state           <= WRITE_RESPONSE;
				end
			end
			WRITE_RESPONSE   : begin
				if (!bvalid) begin
					bvalid <= 1'b1;
					bresp  <= latched_pslverr ? 2'b10 : 2'b00;
				end
				else if (bready) begin
					bvalid      <= 1'b0;
					aw_captured <= 1'b0;
					w_captured  <= 1'b0;
					state       <= IDLE;
				end			
			end
			APB_SETUP_READ   : begin
				penable <= 1'b1;
				state   <= APB_ACCESS_READ;
			end
			APB_ACCESS_READ  : begin
				if (pready) begin
					latched_pslverr <= pslverr;
					latched_prdata  <= prdata;
					state           <= READ_RESPONSE;
				end
			end
			READ_RESPONSE    : begin
				if (!rvalid) begin
					rvalid <= 1'b1;
					rdata  <= latched_prdata;
					rresp  <= latched_pslverr ? 2'b10 : 2'b00;
				end
				else if (rready) begin
					rvalid      <= 1'b0;
					ar_captured <= 1'b0;
					state       <= IDLE;
				end
			end
		endcase
		end
       
	end
	assign awready = (state == IDLE) && !aw_captured;
	assign wready  = (state == IDLE) && !w_captured;
	assign arready = (state == IDLE) && !aw_captured && !w_captured;
	endmodule

