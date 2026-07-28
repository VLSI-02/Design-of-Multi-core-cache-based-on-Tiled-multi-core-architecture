import L1_cache_mem::*;

interface cache();
logic clk,rst;
logic write_en;
logic [7:0]in_data;
logic [3:0]tag;
logic [1:0]set_idx;
logic [1:0]lru_id;
logic way_sel;
logic valid;
logic dirty;
logic C_tag;
logic [15:0]update_line;
l1_cache_line_t cache_mem_out[0:3][0:1];
logic update_lru;
logic lru_way;
logic [9:0]inst;
logic snoop_read;
logic [7:0]snoop_addr;
logic snoop_ack;
logic snoop_write;
logic shared;
logic data_ready;
logic [7:0]Data_addr_fetch;
logic [7:0]Data_fetch;
logic [7:0]cache_mem_in;
logic Data_out;
logic [9:0]L1_miss_out;
logic mem_wr_req;
logic [5:0]mem_addr;
logic [7:0]mem_data;
logic mem_ready;
modport cache_storage_mb(
    input clk,rst,write_en,set_idx,way_sel,tag,valid,dirty,C_tag,update_line,
    output cache_mem_out
);
modport cache_controller_mb(
    input clk,rst,inst,snoop_read,snoop_write,shared,lru_way,cache_mem_out,data_ready,in_data,snoop_addr,Data_addr_fetch,Data_fetch,
    output write_en,way_sel,update_lru,update_line,Data_out,L1_miss_out,mem_wr_req,mem_addr,mem_data,mem_ready,snoop_ack,lru_id,set_idx
);
modport cache_lru_mb(
    input rst,lru_id,update_lru,
    output lru_way
);
endinterface