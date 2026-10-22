module bridge_assert_checker(
 input logic aclk, aresetn, awvalid, awready, wvalid, wready,
 input logic arvalid, arready, bvalid, bready, rvalid, rready,
 input logic psel, penable, pready
);
  default clocking cb @(posedge aclk); endclocking
  default disable iff (!aresetn);
  // The bridge must never accept a read while it has accepted part of a write.
  assert property ((awvalid && awready) || (wvalid && wready) |-> !arready)
    else $error("Bridge assertion: read accepted alongside partial write");
  assert property (bvalid |-> !rvalid)
    else $error("Bridge assertion: simultaneous read and write responses");
  assert property (psel && penable && !pready |=> psel && penable)
    else $error("Bridge assertion: APB transfer aborted before PREADY");
endmodule
