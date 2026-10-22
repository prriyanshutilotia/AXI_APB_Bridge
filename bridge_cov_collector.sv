module bridge_cov_collector(axi_apb_intf vif);
  covergroup bridge_cg @(posedge vif.clk);
    option.per_instance = 1;
    cp_kind: coverpoint {vif.awvalid && vif.awready, vif.wvalid && vif.wready,
                         vif.arvalid && vif.arready} iff (vif.resetn) {
      bins write_addr = {3'b100}; bins write_data = {3'b010};
      bins read_addr  = {3'b001};
    }
    cp_addr: coverpoint vif.paddr iff (vif.psel && vif.penable && vif.pready) {
      bins legal[] = {[0:14]}; bins error = {15};
    }
    cp_write: coverpoint vif.pwrite iff (vif.psel && vif.penable && vif.pready);
    cp_wait: coverpoint vif.paddr[1:0] iff (vif.psel && vif.penable && vif.pready) {
      bins wait_0 = {0}; bins wait_1 = {1}; bins wait_2 = {2}; bins wait_3 = {3};
    }
    cp_strb: coverpoint vif.pstrb iff (vif.psel && vif.penable && vif.pready && vif.pwrite) {
      bins byte_en[] = {[1:15]};
    }
    cross cp_write, cp_addr;
  endgroup
  bridge_cg cg = new;
endmodule
