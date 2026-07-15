/*
  Testbench Configuration

  Select the FIFO operating mode by setting the MODE parameter.

  MODE = 0 : FWFT (First Word Fall Through)
  Data is available at the output without asserting read enable.

  MODE = 1 : Standard FIFO
  Data is available only after read enable is asserted.
*/

`timescale 1ns/1ps

module tb;

  localparam DATA_WIDTH = 8;
  localparam DEPTH      = 8;
  localparam PTR_WIDTH  = $clog2(DEPTH);
  localparam [PTR_WIDTH:0]PROG_EMPTY_VALUE = 5;
  localparam [PTR_WIDTH:0]PROG_FULL_VALUE = 3;
  localparam MODE = 1;
  
  reg clk;
  reg rst_n;
  reg r_en;
  reg w_en;
  reg [DATA_WIDTH-1:0] data_in;

  wire [DATA_WIDTH-1:0] data_out;
  wire full;
  wire empty;
  wire rst_busy;
  wire half_full;
  wire half_empty;
  wire almost_full;
  wire almost_empty;
  wire [$clog2(DEPTH+1)-1:0] data_count;
  wire prog_full;
  wire prog_empty;
  wire overflow;
  wire underflow;
  wire wr_ack;
  wire rd_valid;

  sync_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .PROG_FULL_VALUE(PROG_FULL_VALUE),
    .PROG_EMPTY_VALUE(PROG_EMPTY_VALUE),
    .MODE(MODE)
  ) DUT (
    .clk(clk),
    .rst_n(rst_n),
    .r_en(r_en),
    .w_en(w_en),
    .data_in(data_in),
    .prog_full(prog_full),
    .data_out(data_out),
    .full(full),
    .empty(empty),
    .rst_busy(rst_busy),
    .half_full(half_full),
    .half_empty(half_empty),
    .data_count(data_count),
    .almost_full(almost_full),
    .almost_empty(almost_empty),
    .overflow(overflow),
    .underflow(underflow),
    .wr_ack(wr_ack),
    .rd_valid(rd_valid),
    .prog_empty(prog_empty)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    rst_n   = 0;
    w_en  = 0;
    r_en  = 0;
    data_in = 0;

    repeat(5) @(posedge clk);
    rst_n = 1;
  end

  task write_fifo(input integer num);
    integer i;
    begin
      for(i = 0; i < num; i = i + 1) begin
        @(posedge clk);
        if(!full) begin
          w_en    <= 1;
          data_in <= i + 10;
        end
        else
          w_en <= 0;
      end
      @(posedge clk);
      w_en <= 0;
    end
  endtask

  task read_fifo(input integer num);
    integer i;
    begin
      for(i = 0; i < num; i = i + 1) begin
        @(posedge clk);
        if(!empty)
          r_en <= 1;
        else
          r_en <= 0;
      end
      @(posedge clk);
      r_en <= 0;
    end
  endtask

  task simultaneous_rw(input integer num);
    integer i;
    begin
      for(i = 0; i < num; i = i + 1) begin
        @(posedge clk);
        w_en    <= !full;
        r_en    <= !empty;
        data_in <= $urandom_range(0,255);
      end
      @(posedge clk);
      w_en <= 0;
      r_en <= 0;
    end
  endtask

  initial begin
    @(posedge rst_n);

    write_fifo(DEPTH);

    read_fifo(DEPTH);

    write_fifo(DEPTH/2);

    #20;

    simultaneous_rw(DEPTH);

    read_fifo(DEPTH);

    #100;
    $display("TEST COMPLETED");
    $finish;
  end

  initial begin
    $monitor("Time=%0t | w_en=%b r_en=%b | full=%b empty=%b | half_full=%b half_empty=%b | count=%0d | din=%0d dout=%0d",
             $time, w_en, r_en, full, empty, half_full, half_empty, data_count, data_in, data_out);
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb);
  end

endmodule
