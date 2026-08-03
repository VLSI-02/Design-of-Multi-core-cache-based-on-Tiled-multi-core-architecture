import L1_cache_mem::*;
module mux();
Mux_inf m1 ();
always_comb
begin
  if(m1.req_addr_out[5:4] == 2'b00)
    begin
      m1.L2_msg_req = m1.msg_req_out;
      m1.L2_req_addr = m1.req_addr_out;
      m1.L2_req_data = m1.req_data_out;
    end
  else 
    begin
      m1.NIC_msg_req = m1.msg_req_out;
      m1.NIC_peer_id_out = m1.peer_id_out;
      m1.NIC_req_addr = m1.req_addr_out;
      m1.NIC_req_data = m1.req_data_out;
    end
end
initial begin
  m1.msg_req_out = MSG_GETS;
  m1.req_addr_out = 8'b11111110;
  m1.req_data_out = 'bx;
  m1.peer_id_out = 2'b11;
  #40;
end
initial
begin
   $monitor ("msg_req_out = %d, msg_req_addr= %d, req_data_out = %d,NIC_msg_req_out = %d, NIC_add = %d, NIC_data = %d,NIC_peer = %d,L2_msg = %d,L2_addr= %d,L2_data = %d",
   m1.msg_req_out,m1.req_addr_out,m1.req_data_out,m1.NIC_msg_req,m1.NIC_req_addr,m1.NIC_req_data,m1.NIC_peer_id_out,m1.L2_msg_req,m1.L2_req_addr,m1.L2_req_data);
end
endmodule
