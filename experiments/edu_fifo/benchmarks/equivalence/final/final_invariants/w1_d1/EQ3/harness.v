module compare_fifo(input clk, rst, wr_valid, rd_ready,
 input [0:0] wr_data, output ok, output observable_ok);
 reg armed = 1'b0;
 always @(posedge clk) armed <= 1'b1;
 wire reset = rst | !armed;
 wire aw, av, bw, bv;
 wire [0:0] ad, bd;
 wire [0:0] acount;
wire [0:0] arp, awp;
wire [0:0] aword0;
wire [0:0] bcount;
wire [0:0] brp, bwp;
wire [0:0] bword0;
 gold a(.clk(clk), .rst(reset), .wr_valid(wr_valid), .wr_ready(aw), .wr_data(wr_data), .rd_valid(av), .rd_ready(rd_ready), .rd_data(ad), .proof_count(acount), .proof_rd_ptr(arp), .proof_wr_ptr(awp), .proof_word_0(aword0));
gate b(.clk(clk), .rst(reset), .wr_valid(wr_valid), .wr_ready(bw), .wr_data(wr_data), .rd_valid(bv), .rd_ready(rd_ready), .rd_data(bd), .proof_count(bcount), .proof_rd_ptr(brp), .proof_wr_ptr(bwp), .proof_word_0(bword0));
 assign observable_ok = !armed || ((aw == bw) && (av == bv) && (!av || (ad == bd)));
 assign ok = !armed || (observable_ok && (acount <= 1 && acount == bcount && arp == brp && awp == bwp && arp < 1 && awp < 1 && (!(arp == 0 && acount == 0) || awp == 0) && (!(arp == 0 && acount == 1) || awp == 0) && (!((arp == 0 && acount > 0)) || aword0 == bword0)));
endmodule
