module t(input [3:0] a, output [3:0] y);
  assign y = 1'bZ ? 4'b1010 : a;
endmodule
