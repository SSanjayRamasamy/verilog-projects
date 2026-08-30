module top(input clk,rst,async_in,output dot,output [6:0]seg,output [3:0]seg_en);
wire [13:0]freq;
wire [15:0]digits;
frequency_counter fc (.clk(clk),.rst(rst),.async_in(async_in),.freq(freq));
digit_spliter ds (.freq(freq),.digits(digits));
seven_seg ss (.clk(clk),.rst(rst),.digits(digits),.dot(dot),.seg(seg),.seg_en(seg_en));
endmodule
