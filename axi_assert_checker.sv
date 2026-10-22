module axi_assert_checker(axi_apb_intf vif);
  default clocking cb @(posedge vif.clk); endclocking
  default disable iff (!vif.resetn);

  // A VALID request/response must remain asserted until its handshake.
  assert property (vif.awvalid && !vif.awready |=> vif.awvalid)
    else $error("AXI assertion: AWVALID dropped before AWREADY");
  assert property (vif.wvalid && !vif.wready |=> vif.wvalid)
    else $error("AXI assertion: WVALID dropped before WREADY");
  assert property (vif.arvalid && !vif.arready |=> vif.arvalid)
    else $error("AXI assertion: ARVALID dropped before ARREADY");
  assert property (vif.bvalid && !vif.bready |=> vif.bvalid && $stable(vif.bresp))
    else $error("AXI assertion: write response changed before handshake");
  assert property (vif.rvalid && !vif.rready |=> vif.rvalid && $stable(vif.rdata) && $stable(vif.rresp))
    else $error("AXI assertion: read response changed before handshake");
endmodule
