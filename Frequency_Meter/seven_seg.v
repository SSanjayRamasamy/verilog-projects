module seven_seg #(parameter segments=4)(input clk,rst,input [15:0]digits,output dot,output [6:0]seg,output reg [3:0]seg_en);
wire clk_out;
reg [3:0]digit;
reg [$clog2(segments)+1:0] counter;
assign dot=1'b1;
clk_divider c (.clk(clk),.rst(rst),.clk_out(clk_out));
seg7_decoder s (.digit(digit),.seg(seg));

always@(posedge clk_out or negedge rst) begin
    if (!rst) begin
        counter<=0;
    end
    else begin
        if (counter==segments-1) begin
            counter<=0;
        end
        else begin
            counter<=counter+1;
        end
    end
end

always@(counter) begin
    case(counter)
        'd0: begin
            seg_en=4'b0001;
            digit=digits[3:0];
        end
        'd1: begin
            seg_en=4'b0010;
            digit=digits[7:4];
        end
        'd2: begin
            seg_en=4'b0100;
            digit=digits[11:8];
        end
        'd3: begin
            seg_en=4'b1000;
            digit=digits[15:12];
        end
    endcase
end
endmodule
