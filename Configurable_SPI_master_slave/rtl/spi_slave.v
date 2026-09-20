`timescale 1ns / 1ps



module spi_slave (input clk, rst, sclk, mosi, cs, bitwidth,input [1:0] spi_mode, output reg miso, done);


localparam IDLE=0,
           TRANS_M0=1,
           TRANS_M1=2,
           TRANS_M2=3,
           TRANS_M3=4;




reg [4:0] pos_edge_counter, neg_edge_counter;
reg [2:0] state;
wire pos_edge_spi, neg_edge_spi;
reg sclk_d;
wire [4:0] data_count;
//sample at cs low
reg bitwidth_reg;
reg [1:0] spi_mode_reg;

reg [6:0] slave_reg_addr; // shift reg to get slave addr from mosi
reg addr_done; // to indicate the addr has been received
reg [15:0] data_to_master; // data to be shifted onto miso
reg [15:0] data_to_master_shifter; // register to shift the data onto miso
reg write_reg; // to know if it is write or read operation
reg [15:0] data_to_slave; // shift reg to get data from mosi





// register logic
reg [15:0] device_id = 'hABCD;
reg [15:0] control_reg;
reg [15:0] status_reg;
reg [15:0] data_reg;


always@(*) begin

        if(!rst) begin
            data_to_master=0;
        end
        else if(addr_done) begin
            case(slave_reg_addr)
                'h00: begin
                    data_to_master= device_id;
                end
                'h01: begin
                    data_to_master= control_reg;
                end
                'h02: begin
                    data_to_master= status_reg;
                end
                'h03: begin
                    data_to_master= data_reg;
                 end
                 default: data_to_master=0;
            endcase
        end
end


always@(posedge clk or negedge rst) begin
    if(!rst) begin
        control_reg<=0;
        status_reg<=0;
        data_reg<=0;
    end
    else begin
    if(done) begin 
    if(write_reg) begin 
        case(slave_reg_addr)
            'h01: begin
                control_reg<=bitwidth_reg?data_to_slave:{8'b0,data_to_slave};
            end
            'h02: begin
                status_reg<=bitwidth_reg?data_to_slave:{8'b0,data_to_slave};
            end
            'h03: begin
                data_reg<=bitwidth_reg?data_to_slave:{8'b0,data_to_slave};
            end
        endcase
    end
    end
    end
end

// spi_clock podege and negedge detector
always@(posedge clk) begin
    sclk_d<=sclk;
end

assign pos_edge_spi= (sclk)&(~sclk_d);
assign neg_edge_spi= (~sclk)&(sclk_d);


//data_size
assign data_count= bitwidth_reg?15:7;

//fsm
always@(posedge clk or negedge rst) begin

    if(!rst) begin
        pos_edge_counter<=0;
        neg_edge_counter<=0;
        state<=IDLE;
        miso <= 0;
        done<=0;
        bitwidth_reg<=0;
        spi_mode_reg<=0;
        slave_reg_addr<=0;
        addr_done<=0;
        data_to_master_shifter<=0;
    end
    
    else begin
        if(addr_done) begin
            data_to_master_shifter<=data_to_master;
        end        
        if(!cs) begin    
        case(state)
            IDLE: begin
                done<=0;
                pos_edge_counter<=0;
                neg_edge_counter<=0;
                data_to_slave<=0;
                if(!cs) begin
                     bitwidth_reg<=bitwidth;
                     spi_mode_reg<=spi_mode;
                     case(spi_mode)
                            0: state<=TRANS_M0;
                            1: state<=TRANS_M1;
                            2: state<=TRANS_M2;
                            3: state<=TRANS_M3;
                     endcase
                end
            end
            
            TRANS_M0: begin  
                //sample on postive edge
                addr_done<=0;
                if(pos_edge_spi) begin
                    pos_edge_counter<=pos_edge_counter+1;
                    if(pos_edge_counter==0) begin
                        write_reg<=mosi;
                    end
                    else if(pos_edge_counter>0 && pos_edge_counter<8) begin
                        slave_reg_addr<={slave_reg_addr[5:0],mosi};
                        if(pos_edge_counter==7) begin
                            addr_done<=1;
                        end
                    end
                    else if(pos_edge_counter>7 && pos_edge_counter<=(data_count+8)) begin
                        data_to_slave<={data_to_slave[14:0],mosi};
                    end
                end
                
                //change on negative edge
                else if(neg_edge_spi) begin
                    neg_edge_counter<=neg_edge_counter+1;
                    if (neg_edge_counter>=7 && neg_edge_counter<(data_count+8) && !write_reg) begin
                        miso<=data_to_master_shifter[data_count];
                        data_to_master_shifter<= data_to_master_shifter<<1;
                    end
                    else if (neg_edge_counter==(data_count+8)) begin
                        state<=IDLE;
                        done<=1;
                    end  
                end
            end
            
            TRANS_M3: begin  
                //sample on postive edge
                addr_done<=0;
                if(pos_edge_spi) begin
                    pos_edge_counter<=pos_edge_counter+1;
                    if(pos_edge_counter==0) begin
                        write_reg<=mosi;
                    end
                    else if(pos_edge_counter>0 && pos_edge_counter<8) begin
                        slave_reg_addr<={slave_reg_addr[5:0],mosi};
                        if(pos_edge_counter==7) begin
                            addr_done<=1;
                        end
                    end
                    else if(pos_edge_counter>7 && pos_edge_counter<=(data_count+8)) begin
                        data_to_slave<={data_to_slave[14:0],mosi};
                    end
                    else if (pos_edge_counter>(data_count+8)) begin
                        state<=IDLE;
                        done<=1;
                    end  
                    
                end
                
                //change on negative edge
                else if(neg_edge_spi) begin
                    neg_edge_counter<=neg_edge_counter+1;
                    if (neg_edge_counter>=8 && neg_edge_counter<=(data_count+8) && !write_reg) begin
                        miso<=data_to_master_shifter[data_count];
                        data_to_master_shifter<= data_to_master_shifter<<1;
                    end
                end
            end
            
            
            TRANS_M1: begin  
                //sample on nagative edge
                addr_done<=0;
                if(neg_edge_spi) begin
                    neg_edge_counter<=neg_edge_counter+1;
                    if(neg_edge_counter==0) begin
                        write_reg<=mosi;
                    end
                    else if(neg_edge_counter>0 && neg_edge_counter<8) begin
                        slave_reg_addr<={slave_reg_addr[5:0],mosi};
                        if(neg_edge_counter==7) begin
                            addr_done<=1;
                        end
                    end
                    else if(neg_edge_counter>7 && neg_edge_counter<=(data_count+8)) begin
                        data_to_slave<={data_to_slave[14:0],mosi}; ///if(!write)
                        if (neg_edge_counter==(data_count+8)) begin
                           state<=IDLE;
                           done<=1;
                        end
                    end
                    //else if (neg_edge_counter==(data_count+8)) begin
                      //  state<=IDLE;
                        //done<=1;
                    //end  
                    
                end
                
                //change on positive edge
                else if(pos_edge_spi) begin
                    pos_edge_counter<=pos_edge_counter+1;
                    if (pos_edge_counter>=8 && pos_edge_counter<=(data_count+8) && !write_reg) begin
                        miso<=data_to_master_shifter[data_count];
                        data_to_master_shifter<= data_to_master_shifter<<1;
                    end
                end
            end
            
            
            TRANS_M2: begin  
                //sample on nagative edge
                addr_done<=0;
                if(neg_edge_spi) begin
                    neg_edge_counter<=neg_edge_counter+1;
                    if(neg_edge_counter==1) begin
                        write_reg<=mosi;
                    end
                    else if(neg_edge_counter>1 && neg_edge_counter<9) begin
                        slave_reg_addr<={slave_reg_addr[5:0],mosi};
                        if(neg_edge_counter==8) begin
                            addr_done<=1;
                        end
                    end
                    else if(neg_edge_counter>8 && neg_edge_counter<=(data_count+8+1)) begin
                        data_to_slave<={data_to_slave[14:0],mosi}; ///if(!write)
                    end  
                    
                end
                
                //change on positive edge
                else if(pos_edge_spi) begin
                    pos_edge_counter<=pos_edge_counter+1;
                    if (pos_edge_counter>=8 && pos_edge_counter<=(data_count+8) && !write_reg) begin
                        miso<=data_to_master_shifter[data_count];
                        data_to_master_shifter<= data_to_master_shifter<<1;
                    end
                    else if(pos_edge_counter>(data_count+8)) begin
                        state<=IDLE;
                        done<=1;
                    end
                end
            end     
        endcase
        end  
        else begin
            state<=IDLE;
            done<=0;
            pos_edge_counter<=0;
            neg_edge_counter<=0;
            data_to_slave<=0;
        end  
    end

end

endmodule

