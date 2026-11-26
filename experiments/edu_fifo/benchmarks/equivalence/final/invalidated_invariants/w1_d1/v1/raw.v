module edu_fifo
  (input  clk,
   input  rst,
   input  wr_valid,
   input  wr_data,
   input  rd_ready,
   output wr_ready,
   output rd_valid,
   output rd_data);
  wire mem;
  reg count;
  wire rd_valid_i;
  wire wr_ready_i;
  wire pop;
  wire push;
  wire n7_o;
  wire [31:0] n8_o;
  wire n10_o;
  wire n11_o;
  wire n12_o;
  wire n15_o;
  wire [31:0] n16_o;
  wire n18_o;
  wire n19_o;
  wire n20_o;
  wire n21_o;
  wire n22_o;
  wire n24_o;
  wire n25_o;
  wire n38_o;
  wire n39_o;
  wire [31:0] n40_o;
  wire [31:0] n42_o;
  wire n43_o;
  wire n44_o;
  wire n45_o;
  wire [31:0] n46_o;
  wire [31:0] n48_o;
  wire n49_o;
  wire n50_o;
  wire n51_o;
  wire n53_o;
  wire n56_o;
  reg n57_q;
  reg n58_q;
  assign wr_ready = wr_ready_i;
  assign rd_valid = rd_valid_i;
  assign rd_data = mem;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:59:10  */
  assign mem = n57_q; // (signal)
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:62:10  */
  always @*
    count = n58_q; // (isignal)
  initial
    count = 1'b0;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:64:10  */
  assign rd_valid_i = n12_o; // (signal)
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:65:10  */
  assign wr_ready_i = n22_o; // (signal)
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:66:10  */
  assign pop = n24_o; // (signal)
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:67:10  */
  assign push = n25_o; // (signal)
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:72:30  */
  assign n7_o = ~rst;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:72:46  */
  assign n8_o = {31'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:72:46  */
  assign n10_o = n8_o != 32'b00000000000000000000000000000000;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:72:36  */
  assign n11_o = n10_o & n7_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:72:21  */
  assign n12_o = n11_o ? 1'b1 : 1'b0;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:73:30  */
  assign n15_o = ~rst;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:74:33  */
  assign n16_o = {31'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:74:33  */
  assign n18_o = n16_o != 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:74:65  */
  assign n19_o = rd_ready & rd_valid_i;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:74:44  */
  assign n20_o = n18_o | n19_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:73:36  */
  assign n21_o = n20_o & n15_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:73:21  */
  assign n22_o = n21_o ? 1'b1 : 1'b0;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:77:22  */
  assign n24_o = rd_valid_i & rd_ready;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:78:20  */
  assign n25_o = wr_valid & wr_ready_i;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:119:31  */
  assign n38_o = ~pop;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:119:23  */
  assign n39_o = n38_o & push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:120:26  */
  assign n40_o = {31'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:120:26  */
  assign n42_o = n40_o + 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:120:20  */
  assign n43_o = n42_o[0];  // trunc
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:121:34  */
  assign n44_o = ~push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:121:25  */
  assign n45_o = n44_o & pop;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:122:26  */
  assign n46_o = {31'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:122:26  */
  assign n48_o = n46_o - 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:122:20  */
  assign n49_o = n48_o[0];  // trunc
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:121:9  */
  assign n50_o = n45_o ? n49_o : count;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:119:9  */
  assign n51_o = n39_o ? n43_o : n50_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:108:7  */
  assign n53_o = rst ? 1'b0 : n51_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:97:5  */
  assign n56_o = push ? wr_data : mem;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:97:5  */
  always @(posedge clk)
    n57_q <= n56_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:107:5  */
  always @(posedge clk)
    n58_q <= n53_o;
  initial
    n58_q = 1'b0;
endmodule

