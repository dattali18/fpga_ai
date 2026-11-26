module edu_fifo
  (input  clk,
   input  rst,
   input  wr_valid,
   input  [7:0] wr_data,
   input  rd_ready,
   output wr_ready,
   output rd_valid,
   output [7:0] rd_data);
  wire [31:0] mem;
  reg [1:0] rd_ptr;
  reg [1:0] wr_ptr;
  reg [2:0] count;
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
  wire [7:0] n30_o;
  wire [7:0] n32_o;
  wire [31:0] n34_o;
  wire n36_o;
  wire [7:0] n37_o;
  wire [7:0] n38_o;
  wire [31:0] n39_o;
  wire n41_o;
  wire [7:0] n42_o;
  wire [7:0] n43_o;
  wire [31:0] n44_o;
  wire n46_o;
  wire [7:0] n47_o;
  wire [7:0] n48_o;
  wire [1:0] n53_o;
  wire [31:0] n66_o;
  wire n68_o;
  wire [31:0] n70_o;
  wire [31:0] n72_o;
  wire [1:0] n73_o;
  wire [1:0] n74_o;
  wire [1:0] n75_o;
  wire [31:0] n81_o;
  wire n83_o;
  wire [31:0] n85_o;
  wire [31:0] n87_o;
  wire [1:0] n88_o;
  wire [1:0] n89_o;
  wire [1:0] n90_o;
  wire n91_o;
  wire n92_o;
  wire [31:0] n93_o;
  wire [31:0] n95_o;
  wire [2:0] n96_o;
  wire n97_o;
  wire n98_o;
  wire [31:0] n99_o;
  wire [31:0] n101_o;
  wire [2:0] n102_o;
  wire [2:0] n103_o;
  wire [2:0] n104_o;
  wire [1:0] n106_o;
  wire [1:0] n108_o;
  wire [2:0] n110_o;
  reg [31:0] n116_q;
  reg [1:0] n117_q;
  reg [1:0] n118_q;
  reg [2:0] n119_q;
  wire n120_o;
  wire n121_o;
  wire n122_o;
  wire n123_o;
  wire n124_o;
  wire n125_o;
  wire n126_o;
  wire n127_o;
  wire [7:0] n128_o;
  wire n129_o;
  wire [7:0] n130_o;
  wire [7:0] n131_o;
  wire n132_o;
  wire [7:0] n133_o;
  wire [7:0] n134_o;
  wire n135_o;
  wire [7:0] n136_o;
  wire [7:0] n137_o;
  wire n138_o;
  wire [7:0] n139_o;
  wire [31:0] n140_o;
  assign wr_ready = wr_ready_i;
  assign rd_valid = rd_valid_i;
  assign rd_data = n48_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:59:10  */
  assign mem = n116_q; // (signal)
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:60:10  */
  always @*
    rd_ptr = n117_q; // (isignal)
  initial
    rd_ptr = 2'b00;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:61:10  */
  always @*
    wr_ptr = n118_q; // (isignal)
  initial
    wr_ptr = 2'b00;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:62:10  */
  always @*
    count = n119_q; // (isignal)
  initial
    count = 3'b000;
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
  assign n8_o = {29'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:72:46  */
  assign n10_o = n8_o != 32'b00000000000000000000000000000000;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:72:36  */
  assign n11_o = n10_o & n7_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:72:21  */
  assign n12_o = n11_o ? 1'b1 : 1'b0;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:73:30  */
  assign n15_o = ~rst;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:74:33  */
  assign n16_o = {29'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:74:33  */
  assign n18_o = n16_o != 32'b00000000000000000000000000000100;
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
  assign n30_o = mem[31:24];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:7  */
  assign n32_o = n29_o ? n30_o : 8'b00000000;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:17  */
  assign n34_o = {30'b0, rd_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:17  */
  assign n36_o = n34_o == 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:88:23  */
  assign n37_o = mem[23:16];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:7  */
  assign n38_o = n36_o ? n37_o : n32_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:17  */
  assign n39_o = {30'b0, rd_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:17  */
  assign n41_o = n39_o == 32'b00000000000000000000000000000010;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:88:23  */
  assign n42_o = mem[15:8];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:7  */
  assign n43_o = n41_o ? n42_o : n38_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:17  */
  assign n44_o = {30'b0, rd_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:17  */
  assign n46_o = n44_o == 32'b00000000000000000000000000000011;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:88:23  */
  assign n47_o = mem[7:0];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:87:7  */
  assign n48_o = n46_o ? n47_o : n43_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:13  */
  assign n53_o = 2'b11 - wr_ptr;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:10  */
  assign n66_o = {30'b0, rd_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:10  */
  assign n68_o = n66_o == 32'b00000000000000000000000000000011;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:16  */
  assign n70_o = {30'b0, rd_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:16  */
  assign n72_o = n70_o + 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:7  */
  assign n73_o = n72_o[1:0];  // trunc
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:5  */
  assign n74_o = n68_o ? 2'b00 : n73_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:113:9  */
  assign n75_o = pop ? n74_o : rd_ptr;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:10  */
  assign n81_o = {30'b0, wr_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:10  */
  assign n83_o = n81_o == 32'b00000000000000000000000000000011;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:16  */
  assign n85_o = {30'b0, wr_ptr};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:16  */
  assign n87_o = n85_o + 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:55:7  */
  assign n88_o = n87_o[1:0];  // trunc
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:52:5  */
  assign n89_o = n83_o ? 2'b00 : n88_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:116:9  */
  assign n90_o = push ? n89_o : wr_ptr;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:119:31  */
  assign n91_o = ~pop;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:119:23  */
  assign n92_o = n91_o & push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:120:26  */
  assign n93_o = {29'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:120:26  */
  assign n95_o = n93_o + 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:120:20  */
  assign n96_o = n95_o[2:0];  // trunc
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:121:34  */
  assign n97_o = ~push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:121:25  */
  assign n98_o = n97_o & pop;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:122:26  */
  assign n99_o = {29'b0, count};  //  uext
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:122:26  */
  assign n101_o = n99_o - 32'b00000000000000000000000000000001;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:122:20  */
  assign n102_o = n101_o[2:0];  // trunc
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:121:9  */
  assign n103_o = n98_o ? n102_o : count;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:119:9  */
  assign n104_o = n92_o ? n96_o : n103_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:108:7  */
  assign n106_o = rst ? 2'b00 : n75_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:108:7  */
  assign n108_o = rst ? 2'b00 : n90_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:108:7  */
  assign n110_o = rst ? 3'b000 : n104_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:97:5  */
  always @(posedge clk)
    n116_q <= n140_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:107:5  */
  always @(posedge clk)
    n117_q <= n106_o;
  initial
    n117_q = 2'b00;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:107:5  */
  always @(posedge clk)
    n118_q <= n108_o;
  initial
    n118_q = 2'b00;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:107:5  */
  always @(posedge clk)
    n119_q <= n110_o;
  initial
    n119_q = 3'b000;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n120_o = n53_o[1];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n121_o = ~n120_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n122_o = n53_o[0];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n123_o = ~n122_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n124_o = n121_o & n123_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n125_o = n121_o & n122_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n126_o = n120_o & n123_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n127_o = n120_o & n122_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:50:12  */
  assign n128_o = mem[7:0];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n129_o = n124_o & push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n130_o = n129_o ? wr_data : n128_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:50:12  */
  assign n131_o = mem[15:8];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n132_o = n125_o & push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n133_o = n132_o ? wr_data : n131_o;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:97:5  */
  assign n134_o = mem[23:16];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n135_o = n126_o & push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n136_o = n135_o ? wr_data : n134_o;
  assign n137_o = mem[31:24];
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n138_o = n127_o & push;
  /* /workspace/experiments/edu_fifo/rtl/edu_fifo.vhd:99:9  */
  assign n139_o = n138_o ? wr_data : n137_o;
  assign n140_o = {n139_o, n136_o, n133_o, n130_o};
endmodule

