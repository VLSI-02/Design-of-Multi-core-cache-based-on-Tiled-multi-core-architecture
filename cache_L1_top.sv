package L1_cache_mem;
typedef enum logic [1:0]{
    INVALID, EXCLUSIVE , SHARED , MODIFIED
} MESI_STATES_t;
typedef struct packed{
    logic valid;
    logic dirty;
    logic [1:0]set_index;
    MESI_STATES_t C_tag;
    logic [3:0]tag;
    logic [7:0]data;
}l1_cache_line_t;
typedef enum logic [2:0] {
    IDLE,COMPARE,DONE,SNOOP,WRITEBACK
} C_STATES_t;
endpackage

import L1_cache_mem::*;


module cache_L1_top ();
cache c1_inf(); 
l1_cache_line_t cache_mem_out[0:3][0:1];
cache_controller c1(.c1_inf(c1_inf.cache_controller_mb));
cache_storage c2(.c1_inf(c1_inf.cache_storage_mb));
cache_lru c3(.c1_inf(c1_inf.cache_lru_mb));
initial
begin
 c1_inf.clk = 1'b0;
 forever  #10 c1_inf.clk = ~c1_inf.clk;
end
initial begin

  c1_inf.rst = 1'b1;
  c1_inf.snoop_read  = 1'b0;
  c1_inf.snoop_write = 1'b0;
  #20;
  c1_inf.rst = 1'b0;

  // load miss: set 0, tag 1 -> EXCLUSIVE, data 100
  c1_inf.inst = 10'b0100010010;
  #20;
  c1_inf.data_ready      = 1'b1;
  c1_inf.shared          = 1'b0;
  c1_inf.Data_fetch      = 8'd100;
  c1_inf.Data_addr_fetch = 10'b0100010010;
  #100;
  c1_inf.data_ready = 1'b0;
  #40;
c1_inf.inst = 10'b0000000000; 
#20;
  // load miss: set 0, tag 2 -> SHARED, data 200
  c1_inf.inst = 10'b0100100011;
  #20;
  c1_inf.data_ready      = 1'b1;
  c1_inf.shared          = 1'b1;
  c1_inf.Data_fetch      = 8'd200;
  c1_inf.Data_addr_fetch = 10'b0100100011;
  #100;
  c1_inf.data_ready = 1'b0;
  #40;
c1_inf.inst = 10'b0000000000; 
#20;
  // store miss: set 0, tag 4 (set is full -> LRU eviction path)
  c1_inf.inst    = 10'b1001000000;
  c1_inf.in_data = 8'd2;
  #20;
  c1_inf.data_ready      = 1'b1;
  c1_inf.shared          = 1'b0;
  c1_inf.Data_fetch      = 8'd20;
  c1_inf.Data_addr_fetch = 10'b1001000000;
  #40;
  c1_inf.data_ready = 1'b0;
  #60;
  c1_inf.inst = 10'b0101000000;
  #100;
  /*
 #20;
  // snoop read, non-matching address
  c1_inf.snoop_addr = 8'b0011_0000;
  c1_inf.snoop_read = 1'b1;
  #20;
  c1_inf.snoop_read = 1'b0;
  #60;
*/
  /* c1_inf.inst = 10'b0000000000;
  // snoop read, matching tag 1 (EXCLUSIVE -> SHARED)
  c1_inf.snoop_addr = 8'b0100_0000;
  c1_inf.snoop_read = 1'b1;
    #20;
  c1_inf.mem_ready = 1'b1;
  #100;
  c1_inf.snoop_read = 1'b0;
    c1_inf.mem_ready = 1'b0;

  #100;
  c1_inf.snoop_addr = 8'bx;
  #100;

  c1_inf.snoop_write = 1'b1;
  c1_inf.snoop_addr = 8'b00100000;
  #40;
  c1_inf.snoop_write = 1'b0;
  #100;

/*
  // snoop read, matching tag 4 (MODIFIED -> writeback -> SHARED)
  c1_inf.snoop_addr = 8'b0100_0000;
  c1_inf.snoop_read = 1'b1;
  #20;
  c1_inf.snoop_read = 1'b0;
  #40;
  c1_inf.mem_ready = 1'b1;
  #40;
  c1_inf.mem_ready = 1'b0;
  #80;
#100;
c1_inf.data_ready = 1'b0;
c1_inf.inst = 10'b0000000000; 
#40;*/
  $finish;

end
initial
begin
  $monitor("time = %t,clk = %b, rst = %b,snoop_addr = %b,inst = %b,Data_out = %b,cache_mem_out = %p,data ready = %b,Data_fetch = %d,Data_fetch_addr = %b,update_line = %b,C_PS = %b,C_NS = %b,stall = %b,done = %b,write_back = %b,mem_wr_req = %b,mem_ready = %b, mem_data = %d, mem_addr = %b,lru_way = %b,snoop_ack = %b,write_en = %b,victim_way = %b,snoop_read = %b,snoop_write = %b,way_sel = %b,fill_pending = %b",
            $time , c1_inf.clk,c1_inf.rst,c1_inf.snoop_addr,c1_inf.inst,c1_inf.Data_out,c1_inf.cache_mem_out,c1_inf.data_ready,c1_inf.Data_fetch,c1_inf.Data_addr_fetch,c1_inf.update_line,cache_L1_top.c1.C_PS,cache_L1_top.c1.C_NS,cache_L1_top.c1.stall,cache_L1_top.c1.done,cache_L1_top.c1.write_back,c1_inf.mem_wr_req,c1_inf.mem_ready,c1_inf.mem_data,c1_inf.mem_addr,c1_inf.lru_way,c1_inf.snoop_ack,c1_inf.write_en,cache_L1_top.c1.victim_way,c1_inf.snoop_read,c1_inf.snoop_write,c1_inf.way_sel,cache_L1_top.c1.fill_pending);
end
endmodule