module edu_fifo
  (input  clk,
   input  rst,
   input  wr_valid,
   input  [7:0] wr_data,
   input  rd_ready,
   output wr_ready,
   output rd_valid,
   output [7:0] rd_data);
  reg [2:0] count;
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
  wire [2:0] n31_o;
  wire n32_o;
  wire n33_o;
  wire [31:0] n34_o;
  wire [31:0] n36_o;
  wire [2:0] n37_o;
  wire [2:0] n38_o;
  wire [2:0] n39_o;
  wire [2:0] n41_o;
  reg [1:0] g_mem_rd_ptr;
  reg [1:0] g_mem_wr_ptr;
  wire n69_o;
  wire [1:0] n72_o;
  wire [1:0] n73_o;
  wire [1:0] n74_o;
  wire n81_o;
  wire [1:0] n84_o;
  wire [1:0] n85_o;
  wire [1:0] n86_o;
  wire [1:0] n88_o;
  wire [1:0] n90_o;
  reg [1:0] n96_q;
  reg [1:0] n97_q;
  reg [2:0] n98_q;
  wire [7:0] n99_data; // mem_rd
  assign wr_ready = wr_ready_i;
  assign rd_valid = rd_valid_i;
  assign rd_data = n99_data;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:58:10  */
  always @*
    count = n98_q; // (isignal)
  initial
    count = 3'b000;
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
  assign n6_o = {29'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:68:46  */
  assign n8_o = n6_o != 32'b00000000000000000000000000000000;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:68:36  */
  assign n9_o = n8_o & n5_o;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:68:21  */
  assign n10_o = n9_o ? 1'b1 : 1'b0;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:69:30  */
  assign n13_o = ~rst;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:70:33  */
  assign n14_o = {29'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:70:33  */
  assign n16_o = n14_o != 32'b00000000000000000000000000000100;
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
  assign n28_o = {29'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:85:24  */
  assign n30_o = n28_o + 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:85:18  */
  assign n31_o = n30_o[2:0];  // trunc
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:86:32  */
  assign n32_o = ~push;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:86:23  */
  assign n33_o = n32_o & pop;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:87:24  */
  assign n34_o = {29'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:87:24  */
  assign n36_o = n34_o - 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:87:18  */
  assign n37_o = n36_o[2:0];  // trunc
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:86:7  */
  assign n38_o = n33_o ? n37_o : count;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:84:7  */
  assign n39_o = n27_o ? n31_o : n38_o;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:82:7  */
  assign n41_o = rst ? 3'b000 : n39_o;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:131:12  */
  always @*
    g_mem_rd_ptr = n96_q; // (isignal)
  initial
    g_mem_rd_ptr = 2'b00;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:132:12  */
  always @*
    g_mem_wr_ptr = n97_q; // (isignal)
  initial
    g_mem_wr_ptr = 2'b00;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:123:12  */
  assign n69_o = g_mem_rd_ptr == 2'b11;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:126:18  */
  assign n72_o = g_mem_rd_ptr + 2'b01;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:123:7  */
  assign n73_o = n69_o ? 2'b00 : n72_o;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:156:11  */
  assign n74_o = pop ? n73_o : g_mem_rd_ptr;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:123:12  */
  assign n81_o = g_mem_wr_ptr == 2'b11;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:126:18  */
  assign n84_o = g_mem_wr_ptr + 2'b01;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:123:7  */
  assign n85_o = n81_o ? 2'b00 : n84_o;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:159:11  */
  assign n86_o = push ? n85_o : g_mem_wr_ptr;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:152:9  */
  assign n88_o = rst ? 2'b00 : n74_o;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:152:9  */
  assign n90_o = rst ? 2'b00 : n86_o;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:151:7  */
  always @(posedge clk)
    n96_q <= n88_o;
  initial
    n96_q = 2'b00;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:151:7  */
  always @(posedge clk)
    n97_q <= n90_o;
  initial
    n97_q = 2'b00;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:81:5  */
  always @(posedge clk)
    n98_q <= n41_o;
  initial
    n98_q = 3'b000;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:147:20  */
  reg [7:0] g_mem_mem[3:0] ; // memory
  assign n99_data = g_mem_mem[g_mem_rd_ptr];
  always @(posedge clk)
    if (push)
      g_mem_mem[g_mem_wr_ptr] <= wr_data;
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:147:20  */
  /* /workspace/experiments/edu_fifo/v2/rtl/edu_fifo.vhd:140:15  */
endmodule

