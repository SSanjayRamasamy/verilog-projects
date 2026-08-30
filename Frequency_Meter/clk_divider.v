`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.04.2026 18:09:25
// Design Name: 
// Module Name: clk_divider
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


module clk_divider #(parameter clk_freq=50000000, req_freq=10000)(input clk,rst,output reg clk_out);
localparam clk_div=((clk_freq/req_freq)/2)-1;

reg [$clog2(clk_div)+1:0]counter;

always@(posedge clk or negedge rst) begin
    if (!rst)begin
        counter<=0;
        clk_out<=0;
    end
    else begin
        if(counter==clk_div)begin
            counter<=0;
            clk_out<=~clk_out;
        end
        else if(counter!=clk_div)begin
            counter<=counter+1;
        end
    end
    
end
endmodule

