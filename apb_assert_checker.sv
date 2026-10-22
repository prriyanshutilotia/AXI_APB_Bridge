module apb_assert_checker(axi_apb_intf vif);
  default clocking cb @(posedge vif.clk); endclocking
  default disable iff (!vif.resetn);

  // APB has one setup cycle followed by one or more access cycles.
  assert property (vif.psel && !vif.penable |=> vif.psel && vif.penable)
    else $error("APB assertion: setup was not followed by access");
  assert property (vif.psel && vif.penable && !vif.pready |=> vif.psel && vif.penable)
    else $error("APB assertion: access ended before PREADY");
  assert property (vif.psel && vif.penable && vif.pready |=> !vif.penable)
    else $error("APB assertion: PENABLE was not deasserted after completion");
endmodule
