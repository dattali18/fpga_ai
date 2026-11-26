module edu_fifo
  (input  clk,
   input  rst,
   input  wr_valid,
   input  [1:0] wr_data,
   input  rd_ready,
   output wr_ready,
   output rd_valid,
   output [1:0] rd_data);
  wire [3:0] mem;
  reg rd_ptr;
  reg wr_ptr;
  reg [1:0] count;
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
  wire [31:0] n27_o;
  wire n29_o;
  wire [1:0] n30_o;
  wire [1:0] n32_o;
  wire [31:0] n34_o;
  wire n36_o;
  wire [1:0] n37_o;
  wire [1:0] n38_o;
  wire n43_o;
  wire [31:0] n56_o;
  wire n58_o;
  wire [31:0] n60_o;
  wire [31:0] n62_o;
  wire n63_o;
  wire n64_o;
  wire n65_o;
  wire [31:0] n71_o;
  wire n73_o;
  wire [31:0] n75_o;
  wire [31:0] n77_o;
  wire n78_o;
  wire n79_o;
  wire n80_o;
  wire n81_o;
  wire n82_o;
  wire [31:0] n83_o;
  wire [31:0] n85_o;
  wire [1:0] n86_o;
  wire n87_o;
  wire n88_o;
  wire [31:0] n89_o;
  wire [31:0] n91_o;
  wire [1:0] n92_o;
  wire [1:0] n93_o;
  wire [1:0] n94_o;
  wire n96_o;
  wire n98_o;
  wire [1:0] n100_o;
  reg [3:0] n106_q;
  reg n107_q;
  reg n108_q;
  reg [1:0] n109_q;
  wire n110_o;
  wire n111_o;
  wire [1:0] n112_o;
  wire n113_o;
  wire [1:0] n114_o;
  wire [1:0] n115_o;
  wire n116_o;
  wire [1:0] n117_o;
  wire [3:0] n118_o;
  assign wr_ready = wr_ready_i;
  assign rd_valid = rd_valid_i;
  assign rd_data = n38_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:59:10  */
  assign mem = n106_q; // (signal)
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:60:10  */
  always @*
    rd_ptr = n107_q; // (isignal)
  initial
    rd_ptr = 1'b0;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:61:10  */
  always @*
    wr_ptr = n108_q; // (isignal)
  initial
    wr_ptr = 1'b0;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:62:10  */
  always @*
    count = n109_q; // (isignal)
  initial
    count = 2'b00;
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
  assign n8_o = {30'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:72:46  */
  assign n10_o = n8_o != 32'b00000000000000000000000000000000;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:72:36  */
  assign n11_o = n10_o & n7_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:72:21  */
  assign n12_o = n11_o ? 1'b1 : 1'b0;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:73:30  */
  assign n15_o = ~rst;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:74:33  */
  assign n16_o = {30'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:74:33  */
  assign n18_o = n16_o != 32'b00000000000000000000000000000010;
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
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:17  */
  assign n27_o = {31'b0, rd_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:17  */
  assign n29_o = n27_o == 32'b00000000000000000000000000000000;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:88:23  */
  assign n30_o = mem[3:2];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:7  */
  assign n32_o = n29_o ? n30_o : 2'b00;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:17  */
  assign n34_o = {31'b0, rd_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:17  */
  assign n36_o = n34_o == 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:88:23  */
  assign n37_o = mem[1:0];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:7  */
  assign n38_o = n36_o ? n37_o : n32_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:13  */
  assign n43_o = 1'b1 - wr_ptr;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:10  */
  assign n56_o = {31'b0, rd_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:10  */
  assign n58_o = n56_o == 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:16  */
  assign n60_o = {31'b0, rd_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:16  */
  assign n62_o = n60_o + 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:7  */
  assign n63_o = n62_o[0];  // trunc
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:5  */
  assign n64_o = n58_o ? 1'b0 : n63_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:113:9  */
  assign n65_o = pop ? n64_o : rd_ptr;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:10  */
  assign n71_o = {31'b0, wr_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:10  */
  assign n73_o = n71_o == 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:16  */
  assign n75_o = {31'b0, wr_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:16  */
  assign n77_o = n75_o + 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:7  */
  assign n78_o = n77_o[0];  // trunc
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:5  */
  assign n79_o = n73_o ? 1'b0 : n78_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:116:9  */
  assign n80_o = push ? n79_o : wr_ptr;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:119:31  */
  assign n81_o = ~pop;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:119:23  */
  assign n82_o = n81_o & push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:120:26  */
  assign n83_o = {30'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:120:26  */
  assign n85_o = n83_o + 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:120:20  */
  assign n86_o = n85_o[1:0];  // trunc
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:121:34  */
  assign n87_o = ~push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:121:25  */
  assign n88_o = n87_o & pop;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:122:26  */
  assign n89_o = {30'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:122:26  */
  assign n91_o = n89_o - 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:122:20  */
  assign n92_o = n91_o[1:0];  // trunc
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:121:9  */
  assign n93_o = n88_o ? n92_o : count;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:119:9  */
  assign n94_o = n82_o ? n86_o : n93_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:108:7  */
  assign n96_o = rst ? 1'b0 : n65_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:108:7  */
  assign n98_o = rst ? 1'b0 : n80_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:108:7  */
  assign n100_o = rst ? 2'b00 : n94_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:97:5  */
  always @(posedge clk)
    n106_q <= n118_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:107:5  */
  always @(posedge clk)
    n107_q <= n96_o;
  initial
    n107_q = 1'b0;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:107:5  */
  always @(posedge clk)
    n108_q <= n98_o;
  initial
    n108_q = 1'b0;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:107:5  */
  always @(posedge clk)
    n109_q <= n100_o;
  initial
    n109_q = 2'b00;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n110_o = n43_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n111_o = ~n110_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:34:5  */
  assign n112_o = mem[1:0];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n113_o = n111_o & push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n114_o = n113_o ? wr_data : n112_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:50:12  */
  assign n115_o = mem[3:2];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n116_o = n110_o & push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n117_o = n116_o ? wr_data : n115_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:50:12  */
  assign n118_o = {n117_o, n114_o};
endmodule

