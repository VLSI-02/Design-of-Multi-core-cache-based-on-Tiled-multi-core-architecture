module cache_lru(cache.cache_lru_mb c1_inf);
//cache c1_inf();
logic [3:0]lru_tag = 4'b0000;
always_comb
begin
   if(c1_inf.rst)
     begin
       lru_tag <= 4'b0000;
     end
   else if ( c1_inf.update_lru == 1)
      begin
        if (c1_inf.lru_id == 2'b00)
          begin
            lru_tag[0]  =  ~lru_tag[0];
            c1_inf.lru_way = lru_tag[0];
          end
        else if(c1_inf.lru_id == 2'b01)
          begin
            lru_tag[1] = ~lru_tag[1];
            c1_inf.lru_way = lru_tag[0];
          end
        else if (c1_inf.lru_id == 2'b10)
          begin
            lru_tag[2] = ~lru_tag[2];
            c1_inf.lru_way = lru_tag[0];
          end
        else 
          begin
            lru_tag[3] = ~lru_tag[3];
            c1_inf.lru_way = lru_tag[0];
          end
      end
end
endmodule