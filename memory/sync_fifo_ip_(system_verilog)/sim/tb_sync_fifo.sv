module tb_sync_fifo;

parameter int unsigned DATA_WIDTH = 8;
parameter int unsigned DEPTH = 4;
parameter int unsigned PTR_WIDTH = $clog2(DEPTH);

logic clk;
logic rst;
logic r_en;
logic w_en;
logic mode;
logic [DATA_WIDTH-1:0]data_in;

logic [DATA_WIDTH-1:0]data_out;
logic [PTR_WIDTH:0]data_count;
logic full;
logic empty;
logic rd_valid;
logic underflow;
logic overflow;

sync_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .PTR_WIDTH(PTR_WIDTH)
)sync_dut(
    .clk_i(clk),
    .rst_n_i(rst),
    .r_en_i(r_en),
    .w_en_i(w_en),
    .mode_i(mode),
    .data_in_i(data_in),
    .data_out_o(data_out),
    .data_count_o(data_count),
    .full_o(full),
    .empty_o(empty),
    .rd_valid_o(rd_valid),
    .overflow_o(overflow),
    .underflow_o(underflow)
);

initial begin
    clk = 0;
    rst = 1;
    r_en = 0;
    w_en = 0;
    mode = 0;
end

always #5 clk = ~clk;

initial begin
    #10; rst = 0;
    #10; rst = 1;

    @(negedge clk);
    mode = 0;
    data_in = 8'd1;
    w_en = 1'b1;

    @(negedge clk);
    data_in = 8'd2;
    w_en = 1'b1;

    @(negedge clk);
    data_in = 8'd3;
    w_en = 1'b1;

    @(negedge clk);
    data_in = 8'd4;
    w_en = 1'b1;

    @(negedge clk);
    w_en = 1'b0;

#10;
    @(negedge clk);
    r_en = 1'b1;

    @(negedge clk);
    r_en = 1'b0;


    @(negedge clk);
    data_in = 8'd5;
    w_en = 1'b1;

    @(negedge clk);
    data_in = 8'd6;
    w_en = 1'b1;

    @(negedge clk);
    w_en = 1'b0;


    @(negedge clk);
    r_en = 1'b1;

    @(negedge clk);
    r_en = 1'b1;

    @(negedge clk);
    r_en = 1'b1;

    @(negedge clk);
    r_en = 1'b1;

    @(negedge clk);
    r_en = 1'b1;

    @(negedge clk);
    r_en = 1'b0;


    @(negedge clk);
    data_in = 8'd7;
    w_en = 1'b1;

    @(negedge clk);
    data_in = 8'd8;
    w_en = 1'b1;

    @(negedge clk);
    data_in = 8'd9;
    w_en = 1'b1;

    @(negedge clk);
    data_in = 8'd10;
    w_en = 1'b1;

    @(negedge clk);
    w_en = 1'b0;


    @(negedge clk);
    r_en = 1'b1;

    @(negedge clk);
    r_en = 1'b1;

    @(negedge clk);
    r_en = 1'b1;

    @(negedge clk);
    r_en = 1'b1;

    @(negedge clk);
    r_en = 1'b0;

#100;
$finish;
end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb_sync_fifo);
end

endmodule
