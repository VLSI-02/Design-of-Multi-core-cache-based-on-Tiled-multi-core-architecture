
import L1_cache_mem::*;

module cache_storage(cache.cache_storage_mb c1_inf);
//cache c1_inf();
l1_cache_line_t cache_mem[0:3][0:1];
always_comb
begin
 c1_inf.cache_mem_out = cache_mem;
end

always_ff @(posedge c1_inf.clk or posedge c1_inf.rst)
begin
  if (c1_inf.rst)
    begin
       cache_mem <= '{'{'{1'b0,1'b0,2'b0,INVALID,4'b0,8'd0},'{1'b0,1'b0,2'b0,INVALID,4'b0,8'b0}},// just for test case
                '{'{1'b0,1'b0,2'b01,INVALID,4'b0,8'b0},'{1'b0,1'b0,2'b01,INVALID,4'b0,8'b0}},
                '{'{1'b0,1'b0,2'b10,INVALID,4'b0,8'b0},'{1'b0,1'b0,2'b10,INVALID,4'b0,8'b0}},
                '{'{1'b0,1'b0,2'b11,INVALID,4'b0,8'b0},'{1'b0,1'b0,2'b11,INVALID,4'b0,8'b0}}};
    end
  else 
    begin
      if (c1_inf.write_en)
        begin
          cache_mem[c1_inf.set_idx][c1_inf.way_sel].data <= c1_inf.update_line[7:0];
          cache_mem[c1_inf.set_idx][c1_inf.way_sel].tag <= c1_inf.update_line[11:8];
          cache_mem[c1_inf.set_idx][c1_inf.way_sel].valid <= c1_inf.update_line[15];
          cache_mem[c1_inf.set_idx][c1_inf.way_sel].dirty <= c1_inf.update_line[14];
          cache_mem[c1_inf.set_idx][c1_inf.way_sel].C_tag <= MESI_STATES_t'(c1_inf.update_line[13:12]);
        end
    end
end

/*initial 
begin
    c1_inf.clk = 0;
    forever #10 c1_inf.clk = ~c1_inf.clk;
end
initial
begin
    c1_inf.rst = 1;
    #10;
    c1_inf.rst = 0;
    c1_inf.write_en = 1'b1;
    c1_inf.set_idx = 2'b00;
    c1_inf.way_sel = 1'b0;
    c1_inf.update_line = 16'b1010010011001100;
end
initial
begin
  $monitor("time = %t,clk = %b, rst = %b, write_en = %d, set_idx = %d, way_sel = %d, tag = %d, cache_mem = %p,/////,cache_mem_out = %p",
           $time,c1_inf.clk,c1_inf.rst,c1_inf.write_en,c1_inf.set_idx,c1_inf.way_sel,c1_inf.tag,cache_mem,cache_mem_out);
#50; $finish;
end*/
endmodule