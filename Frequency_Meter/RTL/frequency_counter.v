module frequency_counter(input clk,rst,async_in,output reg [13:0]freq );

localparam clk_freq=50000000,
           req_freq=1,
           clk_count_1s=(clk_freq/req_freq);

localparam IDLE=2'b00,
           STARTING1=2'b01,
           ENDING1=2'b10;
localparam ZERO=0,
           ONE=1;
                      
reg[13:0] counter;
reg [26:0]clk_counter;

reg [1:0]cs;
reg subcs,sec_flag,in;

always@(posedge clk)begin
    in<=async_in;
end

always@(posedge clk, negedge rst)begin
    if(!rst) begin
        clk_counter<=0;
        sec_flag<=0;
    end
    else begin
        if(clk_counter!=clk_count_1s) begin
            clk_counter=clk_counter+1;
            sec_flag<=0;
        end
        else if(clk_counter==clk_count_1s)begin
            clk_counter<=0;
            sec_flag<=1;
        end
        
    end
    
    
end


always@(posedge clk, negedge rst) begin
    if (!rst) begin
        counter<=0;
        cs<=IDLE;
        freq<=0;
        
    end
    else begin
        case(cs)
        
            IDLE:begin
                if(in)begin
                    cs<=STARTING1;
                    subcs<=ONE;
                end
                else if(!in)begin
                    cs<=ENDING1;
                    subcs<=ZERO;
                end
            end
            
            STARTING1:begin
                case(subcs)
                    ONE: begin
                        if(!in) begin
                            subcs<=ZERO;
                        end
                        if (sec_flag)begin
                                cs<=IDLE;
                                freq<=counter;
                                counter<=0;
                            end
                    end
                    
                    ZERO: begin
                        if(in) begin
                            subcs<=ONE;
                            if(!sec_flag)begin
                                counter<=counter+1;
                            end
                             if (sec_flag)begin
                                cs<=IDLE;
                                freq<=counter;
                                counter<=0;
                            end
                        end
                    end
                endcase
            end
            
            ENDING1:begin
                case(subcs)
                    ZERO: begin
                        if(in) begin
                            subcs<=ONE;
                        end
                         if (sec_flag) begin
                              cs<=IDLE;
                              freq<=counter;
                              counter<=0;
                         end
                    end
                    
                    ONE: begin
                        if(!in) begin
                            subcs<=ZERO;
                            if(!sec_flag)begin
                                counter<=counter+1;
                         end
                          if (sec_flag) begin
                              cs<=IDLE;
                              freq<=counter;
                              counter<=0;
                         end
                        end
                    end
                endcase
            end
        endcase
    
    
    end
    
end
endmodule
