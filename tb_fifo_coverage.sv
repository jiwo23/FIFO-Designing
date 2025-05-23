`timescale 1ns/1ps

module tb_fifo_coverage;

  //--------------------------------------------------------------------------
  // ?????
  //--------------------------------------------------------------------------
  localparam DATA_W = 16;
  localparam DEPTH  = 64;

  // ?/??????
  reg wr_clk    = 0, rd_clk = 0;
  reg wr_rst_n  = 0, rd_rst_n = 0;

  // ?/????????
  reg               wr_en = 0, rd_en = 0;
  reg  [DATA_W-1:0] din;
  wire [DATA_W-1:0] dout;
  wire              full, empty;

  //--------------------------------------------------------------------------
  // DUT ???
  //--------------------------------------------------------------------------
  yibififo #(
    .DATA_W(DATA_W),
    .DEPTH (DEPTH)
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

  //--------------------------------------------------------------------------
  // ????????
  //--------------------------------------------------------------------------
  covergroup cg_fifo @(posedge wr_clk);
    coverpoint full   { bins full_miss = {0}, full_hit = {1}; }
    coverpoint empty  { bins empty_miss = {0}, empty_hit = {1}; }
    coverpoint wr_en  { bins wr0 = {0}, wr1 = {1}; }
    coverpoint rd_en  { bins rd0 = {0}, rd1 = {1}; }
    cross full, wr_en;   // ???? full & wr_en
    cross empty, rd_en;  // ???? empty & rd_en
  endgroup

  cg_fifo cg_fifo;  // covergroup ??

  //--------------------------------------------------------------------------
  // ????
  //--------------------------------------------------------------------------
  always #5  wr_clk = ~wr_clk;  // ????? 10ns
  always #7  rd_clk = ~rd_clk;  // ????? 14ns

  //--------------------------------------------------------------------------
  // ?????????
  //--------------------------------------------------------------------------
  initial begin
    // ??
    wr_rst_n = 0;
    rd_rst_n = 0;
    #20;
    wr_rst_n = 1;
    rd_rst_n = 1;
    // ?????????????
    @(posedge wr_clk); @(posedge rd_clk);

    // ?? Testcase ????
    test_write_full_read_empty();
    test_random_mix();
    test_boundary();

    // ????
    #100;
    $finish;
  end

  //--------------------------------------------------------------------------
  // Testcase 4.1????? ? ????? ? ???? ? ?????
  //--------------------------------------------------------------------------
  task test_write_full_read_empty();
    // 1) ???? full=1
    wr_en = 1;
    do begin
      @(posedge wr_clk);
      din = $urandom;            // ????
      cg_fifo.sample();          // ???? full/empty/wr_en/rd_en
    end while (!full);           // ???? full ?? 1

    // 2) full ??? 1 ?????????? full_hit
    @(posedge wr_clk);
    din   = $urandom;
    wr_en = 1;                   // ?????
    cg_fifo.sample();            // ?? full=1 & wr_en=1
    wr_en = 0;                   // ?????
    @(posedge wr_clk); cg_fifo.sample();

    // 3) ??? empty=1
    rd_en = 1;
    do begin
      @(posedge rd_clk);
      cg_fifo.sample();          // ??
    end while (!empty);          // ???? empty ?? 1

    // 4) empty ??? 1 ???????? empty_hit
    @(posedge rd_clk);
    rd_en = 1;                   // ?????
    cg_fifo.sample();            // ?? empty=1 & rd_en=1
    rd_en = 0;                   // ?????
    @(posedge rd_clk); cg_fifo.sample();
  endtask

  //--------------------------------------------------------------------------
  // Testcase 4.2?2000 ?????
  //--------------------------------------------------------------------------
  task test_random_mix();
    integer j;
    bit [1:0] r;
    for (j = 0; j < 2000; j = j + 1) begin
      @(posedge wr_clk);
      r      = $urandom_range(0,3);       // 0/1/2/3 ????
      wr_en  = (r == 0 || r == 2);        // 50% ?
      rd_en  = (r == 1 || r == 2);        // 50% ?
      if (wr_en) din = $urandom;          // ???
      cg_fifo.sample();                   // ??
    end
    // ???????
    wr_en = 0;
    rd_en = 0;
    @(posedge wr_clk); cg_fifo.sample();
  endtask

  //--------------------------------------------------------------------------
  // Testcase 4.3?????? & ?????
  //--------------------------------------------------------------------------
  task test_boundary();
    integer k;
    // 1) ?? FIFO
    wr_en = 1;
    for (k = 0; k < DEPTH; k = k + 1) begin
      @(posedge wr_clk);
      din = $urandom;
      cg_fifo.sample();
    end
    wr_en = 0; @(posedge wr_clk); cg_fifo.sample();

    // 2) ?????????? full_hit
    @(posedge wr_clk);
    wr_en = 1; din = 16'h1234;  // ????
    cg_fifo.sample();           // ?? full=1 & wr_en=1
    @(posedge wr_clk);
    wr_en = 0; cg_fifo.sample();

    // 3) ?? FIFO
    rd_en = 1;
    for (k = 0; k < DEPTH; k = k + 1) begin
      @(posedge rd_clk);
      cg_fifo.sample();
    end
    rd_en = 0; @(posedge rd_clk); cg_fifo.sample();

    // 4) ?????????? empty_hit
    @(posedge rd_clk);
    rd_en = 1;
    cg_fifo.sample();           // ?? empty=1 & rd_en=1
    @(posedge rd_clk);
    rd_en = 0; cg_fifo.sample();
  endtask

endmodule
