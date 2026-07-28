### TOP MODULE
module nic_top(
    input logic clk,
    input logic rst,
    input logic fifo_wr_en,
    input logic [15:0] fifo_data_in,
    input logic [2:0]  src_tile,
    input logic router_ready,
    output logic router_valid_out,
    output logic [31:0] router_data_out,
    input logic router_valid_in,
    input logic [31:0] router_data_in,
    output logic decode_valid,
    output logic rw,
    output logic [2:0] src_out,
    output logic [2:0] dest_out,
    output logic [11:0] address_out,
    output logic fifo_full,
    output logic fifo_empty
);
logic [15:0] fifo_data_out;
logic [3:0] fifo_count;
logic fifo_rd_en;
logic [31:0] packet;
logic packet_valid;
logic [31:0] rx_packet;
logic rx_packet_valid;
logic tx_ready;
request_fifo fifo
(
    .clk(clk),
    .rst(rst),
    .wr_en(fifo_wr_en),
    .data_in(fifo_data_in),
    .rd_en(fifo_rd_en),
    .data_out(fifo_data_out),
    .full(fifo_full),
    .empty(fifo_empty),
    .count(fifo_count)
);
packet_generator pg
(
    .clk(clk),
    .rst(rst),
    .fifo_data(fifo_data_out),
    .fifo_valid(~fifo_empty),
    .src_tile(src_tile),
    .tx_ready(tx_ready),
    .packet(packet),
    .packet_valid(packet_valid),
    .fifo_rd_en(fifo_rd_en)
);
tx_controller tx
(
    .clk(clk),
    .rst(rst),
    .packet(packet),
    .packet_valid(packet_valid),
    .router_ready(router_ready),
    .router_data(router_data_out),
    .router_valid(router_valid_out),
    .tx_ready(tx_ready)
);
rx_controller rx
(
    .clk(clk),
    .rst(rst),
    .router_valid(router_valid_in),
    .router_data(router_data_in),
    .packet_valid(rx_packet_valid),
    .packet_out(rx_packet)
);
packet_decoder decoder
(
    .clk(clk),
    .rst(rst),
    .packet(rx_packet),
    .packet_valid(rx_packet_valid),
    .decode_valid(decode_valid),
    .rw(rw),
    .src_tile(src_out),
    .dest_tile(dest_out),
    .address(address_out)
);
endmodule
### FIFO
module request_fifo(
    input  logic clk,
    input  logic rst,
    input  logic wr_en,
    input  logic [15:0] data_in,
    input  logic rd_en,
    output logic [15:0] data_out,
    output logic full,
    output logic empty,
    output logic [3:0] count
);
logic [15:0] mem [0:7];
logic [2:0] wr_ptr;
logic [2:0] rd_ptr;
always_ff @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        wr_ptr <= 3'b000;
        rd_ptr <= 3'b000;
        count <= 4'd0;
        for(int i=0;i<8;i++)
            mem[i] <= 16'd0;
    end
    else
    begin
      case({wr_en && !full, rd_en && !empty})
        2'b10:
        begin
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1'b1;
            count <= count + 1'b1;
        end
        2'b01:
        begin
            rd_ptr <= rd_ptr + 1'b1;
            count <= count - 1'b1;
        end
        2'b11:
        begin
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1'b1;
            rd_ptr <= rd_ptr + 1'b1;
            count <= count;
        end
        default:
        begin
            count <= count;
        end
        endcase
    end
end
always_comb
begin
    data_out = mem[rd_ptr];
end
assign empty = (count == 0);
assign full  = (count == 8);
endmodule
### PACKET GENERATOR
module packet_generator(
input logic clk,
input logic rst,
input logic [15:0] fifo_data,
input logic fifo_valid,
input logic [2:0] src_tile,
input logic tx_ready,
output logic [31:0] packet,
output logic packet_valid,
output logic fifo_rd_en
);
logic rw;
logic [2:0] dest_tile;
logic [11:0] address;
always_comb
begin
    rw = fifo_data[15];
    dest_tile = fifo_data[14:12];
    address = fifo_data[11:0];
end
always_ff @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        packet <= 32'd0;
        packet_valid <= 1'b0;
        fifo_rd_en <= 1'b0;
    end
    else
    begin
        packet_valid <= 1'b0;
        fifo_rd_en   <= 1'b0;
        if(fifo_valid && tx_ready)
        begin
            packet <= {
                        rw,
                        src_tile,
                        dest_tile,
                        address,
                        13'b0
                      };

            packet_valid <= 1'b1;
            fifo_rd_en <= 1'b1;
        end
    end
end
endmodule

### TX CONTROLLER
module tx_controller(
input logic clk,
input logic rst,
input logic [31:0] packet,
input logic packet_valid,
input logic router_ready,
output logic [31:0] router_data,
output logic router_valid,
output logic tx_ready
);
typedef enum logic [1:0]
{
    IDLE,
    LOAD,
    WAIT_READY,
    SEND

} state_t;
state_t state,next_state;
logic [31:0] packet_reg;
always_ff @(posedge clk or posedge rst)
begin
    if(rst)
        state <= IDLE;
    else
        state <= next_state;
end
always_ff @(posedge clk or posedge rst)
begin
    if(rst)
        packet_reg <= 32'd0;

    else if(state == LOAD)
        packet_reg <= packet;
    end
always_comb
begin
    next_state = state;
    router_valid = 1'b0;
    router_data  = 32'd0;
    case(state)
    IDLE:
    begin
        if(packet_valid)
            next_state = LOAD;
    end
    LOAD:
    begin
        next_state = WAIT_READY;
    end
    WAIT_READY:
    begin
        if(router_ready)
            next_state = SEND;
    end
    SEND:
    begin
        router_valid = 1'b1;
        router_data = packet_reg;
        if(router_ready)
            next_state = IDLE;
    end
    default:
        next_state = IDLE;
endcase
end
assign tx_ready = (state == IDLE);
endmodule

### RX CONTROLLER
module rx_controller(
    input logic clk,
    input logic rst,
    input  logic router_valid,
    input  logic [31:0] router_data,
    output logic packet_valid,
    output logic [31:0] packet_out
);
always_ff @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        packet_out   <= 32'd0;
        packet_valid <= 1'b0;
    end
    else
    begin
        packet_valid <= 1'b0;
        if(router_valid)
        begin
            packet_out <= router_data;
            packet_valid <= 1'b1;
        end
    end
end
endmodule

### PACKET DECODER
module packet_decoder(
    input logic clk,
    input logic rst,
    input logic [31:0] packet,
    input logic packet_valid,
    output logic decode_valid,
    output logic rw,
    output logic [2:0] src_tile,
    output logic [2:0] dest_tile,
    output logic [11:0] address
);
always_comb
begin
    rw = 1'b0;
    src_tile = 3'b000;
    dest_tile = 3'b000;
    address = 12'd0;
    decode_valid = 1'b0;
    if(packet_valid)
    begin
        rw = packet[31];
        src_tile = packet[30:28];
        dest_tile = packet[27:25];
        address = packet[24:13];
        decode_valid = 1'b1;
    end
end
endmodule

### TB
module nic_top_tb;
logic clk;
logic rst;
logic fifo_wr_en;
logic [15:0] fifo_data_in;
logic [2:0] src_tile;
logic router_ready;
logic router_valid_in;
logic [31:0] router_data_in;
logic router_valid_out;
logic [31:0] router_data_out;
logic decode_valid;
logic rw;
logic [2:0] src_out;
logic [2:0] dest_out;
logic [11:0] address_out;
logic fifo_full;
logic fifo_empty;
nic_top dut
(
.clk(clk),
.rst(rst),
.fifo_wr_en(fifo_wr_en),
.fifo_data_in(fifo_data_in),
.src_tile(src_tile),
.router_ready(router_ready),
.router_valid_in(router_valid_in),
.router_data_in(router_data_in),
.router_valid_out(router_valid_out),
.router_data_out(router_data_out),
.decode_valid(decode_valid),
.rw(rw),
.src_out(src_out),
.dest_out(dest_out),
.address_out(address_out),
.fifo_full(fifo_full),
.fifo_empty(fifo_empty)
);
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end
initial begin
    rst = 1;
    fifo_wr_en = 0;
    fifo_data_in = 0;
    src_tile = 3'b001;
    router_ready = 1;
    router_valid_in = 0;
    router_data_in = 0;
    #20;
    rst = 0;
end
task write_fifo(input logic [15:0] data);
begin
    @(posedge clk);
    fifo_wr_en <= 1'b1;
    fifo_data_in <= data;
    @(posedge clk);
    fifo_wr_en <= 1'b0;
end
endtask
initial begin
    wait(rst == 0);
    #10;
    $display("Starting FIFO writes");
    write_fifo(
        {
        1'b1,
        3'b010,
        12'h123
        }
    );
    write_fifo(
        {
        1'b0,
        3'b011,
        12'h456
        }
    );
    write_fifo(
        {
        1'b1,
        3'b100,
        12'h789
        }
    );
  #300;
    $finish;
end
always @(posedge clk)
begin
    if(router_valid_out)
    begin
        $display("Router received packet");
        $display("TX DATA = %h",router_data_out);
        router_valid_in <= 1'b1;
        router_data_in <= router_data_out;
    end
    else
    begin
        router_valid_in <= 1'b0;
    end
end
always @(posedge clk)
begin
    if(decode_valid)
    begin
        $display("DECODED PACKET ");
        $display("RW = %b",rw);
        $display("SOURCE TILE = %d",src_out);
        $display("DEST TILE = %d",dest_out);
        $display("ADDRESS = %h",address_out);
    end
end
endmodule
