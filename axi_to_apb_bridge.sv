// Converts one AXI-Lite request into one APB transfer.
module axi_to_apb_bridge (
 input logic aclk, aresetn,
 input logic [3:0] awaddr, input logic awvalid, output logic awready,
 input logic [31:0] wdata, input logic [3:0] wstrb, input logic wvalid, output logic wready,
 input logic bready, output logic bvalid, output logic [1:0] bresp,
 input logic [3:0] araddr, input logic arvalid, output logic arready,
 input logic rready, output logic rvalid, output logic [31:0] rdata, output logic [1:0] rresp,
 input logic pready, input logic [31:0] prdata, input logic pslverr,
 output logic [3:0] paddr, output logic [31:0] pwdata, output logic [3:0] pstrb,
 output logic pwrite, psel, penable
);
 // States for idle, APB write/read and AXI response.
 typedef enum logic [2:0] {IDLE, APB_SETUP_WRITE, APB_ACCESS_WRITE, WRITE_RESPONSE,
                           APB_SETUP_READ, APB_ACCESS_READ, READ_RESPONSE} state_t;
 state_t state;
 logic [3:0] awaddr_reg, araddr_reg;       // Stores address until the APB transfer starts.
 logic [31:0] wdata_reg, latched_prdata;   // Stores write data and returned read data.
 logic [3:0] wstrb_reg;
 logic aw_captured, w_captured, ar_captured, latched_pslverr; // Channel-arrival and error flags.

 // Main sequential block: all bridge state changes happen here.
 always_ff @(posedge aclk or negedge aresetn) begin
  if (!aresetn) begin
   state <= IDLE; aw_captured <= 0; w_captured <= 0; ar_captured <= 0;
   awaddr_reg <= 0; araddr_reg <= 0; wdata_reg <= 0; wstrb_reg <= 0;
   latched_prdata <= 0; latched_pslverr <= 0;
   bvalid <= 0; bresp <= 0; rvalid <= 0; rdata <= 0; rresp <= 0;
   paddr <= 0; pwdata <= 0; pstrb <= 0; pwrite <= 0; psel <= 0; penable <= 0;
  end else begin
   if (awvalid && awready) begin awaddr_reg <= awaddr; aw_captured <= 1; end // Write address accepted.
   if (wvalid && wready) begin wdata_reg <= wdata; wstrb_reg <= wstrb; w_captured <= 1; end // Write data accepted.
   if (arvalid && arready) begin araddr_reg <= araddr; ar_captured <= 1; end // Read address accepted.
   case (state)
    IDLE: begin
     psel <= 0; penable <= 0; // No APB transfer is active while idle.
     if (aw_captured && w_captured) begin
      state <= APB_SETUP_WRITE; psel <= 1; pwrite <= 1;
      paddr <= awaddr_reg; pwdata <= wdata_reg; pstrb <= wstrb_reg;
     end else if (ar_captured) begin
      state <= APB_SETUP_READ; psel <= 1; pwrite <= 0; paddr <= araddr_reg;
     end
    end
    APB_SETUP_WRITE: begin penable <= 1; state <= APB_ACCESS_WRITE; end // Start APB access on next clock.
    APB_ACCESS_WRITE: if (pready) begin
     latched_pslverr <= pslverr; latched_prdata <= prdata; // Save APB completion result.
     psel <= 0; penable <= 0; state <= WRITE_RESPONSE;
    end
    WRITE_RESPONSE: if (!bvalid) begin
     bvalid <= 1; bresp <= latched_pslverr ? 2'b10 : 2'b00; // AXI write response.
    end else if (bready) begin
     bvalid <= 0; aw_captured <= 0; w_captured <= 0; state <= IDLE; // Write complete.
    end
    APB_SETUP_READ: begin penable <= 1; state <= APB_ACCESS_READ; end // APB read access phase.
    APB_ACCESS_READ: if (pready) begin
     latched_pslverr <= pslverr; latched_prdata <= prdata;
     psel <= 0; penable <= 0; state <= READ_RESPONSE;
    end
    READ_RESPONSE: if (!rvalid) begin
     rvalid <= 1; rdata <= latched_prdata; rresp <= latched_pslverr ? 2'b10 : 2'b00; // AXI read response.
    end else if (rready) begin
     rvalid <= 0; ar_captured <= 0; state <= IDLE; // Read complete.
    end
    default: state <= IDLE;
   endcase
  end
 end
 assign awready = (state == IDLE) && !aw_captured; // Address buffer is free.
 assign wready  = (state == IDLE) && !w_captured;  // Data buffer is free.
 // A single-entry bridge serializes reads behind any presented write channel.
 assign arready = (state == IDLE) && !aw_captured && !w_captured && !awvalid && !wvalid;
endmodule
