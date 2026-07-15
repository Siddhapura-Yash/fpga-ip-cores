`include "async_top.v"
`include "2_ff_synchronizer.v"
`include "wptr_handler.v"
`include "rptr_handler.v"
`include "memory.v"

`timescale 1ns / 1ps

module tb;
  
  parameter TB_DATA_WIDTH = 8;
  parameter TB_DEPTH = 8; 
  parameter PTR_WIDTH = $clog2(TB_DEPTH);
  parameter [PTR_WIDTH:0] TB_PROG_FULL_VALUE = 3;
  parameter [PTR_WIDTH:0] TB_PROG_EMPTY_VALUE = 3;
  parameter TB_MODE = 1;    

  reg wclk;
  reg rclk;
  reg wrst;
  reg rrst;
  reg w_en;
  reg r_en;
  reg [TB_DATA_WIDTH - 1 : 0]data_in;

  wire [TB_DATA_WIDTH - 1 : 0]data_out;
  wire full;
  wire empty;
  wire rst_busy;
  wire half_empty;
  wire half_full;
  wire rd_valid;
  wire underflow;
  wire overflow;
  wire prog_full;
  wire prog_empty;
  wire wr_ack;
  wire almost_full;
  wire almost_empty;
  wire [PTR_WIDTH:0] data_count;

  async_top #(
    .DEPTH(TB_DEPTH),
    .DATA_WIDTH(TB_DATA_WIDTH),
    .PROG_FULL_VALUE(TB_PROG_FULL_VALUE),
    .PROG_EMPTY_VALUE(TB_PROG_EMPTY_VALUE),
    .MODE(TB_MODE)
  ) DUT (
    .wclk(wclk),
    .wr_rst_n(wrst),
    .rclk(rclk),
    .rd_rst_n(rrst),
    .w_en(w_en),
    .r_en(r_en),
    .data_in(data_in),
    .data_out(data_out),
    
    /* output flags */
    .full(full),
    .empty(empty),
    .rst_busy(rst_busy),
    .half_empty(half_empty),
    .half_full(half_full),
    .rd_valid(rd_valid),
    .underflow(underflow),
    .overflow(overflow),
    .prog_full(prog_full),
    .prog_empty(prog_empty),
    .wr_ack(wr_ack),
    .almost_full(almost_full),
    .almost_empty(almost_empty),
    .data_count(data_count)
  );
  
  initial begin
    rclk = 0;
    wclk = 0;
    rrst = 1;
    wrst = 1;
  end
  
  always #10 wclk = ~wclk;   //50Mhz
  always #5 rclk = ~rclk;   //33.3Mhz

  initial begin
  wrst = 0; rrst = 0;
  w_en = 0; r_en = 0;
  data_in = 0;

/* 
  async FIFO has a 2 pipeline stages of flip-flops
  binary ptr -> gray ptr -> sync FF1 -> sync FF2 -> flag logic
  so reset must be held for multiple clock edges to clear all stages
  If reset is released in only one cycle, some FFs still keep old/unknown values -> FULL/EMPTY become wrong
*/
  repeat(5) @(posedge wclk); wrst = 1;
  repeat(5) @(posedge rclk); rrst = 1;
#100;

/* ------------------------------------------iteration 1------------------------------------------ */
/* WRITE - Iteration 1 */
  repeat(TB_DEPTH + 1) begin
      @(posedge wclk);
      if(!full) begin
        w_en <= 1;
        data_in <= $urandom;
      end else begin
        w_en <= 0;
      end
    end
    @(posedge wclk); 
    w_en <= 0;
    
#100;

/* READ - Iteration 1 */
   repeat(TB_DEPTH) begin
      @(posedge rclk);
      if(!empty) begin
        r_en <= 1;
      end else begin
        r_en <= 0;
      end
    end
    @(posedge rclk); 
    r_en <= 0;

#100;

/* ------------------------------------------iteration 2------------------------------------------ */
/* WRITE - Iteration 2 */
    repeat(TB_DEPTH) begin
      @(posedge wclk);
      if(!full) begin
        w_en <= 1;
        data_in <= $urandom;
      end else begin
        w_en <= 0;
      end
    end
    @(posedge wclk); 
    w_en <= 0;

#100;

/* READ - Iteration 2 */
   repeat(TB_DEPTH + 1) begin
      @(posedge rclk);
      if(!empty) begin
        r_en <= 1;
      end else begin
        r_en <= 0;
      end
    end
    @(posedge rclk); 
    r_en <= 0;

  #1000 
  $finish;

end
    
  initial begin
    $monitor("w_en = %b | r_en = %b | full = %b | data_in = %h | data_out = %h",w_en,r_en,full,data_in,data_out);
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb);
  end
  
endmodule