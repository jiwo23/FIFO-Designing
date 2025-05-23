module yibififo #(
    parameter DATA_W = 16,
    parameter DEPTH = 16384              // 16K RAM
)(
    // 写侧接口
    input wire wr_clk,
    input wire wr_rst_n,
    input wire wr_en,
    input wire [DATA_W-1:0] din,
    output wire full,

    // 读侧接口
    input wire rd_clk,
    input wire rd_rst_n,
    input wire rd_en,
    output wire [DATA_W-1:0] dout,
    output wire empty
);

localparam ADDR_W = $clog2(DEPTH);

// ----------- 写指针逻辑 -----------
reg [ADDR_W:0] wr_ptr_bin, wr_ptr_bin_n;
reg [ADDR_W:0] wr_ptr_gray, wr_ptr_gray_n;

always @(*) begin
    wr_ptr_bin_n  = wr_ptr_bin + (wr_en & ~full);
    wr_ptr_gray_n = (wr_ptr_bin_n >> 1) ^ wr_ptr_bin_n;
end

always @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
        wr_ptr_bin <= 0;
        wr_ptr_gray <= 0;
    end else begin
        wr_ptr_bin <= wr_ptr_bin_n;
        wr_ptr_gray <= wr_ptr_gray_n;
    end
end

// ----------- 读指针逻辑 -----------
reg [ADDR_W:0] rd_ptr_bin, rd_ptr_bin_n;
reg [ADDR_W:0] rd_ptr_gray, rd_ptr_gray_n;

always @(*) begin
    rd_ptr_bin_n  = rd_ptr_bin + (rd_en & ~empty);
    rd_ptr_gray_n = (rd_ptr_bin_n >> 1) ^ rd_ptr_bin_n;
end

always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
        rd_ptr_bin <= 0;
        rd_ptr_gray <= 0;
    end else begin
        rd_ptr_bin <= rd_ptr_bin_n;
        rd_ptr_gray <= rd_ptr_gray_n;
    end
end

// ----------- 跨时钟同步 -----------
reg [ADDR_W:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
reg [ADDR_W:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;

always @(posedge wr_clk) begin
    rd_ptr_gray_sync1 <= rd_ptr_gray;
    rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
end

always @(posedge rd_clk) begin
    wr_ptr_gray_sync1 <= wr_ptr_gray;
    wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
end

// ----------- 满/空判断 -----------
wire [ADDR_W:0] full_compare = {~rd_ptr_gray_sync2[ADDR_W:ADDR_W-1], rd_ptr_gray_sync2[ADDR_W-2:0]};
assign full  = (wr_ptr_gray_n == full_compare);
assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);

// ----------- 存储器阵列（纯Verilog实现） -----------
reg [DATA_W-1:0] ram [0:DEPTH-1];

always @(posedge wr_clk) begin
    if (wr_en & ~full)
        ram[wr_ptr_bin[ADDR_W-1:0]] <= din;
end

assign dout = ram[rd_ptr_bin[ADDR_W-1:0]];

endmodule
