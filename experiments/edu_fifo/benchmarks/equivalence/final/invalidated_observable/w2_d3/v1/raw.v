module edu_fifo
  (input  clk,
   input  rst,
   input  wr_valid,
   input  [1:0] wr_data,
   input  rd_ready,
   output wr_ready,
   output rd_valid,
   output [1:0] rd_data);
  wire [5:0] mem;
  reg [1:0] rd_ptr;
  reg [1:0] wr_ptr;
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
  wire [31:0] n39_o;
  wire n41_o;
  wire [1:0] n42_o;
  wire [1:0] n43_o;
  wire [1:0] n48_o;
  wire [31:0] n61_o;
  wire n63_o;
  wire [31:0] n65_o;
  wire [31:0] n67_o;
  wire [1:0] n68_o;
  wire [1:0] n69_o;
  wire [1:0] n70_o;
  wire [31:0] n76_o;
  wire n78_o;
  wire [31:0] n80_o;
  wire [31:0] n82_o;
  wire [1:0] n83_o;
  wire [1:0] n84_o;
  wire [1:0] n85_o;
  wire n86_o;
  wire n87_o;
  wire [31:0] n88_o;
  wire [31:0] n90_o;
  wire [1:0] n91_o;
  wire n92_o;
  wire n93_o;
  wire [31:0] n94_o;
  wire [31:0] n96_o;
  wire [1:0] n97_o;
  wire [1:0] n98_o;
  wire [1:0] n99_o;
  wire [1:0] n101_o;
  wire [1:0] n103_o;
  wire [1:0] n105_o;
  reg [5:0] n111_q;
  reg [1:0] n112_q;
  reg [1:0] n113_q;
  reg [1:0] n114_q;
  wire n115_o;
  wire n116_o;
  wire n117_o;
  wire n118_o;
  wire n119_o;
  wire n120_o;
  wire n121_o;
  wire [1:0] n122_o;
  wire n123_o;
  wire [1:0] n124_o;
  wire [1:0] n125_o;
  wire n126_o;
  wire [1:0] n127_o;
  wire [1:0] n128_o;
  wire n129_o;
  wire [1:0] n130_o;
  wire [5:0] n131_o;
  assign wr_ready = wr_ready_i;
  assign rd_valid = rd_valid_i;
  assign rd_data = n43_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:59:10  */
  assign mem = n111_q; // (signal)
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:60:10  */
  always @*
    rd_ptr = n112_q; // (isignal)
  initial
    rd_ptr = 2'b00;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:61:10  */
  always @*
    wr_ptr = n113_q; // (isignal)
  initial
    wr_ptr = 2'b00;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:62:10  */
  always @*
    count = n114_q; // (isignal)
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
  assign n18_o = n16_o != 32'b00000000000000000000000000000011;
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
  assign n27_o = {30'b0, rd_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:17  */
  assign n29_o = n27_o == 32'b00000000000000000000000000000000;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:88:23  */
  assign n30_o = mem[5:4];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:7  */
  assign n32_o = n29_o ? n30_o : 2'b00;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:17  */
  assign n34_o = {30'b0, rd_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:17  */
  assign n36_o = n34_o == 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:88:23  */
  assign n37_o = mem[3:2];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:7  */
  assign n38_o = n36_o ? n37_o : n32_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:17  */
  assign n39_o = {30'b0, rd_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:17  */
  assign n41_o = n39_o == 32'b00000000000000000000000000000010;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:88:23  */
  assign n42_o = mem[1:0];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:7  */
  assign n43_o = n41_o ? n42_o : n38_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:13  */
  assign n48_o = 2'b10 - wr_ptr;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:10  */
  assign n61_o = {30'b0, rd_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:10  */
  assign n63_o = n61_o == 32'b00000000000000000000000000000010;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:16  */
  assign n65_o = {30'b0, rd_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:16  */
  assign n67_o = n65_o + 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:7  */
  assign n68_o = n67_o[1:0];  // trunc
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:5  */
  assign n69_o = n63_o ? 2'b00 : n68_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:113:9  */
  assign n70_o = pop ? n69_o : rd_ptr;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:10  */
  assign n76_o = {30'b0, wr_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:10  */
  assign n78_o = n76_o == 32'b00000000000000000000000000000010;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:16  */
  assign n80_o = {30'b0, wr_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:16  */
  assign n82_o = n80_o + 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:7  */
  assign n83_o = n82_o[1:0];  // trunc
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:5  */
  assign n84_o = n78_o ? 2'b00 : n83_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:116:9  */
  assign n85_o = push ? n84_o : wr_ptr;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:119:31  */
  assign n86_o = ~pop;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:119:23  */
  assign n87_o = n86_o & push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:120:26  */
  assign n88_o = {30'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:120:26  */
  assign n90_o = n88_o + 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:120:20  */
  assign n91_o = n90_o[1:0];  // trunc
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:121:34  */
  assign n92_o = ~push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:121:25  */
  assign n93_o = n92_o & pop;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:122:26  */
  assign n94_o = {30'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:122:26  */
  assign n96_o = n94_o - 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:122:20  */
  assign n97_o = n96_o[1:0];  // trunc
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:121:9  */
  assign n98_o = n93_o ? n97_o : count;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:119:9  */
  assign n99_o = n87_o ? n91_o : n98_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:108:7  */
  assign n101_o = rst ? 2'b00 : n70_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:108:7  */
  assign n103_o = rst ? 2'b00 : n85_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:108:7  */
  assign n105_o = rst ? 2'b00 : n99_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:97:5  */
  always @(posedge clk)
    n111_q <= n131_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:107:5  */
  always @(posedge clk)
    n112_q <= n101_o;
  initial
    n112_q = 2'b00;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:107:5  */
  always @(posedge clk)
    n113_q <= n103_o;
  initial
    n113_q = 2'b00;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:107:5  */
  always @(posedge clk)
    n114_q <= n105_o;
  initial
    n114_q = 2'b00;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n115_o = n48_o[1];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n116_o = ~n115_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n117_o = n48_o[0];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n118_o = ~n117_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n119_o = n116_o & n118_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n120_o = n116_o & n117_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n121_o = n115_o & n118_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:50:12  */
  assign n122_o = mem[1:0];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n123_o = n119_o & push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n124_o = n123_o ? wr_data : n122_o;
  assign n125_o = mem[3:2];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n126_o = n120_o & push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n127_o = n126_o ? wr_data : n125_o;
  assign n128_o = mem[5:4];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n129_o = n121_o & push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n130_o = n129_o ? wr_data : n128_o;
  assign n131_o = {n130_o, n127_o, n124_o};
endmodule

