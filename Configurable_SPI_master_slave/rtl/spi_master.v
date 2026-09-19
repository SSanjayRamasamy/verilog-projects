module spi_master #(parameter clk_freq=100000000, cs_high_ns=100, cs_negedge_to_clk_edge_ns=200, clk_edge_to_cs_high_ns=100)(
        input clk, rst, start, miso, bit_width, 
        input [1:0] spi_mode,
        input [25:0] s_clk_freq,
        input [15:0] data_to_slave,
        input write,
        input [6:0] slave_addr,
        output reg cs, mosi, busy, done, 
        output reg [2:0]  err_e, 
        output sclk,
        output reg [15:0] data_from_slave
        );

localparam clk_ns=1000000000/clk_freq; 
 
localparam IDLE=0,
           CS_HIGH=1,
           CS_TO_CLK=2,
           TRANS_M0=3,
           TRANS_M1=4,
           TRANS_M2=5,
           TRANS_M3=6,
           CLK_TO_CS=7;        

localparam count_cs_neg_to_clk= (cs_negedge_to_clk_edge_ns/clk_ns)-1-1,
           count_clk_to_cs_high= (clk_edge_to_cs_high_ns/clk_ns)-1-1,
           count_cs_high=(cs_high_ns/clk_ns)-1-1;

localparam IDLE_ERR=0,
           CHECK_CS=1,
           DONE_TRANS=2;

//           
reg [39:0]counter_timeout; // 3*25 *100M/1           
reg [1:0] err_state;


//sample frequency when start=1
reg [25:0] s_clk_freq_reg;
reg [1:0] spi_mode_reg;
reg bit_width_reg;
reg [15:0] data_to_slave_reg;
reg write_reg;
reg [6:0] slave_addr_reg;


//delay_counter
reg [31:0] counter_delay;


// spi_clk_edge_counters
reg [4:0] spi_posedge_counter;
reg [4:0] spi_negedge_counter;

//spi_clock generation
wire [25:0] half_count_sclk;
reg [25:0] counter_clk;
reg spi_clk;
reg spi_clk_d;
reg start_clk;
wire pos_edge_spi;
wire neg_edge_spi;
reg [2:0]state;
wire [3:0]data_count;

assign half_count_sclk = (s_clk_freq_reg==0 || s_clk_freq_reg>clk_freq/4)?1:(clk_freq/(s_clk_freq_reg*2))-1; //(100,000,000/(1*2))-1= 49999999,  log2(49999999)=25.575

reg err_reg3;
reg err_reg1;
reg err_reg2;
reg err_reg4;
reg err_reg5;
reg counter_to_test;
wire [39:0] threshold_timeout=3*(data_count+9)*2*(half_count_sclk+1);


always@(*) begin
    if(!rst) begin
        err_reg5=0;
        err_reg2=0;
        err_reg4=0;
    end
    else begin
    if(s_clk_freq==0)err_reg5=1; else err_reg5=0;
    if(slave_addr>3) err_reg2=1; else err_reg2=0;
    if((((slave_addr==0)&& write==1))) err_reg4=1; else err_reg4=0;
    end
end

always@(posedge clk or negedge rst) begin
    if(!rst) begin
        err_reg1<=0;
        err_state<=IDLE_ERR;
        counter_timeout<=0;
    end
    else begin
        case(err_state)
            IDLE_ERR: begin
                err_reg1<=0;
                counter_timeout<=0;
                if(start) begin
                    err_state<=CHECK_CS;
                end 
            end
            
            CHECK_CS: begin
                if (!busy) begin
                    err_state<=IDLE_ERR;
                end
                else begin
                        if(counter_timeout==threshold_timeout) begin //3 times the packet size
                            err_reg1<=1;
                            err_state<=IDLE_ERR;
                        end
                        else begin
                            counter_timeout<=counter_timeout+1;
                        end
                end
            end
        endcase
    end
    
end

always@(*) begin
    if (!rst) begin
        err_e=0;
    end
    else begin
        if(err_reg3) begin
            err_e=3'b011;
        end
        else if(err_reg1) begin
            err_e=3'b001;
        end
        else if(err_reg2) begin
            err_e=3'b010;
        end
        else if(err_reg4) begin
            err_e=3'b100;
        end
        else if(err_reg5) begin
            err_e=3'b101;
        end
        else begin
            err_e=0;
        end
    end
end


always @(posedge clk) begin
    if (!rst) begin
        case (spi_mode_reg[1])
            1'b0: spi_clk <= 1'b0;  
            1'b1: spi_clk <= 1'b1; 
        endcase
        counter_clk <= half_count_sclk;
    end
    else if (start_clk) begin
        if (counter_clk == half_count_sclk) begin
            spi_clk <= ~spi_clk;
            counter_clk <= 0;
        end
        else begin
            counter_clk <= counter_clk + 1'b1;
        end
    end
    else begin
        counter_clk <= half_count_sclk;

        case (spi_mode_reg[1])
            1'b0: spi_clk <= 1'b0;  
            1'b1: spi_clk <= 1'b1; 
        endcase
    end
end
assign sclk=spi_clk;

// posedge and negedge detection logic
always@(posedge clk) begin
    spi_clk_d<=spi_clk;
end
assign pos_edge_spi= (~spi_clk_d)&(spi_clk);
assign neg_edge_spi= (spi_clk_d)&(~spi_clk);


// data_size
assign data_count= bit_width_reg?15:7;
//error logic
//assign err_e=err_s;


always@(posedge clk or negedge rst) begin

    if(!rst) begin
        cs<=1;
        mosi<=0;
        busy<=0;
        done<=0;
        s_clk_freq_reg<=0; 
        spi_mode_reg<=0;
        bit_width_reg<=0; 
        start_clk<=0;
        counter_delay<=0;
        data_from_slave<=0;
        state<=IDLE;
        spi_posedge_counter<=0;
        spi_negedge_counter<=0;
        counter_to_test<=0;
        err_reg3<=0;
    end
    
    else begin
    
        if(!err_reg1 && !err_reg2 && !err_reg3 && !err_reg4 && !err_reg5) begin
        case (state)
        
            IDLE: begin
                data_from_slave<=0;
                if(start) begin
                    s_clk_freq_reg<=s_clk_freq; //sample frequency when start=1
                    spi_mode_reg<=spi_mode;
                    bit_width_reg<=bit_width;
                    state<=CS_HIGH;
                    //cs<=0;
                    busy<=1;
                    data_to_slave_reg<=data_to_slave;
                    write_reg<=write;
                    slave_addr_reg<=slave_addr;
                end
            end
            CS_HIGH: begin
                if(counter_delay==count_cs_high) begin
                    state<=CS_TO_CLK;
                    counter_delay<=0;
                    cs<=0;
                end
                else begin
                    counter_delay<=counter_delay+1;
                end
            end
            
            
            CS_TO_CLK: begin
                if(cs) begin
                    err_reg3<=1;
                end
                else begin
                //if(counter_to_test==1) begin
                if(counter_delay==count_cs_neg_to_clk) begin
                    case(spi_mode_reg)
                        0:state<=TRANS_M0;
                        1:state<=TRANS_M1;
                        2:state<=TRANS_M2;
                        3:state<=TRANS_M3;
                        default: state<=TRANS_M0;
                    endcase
                    start_clk<=1;
                    counter_delay<=0;
                    
                end
                //end
                else begin
                    counter_delay<=counter_delay+1;
                end
                //cs<=1;
                end
            end
            
            
            TRANS_M0: begin //data sampled on positive edge and changed on negative edge
                if(cs) begin
                    err_reg3<=1;
                end
                else begin                
                if(spi_negedge_counter==0) begin //virtual negedge to place data before it is sampled at posedge
                    mosi<=write_reg;
                    spi_negedge_counter<=spi_negedge_counter+1;
                end
                
                //read miso
                if(pos_edge_spi) begin
                    spi_posedge_counter<=spi_posedge_counter+1;
                    if(spi_posedge_counter>=8 && !write_reg) begin
                        data_from_slave<={data_from_slave[14:0],miso};
                    end
                end
                
                //change at negedge
                else if(neg_edge_spi)begin
                    spi_negedge_counter<=spi_negedge_counter+1;
                    if(spi_negedge_counter>0 && spi_negedge_counter<8) begin
                        mosi<=slave_addr_reg[6];
                        slave_addr_reg<=slave_addr_reg<<1;
                    end
                    else if (spi_negedge_counter>7 && spi_negedge_counter<=(data_count+8)) begin
                        //mosi<=data_to_slave_reg[data_count];
                        //data_to_slave_reg<=data_to_slave_reg<<1;
                        if(write_reg) begin
                            mosi<=data_to_slave_reg[data_count];
                            data_to_slave_reg<=data_to_slave_reg<<1;
                        end
                        else begin
                            mosi<=0;   
                        end
                    end
                    else begin
                        done<=1;
                        //data_from_slave<=data_from_slave_reg;
                        start_clk<=0;
                        state<=CLK_TO_CS;
                    end
                end
                end
            end
            
            TRANS_M3: begin //data sampled on positive edge and changed on negative edge
          
                if(cs) begin
                    err_reg3<=1;
                end
                else begin
                //read miso
                if(pos_edge_spi) begin
                    spi_posedge_counter<=spi_posedge_counter+1;
                    if(spi_posedge_counter>=8 && spi_posedge_counter<=(data_count+8) && !write_reg) begin
                        data_from_slave<={data_from_slave[14:0],miso};
                    end
                    else if(spi_posedge_counter>(data_count+8)) begin
                        done<=1;
                        //data_from_slave<=data_from_slave_reg;
                        start_clk<=0;
                        state<=CLK_TO_CS;
                    end
                end
                
                //change at negedge
                else if(neg_edge_spi)begin
                    spi_negedge_counter<=spi_negedge_counter+1;
                    if(spi_negedge_counter==0) begin 
                        mosi<=write_reg;
                    end
                    else if(spi_negedge_counter>0 && spi_negedge_counter<8) begin
                        mosi<=slave_addr_reg[6];
                        slave_addr_reg<=slave_addr_reg<<1;
                    end
                    else if (spi_negedge_counter>7 && spi_negedge_counter<=(data_count+8)) begin 
                        //mosi<=data_to_slave_reg[data_count];
                        //data_to_slave_reg<=data_to_slave_reg<<1;
                        if(write_reg) begin
                            mosi<=data_to_slave_reg[data_count];
                            data_to_slave_reg<=data_to_slave_reg<<1;
                        end
                        else begin
                            mosi<=0;   
                        end
                    end
                end
                end
            end
            
            
            TRANS_M1: begin //data sampled on negative edge and changed on positive edge
                if(cs) begin
                    err_reg3<=1;
                end
                else begin
                //read miso
                if(neg_edge_spi) begin
                    spi_negedge_counter<=spi_negedge_counter+1;
                    if(spi_negedge_counter>=8 && spi_negedge_counter<=(data_count+8)) begin
                        if(!write_reg) data_from_slave<={data_from_slave[14:0],miso};
                        if(spi_negedge_counter==(data_count+8)) begin
                            done<=1;
                            start_clk<=0;
                            state<=CLK_TO_CS;
                        end
                    end
                end
                
                //change at negedge
                else if(pos_edge_spi)begin
                    spi_posedge_counter<=spi_posedge_counter+1;
                    if(spi_posedge_counter==0) begin 
                        mosi<=write_reg;
                    end
                    else if(spi_posedge_counter>0 && spi_posedge_counter<8) begin
                        mosi<=slave_addr_reg[6];
                        slave_addr_reg<=slave_addr_reg<<1;
                    end
                    else if (spi_posedge_counter>7 && spi_posedge_counter<=(data_count+8)) begin 
                        //mosi<=data_to_slave_reg[data_count];
                        //data_to_slave_reg<=data_to_slave_reg<<1;
                        if(write_reg) begin
                            mosi<=data_to_slave_reg[data_count];
                            data_to_slave_reg<=data_to_slave_reg<<1;
                        end
                        else begin
                            mosi<=0;   
                        end
                    end
                end
                end
            end
            
            TRANS_M2: begin //data sampled on negative edge and changed on positive edge
                
                if(cs) begin
                    err_reg3<=1;
                end
                else begin
                //read miso
                if(neg_edge_spi) begin
                    spi_negedge_counter<=spi_negedge_counter+1;
                    if(spi_negedge_counter>9 && !write_reg) begin//////////////////////////////////
                        data_from_slave<={data_from_slave[14:0],miso};
                    end
                end
                
                //change at posedge
                else if(pos_edge_spi)begin
                    spi_posedge_counter<=spi_posedge_counter+1;
                    if(spi_posedge_counter==0) begin
                            mosi<=write_reg;
                    spi_negedge_counter<=spi_negedge_counter+1;
                    end
                    else if(spi_posedge_counter>0 && spi_posedge_counter<8) begin
                        mosi<=slave_addr_reg[6];
                        slave_addr_reg<=slave_addr_reg<<1;
                    end
                    else if (spi_posedge_counter>7 && spi_posedge_counter<=(data_count+8)) begin
                        if(write_reg) begin
                            mosi<=data_to_slave_reg[data_count];
                            data_to_slave_reg<=data_to_slave_reg<<1;
                        end
                        else begin
                            mosi<=0;   
                        end
                    end
                    else begin
                        done<=1;
                        //data_from_slave<=data_from_slave_reg;
                        start_clk<=0;
                        state<=CLK_TO_CS;
                    end
                end
                end
            end
     
     
            CLK_TO_CS:begin
                if(cs) begin
                    err_reg3<=1;
                end
                else begin
                done<=0;
                spi_posedge_counter<=0;
                spi_negedge_counter<=0;
                if(counter_delay==count_clk_to_cs_high) begin
                    state<=IDLE;
                    cs<=1;
                    counter_delay<=0;
                    busy<=0;
                end
                else begin
                    counter_delay<=counter_delay+1;
                end
                end
            end
            
        endcase
        end
        
        else begin
            state<= IDLE;
            start_clk<= 0;
            cs<= 1;
            busy<=0;
            done<=0;
            counter_delay<=0;
            spi_posedge_counter<=0;
            spi_negedge_counter<=0;
        end
    end
end



endmodule

