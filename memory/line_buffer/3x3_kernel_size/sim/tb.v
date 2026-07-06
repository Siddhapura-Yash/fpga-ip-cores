module tb;

localparam DATA_WIDTH = 8;
localparam KERNEL_SIZE = 3;
localparam IMAGE_WIDTH = 8;
localparam IMAGE_HEIGHT = 8;

reg clk;
reg rst;
reg [DATA_WIDTH-1:0]data_in;
reg data_in_valid;
wire [DATA_WIDTH*KERNEL_SIZE*KERNEL_SIZE-1:0]data_out;
wire data_out_valid;

control_logic #(.DATA_WIDTH(DATA_WIDTH),
                .KERNEL_SIZE(KERNEL_SIZE),
                .IMAGE_WIDTH(IMAGE_WIDTH))
DUT (
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_in_valid(data_in_valid),
    .data_out(data_out),
    .data_out_valid(data_out_valid)
);

integer i;

initial 
begin
    clk = 0;
    rst = 1;
    data_in_valid = 0;
end

reg [7:0]weight[0:IMAGE_WIDTH*IMAGE_HEIGHT-1];

initial begin
    $readmemh("img.hex",weight);
end

always #5 clk = ~clk;

initial 
begin
    rst = 0;
    #10
    rst = 1;

    for(i=0; i<IMAGE_HEIGHT*IMAGE_WIDTH; i++)
    begin
        @(negedge clk);
        data_in = weight[i];
        data_in_valid = 1'b1;
    end
        @(negedge clk);
        data_in_valid = 1'b0;

        #500;
$finish;
end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb);
end

endmodule