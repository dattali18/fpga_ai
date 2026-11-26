module edu_fifo
  (input  clk,
   input  rst,
   input  wr_valid,
   input  wr_data,
   input  rd_ready,
   output wr_ready,
   output rd_valid,
   output rd_data);
  reg count;
  wire rd_valid_i;
  wire wr_ready_i;
  wire pop;
  wire push;
  wire n5_o;
  wire [31:0] n6_o;
  wire n8_o;
  wire n9_o;
  wire n10_o;
  wire n13_o;
  wire [31:0] n14_o;
  wire n16_o;
  wire n17_o;
  wire n18_o;
  wire n19_o;
  wire n20_o;
  wire n22_o;
  wire n23_o;
  wire n26_o;
  wire n27_o;
  wire [31:0] n28_o;
  wire [31:0] n30_o;
  wire n31_o;
  wire n32_o;
  wire n33_o;
  wire [31:0] n34_o;
  wire [31:0] n36_o;
  wire n37_o;
  wire n38_o;
  wire n39_o;
  wire n41_o;
  wire g_d1_head;
  wire n49_o;
  reg n50_q;
  reg n51_q;
  assign wr_ready = wr_ready_i;
  assign rd_valid = rd_valid_i;
  assign rd_data = g_d1_head;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:58:10  */
  always @*
    count = n51_q; // (isignal)
  initial
    count = 1'b0;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:59:10  */
  assign rd_valid_i = n10_o; // (signal)
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:60:10  */
  assign wr_ready_i = n20_o; // (signal)
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:61:10  */
  assign pop = n22_o; // (signal)
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:62:10  */
  assign push = n23_o; // (signal)
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:68:30  */
  assign n5_o = ~rst;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:68:46  */
  assign n6_o = {31'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:68:46  */
  assign n8_o = n6_o != 32'b00000000000000000000000000000000;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:68:36  */
  assign n9_o = n8_o & n5_o;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:68:21  */
  assign n10_o = n9_o ? 1'b1 : 1'b0;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:69:30  */
  assign n13_o = ~rst;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:70:33  */
  assign n14_o = {31'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:70:33  */
  assign n16_o = n14_o != 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:70:65  */
  assign n17_o = rd_ready & rd_valid_i;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:70:44  */
  assign n18_o = n16_o | n17_o;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:69:36  */
  assign n19_o = n18_o & n13_o;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:69:21  */
  assign n20_o = n19_o ? 1'b1 : 1'b0;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:73:22  */
  assign n22_o = rd_valid_i & rd_ready;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:74:20  */
  assign n23_o = wr_valid & wr_ready_i;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:84:32  */
  assign n26_o = ~pop;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:84:24  */
  assign n27_o = n26_o & push;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:85:24  */
  assign n28_o = {31'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:85:24  */
  assign n30_o = n28_o + 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:85:18  */
  assign n31_o = n30_o[0];  // trunc
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:86:32  */
  assign n32_o = ~push;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:86:23  */
  assign n33_o = n32_o & pop;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:87:24  */
  assign n34_o = {31'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:87:24  */
  assign n36_o = n34_o - 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:87:18  */
  assign n37_o = n36_o[0];  // trunc
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:86:7  */
  assign n38_o = n33_o ? n37_o : count;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:84:7  */
  assign n39_o = n27_o ? n31_o : n38_o;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:82:7  */
  assign n41_o = rst ? 1'b0 : n39_o;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:97:12  */
  assign g_d1_head = n50_q; // (signal)
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:101:7  */
  assign n49_o = push ? wr_data : g_d1_head;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:101:7  */
  always @(posedge clk)
    n50_q <= n49_o;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:81:5  */
  always @(posedge clk)
    n51_q <= n41_o;
  initial
    n51_q = 1'b0;
endmodule

