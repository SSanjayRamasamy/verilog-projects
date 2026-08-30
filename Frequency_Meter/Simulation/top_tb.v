`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.04.2026 18:24:02
// Design Name: 
// Module Name: top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_tb();
reg clk,rst,async_in;
wire dot;
wire [6:0] seg;
wire [3:0] seg_en;
top UUT (.clk(clk),.rst(rst),.async_in(async_in),.dot(dot),.seg(seg),.seg_en(seg_en));
initial begin
clk=0;
#4;
async_in=0;
end

initial begin
rst=0;
#5;
rst=1;
end

always #10 clk=~clk;
always #500000 async_in=~async_in;

endmodule

