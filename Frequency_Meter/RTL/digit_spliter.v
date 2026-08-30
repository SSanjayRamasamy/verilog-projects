`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.04.2026 18:08:46
// Design Name: 
// Module Name: digit_spliter
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


module digit_spliter(input [13:0]freq,output [15:0]digits);
assign digits[3:0]=freq%10;
assign digits[7:4]=(freq/10)%10;
assign digits[11:8]=(freq/100)%10;
assign digits[15:12]=(freq/1000)%10;
endmodule