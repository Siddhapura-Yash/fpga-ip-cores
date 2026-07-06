module tb;

localparam DATA_WIDTH = 8;
localparam KERNEL_SIZE = 3;

reg clk;
reg rst;
reg [DATA_WIDTH*KERNEL_SIZE*KERNEL_SIZE-1:0]data_in;
reg signed [DATA_WIDTH*KERNEL_SIZE*KERNEL_SIZE-1:0]weight;
reg data_in_valid;

wire signed [19:0]data_out;
wire data_out_valid;

mac #(
    .DATA_WIDTH(DATA_WIDTH),
    .KERNEL_SIZE(KERNEL_SIZE))
DUT (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .weight(weight),
        .data_in_valid(data_in_valid),
        .data_out(data_out),
        .data_out_valid(data_out_valid)
    );

initial
begin
    clk = 0;
    rst = 1;
    data_in_valid = 0;
    data_in = 0;
    weight = 0;
end

always #5 clk = ~clk;

initial
begin
    rst = 0;

    #10;
    rst = 1;

    @(negedge clk)
    data_in_valid = 1;
    data_in = {8'd10, 8'd20, 8'd30,
               8'd40, 8'd50, 8'd60,
               8'd70, 8'd80, 8'd90};

    weight  = {8'd1, 8'd2, 8'd3,
               8'd4, 8'd5, 8'd6,
               8'd7, 8'd8, 8'd9};

    @(negedge clk)
    data_in_valid = 0;

    #50;
    $finish;
end

initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb);
end

endmodule