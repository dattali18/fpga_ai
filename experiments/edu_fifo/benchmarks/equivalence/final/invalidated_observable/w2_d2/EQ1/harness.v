module compare_fifo(input clk, rst, wr_valid, rd_ready,
 input [1:0] wr_data, output ok);
 reg armed = 1'b0;
 always @(posedge clk) armed <= 1'b1;
 wire reset = rst | !armed;
 wire aw, av, bw, bv;
 wire [1:0] ad, bd;
 gold a(.clk(clk), .rst(reset), .wr_valid(wr_valid), .wr_ready(aw), .wr_data(wr_data), .rd_valid(av), .rd_ready(rd_ready), .rd_data(ad));
 gate b(.clk(clk), .rst(reset), .wr_valid(wr_valid), .wr_ready(bw), .wr_data(wr_data), .rd_valid(bv), .rd_ready(rd_ready), .rd_data(bd));
 assign ok = !armed || ((aw == bw) && (av == bv) && (!av || (ad == bd)));
endmodule
