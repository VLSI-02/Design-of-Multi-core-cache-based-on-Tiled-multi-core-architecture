
module fifo_in (
input logic clk,
input logic rst,
input logic [7:0] din,
input logic wr,
input logic rd,
output logic [7:0] dout,
output logic full,
output logic empty
);
logic [7:0] mem [0:15];
logic [3:0] wptr;
logic [3:0] rptr;
logic [4:0] cnt;
always_ff @(posedge clk) begin
if (rst) begin
 wptr <='0;
 rptr <='0;
 cnt <='0;
 dout <='0;
  end
  else begin
 if (wr && !full) begin
    mem[wptr] <= din;
    wptr <= wptr + 1;
 end
 if (rd && !empty) begin
    dout <= mem[rptr];
    rptr <= rptr + 1;
  end
unique case ({wr && !full, rd && !empty})
  2'b10: cnt <= cnt + 1;
  2'b01: cnt <= cnt - 1;
  default: cnt <= cnt;
  endcase
  end
end
assign full = (cnt == 16);
assign empty = (cnt == 0);
endmodule

module flit_dec (
input logic [7:0] flit,
output logic [1:0] type,
output logic [1:0] dest
);
assign typ = flit[7:6];
assign dest = flit[5:4];
endmodule

module route_comp (
input logic [1:0] cur,
input logic [1:0] dest,
output logic [1:0] route,
output logic [2:0] cw_dis, 
output logic [2:0] ccw_dis
);
localparam logic [1:0] LOC = 2'b00;
localparam logic [1:0] CW = 2'b01;
localparam logic [1:0] CCW = 2'b10;
always_comb begin
  route = LOC;
  cw_dis = '0;
  ccw_dis = '0;
  if (cur == dest) begin
  route = LOC;
  end
  else begin
  cw_dis  = (dest - cur + 4) % 4;
  ccw_dis = (cur - dest + 4) % 4;
  if (cw_dis <= ccw_dis)
      route = CW;
  else
      route = CCW;
    end
end
endmodule

module sw_ctrl (
input logic [1:0] l_rt,
input logic [1:0] c_rt,
input logic [1:0] cc_rt,
output logic [1:0] l_sel,
output logic [1:0] c_sel,
output logic [1:0] cc_sel
);
localparam logic [1:0] LOC = 2'b00;
localparam logic [1:0] CW = 2'b01;
localparam logic [1:0] CCW = 2'b10;
localparam logic [1:0] NONE = 2'b11;
always_comb begin
  l_sel = NONE;
  c_sel = NONE;
  cc_sel = NONE;
  if (l_rt == LOC)
    l_sel = 2'b00;
  else if (c_rt == LOC)
    l_sel = 2'b01;
  else if (cc_rt == LOC)
    l_sel = 2'b10;
  if (l_rt == CW)
    c_sel = 2'b00;
  else if (c_rt == CW)
    c_sel = 2'b01;
  else if (cc_rt == CW)
    c_sel = 2'b10;
  if (l_rt == CCW)
    cc_sel = 2'b00;
  else if (c_rt == CCW)
    cc_sel = 2'b01;
  else if (cc_rt == CCW)
    cc_sel = 2'b10;
end
endmodule

module xbar (
    input logic [7:0] l_in,
    input logic [7:0] c_in,
    input logic [7:0] cc_in,
    input logic [1:0] l_sel,
    input logic [1:0] c_sel,
    input logic [1:0] cc_sel,
    output logic [7:0] l_out,
    output logic [7:0] c_out,
    output logic [7:0] cc_out
);
always_comb begin
    case (l_sel)
    2'b00: l_out = l_in;
    2'b01: l_out = c_in;
    2'b10: l_out = cc_in;
    default: l_out = '0;
    endcase
    case (c_sel)
    2'b00: c_out = l_in;
    2'b01: c_out = c_in;
    2'b10: c_out = cc_in;
    default: c_out = '0;
    endcase
    case (cc_sel)
    2'b00: cc_out = l_in;
    2'b01: cc_out = c_in;
    2'b10: cc_out = cc_in;
    default: cc_out = '0;
    endcase
end
endmodule

module router_top (
input logic clk,
input logic rst,
input logic [1:0] rid,
input logic [7:0] l_in,
input logic l_wr,
input logic [7:0] c_in,
input logic c_wr,
input logic [7:0] cc_in,
input logic cc_wr,
output logic [7:0] l_out,
output logic [7:0] c_out,
output logic [7:0] cc_out,
output logic [1:0] dbg_l_dest,
output logic [1:0] dbg_c_dest,
output logic [1:0] dbg_cc_dest,
output logic [1:0] dbg_l_rt,
output logic [1:0] dbg_c_rt,
output logic [1:0] dbg_cc_rt,
output logic [2:0] dbg_l_cw,
output logic [2:0] dbg_l_ccw,
output logic [2:0] dbg_c_cw,
output logic [2:0] dbg_c_ccw,
output logic [2:0] dbg_cc_cw,
output logic [2:0] dbg_cc_ccw
);
logic [7:0] l_data;
logic [7:0] c_data;
logic [7:0] cc_data;
logic l_full, l_empty;
logic c_full, c_empty;
logic cc_full, cc_empty;
logic l_rd, c_rd, cc_rd;
assign l_rd = !l_empty;
assign c_rd = !c_empty;
assign cc_rd = !cc_empty;
logic [1:0] l_type, c_type, cc_type;
logic [1:0] l_dest, c_dest, cc_dest;
logic [1:0] l_rt, c_rt, cc_rt;
logic [2:0] l_cw, l_ccw;
logic [2:0] c_cw, c_ccw;
logic [2:0] cc_cw, cc_ccw;
logic [1:0] l_sel, c_sel, cc_sel;
fifo_in f0 (
.clk(clk),
.rst(rst),
.din(l_in),
.wr(l_wr),
.rd(l_rd),
.dout(l_data),
.full(l_full),
.empty(l_empty)
);
fifo_in f1 (
.clk(clk),
.rst(rst),
.din(c_in),
.wr(c_wr),
.rd(c_rd),
.dout(c_data),
.full(c_full),
.empty(c_empty)
);
fifo_in f2 (
.clk(clk),
.rst(rst),
  .din(cc_in),
.wr(cc_wr),
.rd(cc_rd),
.dout(cc_data),
.full(cc_full),
.empty(cc_empty)
);
flit_dec d0 (
.flit(l_data),
.typ(l_type),
.dest(l_dest)
);
flit_dec d1 (
.flit(c_data),
.typ(c_type),
.dest(c_dest)
);
flit_dec d2 (
.flit(cc_data),
.typ(cc_type),
dest(cc_dest)
);
route_comp r0 (
.cur(rid),
.dest(l_dest),
.route(l_rt),
.cw_dis(l_cw),
.ccw_dis(l_ccw)
);
route_comp r1 (
.cur(rid),
.dest(c_dest),
.route(c_rt), 
.cw_dis(c_cw),
.ccw_dis(c_ccw)
);
route_comp r2 (
.cur(rid),
.dest(cc_dest),
.route(cc_rt),
.cw_dis(cc_cw),
.ccw_dis(cc_ccw)
);
sw_ctrl s0 (
   .l_rt(l_rt),
  .c_rt(c_rt),
.cc_rt(cc_rt),
  .l_sel(l_sel),
.c_sel(c_sel),
.cc_sel(cc_sel)
);
xbar x0 (
.l_in(l_data),
.c_in(c_data),
.cc_in(cc_data),
.l_sel(l_sel),
.c_sel(c_sel),
.cc_sel(cc_sel),
.l_out(l_out),
.c_out(c_out),
.cc_out(cc_out)
);
assign dbg_l_dest = l_dest;
assign dbg_c_dest = c_dest;
assign dbg_cc_dest = cc_dest;
assign dbg_l_rt = l_rt;
assign dbg_c_rt = c_rt;
assign dbg_cc_rt = cc_rt;
assign dbg_l_cw = l_cw;
assign dbg_l_ccw = l_ccw;
assign dbg_c_cw = c_cw;
assign dbg_c_ccw = c_ccw;
assign dbg_cc_cw = cc_cw;
assign dbg_cc_ccw = cc_ccw;
endmodule
