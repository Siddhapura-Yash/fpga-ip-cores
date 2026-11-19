module tb_axi4_lite_slave;

parameter int unsigned ADDR_WIDTH               = 32;
parameter int unsigned DATA_WIDTH               = 32;
parameter int unsigned NO_OF_REG                = 32;
parameter logic [ADDR_WIDTH-1:0] BASE_ADDRESS   = 32'h400F8000;

logic clk;
logic rst;

logic [ADDR_WIDTH-1:0]awadder;
logic [2:0]awport;           //not using as of now
logic awvalid;
logic awready;

logic [DATA_WIDTH-1:0]wdata;
logic [3:0]wstrb;
logic wvalid;
logic wready;

logic [1:0]bresp;
logic bvalid;
logic bready;

logic [ADDR_WIDTH-1:0]aradder;
logic [2:0]arprot;
logic arvalid;
logic arready;

logic [DATA_WIDTH-1:0]rdata;
logic [1:0]rresp;
logic rvalid;
logic rready;

axi4_lite_wrapper #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .NO_OF_REG(NO_OF_REG)
)axi4_lite_wrapper_dut(
    .ACLK_i(clk),
    .ARESETn_i(rst),

    .AWADDR_i(awadder),
    .AWPROT_i(awport),
    .AWVALID_i(awvalid),
    .AWREADY_o(awready),

    .WDATA_i(wdata),
    .WSTRB_i(wstrb),
    .WVALID_i(wvalid),
    .WREADY_o(wready),

    .BRESP_o(bresp),
    .BVALID_o(bvalid),
    .BREADY_i(bready),

    .ARADDR_i(aradder),
    .ARPROT_i(arprot),
    .ARVALID_i(arvalid),
    .ARREADY_o(arready),

    .RDATA_o(rdata),
    .RRESP_o(rresp),
    .RVALID_o(rvalid),
    .RREADY_i(rready)
);

logic [31:0] data_out;
logic [31:0] expected_data;
logic [31:0] previous_data;

logic [3:0] full_strb = 4'b1111;

task automatic write_operation (
    input logic [ADDR_WIDTH-1:0]adder,
    input logic [DATA_WIDTH-1:0]data,
    input logic [3:0]wstrb_i );

    @(negedge clk);
        awadder = adder;
        awvalid = 1'b1;

    do @(posedge clk);
        while(!awready);
    @(negedge clk)
        awvalid = 1'b0;

    @(negedge clk);
        wdata = data;
        wstrb = wstrb_i;
        wvalid = 1'b1;

    do @(posedge clk);
        while(!wready);
    @(negedge clk)
        wvalid = 1'b0;

    @(negedge clk);
        bready = 1'b1;

    do @(posedge clk);
        while(!bvalid);
    if(bresp != 00)
        $fatal(1, "BRESP error = %0b", bresp);
    @(negedge clk);
        bready = 1'b0;

endtask

task automatic read_operation (
    input logic [ADDR_WIDTH-1:0]adder,
    output logic [DATA_WIDTH-1:0]data_out
);

    @(negedge clk);
        aradder = adder;
        arvalid = 1'b1;

    do @(posedge clk);
        while(!arready);
    @(negedge clk)
        arvalid = 1'b0;

    @(negedge clk);
        rready = 1'b1;      //ready to accept new data from slvae

    do @(posedge clk);
        while(!rvalid );
    data_out = rdata;
    if(rresp != 00)
        $fatal(1, "RRESP error = %0b", rresp);
    @(negedge clk);
        rready = 1'b0;

endtask

initial begin
    clk = 0;
    rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10; rst = 1'b0;
    #10; rst = 1'b1;

    //  REGISTER : 0x400F8000
    write_operation(32'h400F8000, 32'h12345678, 4'b1111);
    read_operation(32'h400F8000, data_out);
    if (data_out !== 32'h12345678)
        $error("full write failed");

    write_operation(32'h400F8000, 32'h0000ABCD, 4'b0011);
    read_operation(32'h400F8000, data_out);
    if (data_out !== 32'h1234ABCD)
        $error("partial write failed");

    //  REGISTER : 0x400F8008
    write_operation(32'h400F8008, 32'h12345678, 4'b1111);
    read_operation(32'h400F8008, data_out);
    if (data_out !== 32'h12345678)
        $error("full write failed");

    write_operation(32'h400F8008, 32'h0000ABCD, 4'b0011);
    read_operation(32'h400F8008, data_out);
    if (data_out !== 32'h1234ABCD)
        $error("partial write failed");


    // REGISTER : 0x400F800C TO 0x400F8048

    // Full 32-bit writes
    write_operation(32'h400F800C, 32'h41414141, 4'b1111);
    write_operation(32'h400F8010, 32'h42424242, 4'b1111);
    write_operation(32'h400F8014, 32'h43434343, 4'b1111);
    write_operation(32'h400F8018, 32'h44444444, 4'b1111);
    write_operation(32'h400F801C, 32'h45454545, 4'b1111);
    write_operation(32'h400F8020, 32'h46464646, 4'b1111);
    write_operation(32'h400F8024, 32'h47474747, 4'b1111);
    write_operation(32'h400F8028, 32'h48484848, 4'b1111);
    write_operation(32'h400F802C, 32'h49494949, 4'b1111);
    write_operation(32'h400F8030, 32'h50505050, 4'b1111);
    write_operation(32'h400F8034, 32'h51515151, 4'b1111);
    write_operation(32'h400F8038, 32'h52525252, 4'b1111);
    write_operation(32'h400F803C, 32'h53535353, 4'b1111);
    write_operation(32'h400F8040, 32'h54545454, 4'b1111);
    write_operation(32'h400F8044, 32'h55555555, 4'b1111);
    write_operation(32'h400F8048, 32'h56565656, 4'b1111);

    // read and verify all (0x400F800C TO 0x400F8048) registers
    read_operation(32'h400F800C, data_out);
    if (data_out !== 32'h41414141) $error("failed");

    read_operation(32'h400F8010, data_out);
    if (data_out !== 32'h42424242) $error("failed");

    read_operation(32'h400F8014, data_out);
    if (data_out !== 32'h43434343) $error("failed");

    read_operation(32'h400F8018, data_out);
    if (data_out !== 32'h44444444) $error("failed");

    read_operation(32'h400F801C, data_out);
    if (data_out !== 32'h45454545) $error("failed");

    read_operation(32'h400F8020, data_out);
    if (data_out !== 32'h46464646) $error("failed");

    read_operation(32'h400F8024, data_out);
    if (data_out !== 32'h47474747) $error("failed");

    read_operation(32'h400F8028, data_out);
    if (data_out !== 32'h48484848) $error("failed");

    read_operation(32'h400F802C, data_out);
    if (data_out !== 32'h49494949) $error("failed");

    read_operation(32'h400F8030, data_out);
    if (data_out !== 32'h50505050) $error("failed");

    read_operation(32'h400F8034, data_out);
    if (data_out !== 32'h51515151) $error("failed");

    read_operation(32'h400F8038, data_out);
    if (data_out !== 32'h52525252) $error("failed");

    read_operation(32'h400F803C, data_out);
    if (data_out !== 32'h53535353) $error("failed");

    read_operation(32'h400F8040, data_out);
    if (data_out !== 32'h54545454) $error("failed");

    read_operation(32'h400F8044, data_out);
    if (data_out !== 32'h55555555) $error("failed");

    read_operation(32'h400F8048, data_out);
    if (data_out !== 32'h56565656) $error("failed");


    // PARTIAL STROBE TESTS
    // Update lower byte
    write_operation(32'h400F800C, 32'h000000AA, 4'b0001);
    read_operation(32'h400F800C, data_out);
    if (data_out !== 32'h414141AA)
        $error("byte strobe test failed");

    // Update lower 16 bits
    write_operation(32'h400F8010, 32'h0000BBBB, 4'b0011);
    read_operation(32'h400F8010, data_out);
    if (data_out !== 32'h4242BBBB)
        $error("half-word strobe test failed");

    // Update upper 16 bits
    write_operation(32'h400F8014, 32'hCCCC0000, 4'b1100);
    read_operation(32'h400F8014, data_out);
    if (data_out !== 32'hCCCC4343)
        $error("upper half-word strobe test failed");

    // Update bytes 0 and 2
    write_operation(32'h400F8018, 32'h00DD00DD, 4'b0101);
    read_operation(32'h400F8018, data_out);
    if (data_out !== 32'h44DD44DD)
        $error("selective byte strobe test failed");

    $display("register read/write tests completed");

#50;
$finish;
end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb_axi4_lite_slave);
end

endmodule
