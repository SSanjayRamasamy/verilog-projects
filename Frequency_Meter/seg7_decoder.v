module seg7_decoder(input [3:0]digit,output reg [6:0]seg);
always@(*) begin
    case(digit)
        'd0:seg=7'b0000001;//abcdefg
        'd1:seg=7'b1001111;
        'd2:seg=7'b0010010;
        'd3:seg=7'b0000110;
        'd4:seg=7'b1001100;
        'd5:seg=7'b0100100;
        'd6:seg=7'b0100001;
        'd7:seg=7'b0001111;
        'd8:seg=7'b0000000;
        'd9:seg=7'b0000100;
    endcase
end
endmodule
