`timescale 1ns/1ps
module tb_yibififo;

  parameter DATA_W = 16;
  parameter DEPTH  = 16384;

  // ?????
  reg wr_clk = 0, rd_clk = 0;
  reg wr_rst_n = 0, rd_rst_n = 0;
  // ?/???
  reg wr_en = 0, rd_en = 0;
  reg [DATA_W-1:0] din;
  // ????
  wire [DATA_W-1:0] dout;
  wire full, empty;

  // ? i ??????? for ??
  integer i;

  // ??? DUT
  yibififo #(
    .DATA_W(DATA_W),
    .DEPTH(DEPTH)
  ) dut (
    .wr_clk   (wr_clk),
    .wr_rst_n (wr_rst_n),
    .wr_en    (wr_en),
    .din      (din),
    .full     (full),
    .rd_clk   (rd_clk),
    .rd_rst_n (rd_rst_n),
    .rd_en    (rd_en),
    .dout     (dout),
    .empty    (empty)
  );

  // ?/????wr_clk ?? 10ns?rd_clk ?? 12ns
  always #5  wr_clk = ~wr_clk;
  always #6  rd_clk = ~rd_clk;

  initial begin
    // ??
    wr_rst_n = 0;
    rd_rst_n = 0;
    #20;
    wr_rst_n = 1;
    rd_rst_n = 1;

    // ?? 20 ???
    wr_en = 1;
    for (i = 0; i < 20; i = i + 1) begin
      din = i;
      #10;  // ?? wr_clk ??
    end
    wr_en = 0;

    // ???????????
    #100;
    rd_en = 1;
    // ??? 20 ?????? 12ns
    repeat (20) begin
      #12;
    end
    rd_en = 0;

    #100;
    $stop;
  end

endmodule

