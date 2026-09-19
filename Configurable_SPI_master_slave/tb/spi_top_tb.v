`timescale 1ns / 1ps
module spi_top_tb();



localparam clk_frequency=50000000, cs_high_ns=220, cs_negedge_to_clk_edge_ns=500, clk_edge_to_cs_high_ns=220;
reg [50:0] total_testcase;
reg [50:0] pass, fail, error;
integer logfile;
reg clk; 
reg rst; 
reg start;
wire miso;
reg bit_width;
reg [1:0] spi_mode;
reg [25:0] s_clk_freq;
reg [15:0] data_to_slave_master;
reg write_master;
reg [6:0] slave_addr;
wire cs;
wire mosi;
wire busy_master;
wire done_master; 
wire[2:0] err_e;
wire sclk;
wire [15:0] data_from_slave_master;
wire done_slave;
integer i,j,k,l,m,n;
reg [25:0] clk_freq_mem [0:4];
reg [15:0] data_16_bit_mem [0:4];
reg [7:0] data_8_bit_mem [0:4];

spi_master #(clk_frequency, cs_high_ns, cs_negedge_to_clk_edge_ns, clk_edge_to_cs_high_ns) master (
        clk, rst, start, miso, bit_width,spi_mode,
        s_clk_freq,
        data_to_slave_master,
        write_master,
        slave_addr,
        cs, mosi, busy_master, done_master, 
        err_e, 
        sclk,
        data_from_slave_master
        );

spi_slave slave (clk, rst, sclk, mosi, cs, bit_width,spi_mode,miso, done_slave);



task input_vector_continuous (inout [50:0] pass,fail,error,input write_to_slave,input [1:0] spiMode,input data_size, input [25:0] spi_clk_freq, input [15:0] data_to_slave, input [6:0]slave_address);

     begin
        wait(!busy_master)
        start=1;
        bit_width=data_size;
        spi_mode=spiMode;
        s_clk_freq=spi_clk_freq;
        data_to_slave_master=data_to_slave;
        write_master=write_to_slave;
        slave_addr=slave_address;
        @(posedge clk);
        wait (done_master && done_slave|| err_e!=0);
        if(err_e!=0) begin
            error=error+1;
            if(err_e==1) begin
                $display(" ERROR: Timed out");
                $fdisplay(logfile," ERROR: Timed out");
            end
            else if(err_e==2) begin
                $display(" ERROR: Invalid Slave Address (%h)",slave_addr);
                $fdisplay(logfile," ERROR: Invalid Slave Address (%h)",slave_addr);
            end
            else if(err_e==3) begin
                $display(" ERROR: Chip Select asserted high before completion of transaction");
                $fdisplay(logfile," ERROR: Chip Select asserted high before completion of transaction");
            end
            else if(err_e==4) begin
                $display(" ERROR: Writing a read only register (Device ID)");
                $fdisplay(logfile," ERROR: Writing a read only register (Device ID)");
            end
            else if(err_e==5) begin
                $display(" ERROR: Inalid SPI Clock frequency (0Hz)");
                $fdisplay( logfile," ERROR: Inalid SPI Clock frequency (0Hz)");
            end
            @(posedge clk)
            @(posedge clk);
        end
        else begin
            
            
            
            @(posedge clk)
            @(posedge clk)
            if(write_master) begin
                $display("Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Write \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register     ":"Control Register"):(slave_address[1]?"Status Register   ":"Device ID           "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:0))==data_to_slave)?"Pass":"Fail");
                $fdisplay( logfile,"Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Write \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register     ":"Control Register"):(slave_address[1]?"Status Register   ":"Device ID           "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:0))==data_to_slave)?"Pass":"Fail");
                pass=((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:0))==data_to_slave)?pass+1:pass+0;
                fail=((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:0))==data_to_slave)?fail+0:fail+1;
            end
            else if(!write_master) begin
                //$display("%h,%h",data_from_slave_master,slave.device_id);
                if(data_size) begin
                    $display("Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register      ":"Control Register"):(slave_address[1]?"Status Register    ":"Device ID         "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:slave.device_id))==data_from_slave_master)?"Pass":"Fail");
                    $fdisplay( logfile,"Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register      ":"Control Register"):(slave_address[1]?"Status Register    ":"Device ID         "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:slave.device_id))==data_from_slave_master)?"Pass":"Fail");
                    pass=((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:slave.device_id))==data_from_slave_master)?pass+1:pass+0;
                    fail=((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:slave.device_id))==data_from_slave_master)?fail+0:fail+1;
                end
                else begin
                    $display("Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register      ":"Control Register"):(slave_address[1]?"Status Register    ":"Device ID         "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_address[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==data_from_slave_master)?"Pass":"Fail");
                    $fdisplay( logfile,"Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register      ":"Control Register"):(slave_address[1]?"Status Register    ":"Device ID         "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_address[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==data_from_slave_master)?"Pass":"Fail");
                    pass=((slave_address[0]?(slave_address[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_address[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==data_from_slave_master)?pass+1:pass+0;
                    fail=((slave_address[0]?(slave_address[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_address[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==data_from_slave_master)?fail+0:fail+1;
                end
            end
        end
    end
endtask


task input_vector (inout [50:0] pass,fail,error,input write_to_slave,input [1:0] spiMode,input data_size, input [25:0] spi_clk_freq, input [15:0] data_to_slave, input [6:0]slave_address);

     begin
        wait(!busy_master)
        start=1;
        bit_width=data_size;
        spi_mode=spiMode;
        s_clk_freq=spi_clk_freq;
        data_to_slave_master=data_to_slave;
        write_master=write_to_slave;
        slave_addr=slave_address;
        @(posedge clk);
        wait(busy_master || err_e!=0);
        start=0;
        wait (done_master && done_slave|| err_e!=0);
        if(err_e!=0) begin
            error=error+1;
            if(err_e==1) begin
                $display(" ERROR: Timed out");
                $fdisplay( logfile," ERROR: Timed out");
            end
            else if(err_e==2) begin
                $display(" ERROR: Invalid Slave Address (%h)",slave_addr);
                $fdisplay( logfile," ERROR: Invalid Slave Address (%h)",slave_addr);
            end
            else if(err_e==3) begin
                $display(" ERROR: Chip Select asserted high before completion of transaction");
                $fdisplay( logfile," ERROR: Chip Select asserted high before completion of transaction");
            end
            else if(err_e==4) begin
                $display(" ERROR: Writing a read only register (Device ID)");
                $fdisplay( logfile," ERROR: Writing a read only register (Device ID)");
            end
            else if(err_e==5) begin
                $display(" ERROR: Inalid SPI Clock frequency (0Hz)");
                $fdisplay( logfile," ERROR: Inalid SPI Clock frequency (0Hz)");
            end
            @(posedge clk)
            @(posedge clk);
        end
        else begin
            @(posedge clk)
            @(posedge clk)
            if(write_master) begin
                $display("Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Write \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register     ":"Control Register"):(slave_address[1]?"Status Register   ":"Device ID           "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:0))==data_to_slave)?"Pass":"Fail");
                $fdisplay( logfile,"Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Write \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register     ":"Control Register"):(slave_address[1]?"Status Register   ":"Device ID           "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:0))==data_to_slave)?"Pass":"Fail");
                pass=((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:0))==data_to_slave)?pass+1:pass+0;
                fail=((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:0))==data_to_slave)?fail+0:fail+1;
            end
            else if(!write_master) begin
                //$display("%h,%h",data_from_slave_master,slave.device_id);
                if(data_size)begin
                    //$display("%h   :   %h",data_from_slave_master, slave.control_reg);
                    $display("Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register      ":"Control Register"):(slave_address[1]?"Status Register    ":"Device ID         "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:slave.device_id))==data_from_slave_master)?"Pass":"Fail");
                    $fdisplay( logfile,"Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register      ":"Control Register"):(slave_address[1]?"Status Register    ":"Device ID         "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:slave.device_id))==data_from_slave_master)?"Pass":"Fail");
                    pass=((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:slave.device_id))==data_from_slave_master)?pass+1:pass+0;
                    fail=((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:slave.device_id))==data_from_slave_master)?fail+0:fail+1;
                end
                else begin
                    //$display("%h   :   %h",data_from_slave_master, slave.control_reg);
                    $display("Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register      ":"Control Register"):(slave_address[1]?"Status Register    ":"Device ID         "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_address[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==data_from_slave_master)?"Pass":"Fail");
                    $fdisplay( logfile,"Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register      ":"Control Register"):(slave_address[1]?"Status Register    ":"Device ID         "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_address[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==data_from_slave_master)?"Pass":"Fail");
                    pass=((slave_address[0]?(slave_address[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_address[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==data_from_slave_master)?pass+1:pass+0;
                    fail=((slave_address[0]?(slave_address[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_address[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==data_from_slave_master)?fail+0:fail+1;
                end
            end
            
        end
    end
endtask


task input_vector_random (inout [50:0] pass,fail,error);

     begin
        wait(!busy_master)
        start=1;
        bit_width=$random;
        spi_mode=$random;
        s_clk_freq=$random;
        data_to_slave_master=$random;
        write_master=$random;
        slave_addr=$random;
        wait(busy_master || err_e!=0);
        start=0;
        wait (done_master && done_slave|| err_e!=0);
        if(err_e!=0) begin
            error=error+1;
            if(err_e==1) begin
                $display(" ERROR: Timed out");
                $fdisplay( logfile," ERROR: Timed out");
            end
            else if(err_e==2) begin
                $display(" ERROR: Invalid Slave Address (%h)",slave_addr);
                $fdisplay( logfile," ERROR: Invalid Slave Address (%h)",slave_addr);
            end
            else if(err_e==3) begin
                $display(" ERROR: Chip Select asserted high before completion of transaction");
                $fdisplay( logfile," ERROR: Chip Select asserted high before completion of transaction");
            end
            else if(err_e==4) begin
                $display(" ERROR: Writing a read only register (Device ID)");
                $fdisplay( logfile," ERROR: Writing a read only register (Device ID)");
            end
            else if(err_e==5) begin
                $display(" ERROR: Inalid SPI Clock frequency (0Hz)");
                $fdisplay( logfile," ERROR: Inalid SPI Clock frequency (0Hz)");
            end
            @(posedge clk)
            @(posedge clk);
        end
        else begin
            @(posedge clk)
            @(posedge clk)
            if(write_master) begin
                $display("Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Write \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spi_mode, bit_width?'d16:'d8, slave_addr, slave_addr[0]?(slave_addr[1]?"Data Register     ":"Control Register"):(slave_addr[1]?"Status Register   ":"Device ID           "),data_to_slave_master,((slave_addr[0]?(slave_addr[1]?slave.data_reg:slave.control_reg):(slave_addr[1]?slave.status_reg:0))==data_to_slave_master)?"Pass":"Fail");
                $fdisplay( logfile,"Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Write \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spi_mode, bit_width?'d16:'d8, slave_addr, slave_addr[0]?(slave_addr[1]?"Data Register     ":"Control Register"):(slave_addr[1]?"Status Register   ":"Device ID           "),data_to_slave_master,((slave_addr[0]?(slave_addr[1]?slave.data_reg:slave.control_reg):(slave_addr[1]?slave.status_reg:0))==data_to_slave_master)?"Pass":"Fail");
                pass=((slave_addr[0]?(slave_addr[1]?slave.data_reg:slave.control_reg):(slave_addr[1]?slave.status_reg:0))==data_to_slave_master)?pass+1:pass+0;
                fail=((slave_addr[0]?(slave_addr[1]?slave.data_reg:slave.control_reg):(slave_addr[1]?slave.status_reg:0))==data_to_slave_master)?fail+0:fail+1;
            end
            else if(!write_master) begin
                //$display("%h,%h",data_from_slave_master,slave.device_id);
                if(bit_width) begin
                    $display("Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spi_mode, bit_width?'d16:'d8, slave_addr, slave_addr[0]?(slave_addr[1]?"Data Register      ":"Control Register"):(slave_addr[1]?"Status Register    ":"Device ID         "),data_to_slave_master,((slave_addr[0]?(slave_addr[1]?slave.data_reg:slave.control_reg):(slave_addr[1]?slave.status_reg:slave.device_id))==data_from_slave_master)?"Pass":"Fail");
                    $fdisplay( logfile,"Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spi_mode, bit_width?'d16:'d8, slave_addr, slave_addr[0]?(slave_addr[1]?"Data Register      ":"Control Register"):(slave_addr[1]?"Status Register    ":"Device ID         "),data_to_slave_master,((slave_addr[0]?(slave_addr[1]?slave.data_reg:slave.control_reg):(slave_addr[1]?slave.status_reg:slave.device_id))==data_from_slave_master)?"Pass":"Fail");
                    pass=((slave_addr[0]?(slave_addr[1]?slave.data_reg:slave.control_reg):(slave_addr[1]?slave.status_reg:slave.device_id))==data_from_slave_master)?pass+1:pass+0;
                    fail=((slave_addr[0]?(slave_addr[1]?slave.data_reg:slave.control_reg):(slave_addr[1]?slave.status_reg:slave.device_id))==data_from_slave_master)?fail+0:fail+1;
                end
                else begin 
                    $display("Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spi_mode, bit_width?'d16:'d8, slave_addr, slave_addr[0]?(slave_addr[1]?"Data Register      ":"Control Register"):(slave_addr[1]?"Status Register    ":"Device ID         "),data_to_slave_master,((slave_addr[0]?(slave_addr[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_addr[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==data_from_slave_master)?"Pass":"Fail");
                    $fdisplay( logfile,"Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spi_mode, bit_width?'d16:'d8, slave_addr, slave_addr[0]?(slave_addr[1]?"Data Register      ":"Control Register"):(slave_addr[1]?"Status Register    ":"Device ID         "),data_to_slave_master,((slave_addr[0]?(slave_addr[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_addr[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==data_from_slave_master)?"Pass":"Fail");
                    pass=((slave_addr[0]?(slave_addr[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_addr[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==data_from_slave_master)?pass+1:pass+0;
                    fail=((slave_addr[0]?(slave_addr[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_addr[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==data_from_slave_master)?fail+0:fail+1;
                end       
            end
        end
    end
endtask

task input_vector_with_reset (inout [50:0] pass,fail,error,input write_to_slave,input [1:0] spiMode,input data_size, input [25:0] spi_clk_freq, input [15:0] data_to_slave, input [6:0]slave_address);

     begin
        wait(!busy_master && rst)
        start=1;
        bit_width=data_size;
        spi_mode=spiMode;
        s_clk_freq=spi_clk_freq;
        data_to_slave_master=data_to_slave;
        write_master=write_to_slave;
        slave_addr=slave_address;
        @(posedge clk)
        @(posedge clk)
        start=0;
        if(err_e!=0) begin
            error=error+1;
            if(err_e==1) begin
                $display(" ERROR: Timed out");
                $fdisplay( logfile," ERROR: Timed out");
            end
            else if(err_e==2) begin
                $display(" ERROR: Invalid Slave Address (%h)",slave_addr);
                $fdisplay( logfile," ERROR: Invalid Slave Address (%h)",slave_addr);
            end
            else if(err_e==3) begin
                $display(" ERROR: Chip Select asserted high before completion of transaction");
                $fdisplay( logfile," ERROR: Chip Select asserted high before completion of transaction");
            end
            else if(err_e==4) begin
                $display(" ERROR: Writing a read only register (Device ID)");
                $fdisplay( logfile," ERROR: Writing a read only register (Device ID)");
            end
            else if(err_e==5) begin
                $display(" ERROR: Inalid SPI Clock frequency (0Hz)");
                $fdisplay( logfile," ERROR: Inalid SPI Clock frequency (0Hz)");
            end
        end 
        else begin
            //@(posedge clk)
            //@(posedge clk)
            @(posedge clk)
            rst=0;
            wait(!rst);
            if(write_master) begin
                $display("Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Write \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register     ":"Control Register"):(slave_address[1]?"Status Register   ":"Device ID           "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:0))==0)?"Pass":"Fail");
                $fdisplay( logfile,"Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Write \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register     ":"Control Register"):(slave_address[1]?"Status Register   ":"Device ID           "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:0))==0)?"Pass":"Fail");
                pass=((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:0))==0)?pass+1:pass+0;
                fail=((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:0))==0)?fail+0:fail+1;
            end
            else if(!write_master) begin
                //$display("%h,%h",data_from_slave_master,slave.device_id);
                if(data_size) begin 
                    $display("Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register      ":"Control Register"):(slave_address[1]?"Status Register    ":"Device ID         "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:slave.device_id))==(slave_addr?0:'hABCD))?"Pass":"Fail");
                    $fdisplay( logfile,"Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register      ":"Control Register"):(slave_address[1]?"Status Register    ":"Device ID         "),data_to_slave,((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:slave.device_id))==(slave_addr?0:'hABCD))?"Pass":"Fail");
                    pass=((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:slave.device_id))==(slave_addr?0:'hABCD))?pass+1:pass+0;
                    fail=((slave_address[0]?(slave_address[1]?slave.data_reg:slave.control_reg):(slave_address[1]?slave.status_reg:slave.device_id))==(slave_addr?0:'hABCD))?fail+0:fail+1;
                end
                else begin
                    $display("Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register      ":"Control Register"):(slave_address[1]?"Status Register    ":"Device ID         "),data_to_slave,((slave_addr[0]?(slave_addr[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_addr[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==(slave_addr?0:'hCD))?"Pass":"Fail");
                    $fdisplay( logfile,"Time=%0t \t\t SPI_clock_frequency=%0dHz \t\t SPI_MODE=%d \t\t Operation=Read  \t\t Data_Size=%0d bits \t\t Slave_address=0x%h \t\t Selected_Register=%0s \t\t  Data_to_Write=0x%0h \t\t Status=%s", $time, s_clk_freq, spiMode, data_size?'d16:'d8, slave_address, slave_address[0]?(slave_address[1]?"Data Register      ":"Control Register"):(slave_address[1]?"Status Register    ":"Device ID         "),data_to_slave,((slave_addr[0]?(slave_addr[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_addr[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==(slave_addr?0:'hCD))?"Pass":"Fail");
                    pass=((slave_addr[0]?(slave_addr[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_addr[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==(slave_addr?0:'hCD))?pass+1:pass+0;
                    fail=((slave_addr[0]?(slave_addr[1]?slave.data_reg[7:0]:slave.control_reg[7:0]):(slave_addr[1]?slave.status_reg[7:0]:slave.device_id[7:0]))==(slave_addr?0:'hCD))?fail+0:fail+1;
                end
            end
        end
        
        @(posedge clk)
        //@(posedge clk);
        rst=1;
    end
endtask


initial begin
    logfile = $fopen("simulation.log", "w");
    $display("----------------------------------------------------------------------------------------------------------");
    $fdisplay(logfile, "--------------------------------------------------------------------------------------------------------------");
    $display("Simulation Started");
    $fdisplay(logfile, "Simulation Started");
    $display("----------------------------------------------------------------------------------------------------------");
    $fdisplay(logfile, "--------------------------------------------------------------------------------------------------------------");
    $timeformat(-9, 3, " ns", 0);
    total_testcase=0;
    pass=0;
    fail=0;
    error=0;
    clk_freq_mem[0]='d0; //corner case
    clk_freq_mem[1]='d3000; //3khz 
    clk_freq_mem[2]='d1_000_000; //1Mhz
    clk_freq_mem[3]={26{1'b1}}; //corner case
    clk_freq_mem[4]='d67823; // very odd number
    
    data_16_bit_mem[0]=16'h0;   //corner case
    data_16_bit_mem[1]=16'h5555;	// even 1's
    data_16_bit_mem[2]=16'haaaa;	// odd 1's
    data_16_bit_mem[3]=16'h3478;    // different digit	
    data_16_bit_mem[4]=16'hffff;	//corner case
    
    data_8_bit_mem[0]=8'h0; //corner case
    data_8_bit_mem[1]=8'h55;	// even 1's;	
    data_8_bit_mem[2]=8'haa;	//odd 1's
    data_8_bit_mem[3]=8'hbe;	//different digit
    data_8_bit_mem[4]=8'hff;   // corner case
    
    
    clk=0;
    rst=0;
    #100;
    rst=1;
    
    //normal transaction
    $display("----------------------------------------------------------------------------------------------------------");
    $fdisplay(logfile, "--------------------------------------------------------------------------------------------------------------");
    $display("Normal Transaction");
    $fdisplay( logfile,"Normal Transaction");
    $display("----------------------------------------------------------------------------------------------------------");
    $fdisplay(logfile, "--------------------------------------------------------------------------------------------------------------");
   for(l=0;l<5;l=l+1) begin//clk_freq
        for(j=0;j<2;j=j+1) begin //bit_width        
            for(k=0;k<6;k=k+1)begin //register address    
                for(i=0;i<4;i=i+1) begin //mode    
                    for (m=1;m>=0;m=m-1) begin//read write
                        for(n=0;n<5;n=n+1) begin //data
                        //$display("l=%d j=%d k=%d i=%d m=%d n=%d",l,j,k,i,m,n);
                            total_testcase=total_testcase+1;
                            if(j==0) begin
                                input_vector (pass,fail,error,m,i,j,clk_freq_mem[l],data_8_bit_mem[n],k); // read/write, spimode, datasize, clk_freq, data_toslave, slave address
                            end
                            else begin
                                input_vector (pass,fail,error,m,i,j,clk_freq_mem[l],data_16_bit_mem[n],k);
                            end
                        end
                    end
                end
            end
        end
    end
    
    
    //continuous transaction
    $display("----------------------------------------------------------------------------------------------------------");
    $fdisplay(logfile, "--------------------------------------------------------------------------------------------------------------");
    $display("continuous transaction ++++ start=1 while transaction");
    $fdisplay( logfile,"continuous transaction ++++ start=1 while transaction");
    $display("----------------------------------------------------------------------------------------------------------");
    $fdisplay(logfile, "--------------------------------------------------------------------------------------------------------------");
    for(l=0;l<5;l=l+1) begin//clk_freq
        for(j=0;j<2;j=j+1) begin //bit_width        
            for(k=0;k<6;k=k+1)begin //register address    
                for(i=0;i<4;i=i+1) begin //mode    
                    for (m=1;m>=0;m=m-1) begin//read write
                        for(n=0;n<5;n=n+1) begin //data
                        //$display("l=%d j=%d k=%d i=%d m=%d n=%d",l,j,k,i,m,n);
                            total_testcase=total_testcase+1;
                            if(j==0) begin
                                input_vector_continuous (pass,fail,error,m,i,j,clk_freq_mem[l],data_8_bit_mem[n],k); // read/write, spimode, datasize, clk_freq, data_toslave, slave address
                            end
                            else begin
                                input_vector_continuous (pass,fail,error,m,i,j,clk_freq_mem[l],data_16_bit_mem[n],k);
                            end
                        end
                    end
                end
            end
        end
    end
    
    #100;
    start=0;
    
    //random inputs
    $display("----------------------------------------------------------------------------------------------------------");
    $fdisplay(logfile, "--------------------------------------------------------------------------------------------------------------");
    $display("Random inputs conditions");
    $fdisplay( logfile,"Random inputs conditions");
    $display("----------------------------------------------------------------------------------------------------------");
    $fdisplay(logfile, "--------------------------------------------------------------------------------------------------------------");
    for(i=0;i<20;i=i+1) begin
        total_testcase=total_testcase+1;
        input_vector_random(pass,fail,error);
        
    end
    
    
    //transaction with reset
    $display("----------------------------------------------------------------------------------------------------------");
    $fdisplay(logfile, "--------------------------------------------------------------------------------------------------------------");
    $display("Transaction with reset before completion of transfer");
    $fdisplay( logfile,"Transaction with reset before completion of transfer");
    $display("----------------------------------------------------------------------------------------------------------");
    $fdisplay(logfile, "--------------------------------------------------------------------------------------------------------------");
        for(l=0;l<5;l=l+1) begin//clk_freq
        for(j=0;j<2;j=j+1) begin //bit_width        
            for(k=0;k<6;k=k+1)begin //register address    
                for(i=0;i<4;i=i+1) begin //mode    
                    for (m=1;m>=0;m=m-1) begin//read write
                        for(n=0;n<5;n=n+1) begin //data
                            //$display("l=%d j=%d k=%d i=%d m=%d n=%d",l,j,k,i,m,n);
                            total_testcase=total_testcase+1;
                            if(j==0) begin
                                input_vector_with_reset (pass,fail,error,m,i,j,clk_freq_mem[l],data_8_bit_mem[n],k); // read/write, spimode, datasize, clk_freq, data_toslave, slave address
                            end
                            else begin
                                input_vector_with_reset (pass,fail,error,m,i,j,clk_freq_mem[l],data_16_bit_mem[n],k);
                            end
                        end
                    end
                end
            end
        end
    end
    $display("----------------------------------------------------------------------------------------------------------");
    $fdisplay(logfile, "--------------------------------------------------------------------------------------------------------------");
    $display("Simulation Finished");
    $fdisplay(logfile, "Simulation Finished");
    $display("----------------------------------------------------------------------------------------------------------");
    $fdisplay(logfile, "--------------------------------------------------------------------------------------------------------------");
    $display("PASS COUNT \t\t\t: \t\t %d",pass);
    $display("FAIL COUNT \t\t\t: \t\t %d",fail);
    $display("ERROR COUNT \t\t: \t\t %d",error);
    $display("TOTAL COUNT \t\t: \t\t %d",total_testcase);
    $fdisplay(logfile,"PASS COUNT \t\t    : \t\t %d",pass);
    $fdisplay(logfile,"FAIL COUNT \t\t    : \t\t %d",fail);
    $fdisplay(logfile,"ERROR COUNT \t\t: \t\t %d",error);
    $fdisplay(logfile,"TOTAL COUNT \t\t: \t\t %d",total_testcase);
    $fdisplay(logfile, "--------------------------------------------------------------------------------------------------------------");
    $fdisplay(logfile, "--------------------------------------------------------------------------------------------------------------");
    
    $fclose(logfile);
    $finish;
end

always #10 clk=~clk;

endmodule
