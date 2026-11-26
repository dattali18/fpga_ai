module compare_fifo(input clk, rst, wr_valid, rd_ready,
 input [7:0] wr_data, output ok, output observable_ok);
 reg armed = 1'b0;
 always @(posedge clk) armed <= 1'b1;
 wire reset = rst | !armed;
 wire aw, av, bw, bv;
 wire [7:0] ad, bd;
 wire [1:0] acount;
wire [1:0] arp, awp;
wire [7:0] aword0;
wire [7:0] aword1;
wire [7:0] aword2;
wire [1:0] bcount;
wire [1:0] brp, bwp;
wire [7:0] bword0;
wire [7:0] bword1;
wire [7:0] bword2;
 gold a(.clk(clk), .rst(reset), .wr_valid(wr_valid), .wr_ready(aw), .wr_data(wr_data), .rd_valid(av), .rd_ready(rd_ready), .rd_data(ad), .proof_count(acount), .proof_rd_ptr(arp), .proof_wr_ptr(awp), .proof_word_0(aword0), .proof_word_1(aword1), .proof_word_2(aword2));
gate b(.clk(clk), .rst(reset), .wr_valid(wr_valid), .wr_ready(bw), .wr_data(wr_data), .rd_valid(bv), .rd_ready(rd_ready), .rd_data(bd), .proof_count(bcount), .proof_rd_ptr(brp), .proof_wr_ptr(bwp), .proof_word_0(bword0), .proof_word_1(bword1), .proof_word_2(bword2));
 assign observable_ok = !armed || ((aw == bw) && (av == bv) && (!av || (ad == bd)));
 assign ok = !armed || (observable_ok && (acount <= 3 && acount == bcount && arp == brp && awp == bwp && arp < 3 && awp < 3 && (!(arp == 0 && acount == 0) || awp == 0) && (!(arp == 0 && acount == 1) || awp == 1) && (!(arp == 0 && acount == 2) || awp == 2) && (!(arp == 0 && acount == 3) || awp == 0) && (!(arp == 1 && acount == 0) || awp == 1) && (!(arp == 1 && acount == 1) || awp == 2) && (!(arp == 1 && acount == 2) || awp == 0) && (!(arp == 1 && acount == 3) || awp == 1) && (!(arp == 2 && acount == 0) || awp == 2) && (!(arp == 2 && acount == 1) || awp == 0) && (!(arp == 2 && acount == 2) || awp == 1) && (!(arp == 2 && acount == 3) || awp == 2) && (!((arp == 0 && acount > 0) || (arp == 1 && acount > 2) || (arp == 2 && acount > 1)) || aword0 == bword0) && (!((arp == 0 && acount > 1) || (arp == 1 && acount > 0) || (arp == 2 && acount > 2)) || aword1 == bword1) && (!((arp == 0 && acount > 2) || (arp == 1 && acount > 1) || (arp == 2 && acount > 0)) || aword2 == bword2)));
endmodule
