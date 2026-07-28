import L1_cache_mem::*;

module cache_controller(cache.cache_controller_mb c1_inf);
//cache c1_inf();
l1_cache_line_t cache_mem_out[0:3][0:1];
C_STATES_t C_NS,C_PS;
logic done = 1'b0;
//MESI_STATES_t current_mesi_state = INVALID ;
//MESI_STATES_t next_mesi_state;
logic snoop_done = 1'b0;
logic stall  = 1'b0;
logic write_back = 1'b0;
logic snoop_wb_read = 1'b0;
logic snoop_wb_write = 1'b0;
logic hit = 1'b0, miss = 1'b0;
logic victim_way = 'x;
logic fill_pending = 1'b0;
always_ff @(posedge c1_inf.clk or posedge c1_inf.rst)
begin
  if(c1_inf.rst)
    begin
      C_PS <= IDLE;
    end
  else 
    begin
      C_PS <= C_NS;
    end
end
always_comb
begin
 case(C_PS)
  IDLE: begin
          if(c1_inf.rst)
            begin
              C_NS <= IDLE;
            end
          else if (c1_inf.snoop_read == 1'b1 || c1_inf.snoop_write == 1'b1) 
            begin
              C_NS <= SNOOP;
            end
          else if (!done && !stall)
            begin
              C_NS <= COMPARE;
            end
          else if (done)
            begin
              C_NS <= DONE;
            end
           else if (done && stall)
            begin
              C_NS <= DONE;
            end
           else
            begin
              C_NS <= IDLE;
            end
        end
 COMPARE : begin
              if(c1_inf.rst)
                   C_NS <= IDLE;
                else if (write_back)
                    C_NS <= WRITEBACK;
                 else if (stall)
                   C_NS <= DONE;
                 else if (done)
                    C_NS <= DONE;
                 else if (c1_inf.snoop_read == 1'b1 || c1_inf.snoop_write == 1'b1)
                    C_NS <= SNOOP;
                 else
                    C_NS <= COMPARE; 
                 end
 DONE : begin
           if(c1_inf.rst)
                 begin
                   C_NS <= IDLE;
                 end
            else if (c1_inf.data_ready)
                 C_NS <= COMPARE;
            else if (c1_inf.snoop_read == 1'b1 || c1_inf.snoop_write == 1'b1)
                    C_NS <= SNOOP;
              else if (!done)
                begin
                  C_NS <= COMPARE;
                end
               else if(done && stall)
                  C_NS <= DONE;
               else 
                  C_NS <= DONE;
        end
  SNOOP : begin
            if(c1_inf.rst)
              begin
                C_NS <= IDLE;  
              end
            else if (write_back)
              begin
                C_NS <= WRITEBACK;
              end
            else if (snoop_done == 1'b1)
              begin
               C_NS <= DONE;
              end
            else 
              begin
                C_NS <= SNOOP;
              end
          end
 WRITEBACK:begin
              if(c1_inf.rst)
                begin
                  C_NS <= IDLE;
                end
              else if (done)
                begin
                  C_NS <= DONE;
                end
              else 
                begin
                  C_NS <= WRITEBACK;
                end
            end
 default : begin
             C_NS <= IDLE; 
           end
 endcase
end
always_ff @(posedge c1_inf.clk)
begin
  cache_mem_out = c1_inf.cache_mem_out; 
  case(C_PS)
   IDLE : begin
            cache_mem_out <= cache_mem_out;
          end
   COMPARE : begin
               hit        <= 1'b0;
               miss       <= 1'b0;
               stall      <= 1'b0;
               write_back <= 1'b0; 
            done       <= 1'b0;
             if(stall == 1'b0)
               begin
                if(c1_inf.inst[9:8] == 2'b00)
                 begin
                  c1_inf.write_en <= 1'b0;
                 end
                else if (c1_inf.inst[9:8] == 2'b01) // read operation
                 begin
                  if(c1_inf.inst[3:2] == 2'b00)
                    begin
                      if(cache_mem_out[0][0].valid == 1'b1 && (cache_mem_out[0][0].tag == c1_inf.inst[7:4]))
                        begin
                          c1_inf.Data_out <= cache_mem_out[0][0].data;                         
                          hit <= 1'b1;
                          if(c1_inf.Data_out == cache_mem_out[0][0].data)
                            done <= 1'b1;
                        end
                      else if(cache_mem_out[0][1].valid == 1'b1 && (cache_mem_out[0][1].tag == c1_inf.inst[7:4]))
                        begin
                          c1_inf.Data_out <= cache_mem_out[0][1].data;
                          hit <= 1'b1;
                          done <= 1'b1;
                        end
                      else 
                        begin
                          c1_inf.L1_miss_out <= c1_inf.inst;
                          miss <= 1'b1;
                          stall <= 1'b1;
                          fill_pending <= 1'b1;
                        end
                    end
                  else if (c1_inf.inst[3:2] == 2'b01)  
                    begin
                      if(cache_mem_out[1][0].valid == 1'b1 && (cache_mem_out[1][0].tag == c1_inf.inst[7:4]))
                        begin
                          c1_inf.Data_out <= cache_mem_out[1][0].data;
                          hit <= 1'b1;
                          done <= 1'b1;
                        end
                      else if(cache_mem_out[1][1].valid == 1'b1 && (cache_mem_out[1][1].tag == c1_inf.inst[7:4]))
                        begin
                          c1_inf.Data_out <= cache_mem_out[1][1].data;
                          hit <= 1'b1;
                          done <= 1'b1;
                        end
                      else 
                        begin
                          c1_inf.L1_miss_out <= c1_inf.inst;
                          miss <= 1'b1;
                          stall <= 1'b1;
                          write_back <= 1'b0;
                          fill_pending <= 1'b1;
                        end
                    end
                  else if (c1_inf.inst[3:2] == 2'b10)
                    begin
                      if(cache_mem_out[2][0].valid == 1'b1 && (cache_mem_out[2][0].tag == c1_inf.inst[7:4]))
                        begin
                          c1_inf.Data_out <= cache_mem_out[2][0].data;
                          hit <= 1'b1;
                          done <= 1'b1;
                        end
                      else if(cache_mem_out[2][1].valid == 1'b1 && (cache_mem_out[2][1].tag == c1_inf.inst[7:4]))
                        begin
                          c1_inf.Data_out <= cache_mem_out[2][1].data;
                          hit <= 1'b1;
                          done <= 1'b1;
                        end
                      else 
                        begin
                          c1_inf.L1_miss_out <= c1_inf.inst;
                          miss <= 1'b1;
                          stall <= 1'b1;
                          fill_pending <= 1'b1;
                        end
                    end
                   else if (c1_inf.inst[3:2] == 2'b11)
                    begin
                      if(cache_mem_out[3][0].valid == 1'b1 && (cache_mem_out[3][0].tag == c1_inf.inst[7:4]))
                        begin
                          c1_inf.Data_out <= cache_mem_out[3][0].data;
                          hit <= 1'b1;
                          done <= 1'b1;
                        end
                      else if(cache_mem_out[3][1].valid == 1'b1 && (cache_mem_out[3][1].tag == c1_inf.inst[7:4]))
                        begin
                          c1_inf.Data_out <= cache_mem_out[3][1].data;
                          hit <= 1'b1;
                          done <= 1'b1;
                        end
                      else 
                        begin
                          c1_inf.L1_miss_out <= c1_inf.inst;
                          miss <= 1'b1;
                          stall <= 1'b1;
                          fill_pending <= 1'b1;
                        end
                    end
                end
               else if (c1_inf.inst[9:8] == 2'b10)  // store operation
                    begin
                       if (c1_inf.inst[3:2] == 2'b00)
                         begin
                           if(cache_mem_out[0][0].valid == 1'b1 && (cache_mem_out[0][0].tag == c1_inf.inst[7:4]))
                                 begin
                                  c1_inf.write_en <= 1'b1;
                                  write_back <= 1'b0;
                                   c1_inf.update_line <= {1'b1,1'b1,mesi_on_local_op(cache_mem_out[0][0].C_tag,c1_inf.inst[9:8],c1_inf.shared),c1_inf.inst[7:4],c1_inf.in_data};
                                   c1_inf.set_idx <= 2'b00;
                                   c1_inf.way_sel <= 1'b0;
                                   hit <= 1'b1;
                                   done <= 1'b1;
                              end
                           else if(cache_mem_out[0][1].valid == 1'b1 && (cache_mem_out[0][1].tag == c1_inf.inst[7:4]))
                                begin
                                  c1_inf.write_en <= 1'b1;
                                  write_back <= 1'b0;
                                  c1_inf.update_line <= {1'b1,1'b1,mesi_on_local_op(cache_mem_out[0][1].C_tag,c1_inf.inst[9:8],c1_inf.shared),c1_inf.inst[7:4],c1_inf.in_data};
                                  c1_inf.set_idx <= 2'b00;
                                  c1_inf.way_sel <= 1'b1;
                                  hit <= 1'b1;
                                  done <= 1'b1;
                                 end
                            else 
                             begin
                              c1_inf.L1_miss_out <= c1_inf.inst;
                              miss <= 1'b1;
                              stall <= 1'b1;
                              fill_pending <= 1'b1;
                             end
                         end
                       else if (c1_inf.inst[3:2] == 2'b01)
                         begin
                           if(cache_mem_out[1][0].valid == 1'b1 && (cache_mem_out[1][0].tag == c1_inf.inst[7:4]))
                                 begin
                                  c1_inf.write_en <= 1'b1;
                                   write_back <= 1'b0;
                                   c1_inf.update_line <= {1'b1,1'b1,mesi_on_local_op(cache_mem_out[1][0].C_tag,c1_inf.inst[9:8],c1_inf.shared),c1_inf.inst[7:4],c1_inf.in_data};
                                   c1_inf.set_idx <= 2'b01;
                                   c1_inf.way_sel <= 1'b0;
                                   hit <= 1'b1;
                                   done <= 1'b1;
                              end
                           else if(cache_mem_out[1][1].valid == 1'b1 && (cache_mem_out[1][1].tag == c1_inf.inst[7:4]))
                              begin
                              c1_inf.write_en <= 1'b1;
                              write_back <= 1'b0;
                               c1_inf.update_line <= {1'b1,1'b1,mesi_on_local_op(cache_mem_out[1][1].C_tag,c1_inf.inst[9:8],c1_inf.shared),c1_inf.inst[7:4],c1_inf.in_data};
                               c1_inf.set_idx <= 2'b01;
                               c1_inf.way_sel <= 1'b1;
                               hit <= 1'b1;
                               done <= 1'b1;
                             end
                           else 
                            begin
                             c1_inf.L1_miss_out <= c1_inf.inst;
                             miss <= 1'b1;
                             stall <= 1'b1;
                            fill_pending <= 1'b1;
                            end
                        end
                     else if (c1_inf.inst[3:2] == 2'b10)
                         begin
                           if(cache_mem_out[2][0].valid == 1'b1 && (cache_mem_out[2][0].tag == c1_inf.inst[7:4]))
                                 begin
                                  c1_inf.write_en <= 1'b1;
                                  write_back <= 1'b0;
                                   c1_inf.update_line <= {1'b1,1'b1,mesi_on_local_op(cache_mem_out[2][0].C_tag,c1_inf.inst[9:8],c1_inf.shared),c1_inf.inst[7:4],c1_inf.in_data};
                                   c1_inf.set_idx <= 2'b10;
                                   c1_inf.way_sel <= 1'b0;
                                   hit <= 1'b1;
                                   done <= 1'b1;
                                 end
                           else if(cache_mem_out[2][1].valid == 1'b1 && (cache_mem_out[2][1].tag == c1_inf.inst[7:4]))
                               begin
                                 c1_inf.write_en <= 1'b1;
                                 write_back <= 1'b0;
                                 c1_inf.update_line <= {1'b1,1'b1,mesi_on_local_op(cache_mem_out[2][1].C_tag,c1_inf.inst[9:8],c1_inf.shared),c1_inf.inst[7:4],c1_inf.in_data};
                                 c1_inf.set_idx <= 2'b10;
                                 c1_inf.way_sel <= 1'b1;
                                 hit <= 1'b1;
                                 done <= 1'b1;
                              end
                            else 
                              begin
                               c1_inf.L1_miss_out <= c1_inf.inst;
                               miss <= 1'b1;
                               stall <= 1'b1;
                              fill_pending <= 1'b1;
                             end
                    end
              else if (c1_inf.inst[9:8] == 2'b11)  //flush operation
              begin
                if(c1_inf.inst[3:2] == 2'b00)
                  begin
                    if(cache_mem_out[0][0].valid == 1'b1 && cache_mem_out[0][0].tag == c1_inf.inst[7:4])
                      begin
                        if (cache_mem_out[0][0].dirty == 1'b1)
                          begin
                            write_back <= 1'b1;
                            victim_way <= 1'b0;
                            stall <= 1'b1;
                          end
                        else 
                          begin
                            c1_inf.write_en  <= 1'b1;
                            c1_inf.set_idx <= 2'b0;
                            c1_inf.way_sel <= 1'b0;
                            c1_inf.update_line <= {1'b0,1'b0,mesi_on_local_op(cache_mem_out[0][0].C_tag,c1_inf.inst[9:8],c1_inf.shared),4'b0,8'b0};
                            done <= 1'b1;
                          end
                      end
                     else if(cache_mem_out[0][1].valid == 1'b1 && cache_mem_out[0][1].tag == c1_inf.inst[7:4])
                      begin
                        if (cache_mem_out[0][1].dirty == 1'b1)
                          begin
                            write_back <= 1'b1;
                            victim_way <= 1'b1;
                            stall <= 1'b1;
                          end
                        else 
                          begin
                            c1_inf.write_en  <= 1'b1;
                            c1_inf.set_idx <= 2'b0;
                            c1_inf.way_sel <= 1'b1;
                            c1_inf.update_line <= {1'b0,1'b0,mesi_on_local_op(cache_mem_out[0][1].C_tag,c1_inf.inst[9:8],c1_inf.shared),4'b0,8'b0};
                            done <= 1'b1;
                          end
                      end
                  end
                 else if (c1_inf.inst[3:2] == 2'b01)
                  begin
                     if(cache_mem_out[1][0].valid == 1'b1 && cache_mem_out[1][0].tag == c1_inf.inst[7:4])
                      begin
                        if (cache_mem_out[1][0].dirty == 1'b1)
                          begin
                            write_back <= 1'b1;
                            victim_way <= 1'b0;
                            stall <= 1'b1;
                          end
                        else 
                          begin
                            c1_inf.write_en  <= 1'b1;
                            c1_inf.set_idx <= 2'd1;
                            c1_inf.way_sel <= 1'b0;
                            c1_inf.update_line <= {1'b0,1'b0,mesi_on_local_op(cache_mem_out[1][0].C_tag,c1_inf.inst[9:8],c1_inf.shared),4'b0,8'b0};
                            done <= 1'b1;
                          end
                      end
                     else if(cache_mem_out[1][1].valid == 1'b1 && cache_mem_out[1][1].tag == c1_inf.inst[7:4])
                      begin
                        if (cache_mem_out[1][1].dirty == 1'b1)
                          begin
                            write_back <= 1'b1;
                            victim_way <= 1'b1;
                            stall <= 1'b1;
                          end
                        else 
                          begin
                            c1_inf.write_en  <= 1'b1;
                            c1_inf.set_idx <= 2'd1;
                            c1_inf.way_sel <= 1'b1;
                            c1_inf.update_line <= {1'b0,1'b0,mesi_on_local_op(cache_mem_out[1][1].C_tag,c1_inf.inst[9:8],c1_inf.shared),4'b0,8'b0};
                            done <= 1'b1;
                          end
                      end 
                  end
                 else if (c1_inf.inst[3:2] == 2'b10)
                  begin
                   if(cache_mem_out[2][0].valid == 1'b1 && cache_mem_out[2][0].tag == c1_inf.inst[7:4])
                      begin
                        if (cache_mem_out[2][0].dirty == 1'b1)
                          begin
                            write_back <= 1'b1;
                            victim_way <= 1'b0;
                            stall <= 1'b1;
                          end
                        else 
                          begin
                            c1_inf.write_en  <= 1'b1;
                            c1_inf.set_idx <= 2'd2;
                            c1_inf.way_sel <= 1'b0;
                            c1_inf.update_line <= {1'b0,1'b0,mesi_on_local_op(cache_mem_out[2][0].C_tag,c1_inf.inst[9:8],c1_inf.shared),4'b0,8'b0};
                            done <= 1'b1;
                          end
                      end
                     else if(cache_mem_out[2][1].valid == 1'b1 && cache_mem_out[2][1].tag == c1_inf.inst[7:4])
                      begin
                        if (cache_mem_out[2][1].dirty == 1'b1)
                          begin
                            write_back <= 1'b1;
                            victim_way <= 1'b1;
                            stall <= 1'b1;
                          end
                        else 
                          begin
                            c1_inf.write_en  <= 1'b1;
                            c1_inf.set_idx <= 2'd2;
                            c1_inf.way_sel <= 1'b1;
                           c1_inf.update_line <= {1'b0,1'b0,mesi_on_local_op(cache_mem_out[2][1].C_tag,c1_inf.inst[9:8],c1_inf.shared),4'b0,8'b0};
                            done <= 1'b1;
                          end
                      end
                  end
                 else if (c1_inf.inst[3:2] == 2'b11)
                  begin
                     if(cache_mem_out[3][0].valid == 1'b1 && cache_mem_out[3][0].tag == c1_inf.inst[7:4])
                      begin
                        if (cache_mem_out[3][0].dirty == 1'b1)
                          begin
                            write_back <= 1'b1;
                            victim_way <= 1'b0;
                            stall <= 1'b1;
                          end
                        else 
                          begin
                            c1_inf.write_en  <= 1'b1;
                            c1_inf.set_idx <= 2'd3;
                            c1_inf.way_sel <= 1'b0;
                            c1_inf.update_line <= {1'b0,1'b0,mesi_on_local_op(cache_mem_out[3][0].C_tag,c1_inf.inst[9:8],c1_inf.shared),4'b0,8'b0};
                            done <= 1'b1;
                          end
                      end
                     else if(cache_mem_out[3][1].valid == 1'b1 && cache_mem_out[3][1].tag == c1_inf.inst[7:4])
                      begin
                        if (cache_mem_out[3][1].dirty == 1'b1)
                          begin
                            write_back <= 1'b1;
                            victim_way <= 1'b1;
                            stall <= 1'b1;
                          end
                        else 
                          begin
                            c1_inf.write_en  <= 1'b1;
                            c1_inf.set_idx <= 2'd3;
                            c1_inf.way_sel <= 1'b1;
                            c1_inf.update_line <= {1'b0,1'b0,mesi_on_local_op(cache_mem_out[3][1].C_tag,c1_inf.inst[9:8],c1_inf.shared),4'b0,8'b0};
                            done <= 1'b1;
                          end
                      end
                    end
              end
           end
          end
           else  
            begin
             if(c1_inf.Data_addr_fetch[3:2] == 2'b00)
               begin
                if(fill_pending && c1_inf.data_ready)
                  begin
                    if(cache_mem_out[0][0].valid == 1'b0)
                      begin
                       write_back <= 1'b0;
                       c1_inf.write_en <= 1'b1;
                       c1_inf.set_idx <= 2'b00;
                       c1_inf.way_sel <= 1'b0;
                       c1_inf.update_line <= {1'b1,1'b0,mesi_on_local_op(INVALID,2'b01,c1_inf.shared),c1_inf.Data_addr_fetch[7:4],c1_inf.Data_fetch};
                       hit <= 1'b0;
                       stall <= 1'b0;
                       fill_pending <= 1'b0;
                      end
                   else if (cache_mem_out[0][1].valid == 1'b0)
                      begin
                       write_back <= 1'b0;
                       c1_inf.write_en <= 1'b1;
                       c1_inf.set_idx <= 2'b00;
                       c1_inf.way_sel <= 1'b1;
                       c1_inf.update_line <= {1'b1,1'b0,mesi_on_local_op(INVALID,2'b01,c1_inf.shared),c1_inf.Data_addr_fetch[7:4],c1_inf.Data_fetch};
                       hit <= 1'b0;
                       stall <= 1'b0;
                       fill_pending <= 1'b0;
                      end
                 else 
                  begin
                     if(cache_mem_out[0][(c1_inf.lru_way)].dirty == 1'b0)
                    begin
                 write_back <= 1'b0;
                  c1_inf.write_en <= 1'b1;
                  c1_inf.set_idx <= 2'b00;
                  c1_inf.way_sel <= c1_inf.lru_way;
                  c1_inf.update_line <= {1'b1,1'b0,mesi_on_local_op(INVALID,2'b01,c1_inf.shared),c1_inf.Data_addr_fetch[7:4],c1_inf.Data_fetch};
                  hit <= 1'b0;
                  stall <= 1'b0; 
                  fill_pending <= 1'b0;
                 end
                 else 
                 begin
                   write_back <= 1'b1;
                   victim_way <=  c1_inf.lru_way;
                   stall <= 1'b1;
                   // fill_pending stays 1 — victim must be written back first
                 end
               end                        
            end
      else if (c1_inf.Data_addr_fetch[3:2] == 2'b01)
       begin
          if(fill_pending && c1_inf.data_ready)
           begin
              if(cache_mem_out[1][0].valid == 1'b0)
               begin
                 write_back <= 1'b0;
                  c1_inf.write_en <= 1'b1;
                  c1_inf.set_idx <= 2'b01;
                  c1_inf.way_sel <= 1'b0;
                  c1_inf.update_line <= {1'b1,1'b0,mesi_on_local_op(INVALID,2'b01,c1_inf.shared),c1_inf.Data_addr_fetch[7:4],c1_inf.Data_fetch};
                  hit <= 1'b0;
                  stall <= 1'b0;
                  fill_pending <= 1'b0;
               end
              else if (cache_mem_out[1][1].valid == 1'b0)
               begin
                 write_back <= 1'b0;
                  c1_inf.write_en <= 1'b1;
                  c1_inf.set_idx <= 2'b01;
                  c1_inf.way_sel <= 1'b1;
                  c1_inf.update_line <= {1'b1,1'b0,mesi_on_local_op(INVALID,2'b01,c1_inf.shared),c1_inf.Data_addr_fetch[7:4],c1_inf.Data_fetch};
                  hit <= 1'b0;
                  stall <= 1'b0;
                  fill_pending <= 1'b0;
               end
              else 
               begin
                 if(cache_mem_out[1][(c1_inf.lru_way)].dirty == 1'b0)
                 begin
                   write_back <= 1'b0;
                  c1_inf.write_en <= 1'b1;
                  c1_inf.set_idx <= 2'b01;
                  c1_inf.way_sel <=  c1_inf.lru_way;
                  c1_inf.update_line <= {1'b1,1'b0,mesi_on_local_op(INVALID,2'b01,c1_inf.shared),c1_inf.Data_addr_fetch[7:4],c1_inf.Data_fetch};
                  hit <= 1'b0;
                  stall <= 1'b0; 
                  fill_pending <= 1'b0;
                 end
                else 
                 begin
                   write_back <= 1'b1;
                   victim_way <=  c1_inf.lru_way;
                   hit <= 1'b0;
                   stall <= 1'b1;
                   // fill_pending stays 1
                 end
               end                        
           end 
       end
      else if (c1_inf.Data_addr_fetch[3:2] == 2'b10)
       begin
          if(fill_pending && c1_inf.data_ready)
           begin
              if(cache_mem_out[2][0].valid == 1'b0)
               begin
                 write_back <= 1'b0;
                  c1_inf.write_en <= 1'b1;
                  c1_inf.set_idx <= 2'b10;
                  c1_inf.way_sel <= 1'b0;
                  c1_inf.update_line <= {1'b1,1'b0,mesi_on_local_op(INVALID,2'b01,c1_inf.shared),c1_inf.Data_addr_fetch[7:4],c1_inf.Data_fetch};
                  hit <= 1'b0;
                  stall <= 1'b0;
                  fill_pending <= 1'b0;
               end
              else if (cache_mem_out[2][1].valid == 1'b0)
               begin
                 write_back <= 1'b0;
                  c1_inf.write_en <= 1'b1;
                  c1_inf.set_idx <= 2'b10;
                  c1_inf.way_sel <= 1'b1;
                  c1_inf.update_line <= {1'b1,1'b0,mesi_on_local_op(INVALID,2'b01,c1_inf.shared),c1_inf.Data_addr_fetch[7:4],c1_inf.Data_fetch};
                  hit <= 1'b0;
                  stall <= 1'b0;
                  fill_pending <= 1'b0;
               end
              else 
               begin
                 if(cache_mem_out[2][(c1_inf.lru_way)].dirty == 1'b0)
                 begin
                   write_back <= 1'b0;
                  c1_inf.write_en <= 1'b1;
                  c1_inf.set_idx <= 2'b10;
                  c1_inf.way_sel <= c1_inf.lru_way;
                  c1_inf.update_line <= {1'b1,1'b0,mesi_on_local_op(INVALID,2'b01,c1_inf.shared),c1_inf.Data_addr_fetch[7:4],c1_inf.Data_fetch}; 
                  hit <= 1'b0;
                  stall <= 1'b0;
                  fill_pending <= 1'b0;
                 end
                else 
                 begin
                   write_back <= 1'b1;
                   victim_way <= c1_inf.lru_way;
                   hit <= 1'b0;
                   stall <= 1'b1;
                   // fill_pending stays 1
                 end
               end                        
           end 
       end
      else if (c1_inf.Data_addr_fetch[3:2] == 2'b11)
       begin
          if(fill_pending && c1_inf.data_ready)
           begin
              if(cache_mem_out[3][0].valid == 1'b0)
               begin
                 write_back <= 1'b0;
                  c1_inf.write_en <= 1'b1;
                  c1_inf.set_idx <= 2'b11;
                  c1_inf.way_sel <= 1'b0;
                  c1_inf.update_line <= {1'b1,1'b0,mesi_on_local_op(INVALID,2'b01,c1_inf.shared),c1_inf.Data_addr_fetch[7:4],c1_inf.Data_fetch};
                  hit <= 1'b0;
                  stall <= 1'b0;
                  fill_pending <= 1'b0;
               end
              else if (cache_mem_out[3][1].valid == 1'b0)
               begin
                 write_back <= 1'b0;
                  c1_inf.write_en <= 1'b1;
                  c1_inf.set_idx <= 2'b11;
                  c1_inf.way_sel <= 1'b1;
                  c1_inf.update_line <= {1'b1,1'b0,mesi_on_local_op(INVALID,2'b01,c1_inf.shared),c1_inf.Data_addr_fetch[7:4],c1_inf.Data_fetch};
                  hit <= 1'b0;
                  stall <= 1'b0;
                  fill_pending <= 1'b0;
               end
              else 
               begin
                 if(cache_mem_out[3][(c1_inf.lru_way)].dirty == 1'b0)
                 begin
                   write_back <= 1'b0;
                  c1_inf.write_en <= 1'b1;
                  c1_inf.set_idx <= 2'b11;
                  c1_inf.way_sel <= c1_inf.lru_way;
                  c1_inf.update_line <= {1'b1,1'b0,mesi_on_local_op(INVALID,2'b01,c1_inf.shared),c1_inf.Data_addr_fetch[7:4],c1_inf.Data_fetch}; 
                  hit <= 1'b0;
                  stall <= 1'b0;
                  fill_pending <= 1'b0;
                 end
                else 
                 begin
                   write_back <= 1'b1;
                   victim_way <= c1_inf.lru_way;
                   stall <= 1'b1;
                   // fill_pending stays 1
                 end
               end                        
           end 
       end
   end
    end
  end
   DONE : begin
            done <= 1'b0;
            hit <= 1'b0;
            miss <= 1'b0;
            c1_inf.mem_wr_req <= 1'b0;
            c1_inf.snoop_ack <= 1'b0;
            snoop_done <= 1'b0;
            c1_inf.write_en <= 1'b0;
            write_back <= 1'b0;
          end
   SNOOP : begin
             if(c1_inf.snoop_read == 1'b1)
               begin
                 if(c1_inf.snoop_addr[3:2] == 2'b00)
                   begin
                    if(cache_mem_out[0][0].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[0][0].tag)
                      begin
                        if (cache_mem_out[0][0].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            snoop_wb_read <= 1'b1;
                            stall <= 1'b1;
                            victim_way <= 1'b0;
                          end
                        else 
                          begin
                            c1_inf.set_idx <= 2'b00;
                             c1_inf.way_sel <= 1'b0;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {cache_mem_out[0][0].valid,cache_mem_out[0][0].dirty,mesi_on_snoop(cache_mem_out[0][0].C_tag,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[0][0].tag,cache_mem_out[0][0].data}; 
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                        end
                     else if(cache_mem_out[0][1].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[0][1].tag)
                      begin
                         if (cache_mem_out[0][1].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            stall <= 1'b1;
                            snoop_wb_read <= 1'b1;
                            victim_way <= 1'b1;
                          end
                        else 
                          begin
                            c1_inf.set_idx <= 2'b00;
                             c1_inf.way_sel <= 1'b1;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {cache_mem_out[0][1].valid,cache_mem_out[0][1].dirty,mesi_on_snoop(cache_mem_out[0][1].C_tag,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[0][1].tag,cache_mem_out[0][1].data};
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                        end
                     else 
                       begin
                         c1_inf.snoop_ack <= 1'b1;
                          snoop_done <= 1'b1;
                       end
                    end
                 else if(c1_inf.snoop_addr[3:2] == 2'b01)
                   begin
                    if(cache_mem_out[1][0].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[1][0].tag)
                      begin
                          if (cache_mem_out[1][0].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            stall <= 1'b1;
                            snoop_wb_read <= 1'b1;
                            victim_way <= 1'b0;
                          end
                        else 
                          begin
                            c1_inf.set_idx <= 2'b01;
                             c1_inf.way_sel <= 1'b0;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {cache_mem_out[1][0].valid,cache_mem_out[1][0].dirty,mesi_on_snoop(cache_mem_out[1][0].C_tag,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[1][0].tag,cache_mem_out[1][0].data};
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                        end
                     else if(cache_mem_out[1][1].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[1][1].tag)
                      begin
                         if (cache_mem_out[1][1].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            stall <= 1'b1;
                            snoop_wb_read <= 1'b1;
                            victim_way <= 1'b1;
                          end
                        else 
                          begin
                            c1_inf.set_idx <= 2'b01;
                             c1_inf.way_sel <= 1'b1;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {cache_mem_out[1][1].valid,cache_mem_out[1][1].dirty,mesi_on_snoop(cache_mem_out[1][1].C_tag,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[1][1].tag,cache_mem_out[1][1].data};
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                        end
                      else 
                       begin
                         c1_inf.snoop_ack <= 1'b1;
                          snoop_done <= 1'b1;
                       end
                    end
                 if(c1_inf.snoop_addr[3:2] == 2'b10)
                   begin
                    if(cache_mem_out[2][0].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[2][0].tag)
                      begin
                        if (cache_mem_out[2][0].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            stall <= 1'b1;
                            snoop_wb_read <= 1'b1;
                            victim_way <= 1'b0;
                          end
                        else 
                          begin
                            c1_inf.set_idx <= 2'b10;
                             c1_inf.way_sel <= 1'b0;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {cache_mem_out[2][0].valid,cache_mem_out[2][0].dirty,mesi_on_snoop(cache_mem_out[2][0].C_tag,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[2][0].tag,cache_mem_out[2][0].data};
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                        end
                     else if(cache_mem_out[2][1].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[2][1].tag)
                      begin
                         if (cache_mem_out[2][1].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            stall <= 1'b1;
                            snoop_wb_read <= 1'b1;
                            victim_way <= 1'b1;
                          end
                        else 
                          begin
                            c1_inf.set_idx <= 2'b10;
                             c1_inf.way_sel <= 1'b1;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {cache_mem_out[2][1].valid,cache_mem_out[2][1].dirty,mesi_on_snoop(cache_mem_out[2][1].C_tag,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[2][1].tag,cache_mem_out[2][1].data};
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                        end
                        else 
                       begin
                         c1_inf.snoop_ack <= 1'b1;
                          snoop_done <= 1'b1;
                       end
                    end
                 if(c1_inf.snoop_addr[3:2] == 2'b11)
                   begin
                    if(cache_mem_out[3][0].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[3][0].tag)
                      begin
                         if (cache_mem_out[3][0].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            stall <= 1'b1;
                            snoop_wb_read <= 1'b1;
                            victim_way <= 1'b0;
                          end
                        else 
                          begin
                            c1_inf.set_idx <= 2'b11;
                             c1_inf.way_sel <= 1'b0;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {cache_mem_out[3][0].valid,cache_mem_out[3][0].dirty,mesi_on_snoop(cache_mem_out[3][0].C_tag,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[3][0].tag,cache_mem_out[3][0].data};
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                        end
                     else if(cache_mem_out[3][1].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[3][1].tag)
                      begin
                         if (cache_mem_out[3][1].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            stall <= 1'b1;
                            snoop_wb_read <= 1'b1;
                            victim_way <= 1'b1;
                          end
                        else 
                          begin
                            c1_inf.set_idx <= 2'b11;
                             c1_inf.way_sel <= 1'b1;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {cache_mem_out[3][1].valid,cache_mem_out[3][1].dirty,mesi_on_snoop(cache_mem_out[3][1].C_tag,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[3][1].tag,cache_mem_out[3][1].data};
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                        end
                        else 
                       begin
                         c1_inf.snoop_ack <= 1'b1;
                          snoop_done <= 1'b1;
                       end
                    end
               end
             else if(c1_inf.snoop_write == 1'b1)
               begin
                 if(c1_inf.snoop_addr[3:2] == 2'b00)
                   begin
                    if(cache_mem_out[0][0].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[0][0].tag)
                      begin
                          if (cache_mem_out[0][0].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            stall <= 1'b1;
                            snoop_wb_write <= 1'b1;
                            victim_way <= 1'b0;
                          end
                        else 
                          begin
                            c1_inf.set_idx <= 2'b00;
                             c1_inf.way_sel <= 1'b0;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                        end
                     else if(cache_mem_out[0][1].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[0][1].tag)
                      begin
                          if (cache_mem_out[0][1].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            stall <= 1'b1;
                            snoop_wb_write <= 1'b1;
                            victim_way <= 1'b1;
                          end
                        else 
                          begin
                             c1_inf.set_idx <= 2'b00;
                             c1_inf.way_sel <= 1'b1;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                        end
                        else 
                       begin
                         c1_inf.snoop_ack <= 1'b1;
                          snoop_done <= 1'b1;
                       end
                    end
                 else if(c1_inf.snoop_addr[3:2] == 2'b01)
                   begin
                    if(cache_mem_out[1][0].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[1][0].tag)
                      begin
                         if (cache_mem_out[1][0].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            stall <= 1'b1;
                            snoop_wb_write <= 1'b1;
                            victim_way <= 1'b0;
                          end
                        else 
                          begin
                             c1_inf.set_idx <= 2'b01;
                             c1_inf.way_sel <= 1'b0;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                        end
                     else if(cache_mem_out[1][1].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[1][1].tag)
                      begin
                         if (cache_mem_out[1][1].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            stall <= 1'b1;
                            snoop_wb_write <= 1'b1;
                            victim_way <= 1'b1;
                          end
                        else 
                          begin
                            c1_inf.set_idx <= 2'b01;
                             c1_inf.way_sel <= 1'b1;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                        end
                        else 
                       begin
                         c1_inf.snoop_ack <= 1'b1;
                          snoop_done <= 1'b1;
                       end
                    end
                 if(c1_inf.snoop_addr[3:2] == 2'b10)
                   begin
                    if(cache_mem_out[2][0].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[2][0].tag)
                      begin
                         if (cache_mem_out[2][0].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            stall <= 1'b1;
                            snoop_wb_write <= 1'b1;
                            victim_way <= 1'b0;
                          end
                        else 
                          begin
                             c1_inf.set_idx <= 2'b10;
                             c1_inf.way_sel <= 1'b0;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                        end
                     else if(cache_mem_out[2][1].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[2][1].tag)
                      begin
                        if (cache_mem_out[2][1].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            stall <= 1'b1;
                            snoop_wb_write <= 1'b1;
                            victim_way <= 1'b1;
                          end
                        else 
                          begin
                            c1_inf.set_idx <= 2'b10;
                             c1_inf.way_sel <= 1'b1;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                        end
                        else 
                       begin
                         c1_inf.snoop_ack <= 1'b1;
                          snoop_done <= 1'b1;
                       end
                    end
                 if(c1_inf.snoop_addr[3:2] == 2'b11)
                   begin
                    if(cache_mem_out[3][0].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[3][0].tag)
                      begin
                        if (cache_mem_out[3][0].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            stall <= 1'b1;
                            snoop_wb_write <= 1'b1;
                            victim_way <= 1'b0;
                          end
                        else 
                          begin
                             c1_inf.set_idx <= 2'b11;
                             c1_inf.way_sel <= 1'b0;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                        end
                     else if(cache_mem_out[3][1].valid == 1'b1 && c1_inf.snoop_addr[7:4] == cache_mem_out[3][1].tag)
                      begin
                        if (cache_mem_out[3][1].C_tag == MODIFIED)
                          begin
                            write_back <= 1'b1;
                            stall <= 1'b1;
                            snoop_wb_write <= 1'b1;
                            victim_way <= 1'b1;
                          end
                        else 
                          begin
                             c1_inf.set_idx <= 2'b11;
                             c1_inf.way_sel <= 1'b1;
                            c1_inf.write_en <= 1'b1;
                            c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                            c1_inf.snoop_ack <= 1'b1;
                            snoop_done <= 1'b1;
                          end
                      end
                      else 
                       begin
                         c1_inf.snoop_ack <= 1'b1;
                          snoop_done <= 1'b1;
                       end
                    end
               end
           end  
  WRITEBACK : begin
                if(snoop_wb_write  == 1'b1)
                  begin
                   if(c1_inf.snoop_addr[3:2] == 2'b00)
                      begin
                       if(cache_mem_out[0][victim_way].valid == 1'b1 && cache_mem_out[0][victim_way].tag == c1_inf.snoop_addr[7:4])
                        begin
                         if(cache_mem_out[0][victim_way].C_tag == MODIFIED)
                           begin
                             c1_inf.mem_wr_req <= 1'b1;
                             c1_inf.mem_addr <= {cache_mem_out[0][victim_way].tag,cache_mem_out[0][victim_way].set_index};
                             if(c1_inf.mem_ready)
                               begin
                                 c1_inf.mem_data <= cache_mem_out[0][victim_way].data;
                                 c1_inf.write_en <= 1'b1;
                                 c1_inf.set_idx <= 2'b00;
                                 c1_inf.way_sel <= victim_way;
                                 c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                                 done <= 1'b1;
                                 stall <= 1'b0;
                                 write_back <= 1'b0;
                               end
                           end
                         else 
                           begin
                             c1_inf.write_en <= 1'b1;
                             c1_inf.set_idx <= 2'b00;
                             c1_inf.way_sel <= victim_way;
                             c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                             done <= 1'b1;
                             stall <= 1'b0;
                             write_back <= 1'b0; 
                           end
                         end             
                       end               
                   else if(c1_inf.snoop_addr[3:2] == 2'b01)
                    begin
                     if(cache_mem_out[1][victim_way].valid == 1'b1 && cache_mem_out[1][victim_way].tag == c1_inf.snoop_addr[7:4])
                       begin
                         if(cache_mem_out[1][victim_way].C_tag == MODIFIED)
                           begin
                             c1_inf.mem_wr_req <= 1'b1;
                             c1_inf.mem_addr <= {cache_mem_out[1][victim_way].tag,cache_mem_out[1][victim_way].set_index};
                             if(c1_inf.mem_ready)
                               begin
                                 c1_inf.mem_data <= cache_mem_out[1][victim_way].data;
                                 c1_inf.write_en <= 1'b1;
                                 c1_inf.set_idx <= 2'b01;
                                 c1_inf.way_sel <= victim_way;
                                 c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                                 done <= 1'b1;
                                 stall <= 1'b0;
                                 write_back <= 1'b0;
                               end
                           end
                         else 
                           begin
                             c1_inf.write_en <= 1'b1;
                             c1_inf.set_idx <= 2'b01;
                             c1_inf.way_sel <= victim_way;
                             c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                             done <= 1'b1;
                             stall <= 1'b0;
                             write_back <= 1'b0; 
                           end
                       end          
                   end
                   else if(c1_inf.snoop_addr[3:2] == 2'b10)
                    begin
                     if(cache_mem_out[2][victim_way].valid == 1'b1 && cache_mem_out[2][victim_way].tag == c1_inf.snoop_addr[7:4])
                       begin
                         if(cache_mem_out[2][victim_way].C_tag == MODIFIED)
                           begin
                             c1_inf.mem_wr_req <= 1'b1;
                             c1_inf.mem_addr <= {cache_mem_out[2][victim_way].tag,cache_mem_out[2][victim_way].set_index};
                             if(c1_inf.mem_ready)
                               begin
                                 c1_inf.mem_data <= cache_mem_out[2][victim_way].data;
                                 c1_inf.write_en <= 1'b1;
                                 c1_inf.set_idx <= 2'b10;
                                 c1_inf.way_sel <= victim_way;
                                 c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                                 done <= 1'b1;
                                 stall <= 1'b0;
                                 write_back <= 1'b0;
                               end
                           end
                         else 
                           begin
                             c1_inf.write_en <= 1'b1;
                             c1_inf.set_idx <= 2'b10;
                             c1_inf.way_sel <= victim_way;
                             c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                             done <= 1'b1;
                             stall <= 1'b0;
                             write_back <= 1'b0; 
                           end
                       end   
                   end
                   else if(c1_inf.snoop_addr[3:2] == 2'b11)
                   begin
                     if(cache_mem_out[3][victim_way].valid == 1'b1 && cache_mem_out[3][victim_way].tag == c1_inf.snoop_addr[7:4])
                       begin
                         if(cache_mem_out[3][victim_way].C_tag == MODIFIED)
                           begin
                             c1_inf.mem_wr_req <= 1'b1;
                             c1_inf.mem_addr <= {cache_mem_out[3][victim_way].tag,cache_mem_out[3][victim_way].set_index};
                             if(c1_inf.mem_ready)
                               begin
                                 c1_inf.mem_data <= cache_mem_out[3][victim_way].data;
                                 c1_inf.write_en <= 1'b1;
                                 c1_inf.set_idx <= 2'b11;
                                 c1_inf.way_sel <= victim_way;
                                 c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                                 done <= 1'b1;
                                 stall <= 1'b0;
                                 write_back <= 1'b0;
                               end
                           end
                         else 
                           begin
                             c1_inf.write_en <= 1'b1;
                             c1_inf.set_idx <= 2'b11;
                             c1_inf.way_sel <= victim_way;
                             c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                             done <= 1'b1;
                             stall <= 1'b0;
                             write_back <= 1'b0; 
                           end
                       end   
                   end
                   snoop_wb_write <= 1'b0;
                  end
                 else if (snoop_wb_read  == 1'b1)
                   begin
                   if(c1_inf.snoop_addr[3:2] == 2'b00)
                    begin
                     if(cache_mem_out[0][victim_way].valid == 1'b1 && cache_mem_out[0][victim_way].tag == c1_inf.snoop_addr[7:4])
                       begin
                         if(cache_mem_out[0][victim_way].C_tag == MODIFIED)
                           begin
                             c1_inf.mem_wr_req <= 1'b1;
                             c1_inf.mem_addr <= {cache_mem_out[0][victim_way].tag,cache_mem_out[0][victim_way].set_index};
                             if(c1_inf.mem_ready)
                               begin
                                 c1_inf.mem_data <= cache_mem_out[0][victim_way].data;
                                 c1_inf.write_en <= 1'b1;
                                 c1_inf.set_idx <= 2'b00;
                                 c1_inf.way_sel <= victim_way;
                                 c1_inf.update_line <= {1'b1,1'b0,mesi_on_snoop(MODIFIED,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[0][victim_way].tag,cache_mem_out[0][victim_way].data};
                                 done <= 1'b1;
                                 stall <= 1'b0;
                                 write_back <= 1'b0;
                               end
                           end
                         else 
                           begin
                             c1_inf.write_en <= 1'b1;
                             c1_inf.set_idx <= 2'b00;
                             c1_inf.way_sel <= victim_way;
                             c1_inf.update_line <= {1'b1,1'b0,mesi_on_snoop(cache_mem_out[0][victim_way].C_tag,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[0][victim_way].tag,cache_mem_out[0][victim_way].data};
                             done <= 1'b1;
                             stall <= 1'b0;
                             write_back <= 1'b0; 
                           end
                         end             
                       end               
                   else if(c1_inf.snoop_addr[3:2] == 2'b01)
                    begin
                     if(cache_mem_out[1][victim_way].valid == 1'b1 && cache_mem_out[1][victim_way].tag == c1_inf.snoop_addr[7:4])
                       begin
                         if(cache_mem_out[1][victim_way].C_tag == MODIFIED)
                           begin
                             c1_inf.mem_wr_req <= 1'b1;
                             c1_inf.mem_addr <= {cache_mem_out[1][victim_way].tag,cache_mem_out[1][victim_way].set_index};
                             if(c1_inf.mem_ready)
                               begin
                                 c1_inf.mem_data <= cache_mem_out[1][victim_way].data;
                                 c1_inf.write_en <= 1'b1;
                                 c1_inf.set_idx <= 2'b01;
                                 c1_inf.way_sel <= victim_way;
                                 c1_inf.update_line <= {1'b1,1'b0,mesi_on_snoop(cache_mem_out[1][victim_way].C_tag,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[1][victim_way].tag,cache_mem_out[1][victim_way].data};
                                 done <= 1'b1;
                                 stall <= 1'b0;
                                 write_back <= 1'b0;
                               end
                           end
                         else 
                           begin
                             c1_inf.write_en <= 1'b1;
                             c1_inf.set_idx <= 2'b01;
                             c1_inf.way_sel <= victim_way;
                             c1_inf.update_line <= {1'b1,1'b0,mesi_on_snoop(cache_mem_out[1][victim_way].C_tag,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[1][victim_way].tag,cache_mem_out[1][victim_way].data};
                             done <= 1'b1;
                             stall <= 1'b0;
                             write_back <= 1'b0; 
                           end
                       end          
                    end
                   else if(c1_inf.snoop_addr[3:2] == 2'b10)
                   begin
                     if(cache_mem_out[2][victim_way].valid == 1'b1 && cache_mem_out[2][victim_way].tag == c1_inf.snoop_addr[7:4])
                       begin
                         if(cache_mem_out[2][victim_way].C_tag == MODIFIED)
                           begin
                             c1_inf.mem_wr_req <= 1'b1;
                             c1_inf.mem_addr <= {cache_mem_out[2][victim_way].tag,cache_mem_out[2][victim_way].set_index};
                             if(c1_inf.mem_ready)
                               begin
                                 c1_inf.mem_data <= cache_mem_out[2][victim_way].data;
                                 c1_inf.write_en <= 1'b1;
                                 c1_inf.set_idx <= 2'b10;
                                 c1_inf.way_sel <= victim_way;
                                 c1_inf.update_line <= {1'b1,1'b0,mesi_on_snoop(cache_mem_out[2][victim_way].C_tag,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[2][victim_way].tag,cache_mem_out[2][victim_way].data};
                                 done <= 1'b1;
                                 stall <= 1'b0;
                                 write_back <= 1'b0;
                               end
                           end
                         else 
                           begin
                             c1_inf.write_en <= 1'b1;
                             c1_inf.set_idx <= 2'b10;
                             c1_inf.way_sel <= victim_way;
                             c1_inf.update_line <= {1'b1,1'b0,mesi_on_snoop(cache_mem_out[2][victim_way].C_tag,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[2][victim_way].tag,cache_mem_out[2][victim_way].data};
                             done <= 1'b1;
                             stall <= 1'b0;
                             write_back <= 1'b0; 
                           end
                       end   
                   end
                   else if(c1_inf.snoop_addr[3:2] == 2'b11)
                   begin
                     if(cache_mem_out[3][victim_way].valid == 1'b1 && cache_mem_out[3][victim_way].tag == c1_inf.snoop_addr[7:4])
                       begin
                         if(cache_mem_out[3][victim_way].C_tag == MODIFIED)
                           begin
                             c1_inf.mem_wr_req <= 1'b1;
                             c1_inf.mem_addr <= {cache_mem_out[3][victim_way].tag,cache_mem_out[3][victim_way].set_index};
                             if(c1_inf.mem_ready)
                               begin
                                 c1_inf.mem_data <= cache_mem_out[3][victim_way].data;
                                 c1_inf.write_en <= 1'b1;
                                 c1_inf.set_idx <= 2'b11;
                                 c1_inf.way_sel <= victim_way;
                                 c1_inf.update_line <= {1'b1,1'b0,mesi_on_snoop(cache_mem_out[3][victim_way].C_tag,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[3][victim_way].tag,cache_mem_out[3][victim_way].data};
                                 done <= 1'b1;
                                 stall <= 1'b0;
                                 write_back <= 1'b0;
                               end
                           end
                         else 
                           begin
                             c1_inf.write_en <= 1'b1;
                             c1_inf.set_idx <= 2'b11;
                             c1_inf.way_sel <= victim_way;
                             c1_inf.update_line <= {1'b1,1'b0,mesi_on_snoop(cache_mem_out[3][victim_way].C_tag,c1_inf.snoop_read,c1_inf.snoop_write),cache_mem_out[3][victim_way].tag,cache_mem_out[3][victim_way].data};
                             done <= 1'b1;
                             stall <= 1'b0;
                             write_back <= 1'b0; 
                           end
                       end   
                   end     
                    snoop_wb_read <= 1'b0;    
                   end                  
                  else if (c1_inf.inst[9:8] == 2'b10)
                    begin
                     if(c1_inf.inst[3:2] == 2'b00)
                       begin
                         c1_inf.mem_wr_req <= 1'b1;
                          c1_inf.mem_addr <= {cache_mem_out[0][victim_way].tag,cache_mem_out[0][victim_way].set_index};
                           if (c1_inf.mem_ready)
                             begin 
                               c1_inf.mem_data <= cache_mem_out[0][victim_way].data;
                               c1_inf.write_en <= 1'b1;
                               c1_inf.set_idx <= 2'b00;
                               c1_inf.way_sel <= victim_way;
                               c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                               done <= 1'b1;
                                stall <= 1'b0;
                               write_back <= 1'b0;                                 
                             end
                       end 
                      else if (c1_inf.inst[3:2] == 2'b01)
                       begin
                         c1_inf.mem_wr_req <= 1'b1;
                         c1_inf.mem_addr <= {cache_mem_out[1][victim_way].tag,cache_mem_out[1][victim_way].set_index};
                           if (c1_inf.mem_ready)
                             begin 
                               c1_inf.mem_data <= cache_mem_out[1][victim_way].data;
                               c1_inf.write_en <= 1'b1;
                               c1_inf.set_idx <= 2'b01;
                               c1_inf.way_sel <= victim_way;
                               c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                               done <= 1'b1;
                                stall <= 1'b0;
                               write_back <= 1'b0;                               
                             end
                       end
                       else if (c1_inf.inst[3:2] == 2'b10)
                       begin
                         c1_inf.mem_wr_req <= 1'b1;
                         c1_inf.mem_addr <= {cache_mem_out[2][victim_way].tag,cache_mem_out[2][victim_way].set_index}; 
                           if (c1_inf.mem_ready)
                             begin 
                               c1_inf.mem_data <= cache_mem_out[2][victim_way].data;
                               c1_inf.write_en <= 1'b1;
                               c1_inf.set_idx <= 2'b10;
                               c1_inf.way_sel <= victim_way;
                               c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                               done <= 1'b1;
                                stall <= 1'b0;
                               write_back <= 1'b0;                           
                             end
                       end
                       else if (c1_inf.inst[3:2] == 2'b11)
                       begin
                         c1_inf.mem_wr_req <= 1'b1;
                         c1_inf.mem_addr <= {cache_mem_out[3][victim_way].tag,cache_mem_out[3][victim_way].set_index};
                           if (c1_inf.mem_ready)
                             begin 
                               c1_inf.mem_data <= cache_mem_out[3][victim_way].data;
                               c1_inf.write_en <= 1'b1;
                               c1_inf.set_idx <= 2'b11;
                               c1_inf.way_sel <= victim_way;
                               c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                               done <= 1'b1;
                                stall <= 1'b0;
                               write_back <= 1'b0;   
                             end
                       end
                     else if (c1_inf.inst[9:8] == 2'b11)
                      begin
                      if(c1_inf.inst[3:2] == 2'b00)
                       begin
                         c1_inf.mem_wr_req <= 1'b1;
                         c1_inf.mem_addr <= {cache_mem_out[0][victim_way].tag,cache_mem_out[0][victim_way].set_index}; 
                           if (c1_inf.mem_ready)
                             begin 
                               c1_inf.mem_data <= cache_mem_out[0][victim_way].data;
                               c1_inf.write_en <= 1'b1;
                               c1_inf.set_idx <= 2'b00;
                               c1_inf.way_sel <= victim_way;
                               c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                               done <= 1'b1;
                                stall <= 1'b0;
                               write_back <= 1'b0;    
                             end
                       end 
                      else if (c1_inf.inst[3:2] == 2'b01)
                       begin
                         c1_inf.mem_wr_req <= 1'b1;
                          c1_inf.mem_addr <= {cache_mem_out[1][victim_way].tag,cache_mem_out[1][victim_way].set_index};
                           if (c1_inf.mem_ready)
                             begin 
                               c1_inf.mem_data <= cache_mem_out[1][victim_way].data;
                               c1_inf.write_en <= 1'b1;
                               c1_inf.set_idx <= 2'b01;
                               c1_inf.way_sel <= victim_way;
                               c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                               done <= 1'b1;
                                stall <= 1'b0;
                               write_back <= 1'b0;   
                             end
                       end
                       else if (c1_inf.inst[3:2] == 2'b10)
                       begin
                         c1_inf.mem_wr_req <= 1'b1;
                          c1_inf.mem_addr <= {cache_mem_out[2][victim_way].tag,cache_mem_out[2][victim_way].set_index};
                           if (c1_inf.mem_ready)
                             begin 
                               c1_inf.mem_data <= cache_mem_out[2][victim_way].data;
                               c1_inf.write_en <= 1'b1;
                               c1_inf.set_idx <= 2'b10;
                               c1_inf.way_sel <= victim_way;
                               c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                               done <= 1'b1;
                                stall <= 1'b0;
                               write_back <= 1'b0;  
                             end
                       end
                       else if (c1_inf.inst[3:2] == 2'b11)
                       begin
                         c1_inf.mem_wr_req <= 1'b1;
                         c1_inf.mem_addr <= {cache_mem_out[3][victim_way].tag,cache_mem_out[3][victim_way].set_index};
                           if (c1_inf.mem_ready)
                             begin 
                               c1_inf.mem_data <= cache_mem_out[3][victim_way].data;
                               c1_inf.write_en <= 1'b1;
                               c1_inf.set_idx <= 2'b11;
                               c1_inf.way_sel <= victim_way;
                               c1_inf.update_line <= {1'b0,1'b0,INVALID,4'b0,8'b0};
                               done <= 1'b1;
                                stall <= 1'b0;
                               write_back <= 1'b0;                                  
                             end
                       end   
                    end  
                  end
             end
  endcase          
end
always_comb
begin
  if (hit || miss)
   begin
     if(c1_inf.snoop_read  || c1_inf.snoop_write)
       begin
         c1_inf.lru_id = c1_inf.snoop_addr[3:2];
         c1_inf.update_lru = 1'b1;
       end 
     else if (c1_inf.inst[9:8] == 2'b01 || c1_inf.inst[9:8] == 2'b10)
        begin
          c1_inf.lru_id = c1_inf.inst[3:2];
          c1_inf.update_lru = 1'b1;
        end
   end 
  else 
    c1_inf.update_lru = 1'b0;   
end
function MESI_STATES_t mesi_on_local_op(
    input MESI_STATES_t current_mesi,
    input logic [1:0] op_code,
    input logic shared_line
);
    case (current_mesi)
        INVALID:   mesi_on_local_op = (op_code==2'b01) ? (shared_line?SHARED:EXCLUSIVE)
                                     : (op_code==2'b10) ? MODIFIED : INVALID;
        EXCLUSIVE: mesi_on_local_op = (op_code==2'b10) ? MODIFIED : EXCLUSIVE;
        SHARED:    mesi_on_local_op = (op_code==2'b10) ? MODIFIED : SHARED;
        MODIFIED:  mesi_on_local_op = MODIFIED; // local ops never leave M
        default:   mesi_on_local_op = current_mesi;
    endcase
endfunction

function MESI_STATES_t mesi_on_snoop(
    input MESI_STATES_t current_mesi,
    input logic snoop_rd,
    input logic snoop_wr
);
    if (snoop_wr)      mesi_on_snoop = INVALID;
    else if (snoop_rd) mesi_on_snoop = (current_mesi==MODIFIED || current_mesi==EXCLUSIVE) ? SHARED : current_mesi;
    else               mesi_on_snoop = current_mesi;
endfunction

endmodule